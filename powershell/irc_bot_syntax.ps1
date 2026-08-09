#!/usr/bin/env pwsh
# irc_bot_syntax.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
Fetches syntax from documentation sources.
#>

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
    Sources:
    - pbot: https://github.com/pragma-/pbot
    - Limnoria: https://docs.limnoria.net/
    - Eggdrop: https://docs.eggheads.org/
    #>

    static [hashtable]$PBOT_COMMANDS = @{
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

    static [hashtable]$LIMNORIA_COMMANDS = @{
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

    static [hashtable]$EGGDROP_COMMANDS = @{
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

    static [hashtable]$ALL_COMMANDS = @{
        "pbot" = [IRCBotSyntax]::PBOT_COMMANDS
        "limnoria" = [IRCBotSyntax]::LIMNORIA_COMMANDS
        "eggdrop" = [IRCBotSyntax]::EGGDROP_COMMANDS
    }

    static [BotCommand] GetCommand([string]$bot, [string]$command) {
        <#
        .SYNOPSIS
        Get command syntax for a specific bot.
        #>
        $bot = $bot.ToLower()
        $command = $command.ToLower()
        
        $botCommands = [IRCBotSyntax]::ALL_COMMANDS[$bot]
        if ($botCommands -and $botCommands.ContainsKey($command)) {
            return $botCommands[$command]
        }
        return $null
    }

    static [hashtable] ListCommands([string]$bot) {
        <#
        .SYNOPSIS
        List available commands for a bot or all bots.
        #>
        if ($bot) {
            $bot = $bot.ToLower()
            if ([IRCBotSyntax]::ALL_COMMANDS.ContainsKey($bot)) {
                return @{$bot = [IRCBotSyntax]::ALL_COMMANDS[$bot].Keys}
            }
            return @{$bot = @()}
        }
        
        $result = @{}
        foreach ($key in [IRCBotSyntax]::ALL_COMMANDS.Keys) {
            $result[$key] = [IRCBotSyntax]::ALL_COMMANDS[$key].Keys
        }
        return $result
    }

    static [string] GenerateScriptTemplate([string]$bot, [string]$purpose) {
        <#
        .SYNOPSIS
        Generate a script template for a bot.
        #>
        $templates = @{
            "pbot" = @"
# pbot applet - $purpose
# Place in ~/.pbot/applets/

use strict;
use warnings;

sub $($purpose -replace ' ', '_') {
    my (`$self, `$from, `$to, `$args) = @_;
    
    # Your code here
    return "Result: `$args";
}

1;

"@
            "limnoria" = @"
# Limnoria plugin - $purpose
# Place in plugins/$($purpose -replace ' ', '')/

from supybot import utils, plugins, ircutils, callbacks
from supybot.commands import *

class $(($purpose -replace ' ', '').Substring(0, 1).ToUpper() + ($purpose -replace ' ', '').Substring(1))`(callbacks.Plugin):
    """$purpose"""
    
    threaded = True
    
    def $(($purpose -replace ' ', '_'))`(self, irc, msg, args):
        """<args>"""
        irc.reply("Hello from $purpose!")
    
Class = $(($purpose -replace ' ', '').Substring(0, 1).ToUpper() + ($purpose -replace ' ', '').Substring(1))

"@
            "eggdrop" = @"
# Eggdrop Tcl script - $purpose
# Add to eggdrop.conf: source scripts/$($purpose -replace ' ', '_').tcl

proc $(($purpose -replace ' ', '_')) {nick uhost hand chan arg} {
    putserv "PRIVMSG `$chan :Hello `$nick, this is $purpose!"
}

bind pub - !$($purpose -replace ' ', '_') $(($purpose -replace ' ', '_'))

"@
        }
        
        $bot = $bot.ToLower()
        if ($templates.ContainsKey($bot)) {
            return $templates[$bot]
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
    
    $syntax = [IRCBotSyntax]::new()
    
    if ($List) {
        $commands = [IRCBotSyntax]::ListCommands($Bot)
        $commands | ConvertTo-Json -Depth 3
    }
    elseif ($Command) {
        $cmd = [IRCBotSyntax]::GetCommand($Bot, $Command)
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
            $cmds = [IRCBotSyntax]::ListCommands($Bot)
            $cmds | ConvertTo-Json -Depth 3
        }
    }
    elseif ($Template) {
        $template = [IRCBotSyntax]::GenerateScriptTemplate($Bot, $Template)
        Write-Output $template
    }
}

# Parse command line arguments
$bot = $null
$command = $null
$list = $false
$template = $null

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "--bot" {
            $i++
            $bot = $args[$i]
        }
        "--command" {
            $i++
            $command = $args[$i]
        }
        "--list" {
            $list = $true
        }
        "--template" {
            $i++
            $template = $args[$i]
        }
    }
}

# Validate required arguments
if (-not $bot) {
    Write-Error "Error: --bot is required"
    Write-Output "Usage: $($MyInvocation.MyCommand.Name) --bot <pbot|limnoria|eggdrop> [--command <command>] [--list] [--template <purpose>]"
    exit 1
}

# Call main function with parsed arguments
Main -Bot $bot -Command $command -List:$list -Template $template
