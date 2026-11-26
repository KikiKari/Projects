#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "2f3782c10790143c53110f2f983ca6287393379e4a7cd98f56046c399ac1aaf2", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "ruby"}
# irc_bot_syntax.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'json'
require 'optparse'

# IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
# Fetches syntax from documentation sources.

class BotCommand
  attr_reader :bot, :command, :syntax, :example, :description, :permission

  def initialize(bot:, command:, syntax:, example:, description:, permission: nil)
    @bot = bot
    @command = command
    @syntax = syntax
    @example = example
    @description = description
    @permission = permission
  end
end

class IRCBotSyntax
  # IRC Bot command syntax reference.
  # Sources:
  # - pbot: https://github.com/pragma-/pbot
  # - Limnoria: https://docs.limnoria.net/
  # - Eggdrop: https://docs.eggheads.org/

  PBOT_COMMANDS = {
    "keyword add" => BotCommand.new(
      bot: "pbot",
      command: "keyword add",
      syntax: "keyword add <keyword> <text>",
      example: "keyword add hello Hello, World!",
      description: "Add a keyword trigger",
      permission: "admin"
    ),
    "fact add" => BotCommand.new(
      bot: "pbot",
      command: "fact add",
      syntax: "fact add <channel> <subject> <text>",
      example: "fact add #channel python Python is a programming language",
      description: "Add a factoid",
      permission: " whitelisted"
    ),
    "ban" => BotCommand.new(
      bot: "pbot",
      command: "ban",
      syntax: "ban <nick|mask> [duration] [reason]",
      example: "ban spambot 1h Spamming",
      description: "Ban a user",
      permission: "op"
    ),
  }.freeze

  LIMNORIA_COMMANDS = {
    "config channel" => BotCommand.new(
      bot: "limnoria",
      command: "config channel",
      syntax: "config channel <#channel> <plugin>.<variable> <value>",
      example: "config channel #bot supybot.plugins.Channel.enabled True",
      description: "Configure channel-specific settings",
      permission: "admin"
    ),
    "load" => BotCommand.new(
      bot: "limnoria",
      command: "load",
      syntax: "load <plugin>",
      example: "load User",
      description: "Load a plugin",
      permission: "owner"
    ),
    "aka add" => BotCommand.new(
      bot: "limnoria",
      command: "aka add",
      syntax: "aka add <name> <command>",
      example: "aka add hi say Hello $nick!",
      description: "Create command alias",
      permission: "admin"
    ),
  }.freeze

  EGGDROP_COMMANDS = {
    "bind" => BotCommand.new(
      bot: "eggdrop",
      command: "bind",
      syntax: "bind <type> <flags> <keyword> <proc>",
      example: "bind pub - !hello pub_hello",
      description: "Bind a command to a Tcl procedure",
      permission: "n/a (script)"
    ),
    "putserv" => BotCommand.new(
      bot: "eggdrop",
      command: "putserv",
      syntax: "putserv <text>",
      example: "putserv PRIVMSG #channel :Hello World",
      description: "Send raw IRC command",
      permission: "n/a (script)"
    ),
    "setudef" => BotCommand.new(
      bot: "eggdrop",
      command: "setudef",
      syntax: "setudef <type> <name>",
      example: "setudef str bot_setting",
      description: "Define user-defined variable",
      permission: "n/a (script)"
    ),
  }.freeze

  ALL_COMMANDS = {
    "pbot" => PBOT_COMMANDS,
    "limnoria" => LIMNORIA_COMMANDS,
    "eggdrop" => EGGDROP_COMMANDS,
  }.freeze

  # Get command syntax for a specific bot.
  def get_command(bot, command)
    bot = bot.downcase
    command = command.downcase

    bot_commands = ALL_COMMANDS[bot] || {}
    bot_commands[command]
  end

  # List available commands for a bot or all bots.
  def list_commands(bot = nil)
    if bot
      { bot => (ALL_COMMANDS[bot.downcase]&.keys || []) }
    else
      ALL_COMMANDS.transform_values { |v| v.keys }
    end
  end

  # Generate a script template for a bot.
  def generate_script_template(bot, purpose)
    templates = {
      "pbot" => <<~PBO_TTEMPLATE,
        # pbot applet - #{purpose}
        # Place in ~/.pbot/applets/

        use strict;
        use warnings;

        sub #{purpose.gsub(' ', '_')} {
            my ($self, $from, $to, $args) = @_;
            
            # Your code here
            return "Result: $args";
        }

        1;
      PBO_TTEMPLATE
      "limnoria" => <<~LIMNORIA_TEMPLATE,
        # Limnoria plugin - #{purpose}
        # Place in plugins/#{purpose.gsub(' ', '')}/

        from supybot import utils, plugins, ircutils, callbacks
        from supybot.commands import *

        class #{purpose.gsub(' ', '').capitalize}(callbacks.Plugin):
            """#{purpose}"""
            
            threaded = True
            
            def #{purpose.gsub(' ', '_')}(self, irc, msg, args):
                """<args>"""
                irc.reply("Hello from #{purpose}!")
            
        Class = #{purpose.gsub(' ', '').capitalize}
      LIMNORIA_TEMPLATE
      "eggdrop" => <<~EGGDROP_TEMPLATE,
        # Eggdrop Tcl script - #{purpose}
        # Add to eggdrop.conf: source scripts/#{purpose.gsub(' ', '_')}.tcl

        proc #{purpose.gsub(' ', '_')} {nick uhost hand chan arg} {
            putserv "PRIVMSG $chan :Hello $nick, this is #{purpose}!"
        }

        bind pub - !#{purpose.gsub(' ', '_')} #{purpose.gsub(' ', '_')}
      EGGDROP_TEMPLATE
    }
    templates[bot.downcase] || "# Unknown bot"
  end
end

def main
  options = {}
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: irc_bot_syntax.rb [options]"
    opts.separator ""
    opts.separator "IRC Bot command syntax reference"

    opts.on("--bot BOT", ["pbot", "limnoria", "eggdrop"], "Bot type (required)") do |b|
      options[:bot] = b
    end

    opts.on("--command COMMAND", "Command to look up") do |c|
      options[:command] = c
    end

    opts.on("--list", "List all commands") do
      options[:list] = true
    end

    opts.on("--template TEMPLATE", "Generate script template for purpose") do |t|
      options[:template] = t
    end

    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end

  begin
    parser.parse!
    
    if options[:bot].nil?
      puts "Error: --bot is required"
      puts parser.help
      exit 1
    end

    syntax = IRCBotSyntax.new

    if options[:list]
      commands = syntax.list_commands(options[:bot])
      puts JSON.pretty_generate(commands)
    elsif options[:command]
      cmd = syntax.get_command(options[:bot], options[:command])
      if cmd
        puts "Bot: #{cmd.bot}"
        puts "Command: #{cmd.command}"
        puts "Syntax: #{cmd.syntax}"
        puts "Example: #{cmd.example}"
        puts "Description: #{cmd.description}"
        puts "Permission: #{cmd.permission}" if cmd.permission
      else
        puts "Command not found: #{options[:command]}"
        puts "Available commands:"
        cmds = syntax.list_commands(options[:bot])
        puts JSON.pretty_generate(cmds)
      end
    elsif options[:template]
      template = syntax.generate_script_template(options[:bot], options[:template])
      puts template
    else
      puts parser.help
    end
  rescue OptionParser::InvalidOption => e
    puts "Error: #{e.message}"
    puts parser.help
    exit 1
  end
end

if __FILE__ == $0
  main
end
