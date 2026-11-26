#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "73559311023b21542a291853c0bf8f502e185bedc155b4e92c82605870059c58", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "tcl"}
# irc_bot_syntax.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
# Fetches syntax from documentation sources.

# Tcl doesn't have built-in JSON support, so we'll implement basic JSON-like output
# using dict and list structures

# Define BotCommand as a dictionary structure
# Each command will be a dict with keys: bot, command, syntax, example, description, permission

# IRCBotSyntax class equivalent
namespace eval IRCBotSyntax {
    # PBOT_COMMANDS
    variable PBOT_COMMANDS
    dict set PBOT_COMMANDS "keyword add" [dict create \
        bot "pbot" \
        command "keyword add" \
        syntax "keyword add <keyword> <text>" \
        example "keyword add hello Hello, World!" \
        description "Add a keyword trigger" \
        permission "admin"]
    
    dict set PBOT_COMMANDS "fact add" [dict create \
        bot "pbot" \
        command "fact add" \
        syntax "fact add <channel> <subject> <text>" \
        example "fact add #channel python Python is a programming language" \
        description "Add a factoid" \
        permission " whitelisted"]
    
    dict set PBOT_COMMANDS "ban" [dict create \
        bot "pbot" \
        command "ban" \
        syntax "ban <nick|mask> [duration] [reason]" \
        example "ban spambot 1h Spamming" \
        description "Ban a user" \
        permission "op"]
    
    # LIMNORIA_COMMANDS
    variable LIMNORIA_COMMANDS
    dict set LIMNORIA_COMMANDS "config channel" [dict create \
        bot "limnoria" \
        command "config channel" \
        syntax "config channel <#channel> <plugin>.<variable> <value>" \
        example "config channel #bot supybot.plugins.Channel.enabled True" \
        description "Configure channel-specific settings" \
        permission "admin"]
    
    dict set LIMNORIA_COMMANDS "load" [dict create \
        bot "limnoria" \
        command "load" \
        syntax "load <plugin>" \
        example "load User" \
        description "Load a plugin" \
        permission "owner"]
    
    dict set LIMNORIA_COMMANDS "aka add" [dict create \
        bot "limnoria" \
        command "aka add" \
        syntax "aka add <name> <command>" \
        example "aka add hi say Hello \$nick!" \
        description "Create command alias" \
        permission "admin"]
    
    # EGGDROP_COMMANDS
    variable EGGDROP_COMMANDS
    dict set EGGDROP_COMMANDS "bind" [dict create \
        bot "eggdrop" \
        command "bind" \
        syntax "bind <type> <flags> <keyword> <proc>" \
        example "bind pub - !hello pub_hello" \
        description "Bind a command to a Tcl procedure" \
        permission "n/a (script)"]
    
    dict set EGGDROP_COMMANDS "putserv" [dict create \
        bot "eggdrop" \
        command "putserv" \
        syntax "putserv <text>" \
        example "putserv PRIVMSG #channel :Hello World" \
        description "Send raw IRC command" \
        permission "n/a (script)"]
    
    dict set EGGDROP_COMMANDS "setudef" [dict create \
        bot "eggdrop" \
        command "setudef" \
        syntax "setudef <type> <name>" \
        example "setudef str bot_setting" \
        description "Define user-defined variable" \
        permission "n/a (script)"]
    
    # ALL_COMMANDS
    variable ALL_COMMANDS
    dict set ALL_COMMANDS "pbot" $PBOT_COMMANDS
    dict set ALL_COMMANDS "limnoria" $LIMNORIA_COMMANDS
    dict set ALL_COMMANDS "eggdrop" $EGGDROP_COMMANDS
}

# Method to get command
proc IRCBotSyntax::get_command {bot command} {
    variable ALL_COMMANDS
    
    set bot [string tolower $bot]
    set command [string tolower $command]
    
    if {[dict exists $ALL_COMMANDS $bot]} {
        set bot_commands [dict get $ALL_COMMANDS $bot]
        if {[dict exists $bot_commands $command]} {
            return [dict get $bot_commands $command]
        }
    }
    return ""
}

# Method to list commands
proc IRCBotSyntax::list_commands {{bot ""}} {
    variable ALL_COMMANDS
    
    if {$bot ne ""} {
        set bot [string tolower $bot]
        if {[dict exists $ALL_COMMANDS $bot]} {
            set bot_commands [dict get $ALL_COMMANDS $bot]
            return [dict keys $bot_commands]
        } else {
            return {}
        }
    } else {
        set result {}
        dict for {bot_name bot_commands} $ALL_COMMANDS {
            lappend result $bot_name [dict keys $bot_commands]
        }
        return $result
    }
}

# Method to generate script template
proc IRCBotSyntax::generate_script_template {bot purpose} {
    set bot [string tolower $bot]
    # Replace spaces with underscores for identifiers
    set identifier [string map {" " "_"} $purpose]
    set title_cased [string totitle $purpose]
    
    switch $bot {
        "pbot" {
            return "# pbot applet - $purpose\n# Place in ~/.pbot/applets/\n\nuse strict;\nuse warnings;\n\nsub [string map {" " "_"} $purpose] {\n    my (\$self, \$from, \$to, \$args) = \@_;\n    \n    # Your code here\n    return \"Result: \$args\";\n}\n\n1;"
        }
        "limnoria" {
            set plugin_name [string map {" " ""} $purpose]
            return "# Limnoria plugin - $purpose\n# Place in plugins/$plugin_name/\n\nfrom supybot import utils, plugins, ircutils, callbacks\nfrom supybot.commands import *\n\nclass [string map {" " ""} [string totitle $purpose]](callbacks.Plugin):\n    \"\"\"$purpose\"\"\"\n    \n    threaded = True\n    \n    def [string map {" " "_"} $purpose](self, irc, msg, args):\n        \"\"\"<args>\"\"\"\n        irc.reply(\"Hello from $purpose!\")\n    \nClass = [string map {" " ""} [string totitle $purpose]]"
        }
        "eggdrop" {
            return "# Eggdrop Tcl script - $purpose\n# Add to eggdrop.conf: source scripts/[string map {" " "_"} $purpose].tcl\n\nproc [string map {" " "_"} $purpose] {nick uhost hand chan arg} {\n    putserv \"PRIVMSG \$chan :Hello \$nick, this is $purpose!\"\n}\n\nbind pub - ![string map {" " "_"} $purpose] [string map {" " "_"} $purpose]"
        }
        default {
            return "# Unknown bot"
        }
    }
}

# Simple JSON-like formatting proc for our needs
proc format_json_dict {data {indent 0}} {
    set result "{\n"
    set indent_str [string repeat " " [expr {($indent + 2) * 2}]]
    
    foreach {key value_list} $data {
        append result "${indent_str}\"$key\": \["
        set first_item 1
        foreach item $value_list {
            if {!$first_item} {
                append result ","
            }
            append result "\n${indent_str}  \"$item\""
            set first_item 0
        }
        append result "\n${indent_str}\]\n"
    }
    append result "[string repeat " " [expr {$indent * 2}]]}"
    return $result
}

# Main procedure
proc main {} {
    global argv
    
    # Simple argument parsing since Tcl doesn't have argparse
    set bot ""
    set command ""
    set list_commands false
    set template ""
    
    set i 0
    while {$i < [llength $argv]} {
        set arg [lindex $argv $i]
        incr i
        
        switch $arg {
            "--bot" {
                if {$i < [llength $argv]} {
                    set bot [lindex $argv $i]
                    incr i
                }
            }
            "--command" {
                if {$i < [llength $argv]} {
                    set command [lindex $argv $i]
                    incr i
                }
            }
            "--list" {
                set list_commands true
            }
            "--template" {
                if {$i < [llength $argv]} {
                    set template [lindex $argv $i]
                    incr i
                }
            }
        }
    }
    
    # Validate bot argument
    if {$bot eq ""} {
        puts "Error: --bot argument is required"
        puts "Usage: $argv0 --bot <pbot|limnoria|eggdrop> [--command <command>] [--list] [--template <purpose>]"
        exit 1
    }
    
    if {$list_commands} {
        set commands [IRCBotSyntax::list_commands $bot]
        set output_data [list $bot $commands]
        puts [format_json_dict $output_data]
    } elseif {$command ne ""} {
        set cmd [IRCBotSyntax::get_command $bot $command]
        if {$cmd ne ""} {
            puts "Bot: [dict get $cmd bot]"
            puts "Command: [dict get $cmd command]"
            puts "Syntax: [dict get $cmd syntax]"
            puts "Example: [dict get $cmd example]"
            puts "Description: [dict get $cmd description]"
            if {[dict exists $cmd permission] && [dict get $cmd permission] ne ""} {
                puts "Permission: [dict get $cmd permission]"
            }
        } else {
            puts "Command not found: $command"
            puts "Available commands:"
            set cmds [IRCBotSyntax::list_commands $bot]
            set output_data [list $bot $cmds]
            puts [format_json_dict $output_data]
        }
    } elseif {$template ne ""} {
        set template_result [IRCBotSyntax::generate_script_template $bot $template]
        puts $template_result
    } else {
        puts "Error: Must specify one of --command, --list, or --template"
        puts "Usage: $argv0 --bot <pbot|limnoria|eggdrop> [--command <command>] [--list] [--template <purpose>]"
        exit 1
    }
}

# Run main if script is executed directly
if {[info script] eq $argv0} {
    main
}
