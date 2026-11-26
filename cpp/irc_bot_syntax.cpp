// abstraction-provenance: {"artifact_sha256": "53710dfa0dd7edcc941a698494d431a24547b77f67731be97b548a1311e9dc18", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "cpp"}
// irc_bot_syntax.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <optional>
#include <algorithm>
#include <iomanip>
#include <sstream>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

/**
 * IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
 * Fetches syntax from documentation sources.
 */

struct BotCommand {
    std::string bot;
    std::string command;
    std::string syntax;
    std::string example;
    std::string description;
    std::optional<std::string> permission;

    BotCommand(const std::string& b, const std::string& c, const std::string& s,
               const std::string& e, const std::string& d, const std::optional<std::string>& p = std::nullopt)
        : bot(b), command(c), syntax(s), example(e), description(d), permission(p) {}
};

class IRCBotSyntax {
public:
    /**
     * IRC Bot command syntax reference.
     * Sources:
     * - pbot: https://github.com/pragma-/pbot
     * - Limnoria: https://docs.limnoria.net/
     * - Eggdrop: https://docs.eggheads.org/
     */
    
    static const std::map<std::string, BotCommand> PBOT_COMMANDS;
    static const std::map<std::string, BotCommand> LIMNORIA_COMMANDS;
    static const std::map<std::string, BotCommand> EGGDROP_COMMANDS;
    static const std::map<std::string, std::map<std::string, BotCommand>> ALL_COMMANDS;

    /**
     * Get command syntax for a specific bot.
     */
    std::optional<BotCommand> get_command(const std::string& bot, const std::string& command) const {
        std::string lower_bot = bot;
        std::string lower_command = command;
        std::transform(lower_bot.begin(), lower_bot.end(), lower_bot.begin(), ::tolower);
        std::transform(lower_command.begin(), lower_command.end(), lower_command.begin(), ::tolower);

        auto bot_it = ALL_COMMANDS.find(lower_bot);
        if (bot_it != ALL_COMMANDS.end()) {
            auto cmd_it = bot_it->second.find(lower_command);
            if (cmd_it != bot_it->second.end()) {
                return cmd_it->second;
            }
        }
        return std::nullopt;
    }

    /**
     * List available commands for a bot or all bots.
     */
    std::map<std::string, std::vector<std::string>> list_commands(const std::optional<std::string>& bot = std::nullopt) const {
        std::map<std::string, std::vector<std::string>> result;
        
        if (bot.has_value()) {
            std::string lower_bot = bot.value();
            std::transform(lower_bot.begin(), lower_bot.end(), lower_bot.begin(), ::tolower);
            
            auto it = ALL_COMMANDS.find(lower_bot);
            if (it != ALL_COMMANDS.end()) {
                std::vector<std::string> commands;
                for (const auto& pair : it->second) {
                    commands.push_back(pair.first);
                }
                result[lower_bot] = commands;
            }
        } else {
            for (const auto& bot_pair : ALL_COMMANDS) {
                std::vector<std::string> commands;
                for (const auto& cmd_pair : bot_pair.second) {
                    commands.push_back(cmd_pair.first);
                }
                result[bot_pair.first] = commands;
            }
        }
        return result;
    }

    /**
     * Generate a script template for a bot.
     */
    std::string generate_script_template(const std::string& bot, const std::string& purpose) const {
        std::string lower_bot = bot;
        std::transform(lower_bot.begin(), lower_bot.end(), lower_bot.begin(), ::tolower);
        
        std::string purpose_underscore = purpose;
        std::replace(purpose_underscore.begin(), purpose_underscore.end(), ' ', '_');
        
        std::string purpose_title = purpose;
        bool capitalize_next = true;
        for (size_t i = 0; i < purpose_title.length(); ++i) {
            if (purpose_title[i] == ' ') {
                capitalize_next = true;
            } else if (capitalize_next) {
                purpose_title[i] = std::toupper(purpose_title[i]);
                capitalize_next = false;
            } else {
                purpose_title[i] = std::tolower(purpose_title[i]);
            }
        }
        purpose_title.erase(std::remove(purpose_title.begin(), purpose_title.end(), ' '), purpose_title.end());

        if (lower_bot == "pbot") {
            return "# pbot applet - " + purpose + "\n"
                   "# Place in ~/.pbot/applets/\n\n"
                   "use strict;\n"
                   "use warnings;\n\n"
                   "sub " + purpose_underscore + " {\n"
                   "    my ($self, $from, $to, $args) = @_;    \n"
                   "    \n"
                   "    # Your code here\n"
                   "    return \"Result: $args\";\n"
                   "}\n\n"
                   "1;\n";
        } else if (lower_bot == "limnoria") {
            return "# Limnoria plugin - " + purpose + "\n"
                   "# Place in plugins/" + purpose_title + "/\n\n"
                   "from supybot import utils, plugins, ircutils, callbacks\n"
                   "from supybot.commands import *\n\n"
                   "class " + purpose_title + "(callbacks.Plugin):\n"
                   "    \"\"\"" + purpose + "\"\"\"\n"
                   "    \n"
                   "    threaded = True\n"
                   "    \n"
                   "    def " + purpose_underscore + "(self, irc, msg, args):\n"
                   "        \"\"\"<args>\"\"\"\n"
                   "        irc.reply(\"Hello from " + purpose + "!\")\n"
                   "    \n"
                   "Class = " + purpose_title + "\n";
        } else if (lower_bot == "eggdrop") {
            return "# Eggdrop Tcl script - " + purpose + "\n"
                   "# Add to eggdrop.conf: source scripts/" + purpose_underscore + ".tcl\n\n"
                   "proc " + purpose_underscore + " {nick uhost hand chan arg} {\n"
                   "    putserv \"PRIVMSG $chan :Hello $nick, this is " + purpose + "!\"\n"
                   "}\n\n"
                   "bind pub - !" + purpose_underscore + " " + purpose_underscore + "\n";
        } else {
            return "# Unknown bot";
        }
    }
};

// Static member definitions
const std::map<std::string, BotCommand> IRCBotSyntax::PBOT_COMMANDS = {
    {"keyword add", BotCommand(
        "pbot",
        "keyword add",
        "keyword add <keyword> <text>",
        "keyword add hello Hello, World!",
        "Add a keyword trigger",
        "admin"
    )},
    {"fact add", BotCommand(
        "pbot",
        "fact add",
        "fact add <channel> <subject> <text>",
        "fact add #channel python Python is a programming language",
        "Add a factoid",
        " whitelisted"
    )},
    {"ban", BotCommand(
        "pbot",
        "ban",
        "ban <nick|mask> [duration] [reason]",
        "ban spambot 1h Spamming",
        "Ban a user",
        "op"
    )}
};

const std::map<std::string, BotCommand> IRCBotSyntax::LIMNORIA_COMMANDS = {
    {"config channel", BotCommand(
        "limnoria",
        "config channel",
        "config channel <#channel> <plugin>.<variable> <value>",
        "config channel #bot supybot.plugins.Channel.enabled True",
        "Configure channel-specific settings",
        "admin"
    )},
    {"load", BotCommand(
        "limnoria",
        "load",
        "load <plugin>",
        "load User",
        "Load a plugin",
        "owner"
    )},
    {"aka add", BotCommand(
        "limnoria",
        "aka add",
        "aka add <name> <command>",
        "aka add hi say Hello $nick!",
        "Create command alias",
        "admin"
    )}
};

const std::map<std::string, BotCommand> IRCBotSyntax::EGGDROP_COMMANDS = {
    {"bind", BotCommand(
        "eggdrop",
        "bind",
        "bind <type> <flags> <keyword> <proc>",
        "bind pub - !hello pub_hello",
        "Bind a command to a Tcl procedure",
        "n/a (script)"
    )},
    {"putserv", BotCommand(
        "eggdrop",
        "putserv",
        "putserv <text>",
        "putserv PRIVMSG #channel :Hello World",
        "Send raw IRC command",
        "n/a (script)"
    )},
    {"setudef", BotCommand(
        "eggdrop",
        "setudef",
        "setudef <type> <name>",
        "setudef str bot_setting",
        "Define user-defined variable",
        "n/a (script)"
    )}
};

const std::map<std::string, std::map<std::string, BotCommand>> IRCBotSyntax::ALL_COMMANDS = {
    {"pbot", IRCBotSyntax::PBOT_COMMANDS},
    {"limnoria", IRCBotSyntax::LIMNORIA_COMMANDS},
    {"eggdrop", IRCBotSyntax::EGGDROP_COMMANDS}
};

void print_help() {
    std::cout << "Usage: irc_bot_syntax --bot <bot> [--command <command>] [--list] [--template <purpose>]\n"
              << "Options:\n"
              << "  --bot       Required. Bot name (pbot, limnoria, eggdrop)\n"
              << "  --command   Command to look up\n"
              << "  --list      List all commands\n"
              << "  --template  Generate script template for purpose\n";
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        print_help();
        return 1;
    }

    std::string bot;
    std::optional<std::string> command;
    bool list_commands = false;
    std::optional<std::string> template_purpose;
    
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--bot" && i + 1 < argc) {
            bot = argv[++i];
        } else if (arg == "--command" && i + 1 < argc) {
            command = argv[++i];
        } else if (arg == "--list") {
            list_commands = true;
        } else if (arg == "--template" && i + 1 < argc) {
            template_purpose = argv[++i];
        } else if (arg == "--help" || arg == "-h") {
            print_help();
            return 0;
        }
    }

    if (bot.empty()) {
        std::cerr << "Error: --bot is required\n";
        print_help();
        return 1;
    }

    IRCBotSyntax syntax;
    
    if (list_commands) {
        auto commands = syntax.list_commands(bot);
        json j = commands;
        std::cout << j.dump(2) << std::endl;
    } else if (command.has_value()) {
        auto cmd = syntax.get_command(bot, command.value());
        if (cmd.has_value()) {
            std::cout << "Bot: " << cmd->bot << "\n"
                      << "Command: " << cmd->command << "\n"
                      << "Syntax: " << cmd->syntax << "\n"
                      << "Example: " << cmd->example << "\n"
                      << "Description: " << cmd->description << "\n";
            if (cmd->permission.has_value()) {
                std::cout << "Permission: " << cmd->permission.value() << "\n";
            }
        } else {
            std::cout << "Command not found: " << command.value() << "\n";
            std::cout << "Available commands:\n";
            auto cmds = syntax.list_commands(bot);
            json j = cmds;
            std::cout << j.dump(2) << std::endl;
        }
    } else if (template_purpose.has_value()) {
        std::string template_str = syntax.generate_script_template(bot, template_purpose.value());
        std::cout << template_str << std::endl;
    } else {
        print_help();
        return 1;
    }

    return 0;
}
