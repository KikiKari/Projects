#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "e1c576087bf9612a57fea066eda96f12ad275d22cbd67c642b919004e8c57783", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "powershell"}
# irc_bot_syntax.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
.DESCRIPTION
Fetches syntax from documentation sources.
#>

using namespace System.Collections.Generic
using namespace System.Management.Automation

class BotCommand {
    [string]$Bot
    [string]$Command
    [string]$Syntax
    [string]$Example
    [string]$Description
    [string]$Permission

    BotCommand([string]$bot, [string]$command, [string]$syntax, [string]$example, [string]$description, [string]$permission) {
        $this.Bot = $bot
        $this.Command = $command
        $this.Syntax = $syntax
        $this.Example = $example
        $this.Description = $description
        $this.Permission = $permission
    }
}

class IRCBotSyntax {
    <#
    .SYNOPSIS
    IRC Bot command syntax reference.
    .DESCRIPTION
    Sources:
    - pbot: https://github.com/pragma-/pbot
    - Limnoria: https://docs.limnoria.net/
    - Eggdrop: https://docs.eggheads.org/
    #>

    static [hashtable]$PBotCommands = @{
        "keyword add" = [BotCommand]::new(
            "pbot",
            "keyword add",
            "keyword add <keyword> <text>",
            "keyword add hello Hello, World!",
            "Add a keyword trigger",
            "admin"
        )
        "fact add" = [BotCommand]::new(
            "pbot",
            "fact add",
            "fact add <channel> <subject> <text>",
            "fact add #channel python Python is a programming language",
            "Add a factoid",
            " whitelisted"
        )
        "ban" = [BotCommand]::new(
            "pbot",
            "ban",
            "ban <nick|mask> [duration] [reason]",
            "ban spambot 1h Spamming",
            "Ban a user",
            "op"
        )
    }

    static [hashtable]$LimnoriaCommands = @{
        "config channel" = [BotCommand]::new(
            "limnoria",
            "config channel",
            "config channel <#channel> <plugin>.<variable> <value>",
            "config channel #bot supybot.plugins.Channel.enabled True",
            "Configure channel-specific settings",
            "admin"
        )
        "load" = [BotCommand]::new(
            "limnoria",
            "load",
            "load <plugin>",
            "load User",
            "Load a plugin",
            "owner"
        )
        "aka add" = [BotCommand]::new(
            "limnoria",
            "aka add",
            "aka add <name> <command>",
            "aka add hi say Hello `$nick!",
            "Create command alias",
            "admin"
        )
    }

    static [hashtable]$EggdropCommands = @{
        "bind" = [BotCommand]::new(
            "eggdrop",
            "bind",
            "bind <type> <flags> <keyword> <proc>",
            "bind pub - !hello pub_hello",
            "Bind a command to a Tcl procedure",
            "n/a (script)"
        )
        "putserv" = [BotCommand]::new(
            "eggdrop",
            "putserv",
            "putserv <text>",
            "putserv PRIVMSG #channel :Hello World",
            "Send raw IRC command",
            "n/a (script)"
        )
        "setudef" = [BotCommand]::new(
            "eggdrop",
            "setudef",
            "setudef <type> <name>",
            "setudef str bot_setting",
            "Define user-defined variable",
            "n/a (script)"
        )
    }

    static [hashtable]$AllCommands = @{
        "pbot" = [IRCBotSyntax]::PBotCommands
        "limnoria" = [IRCBotSyntax]::LimnoriaCommands
        "eggdrop" = [IRCBotSyntax]::EggdropCommands
    }

    [BotCommand] GetCommand([string]$bot, [string]$command) {
        $bot = $bot.ToLower()
        $command = $command.ToLower()
        
        $botCommands = [IRCBotSyntax]::AllCommands[$bot]
        if ($botCommands -and $botCommands.ContainsKey($command)) {
            return $botCommands[$command]
        }
        return $null
    }

    [hashtable] ListCommands([string]$bot) {
        if ($bot) {
            $bot = $bot.ToLower()
            $commands = [IRCBotSyntax]::AllCommands[$bot]
            if ($commands) {
                $keys = @()
                foreach ($key in $commands.Keys) {
                    $keys += $key
                }
                return @{$bot = $keys}
            }
            return @{$bot = @()}
        }
        
        $result = @{}
        foreach ($entry in [IRCBotSyntax]::AllCommands.GetEnumerator()) {
            $keys = @()
            foreach ($key in $entry.Value.Keys) {
                $keys += $key
            }
            $result[$entry.Key] = $keys
        }
        return $result
    }

    [string] GenerateScriptTemplate([string]$bot, [string]$purpose) {
        $templates = @{
            "pbot" = @"
# pbot applet - $purpose
# Place in ~/.pbot/applets/

use strict;
use warnings;

sub $($purpose.Replace(' ', '_')) {
    my `$(self, `$from, `$to, `$args) = @_;
    
    # Your code here
    return "Result: `$args";
}

1;
"@
            "limnoria" = @"
# Limnoria plugin - $purpose
# Place in plugins/$($purpose.Replace(' ', ''))/

from supybot import utils, plugins, ircutils, callbacks
from supybot.commands import *

class $($purpose.Replace(' ', '').Substring(0,1).ToUpper()+$purpose.Replace(' ', '').Substring(1))`(callbacks.Plugin):
    """"""$purpose""""""
    
    threaded = True
    
    def $($purpose.Replace(' ', '_'))`(self, irc, msg, args):
        """"""<args>""""""
        irc.reply("Hello from $purpose!")
    
Class = $($purpose.Replace(' ', '').Substring(0,1).ToUpper()+$purpose.Replace(' ', '').Substring(1))
"@
            "eggdrop" = @"
# Eggdrop Tcl script - $purpose
# Add to eggdrop.conf: source scripts/$($purpose.Replace(' ', '_')).tcl

proc $($purpose.Replace(' ', '_')) `{`nick uhost hand chan arg`} {
    putserv "PRIVMSG `$chan :Hello `$nick, this is $purpose!"
}

bind pub - !$($purpose.Replace(' ', '_')) $($purpose.Replace(' ', '_'))
"@
        }
        
        $botLower = $bot.ToLower()
        if ($templates.ContainsKey($botLower)) {
            return $templates[$botLower]
        }
        return "# Unknown bot"
    }
}

function Main {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("pbot", "limnoria", "eggdrop")]
        [string]$Bot,
        
        [string]$Command,
        
        [switch]$List,
        
        [string]$Template
    )
    
    $syntax = New-Object IRCBotSyntax
    
    if ($List) {
        $commands = $syntax.ListCommands($Bot)
        $commands | ConvertTo-Json -Depth 3
    }
    elseif ($Command) {
        $cmd = $syntax.GetCommand($Bot, $Command)
        if ($cmd) {
            Write-Output "Bot: $($cmd.Bot)"
            Write-Output "Command: $($cmd.Command)"
            Write-Output "Syntax: $($cmd.Syntax)"
            Write-Output "Example: $($cmd.Example)"
            Write-Output "Description: $($cmd.Description)"
            if ($cmd.Permission) {
                Write-Output "Permission: $($cmd.Permission)"
            }
        }
        else {
            Write-Output "Command not found: $Command"
            Write-Output "Available commands:"
            $cmds = $syntax.ListCommands($Bot)
            $cmds | ConvertTo-Json -Depth 3
        }
    }
    elseif ($Template) {
        $templateContent = $syntax.GenerateScriptTemplate($Bot, $Template)
        Write-Output $templateContent
    }
}

# Entry point
if ($MyInvocation.InvocationName -eq '-' -or $MyInvocation.InvocationName -eq $PSCommandPath) {
    $paramSets = @{
        Bot = $args[1]
        Command = if ($args.IndexOf('--command') -ge 0) { $args[$args.IndexOf('--command') + 1] } else { $null }
        List = $args -contains '--list'
        Template = if ($args.IndexOf('--template') -ge 0) { $args[$args.IndexOf('--template') + 1] } else { $null }
    }
    
    # Validate required parameters
    if (-not $paramSets.Bot) {
        Write-Error "Missing required parameter --bot"
        exit 1
    }
    
    Main @paramSets
}
