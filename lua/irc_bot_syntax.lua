#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "fbb4a689f019255caec878531ead7d9bc0bc834b833412c46abe1f0a41a0cda5", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "lua"}
-- irc_bot_syntax.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
-- auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
Fetches syntax from documentation sources.
]]

local json = require("cjson")

local BotCommand = {}
BotCommand.__index = BotCommand

function BotCommand:new(bot, command, syntax, example, description, permission)
    local obj = {
        bot = bot,
        command = command,
        syntax = syntax,
        example = example,
        description = description,
        permission = permission
    }
    setmetatable(obj, BotCommand)
    return obj
end

local IRCBotSyntax = {}
IRCBotSyntax.__index = IRCBotSyntax

-- Sources:
-- - pbot: https://github.com/pragma-/pbot
-- - Limnoria: https://docs.limnoria.net/
-- - Eggdrop: https://docs.eggheads.org/

IRCBotSyntax.PBOT_COMMANDS = {
    ["keyword add"] = BotCommand:new(
        "pbot",
        "keyword add",
        "keyword add <keyword> <text>",
        "keyword add hello Hello, World!",
        "Add a keyword trigger",
        "admin"
    ),
    ["fact add"] = BotCommand:new(
        "pbot",
        "fact add",
        "fact add <channel> <subject> <text>",
        "fact add #channel python Python is a programming language",
        "Add a factoid",
        " whitelisted"
    ),
    ["ban"] = BotCommand:new(
        "pbot",
        "ban",
        "ban <nick|mask> [duration] [reason]",
        "ban spambot 1h Spamming",
        "Ban a user",
        "op"
    ),
}

IRCBotSyntax.LIMNORIA_COMMANDS = {
    ["config channel"] = BotCommand:new(
        "limnoria",
        "config channel",
        "config channel <#channel> <plugin>.<variable> <value>",
        "config channel #bot supybot.plugins.Channel.enabled True",
        "Configure channel-specific settings",
        "admin"
    ),
    ["load"] = BotCommand:new(
        "limnoria",
        "load",
        "load <plugin>",
        "load User",
        "Load a plugin",
        "owner"
    ),
    ["aka add"] = BotCommand:new(
        "limnoria",
        "aka add",
        "aka add <name> <command>",
        "aka add hi say Hello $nick!",
        "Create command alias",
        "admin"
    ),
}

IRCBotSyntax.EGGDROP_COMMANDS = {
    ["bind"] = BotCommand:new(
        "eggdrop",
        "bind",
        "bind <type> <flags> <keyword> <proc>",
        "bind pub - !hello pub_hello",
        "Bind a command to a Tcl procedure",
        "n/a (script)"
    ),
    ["putserv"] = BotCommand:new(
        "eggdrop",
        "putserv",
        "putserv <text>",
        "putserv PRIVMSG #channel :Hello World",
        "Send raw IRC command",
        "n/a (script)"
    ),
    ["setudef"] = BotCommand:new(
        "eggdrop",
        "setudef",
        "setudef <type> <name>",
        "setudef str bot_setting",
        "Define user-defined variable",
        "n/a (script)"
    ),
}

IRCBotSyntax.ALL_COMMANDS = {
    pbot = IRCBotSyntax.PBOT_COMMANDS,
    limnoria = IRCBotSyntax.LIMNORIA_COMMANDS,
    eggdrop = IRCBotSyntax.EGGDROP_COMMANDS,
}

function IRCBotSyntax:new()
    local obj = {}
    setmetatable(obj, IRCBotSyntax)
    return obj
end

function IRCBotSyntax:get_command(bot, command)
    -- Get command syntax for a specific bot.
    bot = string.lower(bot)
    command = string.lower(command)
    
    local bot_commands = self.ALL_COMMANDS[bot]
    if not bot_commands then return nil end
    return bot_commands[command]
end

function IRCBotSyntax:list_commands(bot)
    -- List available commands for a bot or all bots.
    if bot then
        local bot_lower = string.lower(bot)
        local bot_commands = self.ALL_COMMANDS[bot_lower]
        if not bot_commands then return {[bot] = {}} end
        
        local keys = {}
        for k in pairs(bot_commands) do
            table.insert(keys, k)
        end
        return {[bot] = keys}
    else
        local result = {}
        for bot_name, bot_commands in pairs(self.ALL_COMMANDS) do
            local keys = {}
            for k in pairs(bot_commands) do
                table.insert(keys, k)
            end
            result[bot_name] = keys
        end
        return result
    end
end

function IRCBotSyntax:generate_script_template(bot, purpose)
    -- Generate a script template for a bot.
    local function replace_spaces(str)
        return string.gsub(str, " ", "_")
    end
    
    local function title_case(str)
        return string.gsub(str, "%a", string.upper, 1)
    end
    
    local templates = {
        pbot = function()
            return "# pbot applet - " .. purpose .. "\n" ..
                   "# Place in ~/.pbot/applets/\n\n" ..
                   "use strict;\n" ..
                   "use warnings;\n\n" ..
                   "sub " .. replace_spaces(purpose) .. " {\n" ..
                   "    my ($self, $from, $to, $args) = @_;\n\n" ..
                   "    # Your code here\n" ..
                   "    return \"Result: $args\";\n" ..
                   "}\n\n" ..
                   "1;\n"
        end,
        limnoria = function()
            local class_name = title_case(replace_spaces(purpose))
            return "# Limnoria plugin - " .. purpose .. "\n" ..
                   "# Place in plugins/" .. replace_spaces(purpose) .. "/\n\n" ..
                   "from supybot import utils, plugins, ircutils, callbacks\n" ..
                   "from supybot.commands import *\n\n" ..
                   "class " .. class_name .. "(callbacks.Plugin):\n" ..
                   "    \"\"\"" .. purpose .. "\"\"\"\n\n" ..
                   "    threaded = True\n\n" ..
                   "    def " .. replace_spaces(purpose) .. "(self, irc, msg, args):\n" ..
                   "        \"\"\"<args>\"\"\"\n" ..
                   "        irc.reply(\"Hello from " .. purpose .. "!\")\n\n" ..
                   "Class = " .. class_name .. "\n"
        end,
        eggdrop = function()
            return "# Eggdrop Tcl script - " .. purpose .. "\n" ..
                   "# Add to eggdrop.conf: source scripts/" .. replace_spaces(purpose) .. ".tcl\n\n" ..
                   "proc " .. replace_spaces(purpose) .. " {nick uhost hand chan arg} {\n" ..
                   "    putserv \"PRIVMSG $chan :Hello $nick, this is " .. purpose .. "!\"\n" ..
                   "}\n\n" ..
                   "bind pub - !" .. replace_spaces(purpose) .. " " .. replace_spaces(purpose) .. "\n"
        end
    }
    
    local template_func = templates[string.lower(bot)]
    if template_func then
        return template_func()
    else
        return "# Unknown bot"
    end
end

local function main()
    local argparse = require("argparse")
    local parser = argparse.ArgumentParser()
    parser:description("IRC Bot command syntax reference")
    parser:option("--bot"):choices({"pbot", "limnoria", "eggdrop"}):required(true)
    parser:option("--command"):help("Command to look up")
    parser:flag("--list"):help("List all commands")
    parser:option("--template"):help("Generate script template for purpose")
    
    local args = parser:parse()
    
    local syntax = IRCBotSyntax:new()
    
    if args.list then
        local commands = syntax:list_commands(args.bot)
        print(json.encode(commands))
    elseif args.command then
        local cmd = syntax:get_command(args.bot, args.command)
        if cmd then
            print("Bot: " .. cmd.bot)
            print("Command: " .. cmd.command)
            print("Syntax: " .. cmd.syntax)
            print("Example: " .. cmd.example)
            print("Description: " .. cmd.description)
            if cmd.permission then
                print("Permission: " .. cmd.permission)
            end
        else
            print("Command not found: " .. args.command)
            print("Available commands:")
            local cmds = syntax:list_commands(args.bot)
            print(json.encode(cmds))
        end
    elseif args.template then
        local template = syntax:generate_script_template(args.bot, args.template)
        print(template)
    end
end

main()
