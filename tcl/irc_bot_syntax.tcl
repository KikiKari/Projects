#!/usr/bin/env tclsh8.6
# irc_bot_syntax.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
# Fetches syntax from documentation sources.

# BotCommand class equivalent
proc create_bot_command {bot command syntax example description {permission ""}} {
    return [list \
        bot $bot \
        command $command \
        syntax $syntax \
        example $example \
        description $description \
        permission $permission]
}

# IRCBotSyntax class equivalent
namespace eval IRCBotSyntax {
    # PBOT_COMMANDS
    variable PBOT_COMMANDS
    array set PBOT_COMMANDS {
        "keyword add" {bot pbot command "keyword add" syntax "keyword add <keyword> <text>" example "keyword add hello Hello, World!" description "Add a keyword trigger" permission admin}
        "fact add" {bot pbot command "fact add" syntax "fact add <channel> <subject> <text>" example "fact add #channel python Python is a programming language" description "Add a factoid" permission " whitelisted"}
        "ban" {bot pbot command ban syntax "ban <nick|mask> [duration] [reason]" example "ban spambot 1h Spamming" description "Ban a user" permission op}
    }
    
    # LIMNORIA_COMMANDS
    variable LIMNORIA_COMMANDS
    array set LIMNORIA_COMMANDS {
        "config channel" {bot limnoria command "config channel" syntax "config channel <#channel> <plugin>.<variable> <value>" example "config channel #bot supybot.plugins.Channel.enabled True" description "Configure channel-specific settings" permission admin}
        "load" {bot limnoria command load syntax "load <plugin>" example "load User" description "Load a plugin" permission owner}
        "aka add" {bot limnoria command "aka add" syntax "aka add <name> <command>" example "aka add hi say Hello \$nick!" description "Create command alias" permission admin}
    }
    
    # EGGDROP_COMMANDS
    variable EGGDROP_COMMANDS
    array set EGGDROP_COMMANDS {
        "bind" {bot eggdrop command bind syntax "bind <type> <flags> <keyword> <proc>" example "bind pub - !hello pub_hello" description "Bind a command to a Tcl procedure" permission "n/a (script)"}
        "putserv" {bot eggdrop command putserv syntax "putserv <text>" example "putserv PRIVMSG #channel :Hello World" description "Send raw IRC command" permission "n/a (script)"}
        "setudef" {bot eggdrop command setudef syntax "setudef <type> <name>" example "setudef str bot_setting" description "Define user-defined variable" permission "n/a (script)"}
    }
    
    # ALL_COMMANDS
    variable ALL_COMMANDS
    array set ALL_COMMANDS {
        pbot PBOT_COMMANDS
        limnoria LIMNORIA_COMMANDS
        eggdrop EGGDROP_COMMANDS
    }
    
    # Get command syntax for a specific bot
    proc get_command {bot command} {
        variable ALL_COMMANDS
        set bot [string tolower $bot]
        set command [string tolower $command]
        
        if {[info exists ALL_COMMANDS($bot)]} {
            set bot_array_name $ALL_COMMANDS($bot)
            variable $bot_array_name
            upvar 0 $bot_array_name bot_array
            if {[info exists bot_array($command)]} {
                return $bot_array($command)
            }
        }
        return ""
    }
    
    # List available commands for a bot or all bots
    proc list_commands {{bot ""}} {
        variable ALL_COMMANDS
        variable PBOT_COMMANDS
        variable LIMNORIA_COMMANDS
        variable EGGDROP_COMMANDS
        
        if {$bot ne ""} {
            set bot [string tolower $bot]
            if {[info exists ALL_COMMANDS($bot)]} {
                set bot_array_name $ALL_COMMANDS($bot)
                variable $bot_array_name
                upvar 0 $bot_array_name bot_array
                set result {}
                foreach key [array names bot_array] {
                    lappend result $key
                }
                return [list $bot $result]
            }
            return [list $bot {}]
        } else {
            set result {}
            foreach {bot_name bot_array_name} [array get ALL_COMMANDS] {
                variable $bot_array_name
                upvar 0 $bot_array_name bot_array
                set commands {}
                foreach key [array names bot_array] {
                    lappend commands $key
                }
                lappend result [list $bot_name $commands]
            }
            return $result
        }
    }
    
    # Generate a script template for a bot
    proc generate_script_template {bot purpose} {
        set bot [string tolower $bot]
        set purpose_underscore [string map {" " "_"} $purpose]
        set purpose_title [string totitle [string map {" " ""} $purpose]]
        
        switch $bot {
            pbot {
                return "# pbot applet - $purpose\n# Place in ~/.pbot/applets/\n\nuse strict;\nuse warnings;\n\nsub [string map {" " "_"} $purpose] {\n    my (\$self, \$from, \$to, \$args) = \@_;\n    \n    # Your code here\n    return \"Result: \$args\";\n}\n\n1;\n"
            }
            limnoria {
                return "# Limnoria plugin - $purpose\n# Place in plugins/${purpose_title}/\n\nfrom supybot import utils, plugins, ircutils, callbacks\nfrom supybot.commands import *\n\nclass ${purpose_title}(callbacks.Plugin):\n    \"\"\"$purpose\"\"\"\n    \n    threaded = True\n    \n    def [string map {" " "_"} $purpose](self, irc, msg, args):\n        \"\"\"<args>\"\"\"\n        irc.reply(\"Hello from $purpose!\")\n    \nClass = ${purpose_title}\n"
            }
            eggdrop {
                return "# Eggdrop Tcl script - $purpose\n# Add to eggdrop.conf: source scripts/${purpose_underscore}.tcl\n\nproc ${purpose_underscore} {nick uhost hand chan arg} {\n    putserv \"PRIVMSG \$chan :Hello \$nick, this is $purpose!\"\n}\n\nbind pub - !${purpose_underscore} ${purpose_underscore}\n"
            }
            default {
                return "# Unknown bot"
            }
        }
    }
}

# JSON-like output procedures
proc json_list_commands {bot} {
    set result [IRCBotSyntax::list_commands $bot]
    if {$bot eq ""} {
        set json "{\n"
        set first 1
        foreach item $result {
            if {!$first} {
                append json ",\n"
            }
            lassign $item bot_name commands
            append json "  \"$bot_name\": [json_list $commands]"
            set first 0
        }
        append json "\n}"
        return $json
    } else {
        lassign $result bot_name commands
        return "{\n  \"$bot_name\": [json_list $commands]\n}"
    }
}

proc json_list {list} {
    set json "\["
    set first 1
    foreach item $list {
        if {!$first} {
            append json ", "
        }
        append json "\"$item\""
        set first 0
    }
    append json "\]"
    return $json
}

# Main procedure
proc main {} {
    # Simple argument parsing
    set bot ""
    set command ""
    set list 0
    set template ""
    
    for {set i 0} {$i < $argc} {incr i} {
        set arg [lindex $argv $i]
        switch $arg {
            "--bot" {
                incr i
                set bot [lindex $argv $i]
            }
            "--command" {
                incr i
                set command [lindex $argv $i]
            }
            "--list" {
                set list 1
            }
            "--template" {
                incr i
                set template [lindex $argv $i]
            }
        }
    }
    
    # Validate required arguments
    if {$bot eq ""} {
        puts "usage: $argv0 --bot {pbot,limnoria,eggdrop} [--command COMMAND | --list | --template PURPOSE]"
        exit 1
    }
    
    if {$list} {
        puts [json_list_commands $bot]
    } elseif {$command ne ""} {
        set cmd [IRCBotSyntax::get_command $bot $command]
        if {$cmd ne ""} {
            puts "Bot: [dict get $cmd bot]"
            puts "Command: [dict get $cmd command]"
            puts "Syntax: [dict get $cmd syntax]"
            puts "Example: [dict get $cmd example]"
            puts "Description: [dict get $cmd description]"
            if {[dict get $cmd permission] ne ""} {
                puts "Permission: [dict get $cmd permission]"
            }
        } else {
            puts "Command not found: $command"
            puts "Available commands:"
            puts [json_list_commands $bot]
        }
    } elseif {$template ne ""} {
        puts [IRCBotSyntax::generate_script_template $bot $template]
    } else {
        puts "usage: $argv0 --bot {pbot,limnoria,eggdrop} [--command COMMAND | --list | --template PURPOSE]"
        exit 1
    }
}

# Run main if script is executed directly
if {[info script] eq $argv0} {
    main
}
