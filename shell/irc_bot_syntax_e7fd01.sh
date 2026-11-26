#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "3237c711c2a90c96b920b345b185900e0180e576eeebc397d6ac18cebdb5203e", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "shell"}
# irc_bot_syntax.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
# Fetches syntax from documentation sources.

# Declare associative arrays for bot commands
declare -A PBOT_COMMANDS LIMNORIA_COMMANDS EGGDROP_COMMANDS ALL_COMMANDS

# Initialize pbot commands
PBOT_COMMANDS["keyword add"]="pbot|keyword add|keyword add <keyword> <text>|keyword add hello Hello, World!|Add a keyword trigger|admin"
PBOT_COMMANDS["fact add"]="pbot|fact add|fact add <channel> <subject> <text>|fact add #channel python Python is a programming language|Add a factoid|whitelisted"
PBOT_COMMANDS["ban"]="pbot|ban|ban <nick|mask> [duration] [reason]|ban spambot 1h Spamming|Ban a user|op"

# Initialize limnoria commands
LIMNORIA_COMMANDS["config channel"]="limnoria|config channel|config channel <#channel> <plugin>.<variable> <value>|config channel #bot supybot.plugins.Channel.enabled True|Configure channel-specific settings|admin"
LIMNORIA_COMMANDS["load"]="limnoria|load|load <plugin>|load User|Load a plugin|owner"
LIMNORIA_COMMANDS["aka add"]="limnoria|aka add|aka add <name> <command>|aka add hi say Hello \$nick!|Create command alias|admin"

# Initialize eggdrop commands
EGGDROP_COMMANDS["bind"]="eggdrop|bind|bind <type> <flags> <keyword> <proc>|bind pub - !hello pub_hello|Bind a command to a Tcl procedure|n/a (script)"
EGGDROP_COMMANDS["putserv"]="eggdrop|putserv|putserv <text>|putserv PRIVMSG #channel :Hello World|Send raw IRC command|n/a (script)"
EGGDROP_COMMANDS["setudef"]="eggdrop|setudef|setudef <type> <name>|setudef str bot_setting|Define user-defined variable|n/a (script)"

# Function to get command syntax for a specific bot
get_command() {
    local bot="$1"
    local command="$2"
    local cmd_key=""
    local found=false
    
    case "${bot,,}" in
        "pbot")
            if [[ -n "${PBOT_COMMANDS[$command]+isset}" ]]; then
                echo "${PBOT_COMMANDS[$command]}"
                found=true
            fi
            ;;
        "limnoria")
            if [[ -n "${LIMNORIA_COMMANDS[$command]+isset}" ]]; then
                echo "${LIMNORIA_COMMANDS[$command]}"
                found=true
            fi
            ;;
        "eggdrop")
            if [[ -n "${EGGDROP_COMMANDS[$command]+isset}" ]]; then
                echo "${EGGDROP_COMMANDS[$command]}"
                found=true
            fi
            ;;
    esac
    
    if ! $found; then
        return 1
    fi
}

# Function to list available commands for a bot or all bots
list_commands() {
    local bot="${1:-}"
    
    if [[ -n "$bot" ]]; then
        case "${bot,,}" in
            "pbot")
                printf '{\n  "pbot": [\n'
                local first=true
                for key in "${!PBOT_COMMANDS[@]}"; do
                    if $first; then
                        printf '    "%s"' "$key"
                        first=false
                    else
                        printf ',\n    "%s"' "$key"
                    fi
                done
                printf '\n  ]\n}\n'
                ;;
            "limnoria")
                printf '{\n  "limnoria": [\n'
                local first=true
                for key in "${!LIMNORIA_COMMANDS[@]}"; do
                    if $first; then
                        printf '    "%s"' "$key"
                        first=false
                    else
                        printf ',\n    "%s"' "$key"
                    fi
                done
                printf '\n  ]\n}\n'
                ;;
            "eggdrop")
                printf '{\n  "eggdrop": [\n'
                local first=true
                for key in "${!EGGDROP_COMMANDS[@]}"; do
                    if $first; then
                        printf '    "%s"' "$key"
                        first=false
                    else
                        printf ',\n    "%s"' "$key"
                    fi
                done
                printf '\n  ]\n}\n'
                ;;
        esac
    else
        printf '{\n  "pbot": [\n'
        local first=true
        for key in "${!PBOT_COMMANDS[@]}"; do
            if $first; then
                printf '    "%s"' "$key"
                first=false
            else
                printf ',\n    "%s"' "$key"
            fi
        done
        printf '\n  ],\n  "limnoria": [\n'
        first=true
        for key in "${!LIMNORIA_COMMANDS[@]}"; do
            if $first; then
                printf '    "%s"' "$key"
                first=false
            else
                printf ',\n    "%s"' "$key"
            fi
        done
        printf '\n  ],\n  "eggdrop": [\n'
        first=true
        for key in "${!EGGDROP_COMMANDS[@]}"; do
            if $first; then
                printf '    "%s"' "$key"
                first=false
            else
                printf ',\n    "%s"' "$key"
            fi
        done
        printf '\n  ]\n}\n'
    fi
}

# Function to generate a script template for a bot
generate_script_template() {
    local bot="$1"
    local purpose="$2"
    
    case "${bot,,}" in
        "pbot")
            cat <<EOF
# pbot applet - ${purpose}
# Place in ~/.pbot/applets/

use strict;
use warnings;

sub ${purpose// /_} {
    my (\$self, \$from, \$to, \$args) = \@_;
    
    # Your code here
    return "Result: \$args";
}

1;
EOF
            ;;
        "limnoria")
            cat <<EOF
# Limnoria plugin - ${purpose}
# Place in plugins/${purpose// /}/

from supybot import utils, plugins, ircutils, callbacks
from supybot.commands import *

class ${purpose// /}(callbacks.Plugin):
    """${purpose}"""
    
    threaded = True
    
    def ${purpose// /_}(self, irc, msg, args):
        """<args>"""
        irc.reply("Hello from ${purpose}!")
    
Class = ${purpose// /}
EOF
            ;;
        "eggdrop")
            cat <<EOF
# Eggdrop Tcl script - ${purpose}
# Add to eggdrop.conf: source scripts/${purpose// /_}.tcl

proc ${purpose// /_} {nick uhost hand chan arg} {
    putserv "PRIVMSG \$chan :Hello \$nick, this is ${purpose}!"
}

bind pub - !${purpose// /_} ${purpose// /_}
EOF
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
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$bot" ]]; then
        echo "Error: --bot is required" >&2
        exit 1
    fi
    
    if $list; then
        list_commands "$bot"
    elif [[ -n "$command" ]]; then
        if result=$(get_command "$bot" "$command"); then
            IFS='|' read -r cmd_bot cmd_name cmd_syntax cmd_example cmd_description cmd_permission <<<"$result"
            echo "Bot: $cmd_bot"
            echo "Command: $cmd_name"
            echo "Syntax: $cmd_syntax"
            echo "Example: $cmd_example"
            echo "Description: $cmd_description"
            if [[ -n "$cmd_permission" ]]; then
                echo "Permission: $cmd_permission"
            fi
        else
            echo "Command not found: $command"
            echo "Available commands:"
            list_commands "$bot"
        fi
    elif [[ -n "$template" ]]; then
        generate_script_template "$bot" "$template"
    fi
}

# Run main function with all arguments
main "$@"
