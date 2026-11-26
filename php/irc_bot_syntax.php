<?php
// abstraction-provenance: {"artifact_sha256": "591c5b2b6eb6f80353495afa0e0d846d5fcb4180defd998e370d39f37b89c393", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "php"}
// irc_bot_syntax.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
 * Fetches syntax from documentation sources.
 */

class BotCommand {
    public string $bot;
    public string $command;
    public string $syntax;
    public string $example;
    public string $description;
    public ?string $permission;

    public function __construct(string $bot, string $command, string $syntax, string $example, string $description, ?string $permission = null) {
        $this->bot = $bot;
        $this->command = $command;
        $this->syntax = $syntax;
        $this->example = $example;
        $this->description = $description;
        $this->permission = $permission;
    }
}

class IRCBotSyntax {
    /**
     * IRC Bot command syntax reference.
     * Sources:
     * - pbot: https://github.com/pragma-/pbot
     * - Limnoria: https://docs.limnoria.net/
     * - Eggdrop: https://docs.eggheads.org/
     */
    
    private array $PBOT_COMMANDS;
    private array $LIMNORIA_COMMANDS;
    private array $EGGDROP_COMMANDS;
    private array $ALL_COMMANDS;

    public function __construct() {
        $this->PBOT_COMMANDS = [
            "keyword add" => new BotCommand(
                "pbot",
                "keyword add",
                "keyword add <keyword> <text>",
                "keyword add hello Hello, World!",
                "Add a keyword trigger",
                "admin"
            ),
            "fact add" => new BotCommand(
                "pbot",
                "fact add",
                "fact add <channel> <subject> <text>",
                "fact add #channel python Python is a programming language",
                "Add a factoid",
                " whitelisted"
            ),
            "ban" => new BotCommand(
                "pbot",
                "ban",
                "ban <nick|mask> [duration] [reason]",
                "ban spambot 1h Spamming",
                "Ban a user",
                "op"
            ),
        ];

        $this->LIMNORIA_COMMANDS = [
            "config channel" => new BotCommand(
                "limnoria",
                "config channel",
                "config channel <#channel> <plugin>.<variable> <value>",
                "config channel #bot supybot.plugins.Channel.enabled True",
                "Configure channel-specific settings",
                "admin"
            ),
            "load" => new BotCommand(
                "limnoria",
                "load",
                "load <plugin>",
                "load User",
                "Load a plugin",
                "owner"
            ),
            "aka add" => new BotCommand(
                "limnoria",
                "aka add",
                "aka add <name> <command>",
                "aka add hi say Hello \$nick!",
                "Create command alias",
                "admin"
            ),
        ];

        $this->EGGDROP_COMMANDS = [
            "bind" => new BotCommand(
                "eggdrop",
                "bind",
                "bind <type> <flags> <keyword> <proc>",
                "bind pub - !hello pub_hello",
                "Bind a command to a Tcl procedure",
                "n/a (script)"
            ),
            "putserv" => new BotCommand(
                "eggdrop",
                "putserv",
                "putserv <text>",
                "putserv PRIVMSG #channel :Hello World",
                "Send raw IRC command",
                "n/a (script)"
            ),
            "setudef" => new BotCommand(
                "eggdrop",
                "setudef",
                "setudef <type> <name>",
                "setudef str bot_setting",
                "Define user-defined variable",
                "n/a (script)"
            ),
        ];

        $this->ALL_COMMANDS = [
            "pbot" => $this->PBOT_COMMANDS,
            "limnoria" => $this->LIMNORIA_COMMANDS,
            "eggdrop" => $this->EGGDROP_COMMANDS,
        ];
    }

    /**
     * Get command syntax for a specific bot.
     */
    public function getCommand(string $bot, string $command): ?BotCommand {
        $bot = strtolower($bot);
        $command = strtolower($command);

        if (!isset($this->ALL_COMMANDS[$bot])) {
            return null;
        }

        $botCommands = $this->ALL_COMMANDS[$bot];
        return $botCommands[$command] ?? null;
    }

    /**
     * List available commands for a bot or all bots.
     */
    public function listCommands(?string $bot = null): array {
        if ($bot !== null) {
            $bot = strtolower($bot);
            return [$bot => array_keys($this->ALL_COMMANDS[$bot] ?? [])];
        }
        $result = [];
        foreach ($this->ALL_COMMANDS as $key => $commands) {
            $result[$key] = array_keys($commands);
        }
        return $result;
    }

    /**
     * Generate a script template for a bot.
     */
    public function generateScriptTemplate(string $bot, string $purpose): string {
        $templates = [
            "pbot" => "# pbot applet - {$purpose}\n# Place in ~/.pbot/applets/\n\nuse strict;\nuse warnings;\n\nsub " . str_replace(' ', '_', $purpose) . " {\n    my (\$self, \$from, \$to, \$args) = \@_;\n    \n    # Your code here\n    return \"Result: \$args\";\n}\n\n1;\n",
            "limnoria" => "# Limnoria plugin - {$purpose}\n# Place in plugins/" . str_replace(' ', '', $purpose) . "/\n\nfrom supybot import utils, plugins, ircutils, callbacks\nfrom supybot.commands import *\n\nclass " . ucfirst(str_replace(' ', '', $purpose)) . "(callbacks.Plugin):\n    \"\"\"{$purpose}\"\"\"\n    \n    threaded = True\n    \n    def " . str_replace(' ', '_', $purpose) . "(self, irc, msg, args):\n        \"\"\"<args>\"\"\"\n        irc.reply(\"Hello from {$purpose}!\")\n    \nClass = " . ucfirst(str_replace(' ', '', $purpose)) . "\n",
            "eggdrop" => "# Eggdrop Tcl script - {$purpose}\n# Add to eggdrop.conf: source scripts/" . str_replace(' ', '_', $purpose) . ".tcl\n\nproc " . str_replace(' ', '_', $purpose) . " {nick uhost hand chan arg} {\n    putserv \"PRIVMSG \$chan :Hello \$nick, this is {$purpose}!\"\n}\n\nbind pub - !" . str_replace(' ', '_', $purpose) . " " . str_replace(' ', '_', $purpose) . "\n",
        ];
        return $templates[strtolower($bot)] ?? "# Unknown bot";
    }
}

function main() {
    global $argv;
    
    // Simple argument parsing
    $args = [];
    for ($i = 1; $i < count($argv); $i++) {
        if ($argv[$i] === '--bot' && isset($argv[$i+1])) {
            $args['bot'] = $argv[$i+1];
            $i++;
        } elseif ($argv[$i] === '--command' && isset($argv[$i+1])) {
            $args['command'] = $argv[$i+1];
            $i++;
        } elseif ($argv[$i] === '--list') {
            $args['list'] = true;
        } elseif ($argv[$i] === '--template' && isset($argv[$i+1])) {
            $args['template'] = $argv[$i+1];
            $i++;
        }
    }

    if (!isset($args['bot'])) {
        echo "Error: --bot is required\n";
        exit(1);
    }

    $syntax = new IRCBotSyntax();

    if (isset($args['list'])) {
        $commands = $syntax->listCommands($args['bot']);
        echo json_encode($commands, JSON_PRETTY_PRINT) . "\n";
    } elseif (isset($args['command'])) {
        $cmd = $syntax->getCommand($args['bot'], $args['command']);
        if ($cmd) {
            echo "Bot: {$cmd->bot}\n";
            echo "Command: {$cmd->command}\n";
            echo "Syntax: {$cmd->syntax}\n";
            echo "Example: {$cmd->example}\n";
            echo "Description: {$cmd->description}\n";
            if ($cmd->permission) {
                echo "Permission: {$cmd->permission}\n";
            }
        } else {
            echo "Command not found: {$args['command']}\n";
            echo "Available commands:\n";
            $cmds = $syntax->listCommands($args['bot']);
            echo json_encode($cmds, JSON_PRETTY_PRINT) . "\n";
        }
    } elseif (isset($args['template'])) {
        $template = $syntax->generateScriptTemplate($args['bot'], $args['template']);
        echo $template;
    }
}

// Only run main if called directly
if (basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    main();
}
?>
