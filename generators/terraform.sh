#!/bin/bash

set -u

BASE_DIR="${1:-}"
shift || true

if [ -z "$BASE_DIR" ]; then
    BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
fi

TEMPLATE_ROOT="$BASE_DIR/templates/terraform"

TEMPLATE_ID=""
PROJECT_DIR=""
PREFIX=""
LOCATION=""
VM_SIZE=""
OS_IMAGE_ID=""
SSH_PUBLIC_KEY=""
SSH_PUBLIC_KEY_FILE=""
SSH_KEY_SOURCE="placeholder"
SSH_PRIVATE_KEY_PATH=""
AZ_ACCOUNT_STATUS="unknown"
AZ_ACCOUNT_NAME=""
AZ_SUBSCRIPTION_ID=""
AZ_ACCOUNT_USER=""
VM_SIZE_SOURCE="static fallback"
AUTO_YES=false
LEARNING_MODE=false
PROJECT_STYLE="flat"
PROJECT_STYLE_EXPLICIT=false
CUSTOM_COMPONENTS=""
SELECTED_COMPONENT_IDS=()
ORIGINAL_COMPONENT_IDS=()
AUTO_ADDED_COMPONENT_IDS=()
CUSTOM_BUILDER_LOADING=false

template_label() {
    case "$1" in
        "azure-resource-group") echo "Azure Resource Group" ;;
        "azure-vnet-subnet") echo "Azure VNet + Subnet" ;;
        "azure-linux-vm") echo "Azure Linux VM Basic" ;;
        "azure-custom-builder") echo "Azure Custom Builder" ;;
        "azure-private-vmss-stack") echo "Azure Private VMSS Stack" ;;
        *) echo "$1" ;;
    esac
}

template_description() {
    case "$1" in
        "azure-resource-group") echo "Creates a minimal Azure resource group scaffold." ;;
        "azure-vnet-subnet") echo "Creates a resource group, virtual network, and subnet." ;;
        "azure-linux-vm") echo "Creates a basic Ubuntu VM with networking and SSH access." ;;
        "azure-custom-builder") echo "Build a custom Azure Terraform project by selecting resources." ;;
        "azure-private-vmss-stack") echo "Creates a modular private app stack with VMSS, internal load balancers, and private SQL." ;;
        *) echo "Terraform starter template." ;;
    esac
}

print_usage() {
    cat <<'USAGE'
Usage:
  sakit terraform new
  sakit tf new

Optional non-interactive flags:
  --template <azure-resource-group|azure-vnet-subnet|azure-linux-vm|azure-custom-builder|azure-private-vmss-stack>
  --dir <project-directory>
  --prefix <name-prefix>
  --location <azure-region>
  --vm-size <azure-vm-size>
  --os-image <ubuntu-22-04|ubuntu-24-04>
  --ssh-key-file <public-key-path>
  --ssh-public-key <public-key-value>
  --components <comma-separated-custom-builder-components>
  --style <flat|module>
  -l, --learn
  --yes

Custom builder components:
  resource-group,vnet,subnet,nsg,linux-vm,vmss,internal-lb,azure-sql,private-endpoint,key-vault,app-gateway-waf,monitoring,backup
USAGE
}

prompt_input() {
    local result_var="$1"
    local label="$2"
    local default_value="$3"
    local value

    printf '\n'
    printf '\033[1;36m%s\033[0m' "$label"
    if [ -n "$default_value" ]; then
        printf ' \033[2m[%s]\033[0m' "$default_value"
    fi
    printf ': '

    read -r value
    if [ -z "$value" ] && [ -n "$default_value" ]; then
        value="$default_value"
    fi

    printf -v "$result_var" '%s' "$value"
}

escape_sed_replacement() {
    printf '%s' "$1" | sed -e 's/[\/&|\\]/\\&/g'
}

while [ $# -gt 0 ]; do
    case "$1" in
        "new")
            shift
            ;;
        "--template")
            if [ $# -lt 2 ]; then
                echo "Error: --template requires a value."
                print_usage
                exit 1
            fi
            TEMPLATE_ID="$2"
            shift 2
            ;;
        "--dir")
            if [ $# -lt 2 ]; then
                echo "Error: --dir requires a value."
                print_usage
                exit 1
            fi
            PROJECT_DIR="$2"
            shift 2
            ;;
        "--prefix")
            if [ $# -lt 2 ]; then
                echo "Error: --prefix requires a value."
                print_usage
                exit 1
            fi
            PREFIX="$2"
            shift 2
            ;;
        "--location")
            if [ $# -lt 2 ]; then
                echo "Error: --location requires a value."
                print_usage
                exit 1
            fi
            LOCATION="$2"
            shift 2
            ;;
        "--vm-size")
            if [ $# -lt 2 ]; then
                echo "Error: --vm-size requires a value."
                print_usage
                exit 1
            fi
            VM_SIZE="$2"
            shift 2
            ;;
        "--os-image")
            if [ $# -lt 2 ]; then
                echo "Error: --os-image requires a value."
                print_usage
                exit 1
            fi
            OS_IMAGE_ID="$2"
            shift 2
            ;;
        "--ssh-key-file")
            if [ $# -lt 2 ]; then
                echo "Error: --ssh-key-file requires a value."
                print_usage
                exit 1
            fi
            SSH_PUBLIC_KEY_FILE="$2"
            shift 2
            ;;
        "--ssh-public-key")
            if [ $# -lt 2 ]; then
                echo "Error: --ssh-public-key requires a value."
                print_usage
                exit 1
            fi
            SSH_PUBLIC_KEY="$2"
            SSH_KEY_SOURCE="inline value"
            shift 2
            ;;
        "--components")
            if [ $# -lt 2 ]; then
                echo "Error: --components requires a value."
                print_usage
                exit 1
            fi
            CUSTOM_COMPONENTS="$2"
            shift 2
            ;;
        "--style")
            if [ $# -lt 2 ]; then
                echo "Error: --style requires a value."
                print_usage
                exit 1
            fi
            PROJECT_STYLE="$2"
            PROJECT_STYLE_EXPLICIT=true
            shift 2
            ;;
        "--yes"|"-y")
            AUTO_YES=true
            shift
            ;;
        "--learn"|"-l")
            LEARNING_MODE=true
            shift
            ;;
        "--help"|"-h")
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

menu_label() {
    local kind="$1"
    local id="$2"

    case "$kind" in
        "template") template_label "$id" ;;
        "location") location_label "$id" ;;
        "vm-size") vm_size_label "$id" ;;
        "os-image") os_image_label "$id" ;;
        "ssh-key") ssh_key_label "$id" ;;
        "project-style") project_style_label "$id" ;;
        *) echo "$id" ;;
    esac
}

menu_description() {
    local kind="$1"
    local id="$2"

    case "$kind" in
        "template") template_description "$id" ;;
        "vm-size") vm_size_description "$id" ;;
        "os-image") os_image_description "$id" ;;
        "ssh-key") ssh_key_description "$id" ;;
        "project-style") project_style_description "$id" ;;
        *) echo "" ;;
    esac
}

is_grid_menu() {
    case "$1" in
        "location"|"vm-size") return 0 ;;
        *) return 1 ;;
    esac
}

menu_drawn_lines() {
    local -n menu_ids_ref=$1
    local kind="$2"
    local cols
    local rows
    local per_item=2

    if [ "$kind" = "template" ] || [ "$kind" = "os-image" ] || [ "$kind" = "ssh-key" ] || [ "$kind" = "project-style" ]; then
        per_item=3
        echo $((4 + (${#menu_ids_ref[@]} * per_item) + 1))
        return
    fi

    cols=$(menu_columns "$kind")
    rows=$(((${#menu_ids_ref[@]} + cols - 1) / cols))
    echo $((4 + rows + 1))
}

menu_columns() {
    local kind="$1"
    local width=80
    local cols=4

    if ! is_grid_menu "$kind"; then
        echo 1
        return
    fi

    width=$(tput cols 2>/dev/null || echo 80)
    cols=$((width / 20))
    [ "$cols" -lt 3 ] && cols=3
    [ "$cols" -gt 4 ] && cols=4
    echo "$cols"
}

format_location_item() {
    local text="$1"
    local width="$2"

    if [ "${#text}" -gt $((width - 1)) ]; then
        text="${text:0:$((width - 2))}…"
    fi

    printf '%-*s' "$width" "$text"
}

draw_grid_menu_items() {
    local -n menu_ids_ref=$1
    local selected="$2"
    local kind="$3"
    local cols
    local rows
    local item_width=18
    local row
    local col
    local index
    local id
    local label
    local cell

    cols=$(menu_columns "$kind")
    rows=$(((${#menu_ids_ref[@]} + cols - 1) / cols))

    for ((row = 0; row < rows; row++)); do
        for ((col = 0; col < cols; col++)); do
            index=$(((row * cols) + col))
            [ "$index" -ge "${#menu_ids_ref[@]}" ] && continue

            id="${menu_ids_ref[$index]}"
            label="$(menu_label "$kind" "$id")"
            if [[ "$id" != "__"* ]]; then
                label="$id"
            fi

            cell="$(format_location_item "$label" "$item_width")"
            if [ "$index" -eq "$selected" ]; then
                printf '\033[1;36m> %s\033[0m' "$cell"
            else
                printf '  \033[1m%s\033[0m' "$cell"
            fi
        done
        printf '\n'
    done
}

draw_menu() {
    local ids_name="$1"
    local -n menu_ids_ref=$ids_name
    local selected="$2"
    local drawn_lines="$3"
    local title="$4"
    local subtitle="$5"
    local kind="$6"
    local i
    local id
    local label
    local description

    if [ "$drawn_lines" -gt 0 ]; then
        printf '\033[%sA\033[J' "$drawn_lines"
    fi

    echo
    printf '\033[1;36m%s\033[0m\n' "$title"
    printf '\033[2m%s\033[0m\n\n' "$subtitle"

    if is_grid_menu "$kind"; then
        draw_grid_menu_items "$ids_name" "$selected" "$kind"
        printf '\033[2m↑/↓/←/→ or j/k/h/l navigate • enter select • q/esc quit\033[0m\n'
        return
    fi

    for i in "${!menu_ids_ref[@]}"; do
        id="${menu_ids_ref[$i]}"
        label="$(menu_label "$kind" "$id")"
        description="$(menu_description "$kind" "$id")"

        if [ "$i" -eq "$selected" ]; then
            printf '\033[1;36m> %s\033[0m \033[2m(%s)\033[0m\n' "$label" "$id"
        else
            printf '  \033[1m%s\033[0m \033[2m(%s)\033[0m\n' "$label" "$id"
        fi

        if [ -n "$description" ]; then
            printf '    \033[2m%s\033[0m\n\n' "$description"
        else
            printf '\n'
        fi
    done

    printf '\033[2m↑/↓ or j/k navigate • enter select • q/esc quit\033[0m\n'
}

interactive_menu() {
    local ids_name="$1"
    local -n ids_ref=$ids_name
    local result_var="$2"
    local title="$3"
    local subtitle="$4"
    local kind="$5"
    local selected=0
    local drawn_lines=0
    local cols
    local key

    if [ ! -t 0 ]; then
        echo "Error: interactive menu requires a terminal. Use --template for non-interactive mode."
        exit 1
    fi

    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null || true' EXIT

    while true; do
        draw_menu "$ids_name" "$selected" "$drawn_lines" "$title" "$subtitle" "$kind"
        drawn_lines=$(menu_drawn_lines "$ids_name" "$kind")

        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')
                IFS= read -rsn2 -t 0.05 key || {
                    printf '\nCancelled.\n'
                    exit 0
                }
                case "$key" in
                    "[A")
                        cols=$(menu_columns "$kind")
                        if is_grid_menu "$kind"; then
                            selected=$((selected - cols))
                        else
                            selected=$((selected - 1))
                        fi
                        [ "$selected" -lt 0 ] && selected=$((${#ids_ref[@]} - 1))
                        ;;
                    "[B")
                        cols=$(menu_columns "$kind")
                        if is_grid_menu "$kind"; then
                            selected=$((selected + cols))
                        else
                            selected=$((selected + 1))
                        fi
                        [ "$selected" -ge "${#ids_ref[@]}" ] && selected=0
                        ;;
                    "[C")
                        selected=$((selected + 1))
                        [ "$selected" -ge "${#ids_ref[@]}" ] && selected=0
                        ;;
                    "[D")
                        selected=$((selected - 1))
                        [ "$selected" -lt 0 ] && selected=$((${#ids_ref[@]} - 1))
                        ;;
                    *)
                        printf '\nCancelled.\n'
                        exit 0
                        ;;
                esac
                ;;
            "")
                printf -v "$result_var" '%s' "${ids_ref[$selected]}"
                tput cnorm 2>/dev/null || true
                trap - EXIT
                printf '\033[%sA\033[J' "$drawn_lines"
                if [[ "${ids_ref[$selected]}" != "__"* ]]; then
                    if is_grid_menu "$kind"; then
                        printf '\033[1;36mSelected:\033[0m %s\n' "${ids_ref[$selected]}"
                    else
                        printf '\033[1;36mSelected:\033[0m %s\n' "$(menu_label "$kind" "${ids_ref[$selected]}")"
                    fi
                fi
                return
                ;;
            "q"|"Q")
                printf '\nCancelled.\n'
                exit 0
                ;;
            "k"|"K")
                cols=$(menu_columns "$kind")
                if is_grid_menu "$kind"; then
                    selected=$((selected - cols))
                else
                    selected=$((selected - 1))
                fi
                [ "$selected" -lt 0 ] && selected=$((${#ids_ref[@]} - 1))
                ;;
            "j"|"J")
                cols=$(menu_columns "$kind")
                if is_grid_menu "$kind"; then
                    selected=$((selected + cols))
                else
                    selected=$((selected + 1))
                fi
                [ "$selected" -ge "${#ids_ref[@]}" ] && selected=0
                ;;
            "h"|"H")
                selected=$((selected - 1))
                [ "$selected" -lt 0 ] && selected=$((${#ids_ref[@]} - 1))
                ;;
            "l"|"L")
                selected=$((selected + 1))
                [ "$selected" -ge "${#ids_ref[@]}" ] && selected=0
                ;;
        esac
    done
}

choose_template() {
    local ids=("azure-custom-builder" "azure-resource-group" "azure-vnet-subnet" "azure-linux-vm" "azure-private-vmss-stack")

    if [ -n "$TEMPLATE_ID" ]; then
        return
    fi

    interactive_menu ids TEMPLATE_ID "Terraform Project Generator" "Choose a starter template for your new project." "template"
}

show_custom_builder_loading() {
    if [ "$TEMPLATE_ID" = "azure-custom-builder" ] && [ "$AUTO_YES" != true ] && [ -z "$CUSTOM_COMPONENTS" ] && [ -t 0 ]; then
        printf '\n\033[1;36mLoading Azure Custom Builder resources...\033[0m\n'
        CUSTOM_BUILDER_LOADING=true
    fi
}

clear_custom_builder_loading() {
    if [ "$CUSTOM_BUILDER_LOADING" = true ]; then
        printf '\033[1A\033[J'
        CUSTOM_BUILDER_LOADING=false
    fi
}

custom_component_label() {
    case "$1" in
        "resource-group") echo "Resource Group" ;;
        "vnet") echo "Virtual Network" ;;
        "subnet") echo "Subnet" ;;
        "nsg") echo "Network Security Group" ;;
        "linux-vm") echo "Linux VM" ;;
        "vmss") echo "VM Scale Set" ;;
        "internal-lb") echo "Internal Load Balancer" ;;
        "azure-sql") echo "Azure SQL" ;;
        "private-endpoint") echo "Private Endpoint" ;;
        "key-vault") echo "Key Vault" ;;
        "app-gateway-waf") echo "App Gateway / WAF" ;;
        "monitoring") echo "Monitoring" ;;
        "backup") echo "Backup / Resilience" ;;
        *) echo "$1" ;;
    esac
}

custom_component_description() {
    case "$1" in
        "resource-group") echo "Creates a new Azure resource group." ;;
        "vnet") echo "Creates a virtual network for selected resources." ;;
        "subnet") echo "Creates app, web, api, and data subnets." ;;
        "nsg") echo "Adds basic web/api network security groups." ;;
        "linux-vm") echo "Creates one SSH-accessible Linux VM." ;;
        "vmss") echo "Creates frontend and backend Linux VM scale sets." ;;
        "internal-lb") echo "Creates frontend/backend private Standard Load Balancers." ;;
        "azure-sql") echo "Creates Azure SQL Server and SQL Database." ;;
        "private-endpoint") echo "Adds a SQL private endpoint when Azure SQL is selected." ;;
        "key-vault") echo "Creates a private-ready Key Vault scaffold." ;;
        "app-gateway-waf") echo "Creates an Application Gateway WAF policy scaffold." ;;
        "monitoring") echo "Creates Log Analytics, Application Insights, and basic alerts." ;;
        "backup") echo "Creates Recovery Services Vault and a VM backup policy." ;;
        *) echo "Azure resource component." ;;
    esac
}

component_selected() {
    local wanted="$1"
    local item

    for item in "${SELECTED_COMPONENT_IDS[@]}"; do
        [ "$item" = "$wanted" ] && return 0
    done

    return 1
}

add_component_once() {
    local wanted="$1"

    if ! component_selected "$wanted"; then
        SELECTED_COMPONENT_IDS+=("$wanted")
        return 0
    fi

    return 1
}

component_in_named_list() {
    local list_name="$1"
    local wanted="$2"
    local -n list_ref=$list_name
    local item

    for item in "${list_ref[@]}"; do
        [ "$item" = "$wanted" ] && return 0
    done

    return 1
}

valid_custom_component() {
    case "$1" in
        "resource-group"|"vnet"|"subnet"|"nsg"|"linux-vm"|"vmss"|"internal-lb"|"azure-sql"|"private-endpoint"|"key-vault"|"app-gateway-waf"|"monitoring"|"backup")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

normalize_custom_components() {
    local raw="$1"
    local item
    local normalized

    IFS=',' read -ra SELECTED_COMPONENT_IDS <<< "$raw"
    for item in "${!SELECTED_COMPONENT_IDS[@]}"; do
        normalized="${SELECTED_COMPONENT_IDS[$item]}"
        normalized="${normalized// /}"
        if [ -n "$normalized" ] && ! valid_custom_component "$normalized"; then
            echo "Error: Unknown custom builder component '$normalized'."
            exit 1
        fi
        SELECTED_COMPONENT_IDS[$item]="$normalized"
    done
}

apply_custom_dependencies() {
    local changed=true
    local component

    ORIGINAL_COMPONENT_IDS=("${SELECTED_COMPONENT_IDS[@]}")

    while [ "$changed" = true ]; do
        changed=false

        if component_selected "vnet" || component_selected "subnet" || component_selected "nsg" || component_selected "linux-vm" || component_selected "vmss" || component_selected "internal-lb" || component_selected "azure-sql" || component_selected "private-endpoint" || component_selected "key-vault" || component_selected "app-gateway-waf" || component_selected "monitoring" || component_selected "backup"; then
            add_component_once "resource-group" && changed=true
        fi

        if component_selected "subnet" || component_selected "nsg" || component_selected "linux-vm" || component_selected "vmss" || component_selected "internal-lb" || component_selected "azure-sql" || component_selected "private-endpoint" || component_selected "key-vault" || component_selected "app-gateway-waf"; then
            add_component_once "vnet" && changed=true
            add_component_once "subnet" && changed=true
        fi

        if component_selected "linux-vm" || component_selected "vmss"; then
            add_component_once "nsg" && changed=true
        fi

        if component_selected "internal-lb"; then
            add_component_once "vmss" && changed=true
        fi

        if component_selected "private-endpoint"; then
            add_component_once "azure-sql" && changed=true
        fi
    done

    AUTO_ADDED_COMPONENT_IDS=()
    for component in "${SELECTED_COMPONENT_IDS[@]}"; do
        if ! component_in_named_list ORIGINAL_COMPONENT_IDS "$component"; then
            AUTO_ADDED_COMPONENT_IDS+=("$component")
        fi
    done

    order_custom_components SELECTED_COMPONENT_IDS
    order_custom_components AUTO_ADDED_COMPONENT_IDS
}

order_custom_components() {
    local list_name="$1"
    local -n list_ref=$list_name
    local ordered=()
    local component
    local order=("resource-group" "vnet" "subnet" "nsg" "linux-vm" "vmss" "internal-lb" "azure-sql" "private-endpoint" "key-vault" "app-gateway-waf" "monitoring" "backup")

    for component in "${order[@]}"; do
        if component_in_named_list "$list_name" "$component"; then
            ordered+=("$component")
        fi
    done

    list_ref=("${ordered[@]}")
}

draw_checkbox_menu() {
    local ids_name="$1"
    local -n ids_ref=$ids_name
    local selected="$2"
    local title="$3"
    local subtitle="$4"
    local drawn_lines="$5"
    local start="$6"
    local visible_count="$7"
    local i
    local end
    local id
    local mark

    if [ "$drawn_lines" -gt 0 ]; then
        printf '\033[%sA\033[J' "$drawn_lines"
    fi

    echo
    printf '\033[1;36m%s\033[0m\n' "$title"
    printf '\033[2m%s\033[0m\n\n' "$subtitle"

    end=$((start + visible_count))
    [ "$end" -gt "${#ids_ref[@]}" ] && end="${#ids_ref[@]}"

    if [ "$start" -gt 0 ]; then
        printf '  \033[2m↑ %s more above\033[0m\n\n' "$start"
    fi

    for ((i = start; i < end; i++)); do
        id="${ids_ref[$i]}"
        mark="[ ]"
        component_selected "$id" && mark="[x]"

        if [ "$i" -eq "$selected" ]; then
            printf '\033[1;36m> %s %s\033[0m \033[2m(%s)\033[0m\n' "$mark" "$(custom_component_label "$id")" "$id"
        else
            printf '  %s \033[1m%s\033[0m \033[2m(%s)\033[0m\n' "$mark" "$(custom_component_label "$id")" "$id"
        fi
        printf '    \033[2m%s\033[0m\n\n' "$(custom_component_description "$id")"
    done

    if [ "$end" -lt "${#ids_ref[@]}" ]; then
        printf '  \033[2m↓ %s more below\033[0m\n\n' "$((${#ids_ref[@]} - end))"
    fi

    printf '\033[2m←/→ or space toggle • ↑/↓ or j/k navigate • enter continue • q/esc quit\033[0m\n'
}

checkbox_visible_count() {
    local rows=24
    local visible

    rows=$(tput lines 2>/dev/null || echo 24)
    visible=$(((rows - 8) / 3))
    [ "$visible" -lt 3 ] && visible=3
    [ "$visible" -gt 6 ] && visible=6
    echo "$visible"
}

checkbox_drawn_lines() {
    local total="$1"
    local start="$2"
    local visible="$3"
    local end
    local lines=4

    end=$((start + visible))
    [ "$end" -gt "$total" ] && end="$total"

    [ "$start" -gt 0 ] && lines=$((lines + 2))
    lines=$((lines + ((end - start) * 3)))
    [ "$end" -lt "$total" ] && lines=$((lines + 2))
    lines=$((lines + 1))
    echo "$lines"
}

toggle_component_selection() {
    local id="$1"

    if component_selected "$id"; then
        local next=()
        local existing
        for existing in "${SELECTED_COMPONENT_IDS[@]}"; do
            [ "$existing" != "$id" ] && next+=("$existing")
        done
        SELECTED_COMPONENT_IDS=("${next[@]}")
    else
        SELECTED_COMPONENT_IDS+=("$id")
    fi
}

checkbox_menu() {
    local ids_name="$1"
    local -n ids_ref=$ids_name
    local title="$2"
    local subtitle="$3"
    local selected=0
    local drawn_lines=0
    local start=0
    local visible_count=0
    local key
    local id

    if [ ! -t 0 ]; then
        echo "Error: custom builder checkbox menu requires a terminal. Use --components for non-interactive mode."
        exit 1
    fi

    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null || true' EXIT

    while true; do
        visible_count=$(checkbox_visible_count)
        if [ "$selected" -lt "$start" ]; then
            start="$selected"
        fi
        if [ "$selected" -ge $((start + visible_count)) ]; then
            start=$((selected - visible_count + 1))
        fi
        [ "$start" -lt 0 ] && start=0

        draw_checkbox_menu "$ids_name" "$selected" "$title" "$subtitle" "$drawn_lines" "$start" "$visible_count"
        drawn_lines=$(checkbox_drawn_lines "${#ids_ref[@]}" "$start" "$visible_count")

        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')
                IFS= read -rsn2 -t 0.05 key || {
                    printf '\nCancelled.\n'
                    exit 0
                }
                case "$key" in
                    "[A")
                        selected=$((selected - 1))
                        [ "$selected" -lt 0 ] && selected=$((${#ids_ref[@]} - 1))
                        ;;
                    "[B")
                        selected=$((selected + 1))
                        [ "$selected" -ge "${#ids_ref[@]}" ] && selected=0
                        ;;
                    "[C"|"[D")
                        id="${ids_ref[$selected]}"
                        toggle_component_selection "$id"
                        ;;
                    *)
                        printf '\nCancelled.\n'
                        exit 0
                        ;;
                esac
                ;;
            " ")
                id="${ids_ref[$selected]}"
                toggle_component_selection "$id"
                ;;
            "")
                tput cnorm 2>/dev/null || true
                trap - EXIT
                printf '\033[%sA\033[J' "$drawn_lines"
                return
                ;;
            "q"|"Q")
                printf '\nCancelled.\n'
                exit 0
                ;;
            "k"|"K")
                selected=$((selected - 1))
                [ "$selected" -lt 0 ] && selected=$((${#ids_ref[@]} - 1))
                ;;
            "j"|"J")
                selected=$((selected + 1))
                [ "$selected" -ge "${#ids_ref[@]}" ] && selected=0
                ;;
            "h"|"H"|"l"|"L")
                id="${ids_ref[$selected]}"
                toggle_component_selection "$id"
                ;;
        esac
    done
}

choose_custom_components() {
    local ids=("resource-group" "vnet" "subnet" "nsg" "linux-vm" "vmss" "internal-lb" "azure-sql" "private-endpoint" "key-vault" "app-gateway-waf" "monitoring" "backup")

    if [ "$TEMPLATE_ID" != "azure-custom-builder" ]; then
        return
    fi

    if [ -n "$CUSTOM_COMPONENTS" ]; then
        normalize_custom_components "$CUSTOM_COMPONENTS"
    elif [ "$AUTO_YES" = true ]; then
        SELECTED_COMPONENT_IDS=("resource-group" "vnet" "subnet" "nsg")
    else
        SELECTED_COMPONENT_IDS=("resource-group" "vnet" "subnet")
        clear_custom_builder_loading
        checkbox_menu ids "Azure Custom Builder" "Select resources. Dependencies will be added automatically." 
    fi

    apply_custom_dependencies
}

project_style_label() {
    case "$1" in
        "flat") echo "Flat files" ;;
        "module") echo "Module-based" ;;
        *) echo "$1" ;;
    esac
}

project_style_description() {
    case "$1" in
        "flat") echo "Generate a simple root project with resources in main.tf." ;;
        "module") echo "Generate root files plus modules for network, compute, data, security, and operations." ;;
        *) echo "Terraform project structure." ;;
    esac
}

choose_project_style() {
    local ids=("flat" "module")

    if [ "$TEMPLATE_ID" != "azure-custom-builder" ]; then
        return
    fi

    case "$PROJECT_STYLE" in
        "flat"|"module")
            if [ "$AUTO_YES" = true ] || [ -n "$CUSTOM_COMPONENTS" ] || [ "$PROJECT_STYLE_EXPLICIT" = true ]; then
                return
            fi
            ;;
        *)
            echo "Error: --style must be 'flat' or 'module'."
            exit 1
            ;;
    esac

    interactive_menu ids PROJECT_STYLE "Terraform Project Style" "Choose how generated Terraform code should be organized." "project-style"
}

vm_size_label() {
    case "$1" in
        "__more__") echo "More..." ;;
        "__back__") echo "Back" ;;
        "__next__") echo "Next page" ;;
        "__prev__") echo "Previous page" ;;
        "__b_series__") echo "B-series" ;;
        "__d_series__") echo "D-series" ;;
        "__ds_series__") echo "DS-series" ;;
        "__e_series__") echo "E-series" ;;
        "__f_series__") echo "F-series" ;;
        "__all_sizes__") echo "All discovered" ;;
        *) echo "$1" ;;
    esac
}

vm_size_description() {
    echo "Azure VM size."
}

static_vm_sizes() {
    VM_SIZE_IDS=("Standard_B1s" "Standard_B1ms" "Standard_B2s" "Standard_D2s_v3" "Standard_D2s_v5" "Standard_DS1_v2" "Standard_E2s_v3" "Standard_F2s_v2")
    VM_SIZE_SOURCE="static fallback"
}

append_available_size() {
    local -n target_ref=$1
    local size="$2"
    local available

    for available in "${VM_SIZE_IDS[@]}"; do
        if [ "$available" = "$size" ]; then
            target_ref+=("$size")
            return
        fi
    done
}

filter_vm_sizes_by_family() {
    local -n target_ref=$1
    local pattern="$2"
    local size

    target_ref=()
    target_ref+=("__back__")

    for size in "${VM_SIZE_IDS[@]}"; do
        if [[ "$size" =~ $pattern ]]; then
            target_ref+=("$size")
        fi
    done
}

choose_paged_vm_sizes() {
    local -n source_ref=$1
    local title="$2"
    local subtitle="$3"
    local page=0
    local page_size=20
    local total_pages
    local start
    local end
    local i
    local page_ids=()

    if [ "${#source_ref[@]}" -le "$page_size" ]; then
        interactive_menu source_ref VM_SIZE "$title" "$subtitle" "vm-size"
        return
    fi

    total_pages=$(((${#source_ref[@]} - 1 + page_size - 1) / page_size))

    while true; do
        page_ids=("__back__")
        if [ "$page" -gt 0 ]; then
            page_ids+=("__prev__")
        fi

        start=$((1 + (page * page_size)))
        end=$((start + page_size))
        [ "$end" -gt "${#source_ref[@]}" ] && end="${#source_ref[@]}"

        for ((i = start; i < end; i++)); do
            page_ids+=("${source_ref[$i]}")
        done

        if [ "$page" -lt $((total_pages - 1)) ]; then
            page_ids+=("__next__")
        fi

        interactive_menu page_ids VM_SIZE "$title ($((page + 1))/$total_pages)" "$subtitle" "vm-size"

        case "$VM_SIZE" in
            "__back__")
                return
                ;;
            "__next__")
                page=$((page + 1))
                VM_SIZE=""
                ;;
            "__prev__")
                page=$((page - 1))
                VM_SIZE=""
                ;;
            *)
                return
                ;;
        esac
    done
}

family_has_vm_sizes() {
    local pattern="$1"
    local size

    for size in "${VM_SIZE_IDS[@]}"; do
        if [[ "$size" =~ $pattern ]]; then
            return 0
        fi
    done

    return 1
}

build_vm_size_groups() {
    VM_SIZE_GROUP_IDS=("__back__")

    family_has_vm_sizes '^Standard_B' && VM_SIZE_GROUP_IDS+=("__b_series__")
    family_has_vm_sizes '^Standard_D[0-9]' && VM_SIZE_GROUP_IDS+=("__d_series__")
    family_has_vm_sizes '^Standard_DS' && VM_SIZE_GROUP_IDS+=("__ds_series__")
    family_has_vm_sizes '^Standard_E' && VM_SIZE_GROUP_IDS+=("__e_series__")
    family_has_vm_sizes '^Standard_F' && VM_SIZE_GROUP_IDS+=("__f_series__")

    VM_SIZE_GROUP_IDS+=("__all_sizes__")
}

build_recommended_vm_sizes() {
    RECOMMENDED_VM_SIZE_IDS=()

    append_available_size RECOMMENDED_VM_SIZE_IDS "Standard_B1s"
    append_available_size RECOMMENDED_VM_SIZE_IDS "Standard_B1ms"
    append_available_size RECOMMENDED_VM_SIZE_IDS "Standard_B2s"
    append_available_size RECOMMENDED_VM_SIZE_IDS "Standard_D2s_v3"
    append_available_size RECOMMENDED_VM_SIZE_IDS "Standard_D2s_v5"
    append_available_size RECOMMENDED_VM_SIZE_IDS "Standard_DS1_v2"

    if [ "${#RECOMMENDED_VM_SIZE_IDS[@]}" -eq 0 ]; then
        RECOMMENDED_VM_SIZE_IDS=("${VM_SIZE_IDS[@]:0:8}")
    fi

    if [ "${#VM_SIZE_IDS[@]}" -gt "${#RECOMMENDED_VM_SIZE_IDS[@]}" ]; then
        RECOMMENDED_VM_SIZE_IDS+=("__more__")
    fi
}

load_vm_sizes() {
    local sizes

    static_vm_sizes

    if ! command -v az &> /dev/null || [ "$AZ_ACCOUNT_STATUS" != "signed-in" ] || [ -z "$LOCATION" ]; then
        return
    fi

    printf '\n\033[1;36mLoading VM sizes for %s...\033[0m\n' "$LOCATION"
    sizes=$(az vm list-sizes --location "$LOCATION" --query "[].name" -o tsv 2>/dev/null | grep -E '^Standard_(B|D|DS|E|F)' | sort -u)
    printf '\033[1A\033[J'

    if [ -n "$sizes" ]; then
        mapfile -t VM_SIZE_IDS <<< "$sizes"
        VM_SIZE_SOURCE="Azure CLI: $LOCATION"
    else
        printf '\033[1;33mCould not load VM sizes from Azure CLI. Using static fallback.\033[0m\n'
    fi
}

choose_vm_size() {
    VM_SIZE_IDS=()
    RECOMMENDED_VM_SIZE_IDS=()
    VM_SIZE_GROUP_IDS=()
    local group_choice=""
    local family_ids=()
    local all_ids=()

    if [[ "$TEMPLATE_ID" != "azure-linux-vm" && "$TEMPLATE_ID" != "azure-private-vmss-stack" && "$TEMPLATE_ID" != "azure-custom-builder" ]] || [ -n "$VM_SIZE" ]; then
        return
    fi

    if [ "$TEMPLATE_ID" = "azure-custom-builder" ] && ! component_selected "linux-vm" && ! component_selected "vmss"; then
        return
    fi

    if [ "$AUTO_YES" = true ]; then
        VM_SIZE="Standard_B1s"
        return
    fi

    load_vm_sizes
    build_recommended_vm_sizes
    build_vm_size_groups

    while true; do
        interactive_menu RECOMMENDED_VM_SIZE_IDS VM_SIZE "Azure VM Size" "Choose a recommended VM size. Source: $VM_SIZE_SOURCE" "vm-size"
        if [ "$VM_SIZE" != "__more__" ]; then
            return
        fi

        while true; do
            interactive_menu VM_SIZE_GROUP_IDS group_choice "Azure VM Size: More" "Choose a VM size family." "vm-size"

            case "$group_choice" in
                "__back__")
                    VM_SIZE=""
                    break
                    ;;
                "__b_series__")
                    filter_vm_sizes_by_family family_ids '^Standard_B'
                    choose_paged_vm_sizes family_ids "Azure VM Size: B-series" "Burstable VM sizes."
                    ;;
                "__d_series__")
                    filter_vm_sizes_by_family family_ids '^Standard_D[0-9]'
                    choose_paged_vm_sizes family_ids "Azure VM Size: D-series" "General purpose VM sizes."
                    ;;
                "__ds_series__")
                    filter_vm_sizes_by_family family_ids '^Standard_DS'
                    choose_paged_vm_sizes family_ids "Azure VM Size: DS-series" "General purpose VM sizes with premium storage support."
                    ;;
                "__e_series__")
                    filter_vm_sizes_by_family family_ids '^Standard_E'
                    choose_paged_vm_sizes family_ids "Azure VM Size: E-series" "Memory optimized VM sizes."
                    ;;
                "__f_series__")
                    filter_vm_sizes_by_family family_ids '^Standard_F'
                    choose_paged_vm_sizes family_ids "Azure VM Size: F-series" "Compute optimized VM sizes."
                    ;;
                "__all_sizes__")
                    all_ids=("__back__" "${VM_SIZE_IDS[@]}")
                    choose_paged_vm_sizes all_ids "Azure VM Size: All" "All discovered or fallback VM sizes."
                    ;;
            esac

            if [ "$VM_SIZE" = "__back__" ]; then
                VM_SIZE=""
                group_choice=""
                continue
            fi

            if [ -n "$VM_SIZE" ]; then
                if [[ "$VM_SIZE" != "__"* ]]; then
                    return
                fi
                VM_SIZE=""
            fi
        done
    done
}

os_image_label() {
    case "$1" in
        "ubuntu-22-04") echo "Ubuntu 22.04 LTS" ;;
        "ubuntu-24-04") echo "Ubuntu 24.04 LTS" ;;
        *) echo "$1" ;;
    esac
}

os_image_description() {
    case "$1" in
        "ubuntu-22-04") echo "Stable Jammy image: Canonical:ubuntu-22_04-lts:server:latest" ;;
        "ubuntu-24-04") echo "Current Noble LTS image: Canonical:ubuntu-24_04-lts:server:latest" ;;
        *) echo "Azure Linux image." ;;
    esac
}

os_image_publisher() {
    case "$1" in
        "ubuntu-22-04"|"ubuntu-24-04") echo "Canonical" ;;
        *) echo "" ;;
    esac
}

os_image_offer() {
    case "$1" in
        "ubuntu-22-04") echo "ubuntu-22_04-lts" ;;
        "ubuntu-24-04") echo "ubuntu-24_04-lts" ;;
        *) echo "" ;;
    esac
}

os_image_sku() {
    case "$1" in
        "ubuntu-22-04"|"ubuntu-24-04") echo "server" ;;
        *) echo "" ;;
    esac
}

choose_os_image() {
    local ids=("ubuntu-22-04" "ubuntu-24-04")

    if [[ "$TEMPLATE_ID" != "azure-linux-vm" && "$TEMPLATE_ID" != "azure-private-vmss-stack" && "$TEMPLATE_ID" != "azure-custom-builder" ]] || [ -n "$OS_IMAGE_ID" ]; then
        return
    fi

    if [ "$TEMPLATE_ID" = "azure-custom-builder" ] && ! component_selected "linux-vm" && ! component_selected "vmss"; then
        return
    fi

    if [ "$AUTO_YES" = true ]; then
        OS_IMAGE_ID="ubuntu-22-04"
        return
    fi

    interactive_menu ids OS_IMAGE_ID "Azure OS Image" "Choose the Linux image for the VM." "os-image"
}

detect_azure_account() {
    AZ_ACCOUNT_STATUS="not-installed"
    AZ_ACCOUNT_NAME=""
    AZ_SUBSCRIPTION_ID=""
    AZ_ACCOUNT_USER=""

    if ! command -v az &> /dev/null; then
        return
    fi

    AZ_ACCOUNT_STATUS="not-signed-in"
    if ! az account show &> /dev/null; then
        return
    fi

    AZ_ACCOUNT_STATUS="signed-in"
    AZ_ACCOUNT_NAME=$(az account show --query name -o tsv 2>/dev/null || true)
    AZ_SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null || true)
    AZ_ACCOUNT_USER=$(az account show --query user.name -o tsv 2>/dev/null || true)
}

read_ssh_public_key_file() {
    local path="$1"
    local private_key_path=""

    if [ ! -f "$path" ]; then
        echo "Error: SSH public key file '$path' was not found."
        exit 1
    fi

    IFS= read -r SSH_PUBLIC_KEY < "$path"
    if [ -z "$SSH_PUBLIC_KEY" ]; then
        echo "Error: SSH public key file '$path' is empty."
        exit 1
    fi

    SSH_KEY_SOURCE="$path"
    if [[ "$path" == *.pub ]]; then
        private_key_path="${path%.pub}"
        if [[ "$private_key_path" == "$HOME/"* ]]; then
            private_key_path="~/${private_key_path#"$HOME/"}"
        fi
        SSH_PRIVATE_KEY_PATH="$private_key_path"
    else
        SSH_PRIVATE_KEY_PATH=""
    fi
}

ssh_key_label() {
    case "$1" in
        "__ssh_ed25519__") echo "~/.ssh/id_ed25519.pub" ;;
        "__ssh_rsa__") echo "~/.ssh/id_rsa.pub" ;;
        "__ssh_custom__") echo "Custom public key path" ;;
        "__ssh_placeholder__") echo "Use placeholder" ;;
        *) echo "$1" ;;
    esac
}

ssh_key_description() {
    case "$1" in
        "__ssh_ed25519__") echo "Use your default Ed25519 public key if it exists." ;;
        "__ssh_rsa__") echo "Use your default RSA public key if it exists." ;;
        "__ssh_custom__") echo "Enter a path to another .pub file." ;;
        "__ssh_placeholder__") echo "Leave CHANGE_ME in terraform.tfvars.example." ;;
        *) echo "SSH public key option." ;;
    esac
}

choose_ssh_key() {
    local ids=()
    local choice=""
    local custom_path=""

    if [[ "$TEMPLATE_ID" != "azure-linux-vm" && "$TEMPLATE_ID" != "azure-private-vmss-stack" && "$TEMPLATE_ID" != "azure-custom-builder" ]]; then
        return
    fi

    if [ "$TEMPLATE_ID" = "azure-custom-builder" ] && ! component_selected "linux-vm" && ! component_selected "vmss"; then
        return
    fi

    if [ -n "$SSH_PUBLIC_KEY_FILE" ]; then
        read_ssh_public_key_file "$SSH_PUBLIC_KEY_FILE"
        return
    fi

    if [ -n "$SSH_PUBLIC_KEY" ]; then
        SSH_KEY_SOURCE="inline value"
        SSH_PRIVATE_KEY_PATH=""
        return
    fi

    if [ "$AUTO_YES" = true ]; then
        SSH_PUBLIC_KEY="ssh-ed25519 CHANGE_ME"
        SSH_KEY_SOURCE="placeholder"
        SSH_PRIVATE_KEY_PATH=""
        return
    fi

    [ -f "$HOME/.ssh/id_ed25519.pub" ] && ids+=("__ssh_ed25519__")
    [ -f "$HOME/.ssh/id_rsa.pub" ] && ids+=("__ssh_rsa__")
    ids+=("__ssh_custom__" "__ssh_placeholder__")

    interactive_menu ids choice "SSH Public Key" "Choose the public key that will be written to terraform.tfvars.example." "ssh-key"

    case "$choice" in
        "__ssh_ed25519__")
            read_ssh_public_key_file "$HOME/.ssh/id_ed25519.pub"
            ;;
        "__ssh_rsa__")
            read_ssh_public_key_file "$HOME/.ssh/id_rsa.pub"
            ;;
        "__ssh_custom__")
            prompt_input custom_path "SSH public key path" "$HOME/.ssh/id_ed25519.pub"
            read_ssh_public_key_file "$custom_path"
            ;;
        "__ssh_placeholder__")
            SSH_PUBLIC_KEY="ssh-ed25519 CHANGE_ME"
            SSH_KEY_SOURCE="placeholder"
            SSH_PRIVATE_KEY_PATH=""
            ;;
    esac
}

location_label() {
    case "$1" in
        "__more__") echo "More..." ;;
        "__back__") echo "Back" ;;
        "__next__") echo "Next page" ;;
        "__prev__") echo "Previous page" ;;
        "__americas__") echo "Americas" ;;
        "__europe__") echo "Europe" ;;
        "__asia_pacific__") echo "Asia Pacific" ;;
        "__middle_east_africa__") echo "Middle East & Africa" ;;
        "__special__") echo "Special / Stage / Geo" ;;
        "swedencentral") echo "Sweden Central" ;;
        "westeurope") echo "West Europe" ;;
        "northeurope") echo "North Europe" ;;
        "uksouth") echo "UK South" ;;
        "eastus") echo "East US" ;;
        "eastus2") echo "East US 2" ;;
        "westus2") echo "West US 2" ;;
        "westus3") echo "West US 3" ;;
        "centralus") echo "Central US" ;;
        "southcentralus") echo "South Central US" ;;
        "northcentralus") echo "North Central US" ;;
        "australiaeast") echo "Australia East" ;;
        "southeastasia") echo "Southeast Asia" ;;
        "centralindia") echo "Central India" ;;
        "eastasia") echo "East Asia" ;;
        "japaneast") echo "Japan East" ;;
        "koreacentral") echo "Korea Central" ;;
        "canadacentral") echo "Canada Central" ;;
        *) echo "$1" ;;
    esac
}

choose_location() {
    local primary_ids=("swedencentral" "eastus" "eastus2" "westus2" "westus3" "centralus" "westeurope" "northeurope" "uksouth" "southeastasia" "australiaeast" "centralindia" "japaneast" "canadacentral" "__more__")
    local group_ids=("__back__" "__americas__" "__europe__" "__asia_pacific__" "__middle_east_africa__" "__special__")
    local americas_ids=("__back__" "eastus" "eastus2" "centralus" "northcentralus" "southcentralus" "westus" "westus2" "westus3" "westcentralus" "canadacentral" "canadaeast" "brazilsouth" "brazilsoutheast" "chilecentral" "mexicocentral")
    local europe_ids=("__back__" "swedencentral" "westeurope" "northeurope" "uksouth" "ukwest" "austriaeast" "belgiumcentral" "denmarkeast" "francecentral" "francesouth" "germanywestcentral" "germanynorth" "italynorth" "norwayeast" "norwaywest" "polandcentral" "spaincentral" "switzerlandnorth" "switzerlandwest")
    local asia_pacific_ids=("__back__" "australiaeast" "australiacentral" "australiacentral2" "australiasoutheast" "southeastasia" "eastasia" "indonesiacentral" "japaneast" "japanwest" "koreacentral" "koreasouth" "malaysiawest" "newzealandnorth" "centralindia" "southindia" "westindia" "jioindiacentral" "jioindiawest")
    local middle_east_africa_ids=("__back__" "israelcentral" "qatarcentral" "uaenorth" "uaecentral" "southafricanorth" "southafricawest")
    local special_ids=("__back__" "asia" "asiapacific" "australia" "brazil" "canada" "europe" "france" "germany" "global" "india" "indonesia" "israel" "italy" "japan" "korea" "malaysia" "mexico" "newzealand" "norway" "poland" "qatar" "singapore" "southafrica" "spain" "sweden" "switzerland" "taiwan" "uae" "uk" "unitedstates" "unitedstateseuap" "eastus2euap" "centraluseuap" "centralusstage" "eastusstage" "eastus2stage" "northcentralusstage" "southcentralusstage" "westusstage" "westus2stage" "eastasiastage" "southeastasiastage" "eastusstg" "southcentralusstg")
    local group_choice=""

    if [ -n "$LOCATION" ]; then
        return
    fi

    if [ "$AUTO_YES" = true ]; then
        LOCATION="swedencentral"
        return
    fi

    while true; do
        interactive_menu primary_ids LOCATION "Azure Location" "Choose the Azure region for generated resources." "location"
        if [ "$LOCATION" != "__more__" ]; then
            return
        fi

        while true; do
            interactive_menu group_ids group_choice "Azure Location: More" "Choose a region group." "location"

            case "$group_choice" in
                "__back__")
                    LOCATION=""
                    break
                    ;;
                "__americas__")
                    interactive_menu americas_ids LOCATION "Azure Location: Americas" "Choose an Azure region." "location"
                    ;;
                "__europe__")
                    interactive_menu europe_ids LOCATION "Azure Location: Europe" "Choose an Azure region." "location"
                    ;;
                "__asia_pacific__")
                    interactive_menu asia_pacific_ids LOCATION "Azure Location: Asia Pacific" "Choose an Azure region." "location"
                    ;;
                "__middle_east_africa__")
                    interactive_menu middle_east_africa_ids LOCATION "Azure Location: Middle East & Africa" "Choose an Azure region." "location"
                    ;;
                "__special__")
                    interactive_menu special_ids LOCATION "Azure Location: Special / Stage / Geo" "Choose an Azure location alias or special region." "location"
                    ;;
            esac

            if [ "$LOCATION" = "__back__" ]; then
                LOCATION=""
                group_choice=""
                continue
            fi

            if [ -n "$LOCATION" ]; then
                if [[ "$LOCATION" != "__"* ]]; then
                    return
                fi
                LOCATION=""
            fi
        done
    done
}

prompt_defaults() {
    local prefix_default

    if [ -z "$PROJECT_DIR" ]; then
        prompt_input PROJECT_DIR "Project directory" ""
    fi

    if [ -z "$PREFIX" ]; then
        prefix_default=$(basename "$PROJECT_DIR")
        [ -z "$prefix_default" ] || [ "$prefix_default" = "." ] && prefix_default="sakit"
        prompt_input PREFIX "Resource prefix" "$prefix_default"
    fi
}

validate_inputs() {
    if [ -z "$TEMPLATE_ID" ] || { [ "$TEMPLATE_ID" != "azure-custom-builder" ] && [ ! -d "$TEMPLATE_ROOT/$TEMPLATE_ID" ]; }; then
        echo "Error: Unknown Terraform template '$TEMPLATE_ID'."
        exit 1
    fi

    if [ -z "$PROJECT_DIR" ]; then
        echo "Error: Project directory is required."
        exit 1
    fi

    if [ -e "$PROJECT_DIR" ]; then
        echo "Error: '$PROJECT_DIR' already exists. Choose a new directory to avoid overwriting files."
        exit 1
    fi

    if [[ "$TEMPLATE_ID" = "azure-custom-builder" && "${#SELECTED_COMPONENT_IDS[@]}" -eq 0 ]]; then
        echo "Error: Select at least one custom builder component."
        exit 1
    fi

    if [ "$TEMPLATE_ID" = "azure-custom-builder" ] && [[ "$PROJECT_STYLE" != "flat" && "$PROJECT_STYLE" != "module" ]]; then
        echo "Error: Project style must be 'flat' or 'module'."
        exit 1
    fi

    if [[ "$TEMPLATE_ID" = "azure-linux-vm" || "$TEMPLATE_ID" = "azure-private-vmss-stack" ]] || { [ "$TEMPLATE_ID" = "azure-custom-builder" ] && { component_selected "linux-vm" || component_selected "vmss"; }; }; then
        if [ -z "$VM_SIZE" ]; then
            echo "Error: VM size is required for $TEMPLATE_ID."
            exit 1
        fi

        if [ -z "$(os_image_publisher "$OS_IMAGE_ID")" ]; then
            echo "Error: Unknown OS image '$OS_IMAGE_ID'."
            exit 1
        fi

        if [ -z "$SSH_PUBLIC_KEY" ]; then
            echo "Error: SSH public key is required for $TEMPLATE_ID."
            exit 1
        fi
    fi
}

print_preview_row() {
    local component="$1"
    local action="$2"
    local resource="$3"
    local detail="$4"

    if component_selected "$component"; then
        printf '    \033[1;32m%-7s\033[0m %-26s %s\n' "$action" "$resource" "$detail"
    fi
}

print_preview_line() {
    printf '    \033[1;32m%-7s\033[0m %-26s %s\n' "$1" "$2" "$3"
}

print_preview_section() {
    printf '\n  \033[1;36m%s\033[0m\n' "$1"
    printf '  \033[2m%s\033[0m\n' "$2"
}

custom_preview_has_group() {
    for component in "$@"; do
        component_selected "$component" && return 0
    done

    return 1
}

write_selected_components_markdown() {
    local target_file="$1"
    local component

    for component in "${SELECTED_COMPONENT_IDS[@]}"; do
        printf -- "- %s\n" "$(custom_component_label "$component")" >> "$target_file"
    done
}

write_learning_component_notes() {
    local target_file="$1"

    if custom_preview_has_group "resource-group" "vnet" "subnet" "nsg"; then
        cat >> "$target_file" <<'EOF'

## Network Layer

The network layer gives all later resources a place to live. The Resource Group is the Azure container, the Virtual Network is the private address space, and subnets divide the network into roles.

EOF
        component_selected "resource-group" && cat >> "$target_file" <<'EOF'
- **Resource Group** keeps the generated resources together so they can be managed and cleaned up as one unit.
EOF
        component_selected "vnet" && cat >> "$target_file" <<'EOF'
- **Virtual Network** creates the private network boundary for compute, data, and private endpoints.
EOF
        component_selected "subnet" && cat >> "$target_file" <<'EOF'
- **Subnets** split the VNet into `appgw`, `web`, `api`, and `data` tiers.
EOF
        component_selected "nsg" && cat >> "$target_file" <<'EOF'
- **Network Security Groups** control allowed traffic for the generated web and API subnets.
EOF
    fi

    if custom_preview_has_group "linux-vm" "vmss" "internal-lb"; then
        cat >> "$target_file" <<'EOF'

## Compute Layer

The compute layer runs Linux workloads. SSH access uses the public key written into `terraform.tfvars.example`.

EOF
        component_selected "linux-vm" && cat >> "$target_file" <<'EOF'
- **Linux VM** is useful for single-server labs, jump hosts, or quick experiments.
EOF
        component_selected "vmss" && cat >> "$target_file" <<'EOF'
- **VM Scale Sets** create frontend and backend groups that can later be scaled or attached to load balancers.
EOF
        component_selected "internal-lb" && cat >> "$target_file" <<'EOF'
- **Internal Load Balancers** distribute private traffic to frontend and backend pools without exposing public endpoints.
EOF
    fi

    if custom_preview_has_group "azure-sql" "private-endpoint"; then
        cat >> "$target_file" <<'EOF'

## Data Layer

The data layer uses Azure SQL. Public network access is disabled in the generated SQL server.

EOF
        component_selected "azure-sql" && cat >> "$target_file" <<'EOF'
- **Azure SQL** creates a managed SQL server and database.
EOF
        component_selected "private-endpoint" && cat >> "$target_file" <<'EOF'
- **Private Endpoint** connects SQL privately through the data subnet.
EOF
    fi

    if custom_preview_has_group "key-vault" "app-gateway-waf"; then
        cat >> "$target_file" <<'EOF'

## Security Layer

The security layer starts the scaffolding for secrets and edge protection.

EOF
        component_selected "key-vault" && cat >> "$target_file" <<'EOF'
- **Key Vault** stores secrets with public network access disabled.
EOF
        component_selected "app-gateway-waf" && cat >> "$target_file" <<'EOF'
- **WAF Policy** enables OWASP managed rules in prevention mode.
EOF
    fi

    if custom_preview_has_group "monitoring" "backup"; then
        cat >> "$target_file" <<'EOF'

## Operations Layer

The operations layer makes the environment easier to observe and recover.

EOF
        component_selected "monitoring" && cat >> "$target_file" <<'EOF'
- **Monitoring** creates Log Analytics and Application Insights.
EOF
        component_selected "backup" && cat >> "$target_file" <<'EOF'
- **Backup** creates a Recovery Services Vault and a daily VM backup policy.
EOF
    fi
}

print_custom_architecture_preview() {
    if [ "$TEMPLATE_ID" != "azure-custom-builder" ]; then
        return
    fi

    printf '\n\033[1;36mArchitecture Preview\033[0m\n'
    printf '\033[2m%s\033[0m\n' '----------------------------------------'

    if custom_preview_has_group "resource-group" "vnet" "subnet" "nsg"; then
        print_preview_section "Network" "Core Azure networking resources"
        print_preview_row "resource-group" "create" "Resource Group" "${PREFIX}-rg"
        print_preview_row "vnet" "create" "Virtual Network" "${PREFIX}-vnet (${LOCATION})"
        print_preview_row "subnet" "create" "Subnets" "appgw, web, api, data"
        print_preview_row "nsg" "create" "NSGs" "web/api traffic rules"
    fi

    if custom_preview_has_group "linux-vm" "vmss" "internal-lb"; then
        print_preview_section "Compute" "Linux compute and private traffic distribution"
        print_preview_row "linux-vm" "create" "Linux VM" "${PREFIX}-vm (${VM_SIZE})"
        print_preview_row "vmss" "create" "VM Scale Sets" "frontend + backend (${VM_SIZE})"
        print_preview_row "internal-lb" "create" "Internal LBs" "frontend:80, backend:8080"
    fi

    if custom_preview_has_group "azure-sql" "private-endpoint"; then
        print_preview_section "Data" "Managed database layer"
        print_preview_row "azure-sql" "create" "Azure SQL" "${PREFIX}-sql / ${PREFIX}-sqldb"
        print_preview_row "private-endpoint" "create" "Private Endpoint" "SQL private access via data subnet"
    fi

    if custom_preview_has_group "key-vault" "app-gateway-waf"; then
        print_preview_section "Security" "Access and edge protection scaffolds"
        print_preview_row "key-vault" "create" "Key Vault" "public network access disabled"
        print_preview_row "app-gateway-waf" "create" "WAF Policy" "OWASP 3.2 prevention mode"
    fi

    if custom_preview_has_group "monitoring" "backup"; then
        print_preview_section "Operations" "Observability and recovery resources"
        print_preview_row "monitoring" "create" "Monitoring" "Log Analytics + Application Insights"
        print_preview_row "backup" "create" "Backup" "Recovery Services Vault + daily policy"
    fi

    print_preview_section "Files" "Terraform project files to be written"
    if [ "$PROJECT_STYLE" = "module" ]; then
        print_preview_line "write" "versions.tf" "provider and version constraints"
        print_preview_line "write" "main.tf" "root module calls"
        print_preview_line "write" "variables.tf" "root input variables"
        print_preview_line "write" "outputs.tf" "root outputs"
        print_preview_line "write" "modules/network" "resource group, vnet, subnets, nsgs"
        custom_preview_has_group "internal-lb" && print_preview_line "write" "modules/load_balancer" "private frontend/backend load balancers"
        custom_preview_has_group "linux-vm" "vmss" && print_preview_line "write" "modules/compute" "linux vm and vm scale sets"
        custom_preview_has_group "azure-sql" "private-endpoint" && print_preview_line "write" "modules/data" "sql database and private endpoint"
        custom_preview_has_group "key-vault" "app-gateway-waf" && print_preview_line "write" "modules/security" "key vault and waf policy"
        custom_preview_has_group "monitoring" "backup" && print_preview_line "write" "modules/operations" "monitoring and backup"
        print_preview_line "write" "terraform.tfvars.example" "editable example values"
        print_preview_line "write" "README.md" "project summary"
    else
        print_preview_line "write" "versions.tf" "provider and version constraints"
        print_preview_line "write" "main.tf" "selected Azure resources"
        print_preview_line "write" "variables.tf" "input variables"
        print_preview_line "write" "outputs.tf" "useful outputs"
        print_preview_line "write" "terraform.tfvars.example" "editable example values"
        print_preview_line "write" "README.md" "project summary"
    fi

    if [ "${#AUTO_ADDED_COMPONENT_IDS[@]}" -gt 0 ]; then
        print_preview_section "Auto-added Dependencies" "Required by the resources you selected"
        for component in "${AUTO_ADDED_COMPONENT_IDS[@]}"; do
            print_preview_line "add" "$(custom_component_label "$component")" "dependency"
        done
    fi

    printf '\033[2m%s\033[0m\n' '----------------------------------------'
}

confirm_create() {
    local choice

    printf '\n\033[1;36mProject Summary\033[0m\n'
    printf '  \033[2mTemplate:\033[0m  %s\n' "$(template_label "$TEMPLATE_ID")"
    printf '  \033[2mDirectory:\033[0m %s\n' "$PROJECT_DIR"
    printf '  \033[2mPrefix:\033[0m    %s\n' "$PREFIX"
    printf '  \033[2mLocation:\033[0m  %s\n' "$LOCATION"
    case "$AZ_ACCOUNT_STATUS" in
        "signed-in")
            printf '  \033[2mAzure:\033[0m    %s (%s)\n' "$AZ_ACCOUNT_NAME" "$AZ_SUBSCRIPTION_ID"
            [ -n "$AZ_ACCOUNT_USER" ] && printf '  \033[2mAzure User:\033[0m %s\n' "$AZ_ACCOUNT_USER"
            ;;
        "not-signed-in")
            printf '  \033[2mAzure:\033[0m    Azure CLI found, but no active login\n'
            ;;
        "not-installed")
            printf '  \033[2mAzure:\033[0m    Azure CLI not found\n'
            ;;
    esac
    if [[ "$TEMPLATE_ID" = "azure-linux-vm" || "$TEMPLATE_ID" = "azure-private-vmss-stack" ]]; then
        printf '  \033[2mVM Size:\033[0m   %s\n' "$VM_SIZE"
        printf '  \033[2mSize List:\033[0m  %s\n' "$VM_SIZE_SOURCE"
        printf '  \033[2mOS Image:\033[0m  %s\n' "$(os_image_label "$OS_IMAGE_ID")"
        printf '  \033[2mSSH Key:\033[0m   %s\n' "$SSH_KEY_SOURCE"
    fi
    if [ "$TEMPLATE_ID" = "azure-custom-builder" ]; then
        printf '  \033[2mStyle:\033[0m      %s\n' "$(project_style_label "$PROJECT_STYLE")"
        printf '  \033[2mComponents:\033[0m\n'
        for component in "${SELECTED_COMPONENT_IDS[@]}"; do
            printf '    - %s\n' "$(custom_component_label "$component")"
        done
        if component_selected "linux-vm" || component_selected "vmss"; then
            printf '  \033[2mVM Size:\033[0m   %s\n' "$VM_SIZE"
            printf '  \033[2mSize List:\033[0m  %s\n' "$VM_SIZE_SOURCE"
            printf '  \033[2mOS Image:\033[0m  %s\n' "$(os_image_label "$OS_IMAGE_ID")"
            printf '  \033[2mSSH Key:\033[0m   %s\n' "$SSH_KEY_SOURCE"
        fi
    fi

    print_custom_architecture_preview

    if [ "$AUTO_YES" = true ]; then
        return
    fi

    printf '\n\033[1;36mCreate Terraform project?\033[0m \033[2m(y/n)\033[0m: '
    read -r choice
    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
}

render_templates() {
    local src
    local dest
    local rel
    local project_name
    local image_publisher
    local image_offer
    local image_sku
    local ssh_public_key
    local ssh_private_key_path

    project_name=$(basename "$PROJECT_DIR")
    image_publisher=$(os_image_publisher "$OS_IMAGE_ID")
    image_offer=$(os_image_offer "$OS_IMAGE_ID")
    image_sku=$(os_image_sku "$OS_IMAGE_ID")
    ssh_public_key=$(escape_sed_replacement "$SSH_PUBLIC_KEY")
    ssh_private_key_path=$(escape_sed_replacement "$SSH_PRIVATE_KEY_PATH")
    mkdir -p "$PROJECT_DIR"

    while IFS= read -r src; do
        rel="${src#"$TEMPLATE_ROOT/$TEMPLATE_ID"/}"
        dest="$PROJECT_DIR/${rel%.tpl}"
        mkdir -p "$(dirname "$dest")"
        sed \
            -e "s|__PROJECT_NAME__|$project_name|g" \
            -e "s|__PREFIX__|$PREFIX|g" \
            -e "s|__LOCATION__|$LOCATION|g" \
            -e "s|__VM_SIZE__|$VM_SIZE|g" \
            -e "s|__OS_IMAGE_ID__|$OS_IMAGE_ID|g" \
            -e "s|__IMAGE_PUBLISHER__|$image_publisher|g" \
            -e "s|__IMAGE_OFFER__|$image_offer|g" \
            -e "s|__IMAGE_SKU__|$image_sku|g" \
            -e "s|__SSH_PUBLIC_KEY__|$ssh_public_key|g" \
            -e "s|__SSH_PRIVATE_KEY_PATH__|$ssh_private_key_path|g" \
            "$src" > "$dest"
    done < <(find "$TEMPLATE_ROOT/$TEMPLATE_ID" -type f -name '*.tpl' | sort)
}

write_custom_builder_project() {
    local image_publisher
    local image_offer
    local image_sku
    local ssh_public_key
    local ssh_private_key_path

    image_publisher=$(os_image_publisher "$OS_IMAGE_ID")
    image_offer=$(os_image_offer "$OS_IMAGE_ID")
    image_sku=$(os_image_sku "$OS_IMAGE_ID")
    ssh_public_key="$SSH_PUBLIC_KEY"
    ssh_private_key_path="$SSH_PRIVATE_KEY_PATH"

    mkdir -p "$PROJECT_DIR"

    cat > "$PROJECT_DIR/versions.tf" <<'EOF'
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
EOF

    cat > "$PROJECT_DIR/variables.tf" <<EOF
variable "prefix" {
  description = "Name prefix for Azure resources."
  type        = string
  default     = "$PREFIX"
}

variable "location" {
  description = "Azure region where resources will be created."
  type        = string
  default     = "$LOCATION"
}

variable "vnet_address_space" {
  description = "CIDR block for the virtual network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "appgw_subnet_prefix" {
  description = "CIDR block for the application gateway subnet."
  type        = string
  default     = "10.0.11.0/24"
}

variable "web_subnet_prefix" {
  description = "CIDR block for the web subnet."
  type        = string
  default     = "10.0.12.0/24"
}

variable "api_subnet_prefix" {
  description = "CIDR block for the api subnet."
  type        = string
  default     = "10.0.13.0/24"
}

variable "data_subnet_prefix" {
  description = "CIDR block for the data subnet."
  type        = string
  default     = "10.0.14.0/24"
}

variable "admin_username" {
  description = "Admin username for Linux compute resources."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for Linux compute resources."
  type        = string
  default     = "$ssh_public_key"

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)[[:space:]]+[^[:space:]]+", var.ssh_public_key))
    error_message = "ssh_public_key must be a complete SSH public key, for example: ssh-ed25519 AAAA... user@host. Do not enter a password or a short word."
  }
}

variable "ssh_private_key_path" {
  description = "Local private key path used only to print a convenient SSH command."
  type        = string
  default     = "$ssh_private_key_path"
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "$VM_SIZE"
}

variable "image_publisher" {
  description = "Azure Marketplace image publisher."
  type        = string
  default     = "$image_publisher"
}

variable "image_offer" {
  description = "Azure Marketplace image offer."
  type        = string
  default     = "$image_offer"
}

variable "image_sku" {
  description = "Azure Marketplace image SKU."
  type        = string
  default     = "$image_sku"
}

variable "image_version" {
  description = "Azure Marketplace image version."
  type        = string
  default     = "latest"
}

variable "sql_admin_login" {
  description = "Azure SQL administrator username."
  type        = string
  default     = "sqladminuser"
}

variable "sql_admin_password" {
  description = "Azure SQL administrator password."
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_STRONG_PASSWORD"
}
EOF

    cat > "$PROJECT_DIR/main.tf" <<'EOF'
locals {
  tags = {
    project    = var.prefix
    managed_by = "terraform"
  }
}

EOF

    if component_selected "resource-group"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = local.tags
}

EOF
    fi

    if component_selected "vnet"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

EOF
    fi

    if component_selected "subnet"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_subnet" "appgw" {
  name                 = "${var.prefix}-appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.appgw_subnet_prefix]
}

resource "azurerm_subnet" "web" {
  name                 = "${var.prefix}-web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.web_subnet_prefix]
}

resource "azurerm_subnet" "api" {
  name                 = "${var.prefix}-api-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.api_subnet_prefix]
}

resource "azurerm_subnet" "data" {
  name                              = "${var.prefix}-data-subnet"
  resource_group_name               = azurerm_resource_group.rg.name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = [var.data_subnet_prefix]
  private_endpoint_network_policies = "Disabled"
}

EOF
    fi

    if component_selected "nsg"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_network_security_group" "web" {
  name                = "${var.prefix}-web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "api" {
  name                = "${var.prefix}-api-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-API"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.web_subnet_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "api" {
  subnet_id                 = azurerm_subnet.api.id
  network_security_group_id = azurerm_network_security_group.api.id
}

EOF
    fi

    if component_selected "internal-lb"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_lb" "frontend" {
  name                = "${var.prefix}-frontend-ilb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = local.tags

  frontend_ip_configuration {
    name                          = "frontend-private"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "frontend" {
  name            = "frontend-pool"
  loadbalancer_id = azurerm_lb.frontend.id
}

resource "azurerm_lb_probe" "frontend" {
  name            = "frontend-health"
  loadbalancer_id = azurerm_lb.frontend.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_rule" "frontend" {
  name                           = "frontend-http"
  loadbalancer_id                = azurerm_lb.frontend.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-private"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.frontend.id]
  probe_id                       = azurerm_lb_probe.frontend.id
}

resource "azurerm_lb" "backend" {
  name                = "${var.prefix}-backend-ilb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = local.tags

  frontend_ip_configuration {
    name                          = "backend-private"
    subnet_id                     = azurerm_subnet.api.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "backend" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.backend.id
}

resource "azurerm_lb_probe" "backend" {
  name            = "backend-health"
  loadbalancer_id = azurerm_lb.backend.id
  protocol        = "Tcp"
  port            = 8080
}

resource "azurerm_lb_rule" "backend" {
  name                           = "backend-http"
  loadbalancer_id                = azurerm_lb.backend.id
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "backend-private"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend.id]
  probe_id                       = azurerm_lb_probe.backend.id
}

EOF
    fi

    if component_selected "linux-vm"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_public_ip" "vm" {
  name                = "${var.prefix}-vm-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "vm" {
  name                = "${var.prefix}-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${var.prefix}-vm"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  custom_data = base64encode(<<-CLOUDINIT
#cloud-config
write_files:
  - path: /etc/sudoers.d/90-${var.admin_username}-nopasswd
    owner: root:root
    permissions: '0440'
    content: |
      ${var.admin_username} ALL=(ALL) NOPASSWD:ALL
CLOUDINIT
  )
  network_interface_ids           = [azurerm_network_interface.vm.id]
  tags                            = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
}

EOF
    fi

    if component_selected "vmss"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_linux_virtual_machine_scale_set" "frontend" {
  name                            = "${var.prefix}-frontend-vmss"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  sku                             = var.vm_size
  instances                       = 1
  admin_username                  = var.admin_username
  disable_password_authentication = true
  overprovision                   = false
  upgrade_mode                    = "Manual"
  tags                            = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  network_interface {
    name    = "nic-frontend"
    primary = true

    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.web.id
EOF
        if component_selected "internal-lb"; then
            cat >> "$PROJECT_DIR/main.tf" <<'EOF'
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.frontend.id]
EOF
        fi
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
    }
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "backend" {
  name                            = "${var.prefix}-backend-vmss"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  sku                             = var.vm_size
  instances                       = 1
  admin_username                  = var.admin_username
  disable_password_authentication = true
  overprovision                   = false
  upgrade_mode                    = "Manual"
  tags                            = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  network_interface {
    name    = "nic-backend"
    primary = true

    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.api.id
EOF
        if component_selected "internal-lb"; then
            cat >> "$PROJECT_DIR/main.tf" <<'EOF'
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend.id]
EOF
        fi
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
    }
  }
}

EOF
    fi

    if component_selected "azure-sql"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_mssql_server" "sql" {
  name                          = "${var.prefix}-sql"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"
  tags                          = local.tags
}

resource "azurerm_mssql_database" "sql" {
  name        = "${var.prefix}-sqldb"
  server_id   = azurerm_mssql_server.sql.id
  sku_name    = "S0"
  max_size_gb = 10
  tags        = local.tags
}

EOF
    fi

    if component_selected "private-endpoint"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_private_endpoint" "sql" {
  name                = "${var.prefix}-sql-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.data.id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.prefix}-sql-psc"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

EOF
    fi

    if component_selected "key-vault"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_key_vault" "kv" {
  name                          = substr(replace("${var.prefix}-kv", "-", ""), 0, 24)
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = false
  soft_delete_retention_days    = 7
  tags                          = local.tags
}

data "azurerm_client_config" "current" {}

EOF
    fi

    if component_selected "app-gateway-waf"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_web_application_firewall_policy" "waf" {
  name                = "${var.prefix}-waf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

EOF
    fi

    if component_selected "monitoring"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights" "appi" {
  name                = "${var.prefix}-appi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
  tags                = local.tags
}

EOF
    fi

    if component_selected "backup"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
resource "azurerm_recovery_services_vault" "rsv" {
  name                = "${var.prefix}-rsv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  storage_mode_type   = "GeoRedundant"
  tags                = local.tags
}

resource "azurerm_backup_policy_vm" "daily" {
  name                = "${var.prefix}-daily-backup"
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name
  timezone            = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 14
  }
}

EOF
    fi

    cat > "$PROJECT_DIR/outputs.tf" <<'EOF'
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
EOF
    component_selected "linux-vm" && cat >> "$PROJECT_DIR/outputs.tf" <<'EOF'

output "linux_vm_public_ip" {
  value = azurerm_public_ip.vm.ip_address
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.vm.ip_address}"
}
EOF
    component_selected "vmss" && cat >> "$PROJECT_DIR/outputs.tf" <<'EOF'

output "frontend_vmss_name" {
  value = azurerm_linux_virtual_machine_scale_set.frontend.name
}

output "backend_vmss_name" {
  value = azurerm_linux_virtual_machine_scale_set.backend.name
}
EOF
    component_selected "azure-sql" && cat >> "$PROJECT_DIR/outputs.tf" <<'EOF'

output "sql_server_name" {
  value = azurerm_mssql_server.sql.name
}
EOF

    cat > "$PROJECT_DIR/terraform.tfvars.example" <<EOF
prefix              = "$PREFIX"
location            = "$LOCATION"
vnet_address_space  = "10.0.0.0/16"
appgw_subnet_prefix = "10.0.11.0/24"
web_subnet_prefix   = "10.0.12.0/24"
api_subnet_prefix   = "10.0.13.0/24"
data_subnet_prefix  = "10.0.14.0/24"
admin_username      = "azureuser"
ssh_public_key      = "$ssh_public_key"
ssh_private_key_path = "$ssh_private_key_path"
vm_size             = "$VM_SIZE"
image_publisher     = "$image_publisher"
image_offer         = "$image_offer"
image_sku           = "$image_sku"
image_version       = "latest"
sql_admin_login     = "sqladminuser"
sql_admin_password  = "CHANGE_ME_STRONG_PASSWORD"
EOF

    if [ "$LEARNING_MODE" = true ]; then
        cat > "$PROJECT_DIR/README.md" <<EOF
# $(basename "$PROJECT_DIR")

Generated with Sakit-DB Azure Custom Builder.

This README was generated in learning mode. It explains what the selected resources do and how they fit together.

## Selected Components

EOF
        write_selected_components_markdown "$PROJECT_DIR/README.md"

        cat >> "$PROJECT_DIR/README.md" <<'EOF'

## Architecture Flow

```text
Resource Group
  -> Virtual Network
    -> Subnets
      -> NSG / Load Balancer / Compute / Private Endpoint
```
EOF
        write_learning_component_notes "$PROJECT_DIR/README.md"

        cat >> "$PROJECT_DIR/README.md" <<'EOF'

## Terraform Workflow

1. Copy example variables:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Initialize providers:

```bash
terraform init
```

3. Preview changes:

```bash
terraform plan
```

4. Apply when the plan looks correct:

```bash
terraform apply
```

5. Destroy lab resources when finished:

```bash
terraform destroy
```

## Things To Review

- Replace placeholder passwords before applying.
- Review CIDR ranges if you deploy into an existing network.
- Restrict SSH access before using this outside a lab.
- Run `terraform plan` carefully before `terraform apply`.
EOF
    else
        cat > "$PROJECT_DIR/README.md" <<EOF
# $(basename "$PROJECT_DIR")

Generated with Sakit-DB Azure Custom Builder.

## Selected Components

EOF
        write_selected_components_markdown "$PROJECT_DIR/README.md"

        cat >> "$PROJECT_DIR/README.md" <<'EOF'

## Next Steps

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Review generated CIDR ranges, public exposure, and placeholder secrets before applying.
EOF
    fi
}

write_module_network() {
    local dir="$1"

    cat > "$dir/variables.tf" <<'EOF'
variable "prefix" { type = string }
variable "location" { type = string }
variable "vnet_address_space" { type = string }
variable "appgw_subnet_prefix" { type = string }
variable "web_subnet_prefix" { type = string }
variable "api_subnet_prefix" { type = string }
variable "data_subnet_prefix" { type = string }
EOF

    cat > "$dir/main.tf" <<'EOF'
locals {
  tags = {
    project    = var.prefix
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = local.tags
}
EOF

    if component_selected "vnet"; then
        cat >> "$dir/main.tf" <<'EOF'

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}
EOF
    fi

    if component_selected "subnet"; then
        cat >> "$dir/main.tf" <<'EOF'

resource "azurerm_subnet" "appgw" {
  name                 = "${var.prefix}-appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.appgw_subnet_prefix]
}

resource "azurerm_subnet" "web" {
  name                 = "${var.prefix}-web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.web_subnet_prefix]
}

resource "azurerm_subnet" "api" {
  name                 = "${var.prefix}-api-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.api_subnet_prefix]
}

resource "azurerm_subnet" "data" {
  name                              = "${var.prefix}-data-subnet"
  resource_group_name               = azurerm_resource_group.rg.name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = [var.data_subnet_prefix]
  private_endpoint_network_policies = "Disabled"
}
EOF
    fi

    if component_selected "nsg"; then
        cat >> "$dir/main.tf" <<'EOF'

resource "azurerm_network_security_group" "web" {
  name                = "${var.prefix}-web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "api" {
  name                = "${var.prefix}-api-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-API"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.web_subnet_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "api" {
  subnet_id                 = azurerm_subnet.api.id
  network_security_group_id = azurerm_network_security_group.api.id
}
EOF
    fi

    cat > "$dir/outputs.tf" <<'EOF'
output "rg_name" { value = azurerm_resource_group.rg.name }
output "rg_location" { value = azurerm_resource_group.rg.location }
EOF

    if component_selected "subnet"; then
        cat >> "$dir/outputs.tf" <<'EOF'
output "web_subnet_id" { value = azurerm_subnet.web.id }
output "api_subnet_id" { value = azurerm_subnet.api.id }
output "data_subnet_id" { value = azurerm_subnet.data.id }
EOF
    fi

    if component_selected "nsg"; then
        cat >> "$dir/outputs.tf" <<'EOF'
output "web_nsg_id" { value = azurerm_network_security_group.web.id }
EOF
    fi
}


write_module_load_balancer() {
    local dir="$1"

    cat > "$dir/variables.tf" <<'EOF'
variable "prefix" { type = string }
variable "location" { type = string }
variable "rg_name" { type = string }
variable "web_subnet_id" { type = string }
variable "api_subnet_id" { type = string }
EOF

    cat > "$dir/main.tf" <<'EOF'
locals {
  tags = {
    project    = var.prefix
    managed_by = "terraform"
  }
}

resource "azurerm_lb" "frontend" {
  name                = "${var.prefix}-frontend-ilb"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  tags                = local.tags

  frontend_ip_configuration {
    name                          = "frontend-private"
    subnet_id                     = var.web_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "frontend" {
  name            = "frontend-pool"
  loadbalancer_id = azurerm_lb.frontend.id
}

resource "azurerm_lb_probe" "frontend" {
  name            = "frontend-health"
  loadbalancer_id = azurerm_lb.frontend.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_rule" "frontend" {
  name                           = "frontend-http"
  loadbalancer_id                = azurerm_lb.frontend.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-private"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.frontend.id]
  probe_id                       = azurerm_lb_probe.frontend.id
}

resource "azurerm_lb" "backend" {
  name                = "${var.prefix}-backend-ilb"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  tags                = local.tags

  frontend_ip_configuration {
    name                          = "backend-private"
    subnet_id                     = var.api_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "backend" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.backend.id
}

resource "azurerm_lb_probe" "backend" {
  name            = "backend-health"
  loadbalancer_id = azurerm_lb.backend.id
  protocol        = "Tcp"
  port            = 8080
}

resource "azurerm_lb_rule" "backend" {
  name                           = "backend-http"
  loadbalancer_id                = azurerm_lb.backend.id
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "backend-private"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend.id]
  probe_id                       = azurerm_lb_probe.backend.id
}
EOF

    cat > "$dir/outputs.tf" <<'EOF'
output "frontend_backend_pool_id" { value = azurerm_lb_backend_address_pool.frontend.id }
output "backend_backend_pool_id" { value = azurerm_lb_backend_address_pool.backend.id }
EOF
}

write_module_compute() {
    local dir="$1"

    cat > "$dir/variables.tf" <<'EOF'
variable "prefix" { type = string }
variable "location" { type = string }
variable "rg_name" { type = string }
variable "web_subnet_id" { type = string }
variable "api_subnet_id" { type = string }
variable "web_nsg_id" { type = string }
variable "admin_username" { type = string }
variable "ssh_public_key" { type = string }
variable "ssh_private_key_path" { type = string }
variable "vm_size" { type = string }
variable "image_publisher" { type = string }
variable "image_offer" { type = string }
variable "image_sku" { type = string }
variable "image_version" { type = string }
variable "frontend_lb_backend_pool_id" {
  type    = string
  default = null
}
variable "backend_lb_backend_pool_id" {
  type    = string
  default = null
}
EOF

    cat > "$dir/main.tf" <<'EOF'
locals {
  tags = {
    project    = var.prefix
    managed_by = "terraform"
  }
}
EOF

    if component_selected "linux-vm"; then
        cat >> "$dir/main.tf" <<'EOF'

resource "azurerm_public_ip" "vm" {
  name                = "${var.prefix}-vm-pip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "vm" {
  name                = "${var.prefix}-vm-nic"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.web_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = var.web_nsg_id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${var.prefix}-vm"
  location                        = var.location
  resource_group_name             = var.rg_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  custom_data = base64encode(<<-CLOUDINIT
#cloud-config
write_files:
  - path: /etc/sudoers.d/90-${var.admin_username}-nopasswd
    owner: root:root
    permissions: '0440'
    content: |
      ${var.admin_username} ALL=(ALL) NOPASSWD:ALL
CLOUDINIT
  )
  network_interface_ids           = [azurerm_network_interface.vm.id]
  tags                            = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
}
EOF
    fi

    if component_selected "vmss"; then
        cat >> "$dir/main.tf" <<'EOF'

resource "azurerm_linux_virtual_machine_scale_set" "frontend" {
  name                            = "${var.prefix}-frontend-vmss"
  location                        = var.location
  resource_group_name             = var.rg_name
  sku                             = var.vm_size
  instances                       = 1
  admin_username                  = var.admin_username
  disable_password_authentication = true
  overprovision                   = false
  upgrade_mode                    = "Manual"
  tags                            = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  network_interface {
    name    = "nic-frontend"
    primary = true
    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = var.web_subnet_id
      load_balancer_backend_address_pool_ids = var.frontend_lb_backend_pool_id == null ? [] : [var.frontend_lb_backend_pool_id]
    }
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "backend" {
  name                            = "${var.prefix}-backend-vmss"
  location                        = var.location
  resource_group_name             = var.rg_name
  sku                             = var.vm_size
  instances                       = 1
  admin_username                  = var.admin_username
  disable_password_authentication = true
  overprovision                   = false
  upgrade_mode                    = "Manual"
  tags                            = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  network_interface {
    name    = "nic-backend"
    primary = true
    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = var.api_subnet_id
      load_balancer_backend_address_pool_ids = var.backend_lb_backend_pool_id == null ? [] : [var.backend_lb_backend_pool_id]
    }
  }
}
EOF
    fi

    : > "$dir/outputs.tf"
    component_selected "linux-vm" && echo 'output "linux_vm_public_ip" { value = azurerm_public_ip.vm.ip_address }' >> "$dir/outputs.tf"
    component_selected "linux-vm" && echo 'output "ssh_command" { value = "ssh ${var.admin_username}@${azurerm_public_ip.vm.ip_address}" }' >> "$dir/outputs.tf"
    component_selected "vmss" && {
        echo 'output "frontend_vmss_name" { value = azurerm_linux_virtual_machine_scale_set.frontend.name }' >> "$dir/outputs.tf"
        echo 'output "backend_vmss_name" { value = azurerm_linux_virtual_machine_scale_set.backend.name }' >> "$dir/outputs.tf"
    }
}

write_module_data() {
    local dir="$1"

    cat > "$dir/variables.tf" <<'EOF'
variable "prefix" { type = string }
variable "location" { type = string }
variable "rg_name" { type = string }
variable "data_subnet_id" { type = string }
variable "sql_admin_login" { type = string }
variable "sql_admin_password" {
  type      = string
  sensitive = true
}
EOF

    cat > "$dir/main.tf" <<'EOF'
locals {
  tags = {
    project    = var.prefix
    managed_by = "terraform"
  }
}

resource "azurerm_mssql_server" "sql" {
  name                          = "${var.prefix}-sql"
  location                      = var.location
  resource_group_name           = var.rg_name
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"
  tags                          = local.tags
}

resource "azurerm_mssql_database" "sql" {
  name        = "${var.prefix}-sqldb"
  server_id   = azurerm_mssql_server.sql.id
  sku_name    = "S0"
  max_size_gb = 10
  tags        = local.tags
}
EOF
    if component_selected "private-endpoint"; then
        cat >> "$dir/main.tf" <<'EOF'

resource "azurerm_private_endpoint" "sql" {
  name                = "${var.prefix}-sql-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.data_subnet_id
  tags                = local.tags
  private_service_connection {
    name                           = "${var.prefix}-sql-psc"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}
EOF
    fi
    echo 'output "sql_server_name" { value = azurerm_mssql_server.sql.name }' > "$dir/outputs.tf"
}

write_module_security() {
    local dir="$1"

    cat > "$dir/variables.tf" <<'EOF'
variable "prefix" { type = string }
variable "location" { type = string }
variable "rg_name" { type = string }
EOF

    cat > "$dir/main.tf" <<'EOF'
locals {
  tags = {
    project    = var.prefix
    managed_by = "terraform"
  }
}
EOF

    if component_selected "key-vault"; then
        cat >> "$dir/main.tf" <<'EOF'

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                          = substr(replace("${var.prefix}-kv", "-", ""), 0, 24)
  location                      = var.location
  resource_group_name           = var.rg_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = false
  soft_delete_retention_days    = 7
  tags                          = local.tags
}
EOF
    fi

    if component_selected "app-gateway-waf"; then
        cat >> "$dir/main.tf" <<'EOF'

resource "azurerm_web_application_firewall_policy" "waf" {
  name                = "${var.prefix}-waf"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = local.tags

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}
EOF
    fi

    : > "$dir/outputs.tf"
}

write_module_operations() {
    local dir="$1"

    cat > "$dir/variables.tf" <<'EOF'
variable "prefix" { type = string }
variable "location" { type = string }
variable "rg_name" { type = string }
EOF

    cat > "$dir/main.tf" <<'EOF'
locals {
  tags = {
    project    = var.prefix
    managed_by = "terraform"
  }
}
EOF

    if component_selected "monitoring"; then
        cat >> "$dir/main.tf" <<'EOF'

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights" "appi" {
  name                = "${var.prefix}-appi"
  location            = var.location
  resource_group_name = var.rg_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
  tags                = local.tags
}
EOF
    fi

    if component_selected "backup"; then
        cat >> "$dir/main.tf" <<'EOF'

resource "azurerm_recovery_services_vault" "rsv" {
  name                = "${var.prefix}-rsv"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  storage_mode_type   = "GeoRedundant"
  tags                = local.tags
}

resource "azurerm_backup_policy_vm" "daily" {
  name                = "${var.prefix}-daily-backup"
  resource_group_name = var.rg_name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name
  timezone            = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 14
  }
}
EOF
    fi

    : > "$dir/outputs.tf"
}

write_custom_builder_module_project() {
    local target_dir="$PROJECT_DIR"
    local tmp_dir

    tmp_dir=$(mktemp -d /tmp/sakit-custom-module.XXXXXX)

    PROJECT_DIR="$tmp_dir"
    write_custom_builder_project
    PROJECT_DIR="$target_dir"

    mkdir -p "$PROJECT_DIR"

    cp "$tmp_dir/versions.tf" "$PROJECT_DIR/versions.tf"
    cp "$tmp_dir/variables.tf" "$PROJECT_DIR/variables.tf"
    cp "$tmp_dir/terraform.tfvars.example" "$PROJECT_DIR/terraform.tfvars.example"

    cat > "$PROJECT_DIR/main.tf" <<'EOF'
module "network" {
  source = "./modules/network"

  prefix              = var.prefix
  location            = var.location
  vnet_address_space  = var.vnet_address_space
  appgw_subnet_prefix = var.appgw_subnet_prefix
  web_subnet_prefix   = var.web_subnet_prefix
  api_subnet_prefix   = var.api_subnet_prefix
  data_subnet_prefix  = var.data_subnet_prefix
}
EOF

    if component_selected "internal-lb"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'

module "load_balancer" {
  source = "./modules/load_balancer"

  prefix         = var.prefix
  location       = var.location
  rg_name        = module.network.rg_name
  web_subnet_id  = module.network.web_subnet_id
  api_subnet_id  = module.network.api_subnet_id
}
EOF
    fi

    if component_selected "linux-vm" || component_selected "vmss"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'

module "compute" {
  source = "./modules/compute"

  prefix         = var.prefix
  location       = var.location
  rg_name        = module.network.rg_name
  web_subnet_id  = module.network.web_subnet_id
  api_subnet_id  = module.network.api_subnet_id
  web_nsg_id     = module.network.web_nsg_id
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
  ssh_private_key_path = var.ssh_private_key_path
  vm_size             = var.vm_size
  image_publisher     = var.image_publisher
  image_offer         = var.image_offer
  image_sku           = var.image_sku
  image_version       = var.image_version
EOF
        if component_selected "internal-lb"; then
            cat >> "$PROJECT_DIR/main.tf" <<'EOF'
  frontend_lb_backend_pool_id = module.load_balancer.frontend_backend_pool_id
  backend_lb_backend_pool_id  = module.load_balancer.backend_backend_pool_id
EOF
        fi
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'
}
EOF
    fi

    if component_selected "azure-sql"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'

module "data" {
  source = "./modules/data"

  prefix             = var.prefix
  location           = var.location
  rg_name            = module.network.rg_name
  data_subnet_id     = module.network.data_subnet_id
  sql_admin_login     = var.sql_admin_login
  sql_admin_password  = var.sql_admin_password
}
EOF
    fi

    if component_selected "key-vault" || component_selected "app-gateway-waf"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'

module "security" {
  source = "./modules/security"

  prefix   = var.prefix
  location = var.location
  rg_name  = module.network.rg_name
}
EOF
    fi

    if component_selected "monitoring" || component_selected "backup"; then
        cat >> "$PROJECT_DIR/main.tf" <<'EOF'

module "operations" {
  source = "./modules/operations"

  prefix   = var.prefix
  location = var.location
  rg_name  = module.network.rg_name
}
EOF
    fi

    cat > "$PROJECT_DIR/outputs.tf" <<'EOF'
output "resource_group_name" {
  value = module.network.rg_name
}
EOF

    if component_selected "linux-vm"; then
        cat >> "$PROJECT_DIR/outputs.tf" <<'EOF'

output "linux_vm_public_ip" {
  value = module.compute.linux_vm_public_ip
}

output "ssh_command" {
  value = module.compute.ssh_command
}
EOF
    fi

    if component_selected "vmss"; then
        cat >> "$PROJECT_DIR/outputs.tf" <<'EOF'

output "frontend_vmss_name" {
  value = module.compute.frontend_vmss_name
}

output "backend_vmss_name" {
  value = module.compute.backend_vmss_name
}
EOF
    fi

    if component_selected "azure-sql"; then
        cat >> "$PROJECT_DIR/outputs.tf" <<'EOF'

output "sql_server_name" {
  value = module.data.sql_server_name
}
EOF
    fi

    mkdir -p "$PROJECT_DIR/modules/network"
    write_module_network "$PROJECT_DIR/modules/network"

    if component_selected "internal-lb"; then
        mkdir -p "$PROJECT_DIR/modules/load_balancer"
        write_module_load_balancer "$PROJECT_DIR/modules/load_balancer"
    fi

    if component_selected "linux-vm" || component_selected "vmss"; then
        mkdir -p "$PROJECT_DIR/modules/compute"
        write_module_compute "$PROJECT_DIR/modules/compute"
    fi

    if component_selected "azure-sql"; then
        mkdir -p "$PROJECT_DIR/modules/data"
        write_module_data "$PROJECT_DIR/modules/data"
    fi

    if component_selected "key-vault" || component_selected "app-gateway-waf"; then
        mkdir -p "$PROJECT_DIR/modules/security"
        write_module_security "$PROJECT_DIR/modules/security"
    fi

    if component_selected "monitoring" || component_selected "backup"; then
        mkdir -p "$PROJECT_DIR/modules/operations"
        write_module_operations "$PROJECT_DIR/modules/operations"
    fi

    cp "$tmp_dir/README.md" "$PROJECT_DIR/README.md"
    sed -i "1s|.*|# $(basename "$PROJECT_DIR")|" "$PROJECT_DIR/README.md"
    cat >> "$PROJECT_DIR/README.md" <<'EOF'

## Project Style

This project was generated in module-based mode. Root files call generated child modules under `modules/`.
EOF

    rm -rf "$tmp_dir"
}

render_project() {
    if [ "$TEMPLATE_ID" = "azure-custom-builder" ]; then
        if [ "$PROJECT_STYLE" = "module" ]; then
            write_custom_builder_module_project
        else
            write_custom_builder_project
        fi
    else
        render_templates
    fi
}

append_template_learning_readme() {
    local readme="$PROJECT_DIR/README.md"

    if [ "$LEARNING_MODE" != true ] || [ "$TEMPLATE_ID" = "azure-custom-builder" ] || [ ! -f "$readme" ]; then
        return
    fi

    cat >> "$readme" <<EOF

## Learning Notes

This section was added because the project was generated with learning mode.

### What This Template Teaches

EOF

    case "$TEMPLATE_ID" in
        "azure-resource-group")
            cat >> "$readme" <<'EOF'
- How to configure the AzureRM provider.
- How to create the simplest Azure container resource with Terraform.
- How variables and `terraform.tfvars.example` separate inputs from resource code.
EOF
            ;;
        "azure-vnet-subnet")
            cat >> "$readme" <<'EOF'
- How a Resource Group, Virtual Network, and Subnet relate to each other.
- How Terraform references one resource from another.
- Why address spaces and subnet prefixes should be planned before deployment.
EOF
            ;;
        "azure-linux-vm")
            cat >> "$readme" <<'EOF'
- How a Linux VM depends on networking, public IP, NIC, and NSG resources.
- How SSH public key authentication is wired into `azurerm_linux_virtual_machine`.
- How Azure image fields map to publisher, offer, SKU, and version.
EOF
            ;;
        "azure-private-vmss-stack")
            cat >> "$readme" <<'EOF'
- How a private app stack can be split into network, load balancer, compute, and database modules.
- How VM Scale Sets attach to internal load balancer backend pools.
- How private Azure SQL access changes the network design.
EOF
            ;;
    esac

    cat >> "$readme" <<'EOF'

### Practice Workflow

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Use `terraform destroy` when you are done with lab resources.
EOF
}

format_generated_project() {
    if command -v terraform &> /dev/null; then
        terraform fmt -recursive "$PROJECT_DIR" >/dev/null 2>&1 || true
    fi
}

choose_template
prompt_defaults
choose_location
show_custom_builder_loading
detect_azure_account
choose_custom_components
choose_project_style
choose_vm_size
choose_os_image
choose_ssh_key
validate_inputs
confirm_create
render_project
append_template_learning_readme
format_generated_project

printf '\n\033[1;32mCreated Terraform project:\033[0m\n'
printf '  %s\n' "$PROJECT_DIR"
printf '\n\033[1;36mNext steps:\033[0m\n'
printf '  cd %s\n' "$PROJECT_DIR"
printf '  terraform init\n'
printf '  terraform plan\n'
