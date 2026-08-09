#!/usr/bin/env bash
# irc_bot_syntax.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
# Fetches syntax from documentation sources.

# Function to display command syntax
show_command() {
    local bot="$1"
    local command="$2"
    
    case "${bot,,}" in
        pbot)
            case "${command,,}" in
                "keyword add")
                    echo "Bot: pbot"
                    echo "Command: keyword add"
                    echo "Syntax: keyword add <keyword> <text>"
                    echo "Example: keyword add hello Hello, World!"
                    echo "Description: Add a keyword trigger"
                    echo "Permission: admin"
                    ;;
                "fact add")
                    echo "Bot: pbot"
                    echo "Command: fact add"
                    echo "Syntax: fact add <channel> <subject> <text>"
                    echo "Example: fact add #channel python Python is a programming language"
                    echo "Description: Add a factoid"
                    echo "Permission:  whitelisted"
                    ;;
                "ban")
                    echo "Bot: pbot"
                    echo "Command: ban"
                    echo "Syntax: ban <nick|mask> [duration] [reason]"
                    echo "Example: ban spambot 1h Spamming"
                    echo "Description: Ban a user"
                    echo "Permission: op"
                    ;;
                *)
                    echo "Command not found: $command"
                    echo "Available commands:"
                    list_commands "$bot"
                    return 1
                    ;;
            esac
            ;;
        limnoria)
            case "${command,,}" in
                "config channel")
                    echo "Bot: limnoria"
                    echo "Command: config channel"
                    echo "Syntax: config channel <#channel> <plugin>.<variable> <value>"
                    echo "Example: config channel #bot supybot.plugins.Channel.enabled True"
                    echo "Description: Configure channel-specific settings"
                    echo "Permission: admin"
                    ;;
                "load")
                    echo "Bot: limnoria"
                    echo "Command: load"
                    echo "Syntax: load <plugin>"
                    echo "Example: load User"
                    echo "Description: Load a plugin"
                    echo "Permission: owner"
                    ;;
                "aka add")
                    echo "Bot: limnoria"
                    echo "Command: aka add"
                    echo "Syntax: aka add <name> <command>"
                    echo "Example: aka add hi say Hello \$nick!"
                    echo "Description: Create command alias"
                    echo "Permission: admin"
                    ;;
                *)
                    echo "Command not found: $command"
                    echo "Available commands:"
                    list_commands "$bot"
                    return 1
                    ;;
            esac
            ;;
        eggdrop)
            case "${command,,}" in
                "bind")
                    echo "Bot: eggdrop"
                    echo "Command: bind"
                    echo "Syntax: bind <type> <flags> <keyword> <proc>"
                    echo "Example: bind pub - !hello pub_hello"
                    echo "Description: Bind a command to a Tcl procedure"
                    echo "Permission: n/a (script)"
                    ;;
                "putserv")
                    echo "Bot: eggdrop"
                    echo "Command: putserv"
                    echo "Syntax: putserv <text>"
                    echo "Example: putserv PRIVMSG #channel :Hello World"
                    echo "Description: Send raw IRC command"
                    echo "Permission: n/a (script)"
                    ;;
                "setudef")
                    echo "Bot: eggdrop"
                    echo "Command: setudef"
                    echo "Syntax: setudef <type> <name>"
                    echo "Example: setudef str bot_setting"
                    echo "Description: Define user-defined variable"
                    echo "Permission: n/a (script)"
                    ;;
                *)
                    echo "Command not found: $command"
                    echo "Available commands:"
                    list_commands "$bot"
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Unknown bot: $bot"
            return 1
            ;;
    esac
}

# Function to list commands
list_commands() {
    local bot="${1:-}"
    
    if [[ -n "$bot" ]]; then
        case "${bot,,}" in
            pbot)
                echo '{"pbot": ["keyword add", "fact add", "ban"]}'
                ;;
            limnoria)
                echo '{"limnoria": ["config channel", "load", "aka add"]}'
                ;;
            eggdrop)
                echo '{"eggdrop": ["bind", "putserv", "setudef"]}'
                ;;
            *)
                echo "{}"
                ;;
        esac
    else
        echo '{
  "pbot": [
    "keyword add",
    "fact add",
    "ban"
  ],
  "limnoria": [
    "config channel",
    "load",
    "aka add"
  ],
  "eggdrop": [
    "bind",
    "putserv",
    "setudef"
  ]
}'
    fi
}

# Function to generate script template
generate_template() {
    local bot="$1"
    local purpose="$2"
    local safe_purpose="${purpose// /_}"
    
    case "${bot,,}" in
        pbot)
            echo "# pbot applet - $purpose"
            echo "# Place in ~/.pbot/applets/"
            echo ""
            echo "use strict;"
            echo "use warnings;"
            echo ""
            echo "sub ${safe_purpose} {"
            echo "    my (\$self, \$from, \$to, \$args) = @_;"
            echo "    "
            echo "    # Your code here"
            echo "    return \"Result: \$args\";"
            echo "}"
            echo ""
            echo "1;"
            ;;
        limnoria)
            local class_name="${purpose// /}"
            class_name="$(tr '[:lower:]' '[:upper:]' <<< "${class_name:0:1}")${class_name:1}"
            echo "# Limnoria plugin - $purpose"
            echo "# Place in plugins/${class_name}/"
            echo ""
            echo "from supybot import utils, plugins, ircutils, callbacks"
            echo "from supybot.commands import *"
            echo ""
            echo "class ${class_name}(callbacks.Plugin):"
            echo "    \"\"\"$purpose\"\"\""
            echo "    "
            echo "    threaded = True"
            echo "    "
            echo "    def ${safe_purpose}(self, irc, msg, args):"
            echo "        \"\"\"<args>\"\"\""
            echo "        irc.reply(\"Hello from $purpose!\")"
            echo "    "
            echo "Class = ${class_name}"
            ;;
        eggdrop)
            echo "# Eggdrop Tcl script - $purpose"
            echo "# Add to eggdrop.conf: source scripts/${safe_purpose}.tcl"
            echo ""
            echo "proc ${safe_purpose} {nick uhost hand chan arg} {"
            echo "    putserv \"PRIVMSG \$chan :Hello \$nick, this is $purpose!\""
            echo "}"
            echo ""
            echo "bind pub - !${safe_purpose} ${safe_purpose}"
            ;;
        *)
            echo "# Unknown bot"
            ;;
    esac
}

# Main function
main() {
    local bot=""
    local command=""
    local list=false
    local template=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --bot)
                bot="$2"
                shift 2
                ;;
            --command)
                command="$2"
                shift 2
                ;;
            --list)
                list=true
                shift
                ;;
            --template)
                template="$2"
                shift 2
                ;;
            -h|--help)
                echo "IRC Bot command syntax reference"
                echo "Usage: $0 --bot <bot> [--command <command>|--list|--template <purpose>]"
                echo "Bots: pbot, limnoria, eggdrop"
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    
    # Validate bot is provided
    if [[ -z "$bot" ]]; then
        echo "Error: --bot is required"
        return 1
    fi
    
    # Execute based on options
    if [[ "$list" == true ]]; then
        list_commands "$bot"
    elif [[ -n "$command" ]]; then
        show_command "$bot" "$command"
    elif [[ -n "$template" ]]; then
        generate_template "$bot" "$template"
    else
        echo "Error: must specify --command, --list, or --template"
        return 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
