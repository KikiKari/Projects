#!/usr/bin/env bash
# system_manager.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/system_manager.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/system_manager.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# System management abstraction for Ubuntu and CentOS 8.
# Provides command matrix for packages, services, networking.

# Associative arrays for commands (bash 4+)
declare -A UBUNTU_COMMANDS CENTOS_COMMANDS COMMAND_DESCRIPTIONS
declare -A PACKAGE_UBUNTU_MAP PACKAGE_CENTOS_MAP

# Initialize command mappings
init_commands() {
    # Package management
    UBUNTU_COMMANDS["install"]="apt-get install -y {package}"
    CENTOS_COMMANDS["install"]="dnf install -y {package}"
    COMMAND_DESCRIPTIONS["install"]="Install a package"

    UBUNTU_COMMANDS["remove"]="apt-get remove -y {package}"
    CENTOS_COMMANDS["remove"]="dnf remove -y {package}"
    COMMAND_DESCRIPTIONS["remove"]="Remove a package"

    UBUNTU_COMMANDS["update"]="apt-get update && apt-get upgrade -y"
    CENTOS_COMMANDS["update"]="dnf update -y"
    COMMAND_DESCRIPTIONS["update"]="Update all packages"

    UBUNTU_COMMANDS["search"]="apt-cache search {package}"
    CENTOS_COMMANDS["search"]="dnf search {package}"
    COMMAND_DESCRIPTIONS["search"]="Search for package"

    # Service management
    UBUNTU_COMMANDS["service_start"]="systemctl start {service}"
    CENTOS_COMMANDS["service_start"]="systemctl start {service}"
    COMMAND_DESCRIPTIONS["service_start"]="Start a service"

    UBUNTU_COMMANDS["service_stop"]="systemctl stop {service}"
    CENTOS_COMMANDS["service_stop"]="systemctl stop {service}"
    COMMAND_DESCRIPTIONS["service_stop"]="Stop a service"

    UBUNTU_COMMANDS["service_enable"]="systemctl enable {service}"
    CENTOS_COMMANDS["service_enable"]="systemctl enable {service}"
    COMMAND_DESCRIPTIONS["service_enable"]="Enable service at boot"

    UBUNTU_COMMANDS["service_status"]="systemctl status {service}"
    CENTOS_COMMANDS["service_status"]="systemctl status {service}"
    COMMAND_DESCRIPTIONS["service_status"]="Check service status"

    # Firewall
    UBUNTU_COMMANDS["firewall_allow"]="ufw allow {port}/{proto}"
    CENTOS_COMMANDS["firewall_allow"]="firewall-cmd --add-port={port}/{proto} --permanent && firewall-cmd --reload"
    COMMAND_DESCRIPTIONS["firewall_allow"]="Open firewall port"

    UBUNTU_COMMANDS["firewall_status"]="ufw status"
    CENTOS_COMMANDS["firewall_status"]="firewall-cmd --list-all"
    COMMAND_DESCRIPTIONS["firewall_status"]="Check firewall status"

    # User management
    UBUNTU_COMMANDS["add_user"]="adduser --disabled-password --gecos '' {username}"
    CENTOS_COMMANDS["add_user"]="adduser {username}"
    COMMAND_DESCRIPTIONS["add_user"]="Add system user"

    UBUNTU_COMMANDS["add_to_sudo"]="usermod -aG sudo {username}"
    CENTOS_COMMANDS["add_to_sudo"]="usermod -aG wheel {username}"
    COMMAND_DESCRIPTIONS["add_to_sudo"]="Add user to sudoers"
}

# Initialize package name mappings
init_package_map() {
    # apache
    PACKAGE_UBUNTU_MAP["apache"]="apache2"
    PACKAGE_CENTOS_MAP["apache"]="httpd"
    
    # mysql
    PACKAGE_UBUNTU_MAP["mysql"]="mysql-server"
    PACKAGE_CENTOS_MAP["mysql"]="mysql-server"
    
    # php
    PACKAGE_UBUNTU_MAP["php"]="php"
    PACKAGE_CENTOS_MAP["php"]="php"
    
    # nodejs
    PACKAGE_UBUNTU_MAP["nodejs"]="nodejs"
    PACKAGE_CENTOS_MAP["nodejs"]="nodejs"
    
    # nginx
    PACKAGE_UBUNTU_MAP["nginx"]="nginx"
    PACKAGE_CENTOS_MAP["nginx"]="nginx"
}

# Get OS-specific command
get_command() {
    local os_type="$1"
    local action="$2"
    shift 2
    local args=("$@")

    local cmd_template
    if [[ "$os_type" == "ubuntu" ]]; then
        if [[ -n "${UBUNTU_COMMANDS[$action]:-}" ]]; then
            cmd_template="${UBUNTU_COMMANDS[$action]}"
        else
            echo "Error: Unknown action '$action' for Ubuntu" >&2
            exit 1
        fi
    elif [[ "$os_type" == "centos" ]]; then
        if [[ -n "${CENTOS_COMMANDS[$action]:-}" ]]; then
            cmd_template="${CENTOS_COMMANDS[$action]}"
        else
            echo "Error: Unknown action '$action' for CentOS" >&2
            exit 1
        fi
    else
        echo "Error: Unsupported OS: $os_type" >&2
        exit 1
    fi

    # Process arguments and format command
    local formatted_cmd="$cmd_template"
    local i
    for ((i=0; i<${#args[@]}; i+=2)); do
        local key="${args[i]}"
        local value="${args[i+1]}"
        formatted_cmd="${formatted_cmd//\{$key\}/$value}"
    done

    echo "$formatted_cmd"
}

# Get correct package name for OS
get_package_name() {
    local os_type="$1"
    local software="$2"

    case "$os_type" in
        ubuntu)
            if [[ -n "${PACKAGE_UBUNTU_MAP[$software]:-}" ]]; then
                echo "${PACKAGE_UBUNTU_MAP[$software]}"
            else
                echo "$software"
            fi
            ;;
        centos)
            if [[ -n "${PACKAGE_CENTOS_MAP[$software]:-}" ]]; then
                echo "${PACKAGE_CENTOS_MAP[$software]}"
            else
                echo "$software"
            fi
            ;;
        *)
            echo "$software"
            ;;
    esac
}

# Auto-detect OS type
detect_os() {
    if [[ -f /etc/os-release ]]; then
        local content
        content=$(cat /etc/os-release | tr '[:upper:]' '[:lower:]')
        if [[ "$content" == *"ubuntu"* ]] || [[ "$content" == *"debian"* ]]; then
            echo "ubuntu"
        elif [[ "$content" == *"centos"* ]] || [[ "$content" == *"rhel"* ]] || [[ "$content" == *"fedora"* ]]; then
            echo "centos"
        fi
    fi
}

# Generate a shell script for multiple actions
generate_script() {
    local os_type="$1"
    shift
    local actions=("$@")

    cat <<EOF
#!/bin/bash
set -e

EOF

    local i
    for ((i=0; i<${#actions[@]}; i+=6)); do
        local action="${actions[i]}"
        local desc="${COMMAND_DESCRIPTIONS[$action]:-}"
        echo "# $desc"
        
        local args=()
        local j
        for ((j=i+1; j<i+6 && j<${#actions[@]}; j++)); do
            if [[ -n "${actions[j]}" ]]; then
                args+=("${actions[j]}")
            fi
        done
        
        local cmd
        cmd=$(get_command "$os_type" "$action" "${args[@]}")
        echo "$cmd"
        echo ""
    done
}

# Main function
main() {
    local os_type=""
    local action=""
    local package=""
    local service=""
    local port=""
    local proto="tcp"
    local username=""
    local generate=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --os)
                os_type="$2"
                shift 2
                ;;
            --action)
                action="$2"
                shift 2
                ;;
            --package)
                package="$2"
                shift 2
                ;;
            --service)
                service="$2"
                shift 2
                ;;
            --port)
                port="$2"
                shift 2
                ;;
            --proto)
                proto="$2"
                shift 2
                ;;
            --username)
                username="$2"
                shift 2
                ;;
            --generate)
                generate=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 --os [ubuntu|centos] --action ACTION [--package NAME] [--service NAME] [--port PORT] [--proto tcp|udp] [--username NAME] [--generate]"
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$os_type" ]] || [[ -z "$action" ]]; then
        echo "Error: --os and --action are required" >&2
        exit 1
    fi

    # Initialize mappings
    init_commands
    init_package_map

    # Build arguments array
    local args=()
    if [[ -n "$package" ]]; then
        local real_package
        real_package=$(get_package_name "$os_type" "$package")
        args+=("package" "$real_package")
    fi
    if [[ -n "$service" ]]; then
        args+=("service" "$service")
    fi
    if [[ -n "$port" ]]; then
        args+=("port" "$port" "proto" "$proto")
    fi
    if [[ -n "$username" ]]; then
        args+=("username" "$username")
    fi

    # Get command
    local cmd
    cmd=$(get_command "$os_type" "$action" "${args[@]}")

    if [[ "$generate" == true ]]; then
        echo "$cmd"
    else
        echo "Executing: $cmd"
        # eval "$cmd"  # Uncomment to actually execute
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
