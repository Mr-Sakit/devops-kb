#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_FILE="$BASE_DIR/installations.md"
UNINSTALL_FILE="$BASE_DIR/uninstallations.md"
EXPLAIN_FILE="$BASE_DIR/explanations.md"
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

colorize_command() {
    local text="$1"

    text=$(printf '%s' "$text" | sed -E $'s/(<[^>]+>)/\\\033[1;32m\\1\\\033[0m/g')
    text=$(printf '%s' "$text" | sed -E $'s/(^|[[:space:]])(--[[:alnum:]][[:alnum:]_-]*)/\\1\\\033[1;33m\\2\\\033[0m/g')
    text=$(printf '%s' "$text" | sed -E $'s/(^|[[:space:]])(-[[:alpha:]][[:alnum:]]*)/\\1\\\033[1;33m\\2\\\033[0m/g')

    printf '%s' "$text"
}

parse_command_entry() {
    local entry="$1"

    PARSED_CMD=""
    PARSED_DESC=""

    if [[ "$entry" =~ ^\*\ \*\*(.*)\*\*\ :\ (.*)$ ]]; then
        PARSED_CMD="${BASH_REMATCH[1]}"
        PARSED_DESC="${BASH_REMATCH[2]}"
        return 0
    fi

    return 1
}

list_categories() {
    echo -e "\n\e[1;35m📚 Available command categories:\e[0m"
    grep '^# ' "$DB_FILE" | sed 's/^# //' | while IFS= read -r category; do
        echo -e "  \e[1;32m@\e[0m\e[1;36m$(echo "$category" | tr '[:upper:]' '[:lower:]')\e[0m"
    done
    echo -e "\n\e[1;33mTip:\e[0m Use \e[1;32msakit @category\e[0m to list a category.\n"
}

list_install_tools() {
    echo -e "\n\e[1;35m🛠️  Available installation tools:\e[0m"
    grep '^# ' "$INSTALL_FILE" | sed 's/^# //' | while IFS= read -r tool; do
        echo -e "  \e[1;36m$(echo "$tool" | tr '[:upper:]' '[:lower:]')\e[0m"
    done
    echo -e "\n\e[1;33mTip:\e[0m Use \e[1;32msakit install <tool>\e[0m to install a tool.\n"
}

list_uninstall_tools() {
    echo -e "\n\e[1;35m🧹 Available uninstall tools:\e[0m"
    grep '^# ' "$UNINSTALL_FILE" | sed 's/^# //' | while IFS= read -r tool; do
        echo -e "  \e[1;36m$(echo "$tool" | tr '[:upper:]' '[:lower:]')\e[0m"
    done
    echo -e "\n\e[1;33mTip:\e[0m Use \e[1;32msakit uninstall <tool>\e[0m to uninstall a tool.\n"
}

doctor_ok() {
    echo -e "✅ \e[1;32m$1\e[0m"
}

doctor_warn() {
    echo -e "⚠️  \e[1;33m$1\e[0m"
}

doctor_fail() {
    echo -e "❌ \e[1;31m$1\e[0m"
    DOCTOR_FAILED=true
}

check_data_format() {
    local file="$1"
    local type="$2"
    local invalid=""

    if [ "$type" = "commands" ]; then
        invalid=$(awk '/^\* / && $0 !~ /^\* \*\*.*\*\* : .+/ {print FNR ":" $0}' "$file")
    else
        invalid=$(awk 'NF && $0 !~ /^# [A-Z0-9 -]+$/ && $0 !~ /^(apt|dnf): / {print FNR ":" $0}' "$file")
    fi

    if [ -z "$invalid" ]; then
        doctor_ok "$file format looks valid"
    else
        doctor_fail "$file has invalid lines"
        echo "$invalid"
    fi
}

run_doctor() {
    local pkg_mgr
    DOCTOR_FAILED=false

    echo -e "\n\e[1;35m🩺 Sakit Doctor\e[0m"
    echo -e "------------------------------------"

    for file in "$DB_FILE" "$INSTALL_FILE" "$UNINSTALL_FILE" "$EXPLAIN_FILE"; do
        if [ -f "$file" ]; then
            doctor_ok "$(basename "$file") exists"
        else
            doctor_fail "$(basename "$file") is missing"
        fi
    done

    if [ -x "$BASE_DIR/devdb.sh" ]; then
        doctor_ok "devdb.sh is executable"
    else
        doctor_fail "devdb.sh is not executable"
    fi

    if bash -n "$BASE_DIR/devdb.sh"; then
        doctor_ok "devdb.sh syntax is valid"
    else
        doctor_fail "devdb.sh has syntax errors"
    fi

    [ -f "$DB_FILE" ] && check_data_format "$DB_FILE" "commands"
    [ -f "$INSTALL_FILE" ] && check_data_format "$INSTALL_FILE" "steps"
    [ -f "$UNINSTALL_FILE" ] && check_data_format "$UNINSTALL_FILE" "steps"

    pkg_mgr=$(detect_pkg_mgr)
    if [ -n "$pkg_mgr" ]; then
        doctor_ok "supported package manager detected: $pkg_mgr"
    else
        doctor_fail "no supported package manager detected (dnf/apt)"
    fi

    if alias sakit &> /dev/null || grep -q "alias sakit=" ~/.bashrc 2>/dev/null; then
        doctor_ok "sakit alias is configured"
    else
        doctor_warn "sakit alias was not found in current shell or ~/.bashrc"
    fi

    if [[ -f "$CONF_FILE" ]] && grep -q 'WRITE_MODE="on"' "$CONF_FILE"; then
        doctor_ok "WRITE_MODE is on"
    else
        doctor_warn "WRITE_MODE is off or missing; add/sync features are read-only"
    fi

    if git -C "$BASE_DIR" remote get-url origin &> /dev/null; then
        doctor_ok "git origin remote is configured"
    else
        doctor_warn "git origin remote is not configured"
    fi

    echo -e "------------------------------------"
    if [ "$DOCTOR_FAILED" = true ]; then
        echo -e "❌ \e[1;31mDoctor found issues that should be fixed.\e[0m\n"
        return 1
    fi

    echo -e "✅ \e[1;32mDoctor completed. No blocking issues found.\e[0m\n"
}

render_explain_line() {
    local line="$1"

    if [[ "$line" == '```'* ]]; then
        if [ "$EXPLAIN_CODE_BLOCK" = true ]; then
            EXPLAIN_CODE_BLOCK=false
        else
            EXPLAIN_CODE_BLOCK=true
        fi
        return
    fi

    if [ "$EXPLAIN_CODE_BLOCK" = true ]; then
        printf '  %s\n' "$(colorize_command "$line")"
        return
    fi

    if [[ "$line" == "## "* ]]; then
        printf '\n\e[1;34m%s\e[0m\n' "${line#'## '}"
        return
    fi

    if [[ "$line" == "- "* ]]; then
        line="${line#- }"
        line="${line//\`/}"
        printf '  \e[1;33m-\e[0m %s\n' "$line"
        return
    fi

    line="${line//\`/}"
    printf '%s\n' "$line"
}

explain_topic() {
    local topic
    local key
    local found=false
    EXPLAIN_CODE_BLOCK=false

    topic=$(echo "$*" | xargs)
    key=$(echo "$topic" | tr '[:lower:]' '[:upper:]')

    if [ -z "$topic" ]; then
        echo -e "❌ \e[1;31mUsage: sakit explain [topic]\e[0m"
        return 1
    fi

    if [ ! -f "$EXPLAIN_FILE" ]; then
        echo -e "❌ \e[1;31mexplanations.md not found.\e[0m"
        return 1
    fi

    while IFS= read -r line; do
        if [[ "$line" == "# "* ]]; then
            current_topic=$(echo "$line" | sed 's/^# //' | xargs)
            if [ "$current_topic" == "$key" ]; then
                found=true
                echo -e "\n\e[1;35m📖 $current_topic\e[0m"
                continue
            elif [ "$found" = true ]; then
                break
            fi
        fi

        if [ "$found" = true ]; then
            render_explain_line "$line"
        fi
    done < "$EXPLAIN_FILE"

    if [ "$found" = false ]; then
        echo -e "❌ \e[1;31mNo explanation found for '$topic'.\e[0m"
        echo -e "💡 Try a base command like: \e[1;32mdocker run\e[0m, \e[1;32mkubectl apply\e[0m, \e[1;32mterraform init\e[0m\n"
        return 1
    fi
}

# If user types 'sakit add'
if [ "$1" == "add" ]; then
    add_command
    exit 0
fi

# If user types 'sakit [keyword]' (Search mode)
if [ -z "$1" ]; then
    echo -e "\e[1;33mUsage: \n  sakit [keyword]        -> Search\n  sakit @[category]      -> List Category\n  sakit list             -> List command categories\n  sakit doctor           -> Check project health\n  sakit explain <topic>  -> Show a longer explanation\n  sakit install list     -> List installable tools\n  sakit uninstall list   -> List uninstallable tools\n  sakit add              -> Add new entry\e[0m"
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
parse_tool_args() {
    PARSED_TOOL=""
    VERBOSE_MODE=false
    SHOW_MODE=false

    for arg in "$@"; do
        case "$arg" in
            "--verbose"|"--default")
                VERBOSE_MODE=true
                ;;
            "-show"|"--show")
                SHOW_MODE=true
                ;;
            "--quiet")
                VERBOSE_MODE=false
                ;;
            *)
                PARSED_TOOL="$PARSED_TOOL $arg"
                ;;
        esac
    done

    PARSED_TOOL=$(echo "$PARSED_TOOL" | xargs | tr '[:lower:]' '[:upper:]')
}

print_command_preview() {
    local action="$1"
    local tool="$2"
    local commands="$3"

    echo -e "\n\e[1;34m$action preview for \e[1;36m$tool\e[0m"
    echo -e "------------------------------------"
    printf '%s\n' "$commands"
    echo -e "------------------------------------"
    echo -e "\e[1;33mNo commands were executed.\e[0m\n"
}

installed_command_for() {
    case "$1" in
        "AZURE CLI") echo "az" ;;
        "JAVA") echo "java" ;;
        "MAVEN") echo "mvn" ;;
        "NODEJS") echo "node" ;;
        "SONARQUBE") echo "" ;;
        *) echo "$(echo "$1" | tr '[:upper:]' '[:lower:]')" ;;
    esac
}

detect_pkg_mgr() {
    if command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v apt &> /dev/null; then
        echo "apt"
    fi
}

commands_need_sudo() {
    printf '%s\n' "$1" | grep -q 'sudo '
}

run_command_steps() {
    local action="$1"
    local tool="$2"
    local commands="$3"
    local verbose="$4"
    local total=0
    local step=0
    local cmd
    local output_file=""

    total=$(printf '%s\n' "$commands" | sed '/^[[:space:]]*$/d' | wc -l)

    if [ "$verbose" = true ]; then
        echo -e "\n🚀 \e[1;32m$action started in verbose mode...\e[0m"
    else
        if commands_need_sudo "$commands"; then
            echo -e "\n🔐 \e[1;33mSudo permission may be required.\e[0m"
            sudo -v || {
                echo -e "\n❌ \e[1;31mSudo authentication failed. Stopping.\e[0m"
                return 1
            }
        fi
        echo -e "\n🚀 \e[1;32m$action $tool...\e[0m"
    fi

    while IFS= read -r cmd; do
        [ -z "$cmd" ] && continue
        step=$((step + 1))

        if [ "$verbose" = true ]; then
            echo -e "\n⚡ Running: \e[1;32m$cmd\e[0m"
            eval "$cmd"
        else
            echo -e "⏳ Step $step/$total..."
            output_file=$(mktemp)
            eval "$cmd" > "$output_file" 2>&1
        fi

        if [ $? -ne 0 ]; then
            echo -e "\n❌ \e[1;31mCommand failed! Stopping.\e[0m"
            if [ "$verbose" != true ] && [ -f "$output_file" ]; then
                echo -e "\n\e[1;34mError output:\e[0m"
                cat "$output_file"
                rm -f "$output_file"
            fi
            return 1
        fi

        [ -n "$output_file" ] && rm -f "$output_file"
        output_file=""
    done <<< "$commands"

    echo -e "\n✅ \e[1;32m$action of $tool completed successfully!\e[0m"
}

install_tool() {
    local tool
    local pkg_mgr=""
    local installed_cmd
    local commands
    local VERBOSE_MODE

    parse_tool_args "$@"
    tool="$PARSED_TOOL"
    if [ -z "$tool" ]; then
        echo -e "❌ \e[1;31mUsage: sakit install [tool] [--verbose]\e[0m"
        return 1
    fi

    installed_cmd=$(installed_command_for "$tool")
    if [ "$SHOW_MODE" != true ] && [ -n "$installed_cmd" ] && command -v "$installed_cmd" &> /dev/null; then
        echo -e "\n✅ \e[1;32m$tool is already installed.\e[0m"
        echo -e "🔎 Found command: \e[1;36m$(command -v "$installed_cmd")\e[0m\n"
        return
    fi

    # 🔍 Avtomatik OS/Paket Meneceri Tespiti
    pkg_mgr=$(detect_pkg_mgr)
    if [ -z "$pkg_mgr" ]; then
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

    if [ "$SHOW_MODE" = true ]; then
        print_command_preview "Installation" "$tool" "$commands"
        return
    fi

    echo -e "\e[1;34mThe following commands will be executed:\e[0m"
    echo -e "------------------------------------"
    echo -e "$commands"
    echo -e "------------------------------------"

    echo -ne "\e[1;33mDo you want to proceed with installation? (y/n): \e[0m"
    read -r choice

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        run_command_steps "Installation" "$tool" "$commands" "$VERBOSE_MODE"
    else
        echo -e "\n🚫 \e[1;31mInstallation cancelled.\e[0m"
    fi
}

uninstall_tool() {
    local tool
    local pkg_mgr=""
    local installed_cmd
    local commands
    local VERBOSE_MODE

    parse_tool_args "$@"
    tool="$PARSED_TOOL"
    if [ -z "$tool" ]; then
        echo -e "❌ \e[1;31mUsage: sakit uninstall [tool] [--verbose]\e[0m"
        return 1
    fi

    installed_cmd=$(installed_command_for "$tool")
    if [ "$SHOW_MODE" != true ] && [ -n "$installed_cmd" ] && ! command -v "$installed_cmd" &> /dev/null; then
        echo -e "\n✅ \e[1;32m$tool is already not installed.\e[0m\n"
        return
    fi

    pkg_mgr=$(detect_pkg_mgr)
    if [ -z "$pkg_mgr" ]; then
        echo -e "❌ \e[1;31mError: No supported package manager (dnf/apt) found!\e[0m"
        return
    fi

    echo -e "\n🛠️  Detecting System... \e[1;33m$pkg_mgr based system detected.\e[0m"
    echo -e "🔍 Searching uninstall steps for: \e[1;36m$tool\e[0m\n"

    commands=$(sed -n "/# $tool/,/#/p" "$UNINSTALL_FILE" | grep "^$pkg_mgr:" | sed "s/^$pkg_mgr: //")

    if [ -z "$commands" ]; then
        echo -e "❌ \e[1;31mNo uninstall steps found for '$tool' on $pkg_mgr.\e[0m"
        return
    fi

    if [ "$SHOW_MODE" = true ]; then
        print_command_preview "Uninstall" "$tool" "$commands"
        return
    fi

    echo -e "\e[1;34mThe following commands will be executed:\e[0m"
    echo -e "------------------------------------"
    echo -e "$commands"
    echo -e "------------------------------------"

    echo -ne "\e[1;33mDo you want to proceed with uninstall? (y/n): \e[0m"
    read -r choice

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        run_command_steps "Uninstall" "$tool" "$commands" "$VERBOSE_MODE"
    else
        echo -e "\n🚫 \e[1;31mUninstall cancelled.\e[0m"
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
    "list")
        list_categories
        exit 0
        ;;
    "doctor")
        run_doctor
        exit $?
        ;;
    "explain")
        explain_topic "${@:2}"
        exit $?
        ;;
    "install")
        if [[ "$2" == "list" ]]; then
            list_install_tools
        elif [ -z "$2" ]; then
            echo -e "❌ \e[1;31mUsage: sakit install [tool] [-show|--verbose]\e[0m"
        else
            install_tool "${@:2}"
        fi
        exit 0
        ;;
    "uninstall")
        if [[ "$2" == "list" ]]; then
            list_uninstall_tools
        elif [ -z "$2" ]; then
            echo -e "❌ \e[1;31mUsage: sakit uninstall [tool] [-show|--verbose]\e[0m"
        else
            uninstall_tool "${@:2}"
        fi
        exit 0
        ;;
    "")
        echo -e "\e[1;33mUsage: \n  sakit [keyword]          -> Search\n  sakit @[category]        -> List Category\n  sakit list               -> List command categories\n  sakit doctor             -> Check project health\n  sakit explain <topic>    -> Show a longer explanation\n  sakit install list       -> List installable tools\n  sakit uninstall list     -> List uninstallable tools\n  sakit add                -> Add new\n  sakit bulk               -> Bulk add\n  sakit install <tool>     -> Automated Install\n  sakit uninstall <tool>   -> Automated Uninstall\e[0m"
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

                if [ "$in_zone" = true ] && [[ "$line" == "*"* ]] && parse_command_entry "$line"; then
                    printf '\e[1;32m🚀 COMMAND: \e[0m %s\n' "$(colorize_command "$PARSED_CMD")"
                    printf '\e[1;34m📝 INFO:    \e[0m%s\n' "$PARSED_DESC"
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

                if echo "$line" | grep -qi "$search_term" && parse_command_entry "$line"; then
                    if [ "$current_category" != "$last_category" ]; then
                        echo -e "\e[1;35m📂 CATEGORY: $current_category\e[0m"
                        last_category="$current_category"
                    fi

                    printf '\e[1;32m🚀 COMMAND: \e[0m %s\n' "$(colorize_command "$PARSED_CMD")"
                    printf '\e[1;34m📝 INFO:    \e[0m%s\n' "$PARSED_DESC"
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
