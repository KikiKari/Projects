// abstraction-provenance: {"artifact_sha256": "11601ee56b0eb91805d21e2cc3dfd7987f0d236584386984c7b49004185876f7", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "java"}
// irc_bot_syntax.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.util.*;
import java.util.stream.Collectors;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

/**
 * IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
 * Fetches syntax from documentation sources.
 */
class BotCommand {
    private String bot;
    private String command;
    private String syntax;
    private String example;
    private String description;
    private String permission;

    public BotCommand(String bot, String command, String syntax, String example, String description, String permission) {
        this.bot = bot;
        this.command = command;
        this.syntax = syntax;
        this.example = example;
        this.description = description;
        this.permission = permission;
    }

    // Getters
    public String getBot() { return bot; }
    public String getCommand() { return command; }
    public String getSyntax() { return syntax; }
    public String getExample() { return example; }
    public String getDescription() { return description; }
    public String getPermission() { return permission; }
}

class IRCBotSyntax {
    /**
     * IRC Bot command syntax reference.
     * Sources:
     * - pbot: https://github.com/pragma-/pbot
     * - Limnoria: https://docs.limnoria.net/
     * - Eggdrop: https://docs.eggheads.org/
     */

    private static final Map<String, Map<String, BotCommand>> PBOT_COMMANDS = new HashMap<>();
    private static final Map<String, Map<String, BotCommand>> LIMNORIA_COMMANDS = new HashMap<>();
    private static final Map<String, Map<String, BotCommand>> EGGDROP_COMMANDS = new HashMap<>();
    private static final Map<String, Map<String, Map<String, BotCommand>>> ALL_COMMANDS = new HashMap<>();

    static {
        // Initialize pbot commands
        PBOT_COMMANDS.put("keyword add", new BotCommand(
            "pbot",
            "keyword add",
            "keyword add <keyword> <text>",
            "keyword add hello Hello, World!",
            "Add a keyword trigger",
            "admin"
        ));
        PBOT_COMMANDS.put("fact add", new BotCommand(
            "pbot",
            "fact add",
            "fact add <channel> <subject> <text>",
            "fact add #channel python Python is a programming language",
            "Add a factoid",
            " whitelisted"
        ));
        PBOT_COMMANDS.put("ban", new BotCommand(
            "pbot",
            "ban",
            "ban <nick|mask> [duration] [reason]",
            "ban spambot 1h Spamming",
            "Ban a user",
            "op"
        ));

        // Initialize Limnoria commands
        LIMNORIA_COMMANDS.put("config channel", new BotCommand(
            "limnoria",
            "config channel",
            "config channel <#channel> <plugin>.<variable> <value>",
            "config channel #bot supybot.plugins.Channel.enabled True",
            "Configure channel-specific settings",
            "admin"
        ));
        LIMNORIA_COMMANDS.put("load", new BotCommand(
            "limnoria",
            "load",
            "load <plugin>",
            "load User",
            "Load a plugin",
            "owner"
        ));
        LIMNORIA_COMMANDS.put("aka add", new BotCommand(
            "limnoria",
            "aka add",
            "aka add <name> <command>",
            "aka add hi say Hello $nick!",
            "Create command alias",
            "admin"
        ));

        // Initialize Eggdrop commands
        EGGDROP_COMMANDS.put("bind", new BotCommand(
            "eggdrop",
            "bind",
            "bind <type> <flags> <keyword> <proc>",
            "bind pub - !hello pub_hello",
            "Bind a command to a Tcl procedure",
            "n/a (script)"
        ));
        EGGDROP_COMMANDS.put("putserv", new BotCommand(
            "eggdrop",
            "putserv",
            "putserv <text>",
            "putserv PRIVMSG #channel :Hello World",
            "Send raw IRC command",
            "n/a (script)"
        ));
        EGGDROP_COMMANDS.put("setudef", new BotCommand(
            "eggdrop",
            "setudef",
            "setudef <type> <name>",
            "setudef str bot_setting",
            "Define user-defined variable",
            "n/a (script)"
        ));

        // Initialize all commands map
        ALL_COMMANDS.put("pbot", PBOT_COMMANDS);
        ALL_COMMANDS.put("limnoria", LIMNORIA_COMMANDS);
        ALL_COMMANDS.put("eggdrop", EGGDROP_COMMANDS);
    }

    /**
     * Get command syntax for a specific bot.
     */
    public BotCommand getCommand(String bot, String command) {
        String lowerBot = bot.toLowerCase();
        String lowerCommand = command.toLowerCase();

        Map<String, Map<String, BotCommand>> botCommands = ALL_COMMANDS.get(lowerBot);
        if (botCommands != null) {
            return botCommands.get(lowerCommand);
        }
        return null;
    }

    /**
     * List available commands for a bot or all bots.
     */
    public Map<String, List<String>> listCommands(String bot) {
        Map<String, List<String>> result = new HashMap<>();
        if (bot != null) {
            Map<String, Map<String, BotCommand>> botMap = ALL_COMMANDS.get(bot.toLowerCase());
            if (botMap != null) {
                result.put(bot, new ArrayList<>(botMap.keySet()));
            } else {
                result.put(bot, new ArrayList<>());
            }
        } else {
            for (Map.Entry<String, Map<String, Map<String, BotCommand>>> entry : ALL_COMMANDS.entrySet()) {
                result.put(entry.getKey(), new ArrayList<>(entry.getValue().keySet()));
            }
        }
        return result;
    }

    /**
     * Generate a script template for a bot.
     */
    public String generateScriptTemplate(String bot, String purpose) {
        Map<String, String> templates = new HashMap<>();
        
        templates.put("pbot", String.format(
            "# pbot applet - %s\n" +
            "# Place in ~/.pbot/applets/\n\n" +
            "use strict;\n" +
            "use warnings;\n\n" +
            "sub %s {\n" +
            "    my ($self, $from, $to, $args) = @_;\n\n" +
            "    # Your code here\n" +
            "    return \"Result: $args\";\n" +
            "}\n\n" +
            "1;\n",
            purpose, purpose.replace(" ", "_")
        ));
        
        templates.put("limnoria", String.format(
            "# Limnoria plugin - %s\n" +
            "# Place in plugins/%s/\n\n" +
            "from supybot import utils, plugins, ircutils, callbacks\n" +
            "from supybot.commands import *\n\n" +
            "class %s(callbacks.Plugin):\n" +
            "    \"\"\"%s\"\"\"\n\n" +
            "    threaded = True\n\n" +
            "    def %s(self, irc, msg, args):\n" +
            "        \"\"\"<args>\"\"\"\n" +
            "        irc.reply(\"Hello from %s!\")\n\n" +
            "Class = %s\n",
            purpose, purpose.replace(" ", ""),
            purpose.replace(" ", "").substring(0, 1).toUpperCase() + purpose.replace(" ", "").substring(1),
            purpose,
            purpose.replace(" ", "_"),
            purpose,
            purpose.replace(" ", "").substring(0, 1).toUpperCase() + purpose.replace(" ", "").substring(1)
        ));
        
        templates.put("eggdrop", String.format(
            "# Eggdrop Tcl script - %s\n" +
            "# Add to eggdrop.conf: source scripts/%s.tcl\n\n" +
            "proc %s {nick uhost hand chan arg} {\n" +
            "    putserv \"PRIVMSG $chan :Hello $nick, this is %s!\"\n" +
            "}\n\n" +
            "bind pub - !%s %s\n",
            purpose, purpose.replace(" ", "_"),
            purpose.replace(" ", "_"),
            purpose,
            purpose.replace(" ", "_"),
            purpose.replace(" ", "_")
        ));

        return templates.getOrDefault(bot.toLowerCase(), "# Unknown bot");
    }
}

public class IrcBotSyntax {
    public static void main(String[] args) {
        // Simple argument parsing
        String bot = null;
        String command = null;
        boolean list = false;
        String template = null;

        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--bot":
                    if (i + 1 < args.length) bot = args[++i];
                    break;
                case "--command":
                    if (i + 1 < args.length) command = args[++i];
                    break;
                case "--list":
                    list = true;
                    break;
                case "--template":
                    if (i + 1 < args.length) template = args[++i];
                    break;
            }
        }

        if (bot == null) {
            System.err.println("Error: --bot argument is required");
            System.exit(1);
        }

        IRCBotSyntax syntax = new IRCBotSyntax();
        ObjectMapper mapper = new ObjectMapper();
        mapper.enable(SerializationFeature.INDENT_OUTPUT);

        try {
            if (list) {
                Map<String, List<String>> commands = syntax.listCommands(bot);
                System.out.println(mapper.writeValueAsString(commands));
            } else if (command != null) {
                BotCommand cmd = syntax.getCommand(bot, command);
                if (cmd != null) {
                    System.out.println("Bot: " + cmd.getBot());
                    System.out.println("Command: " + cmd.getCommand());
                    System.out.println("Syntax: " + cmd.getSyntax());
                    System.out.println("Example: " + cmd.getExample());
                    System.out.println("Description: " + cmd.getDescription());
                    if (cmd.getPermission() != null) {
                        System.out.println("Permission: " + cmd.getPermission());
                    }
                } else {
                    System.out.println("Command not found: " + command);
                    System.out.println("Available commands:");
                    Map<String, List<String>> cmds = syntax.listCommands(bot);
                    System.out.println(mapper.writeValueAsString(cmds));
                }
            } else if (template != null) {
                String templateStr = syntax.generateScriptTemplate(bot, template);
                System.out.println(templateStr);
            }
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private Map<String, List<String>> listCommands(String bot) {
        IRCBotSyntax syntaxRef = new IRCBotSyntax();
        return syntaxRef.listCommands(bot);
    }

    private BotCommand getCommand(String bot, String command) {
        IRCBotSyntax syntaxRef = new IRCBotSyntax();
        return syntaxRef.getCommand(bot, command);
    }

    private String generateScriptTemplate(String bot, String purpose) {
        IRCBotSyntax syntaxRef = new IRCBotSyntax();
        return syntaxRef.generateScriptTemplate(bot, purpose);
    }
}
