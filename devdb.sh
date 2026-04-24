#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_FILE="$BASE_DIR/installations.md"
DB_FILE="$BASE_DIR/commands.md"
CONF_FILE="$BASE_DIR/.config"

# --- FUNCTION: ADD NEW COMMAND ---
add_command() {

	# Read configuration, default to 'off' if not present
    [[ -f "$CONF_FILE" ]] && source "$CONF_FILE" || WRITE_MODE="off"

    if [[ "$WRITE_MODE" != "on" ]]; then
        echo -e "\n❌ \e[1;31mPermission Denied: Read-Only Mode active.\e[0m"
        echo -e "💡 To enable 'add' and 'sync' features, run: \e[1;32msakit setup-git\e[0m\n"
        return
    fi
    # Check for arguments or use interactive mode
    if [ ! -z "$2" ] && [ ! -z "$3" ] && [ ! -z "$4" ]; then
        category=$(echo "$2" | tr '[:lower:]' '[:upper:]')
        cmd="$3"
        desc="$4"
    else
        echo -e "\e[1;33m--- Interactive Add Mode ---\e[0m"
        read -p "Category: " category
        category=$(echo "$category" | tr '[:lower:]' '[:upper:]')
        read -p "Command: " cmd
        read -p "Description: " desc
    fi

    # 1. Update the Markdown File
    if grep -q "# $category" "$DB_FILE"; then
        sed -i "/# $category/a **$cmd** : $desc" "$DB_FILE"
    else
        printf "\n# $category\n* **$cmd** : $desc\n" >> "$DB_FILE"
    fi

    echo -e "\e[1;32m✅ Local update successful!\e[0m"

    # 2. AUTOMATIC GIT SYNC
    echo -e "\e[1;36m🔄 Syncing with GitHub...\e[0m"

    # Move to the knowledge-base directory
    REPO_DIR=$(dirname "$DB_FILE")
    cd "$REPO_DIR" || exit

    # Git Operations
    git add commands.md

    # Commit message includes the added command for better history
    git commit -m "feat: added '$cmd' to $category"

    # Push to the remote repository (assumes 'origin' and 'main' are set)
    git push origin main

    if [ $? -eq 0 ]; then
        echo -e "\e[1;32m🚀 Successfully synced to GitHub!\e[0m\n"
    else
        echo -e "\e[1;31m⚠️  Git push failed. Please check your connection or remote settings.\e[0m\n"
    fi
}

# --- MAIN LOGIC ---

# If user types 'sakit add'
if [ "$1" == "add" ]; then
    add_command
    exit 0
fi

# If user types 'sakit [keyword]' (Search mode)
if [ -z "$1" ]; then
    echo -e "\e[1;33mUsage: \n  sakit [keyword] -> Search\n  sakit add       -> Add new entry\e[0m"
    exit 1
fi

# --- FUNCTION: BULK ADD ---
bulk_add() {
    TEMP_FILE=$(mktemp)
    echo -e "# Format:\n# .CATEGORY\n# command\n#  description (1 space at start)\n" > "$TEMP_FILE"

    nano "$TEMP_FILE"

    local current_cat=""
    local last_cmd=""

    # We set IFS= so that spaces at the beginning of the line are not removed
    while IFS= read -r line || [ -n "$line" ]; do
   		 # 1. Category: If it starts with .
        if [[ "$line" =~ ^\. ]]; then
            current_cat=$(echo "$line" | sed 's/^\.//' | tr '[:lower:]' '[:upper:]' | xargs)
            if ! grep -q "# $current_cat" "$DB_FILE"; then
                echo -e "\n# $current_cat" >> "$DB_FILE"
            fi
		# 2. Explanation: If the LESS starts with a space
        elif [[ "$line" =~ ^[[:space:]]+ ]]; then
            local desc=$(echo "$line" | xargs)
            if [ -n "$current_cat" ] && [ -n "$last_cmd" ] && [ -n "$desc" ]; then
                # We add in a neat list format
                echo "* **$last_cmd** : $desc" >> "$DB_FILE"
                echo "✅ Added to $current_cat: $last_cmd"
                last_cmd="" # After each explanation, we reset the command so that it is not repeated
            fi
            # 3. Command: If it does not start with a period or space and is not empty
        elif [[ -n "$line" && ! "$line" =~ ^# ]]; then
            last_cmd=$(echo "$line" | xargs)
        fi
    done < "$TEMP_FILE"

    rm "$TEMP_FILE"

    # Git Sync 
    cd "$(dirname "$DB_FILE")" || exit
    git add commands.md
    git commit -m "fix: corrected bulk entry logic"
    git push origin main
}


# --- INSTALLATION LOGIC ---
install_tool() {
    local tool=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    local pkg_mgr=""

    # 🔍 Avtomatik OS/Paket Meneceri Tespiti
    if command -v dnf &> /dev/null; then
        pkg_mgr="dnf"
    elif command -v apt &> /dev/null; then
        pkg_mgr="apt"
    else
        echo -e "❌ \e[1;31mError: No supported package manager (dnf/apt) found!\e[0m"
        return
    fi

    echo -e "\n🛠️  Detecting System... \e[1;33m$pkg_mgr based system detected.\e[0m"
    echo -e "🔍 Searching installation steps for: \e[1;36m$tool\e[0m\n"

    # sed logic: # Find between TOOL and next #, take lines starting with pkg_mgr
    commands=$(sed -n "/# $tool/,/#/p" "$INSTALL_FILE" | grep "^$pkg_mgr:" | sed "s/^$pkg_mgr: //")

    if [ -z "$commands" ]; then
        echo -e "❌ \e[1;31mNo installation steps found for '$tool' on $pkg_mgr.\e[0m"
        return
    fi

    echo -e "\e[1;34mThe following commands will be executed:\e[0m"
    echo -e "------------------------------------"
    echo -e "$commands"
    echo -e "------------------------------------"

    echo -ne "\e[1;33mDo you want to proceed with installation? (y/n): \e[0m"
    read -r choice

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo -e "\n🚀 \e[1;32mExecution started...\e[0m"
        while read -r cmd; do
            echo -e "\n⚡ Running: \e[1;32m$cmd\e[0m"
            eval "$cmd"

            if [ $? -ne 0 ]; then
                echo -e "\n❌ \e[1;31mCommand failed! Stopping installation.\e[0m"
                return 1
            fi
        done <<< "$commands"
        echo -e "\n✅ \e[1;32mInstallation of $tool completed successfully!\e[0m"
    else
        echo -e "\n🚫 \e[1;31mInstallation cancelled.\e[0m"
    fi
}


setup_git() {
    echo -e "\n🛠️  \e[1;34mStarting Git & SSH Setup Wizard...\e[0m"

    # 1. Git Identity
    if [[ -z "$(git config --global user.name)" ]]; then
        read -p "👤 Enter Git Username: " g_name
        read -p "📧 Enter Git Email: " g_email
        git config --global user.name "$g_name"
        git config --global user.email "$g_email"
    fi

    # 2. SSH Key Generation (ed25519)
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        echo -e "🔑 Generating new SSH key (ed25519)..."
        ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f ~/.ssh/id_ed25519 -N ""
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
    fi

    # 3. Display Public Key
    echo -e "\n✅ \e[1;32mSSH Key created successfully!\e[0m"
    echo -e "----------------------------------------------------------------"
    cat ~/.ssh/id_ed25519.pub
    echo -e "----------------------------------------------------------------"
    echo -e "👉 \e[1;33mCopy the key above and add it to:\e[0m"
    echo -e "   https://github.com/settings/keys (New SSH Key)\n"

    # 4. Enable Write Mode
    echo "WRITE_MODE=\"on\"" > "$BASE_DIR/.config"
    echo -e "🚀 \e[1;32mWrite Mode is now ENABLED. You can use 'sakit add' now.\e[0m\n"
}


# --- UPDATED MAIN LOGIC ---
case "$1" in
    "setup-git")
        setup_git
        exit 0
        ;;
    "add")
        if [[ "$2" == "on" || "$2" == "--enable" ]]; then
            setup_git
        else
            add_command "$@"
        fi
        exit 0
        ;;
    "bulk")
        bulk_add
        exit 0
        ;;
    "install")
        if [ -z "$2" ]; then
            echo -e "❌ \e[1;31mUsage: sakit install [tool]\e[0m"
        else
            install_tool "$2"
        fi
        exit 0
        ;;
    "")
        echo -e "\e[1;33mUsage: \n  sakit [keyword] -> Search\n  sakit @[category] -> List Category\n  sakit add        -> Add new\n  sakit bulk       -> Bulk add\n  sakit install   -> Automated Install\e[0m"
        ;;
    *)
        # THIS IS WHERE SEARCH LOGIC COMES INTO USE
        search_term="$*"

        echo -e "\n🔍 Searching for: '$search_term'...\n"
        last_category=""
        found=false

        if [[ "$search_term" == "@"* ]]; then
            target_cat=$(echo "$search_term" | sed 's/@//' | tr '[:lower:]' '[:upper:]' | xargs)
            in_zone=false

            while IFS= read -r line; do
                if [[ $line == "#"* ]]; then
                    current_cat=$(echo "$line" | sed 's/# //' | xargs)
                    if [ "$current_cat" == "$target_cat" ]; then
                        in_zone=true
                        echo -e "\e[1;35m📂 CATEGORY: $current_cat (Full List)\e[0m"
                        continue
                    else
                        in_zone=false
                    fi
                fi

                if [ "$in_zone" = true ] && [[ "$line" == "*"* ]]; then
                    cmd=$(echo "$line" | cut -d ':' -f 1 | sed 's/\*//g' | xargs)
                    desc=$(echo "$line" | cut -d ':' -f 2 | xargs)
                    echo -e "\e[1;32m🚀 COMMAND: \e[0m $cmd"
                    echo -e "\e[1;34m📝 INFO:    \e[0m$desc"
                    echo -e "------------------------------------"
                    found=true
                fi
            done < "$DB_FILE"
        else
            # Standard search mode
            while IFS= read -r line; do
                if [[ $line == "#"* ]]; then
                    current_category=$(echo "$line" | sed 's/# //' | xargs)
                    continue
                fi

                if echo "$line" | grep -qi "$search_term"; then
                    cmd=$(echo "$line" | cut -d ':' -f 1 | sed 's/\*//g' | xargs)
                    desc=$(echo "$line" | cut -d ':' -f 2 | xargs)

                    if [ "$current_category" != "$last_category" ]; then
                        echo -e "\e[1;35m📂 CATEGORY: $current_category\e[0m"
                        last_category="$current_category"
                    fi

                    echo -e "\e[1;32m🚀 COMMAND: \e[0m $cmd"
                    echo -e "\e[1;34m📝 INFO:    \e[0m$desc"
                    echo -e "------------------------------------"
                    found=true
                fi
            done < "$DB_FILE"
        fi

        if [ "$found" = false ]; then
            echo -e "\e[1;31m❌ No entries found for '$search_term'.\e[0m"
        fi
        ;;
esac
