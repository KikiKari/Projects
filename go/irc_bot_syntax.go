// abstraction-provenance: {"artifact_sha256": "7d7138714cb1cf5f5272b394d82ed62bb4dc22ce55d77d2dba7995ba6436a124", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "go"}
// irc_bot_syntax.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strings"
)

// BotCommand represents an IRC bot command with its details
type BotCommand struct {
	Bot         string  `json:"bot"`
	Command     string  `json:"command"`
	Syntax      string  `json:"syntax"`
	Example     string  `json:"example"`
	Description string  `json:"description"`
	Permission  *string `json:"permission,omitempty"`
}

// IRCBotSyntax holds all the bot command definitions
type IRCBotSyntax struct {
	PBotCommands     map[string]BotCommand
	LimnoriaCommands map[string]BotCommand
	EggdropCommands  map[string]BotCommand
	AllCommands      map[string]map[string]BotCommand
}

// NewIRCBotSyntax creates a new instance with all command definitions
func NewIRCBotSyntax() *IRCBotSyntax {
	s := &IRCBotSyntax{
		PBotCommands: map[string]BotCommand{
			"keyword add": {
				Bot:         "pbot",
				Command:     "keyword add",
				Syntax:      "keyword add <keyword> <text>",
				Example:     "keyword add hello Hello, World!",
				Description: "Add a keyword trigger",
				Permission:  stringPtr("admin"),
			},
			"fact add": {
				Bot:         "pbot",
				Command:     "fact add",
				Syntax:      "fact add <channel> <subject> <text>",
				Example:     "fact add #channel python Python is a programming language",
				Description: "Add a factoid",
				Permission:  stringPtr(" whitelisted"),
			},
			"ban": {
				Bot:         "pbot",
				Command:     "ban",
				Syntax:      "ban <nick|mask> [duration] [reason]",
				Example:     "ban spambot 1h Spamming",
				Description: "Ban a user",
				Permission:  stringPtr("op"),
			},
		},
		LimnoriaCommands: map[string]BotCommand{
			"config channel": {
				Bot:         "limnoria",
				Command:     "config channel",
				Syntax:      "config channel <#channel> <plugin>.<variable> <value>",
				Example:     "config channel #bot supybot.plugins.Channel.enabled True",
				Description: "Configure channel-specific settings",
				Permission:  stringPtr("admin"),
			},
			"load": {
				Bot:         "limnoria",
				Command:     "load",
				Syntax:      "load <plugin>",
				Example:     "load User",
				Description: "Load a plugin",
				Permission:  stringPtr("owner"),
			},
			"aka add": {
				Bot:         "limnoria",
				Command:     "aka add",
				Syntax:      "aka add <name> <command>",
				Example:     "aka add hi say Hello $nick!",
				Description: "Create command alias",
				Permission:  stringPtr("admin"),
			},
		},
		EggdropCommands: map[string]BotCommand{
			"bind": {
				Bot:         "eggdrop",
				Command:     "bind",
				Syntax:      "bind <type> <flags> <keyword> <proc>",
				Example:     "bind pub - !hello pub_hello",
				Description: "Bind a command to a Tcl procedure",
				Permission:  stringPtr("n/a (script)"),
			},
			"putserv": {
				Bot:         "eggdrop",
				Command:     "putserv",
				Syntax:      "putserv <text>",
				Example:     "putserv PRIVMSG #channel :Hello World",
				Description: "Send raw IRC command",
				Permission:  stringPtr("n/a (script)"),
			},
			"setudef": {
				Bot:         "eggdrop",
				Command:     "setudef",
				Syntax:      "setudef <type> <name>",
				Example:     "setudef str bot_setting",
				Description: "Define user-defined variable",
				Permission:  stringPtr("n/a (script)"),
			},
		},
	}

	s.AllCommands = map[string]map[string]BotCommand{
		"pbot":     s.PBotCommands,
		"limnoria": s.LimnoriaCommands,
		"eggdrop":  s.EggdropCommands,
	}

	return s
}

// GetCommand returns a command for a specific bot
func (s *IRCBotSyntax) GetCommand(bot, command string) (*BotCommand, bool) {
	bot = strings.ToLower(bot)
	command = strings.ToLower()

	if botCommands, exists := s.AllCommands[bot]; exists {
		if cmd, found := botCommands[command]; found {
			return &cmd, true
		}
	}
	return nil, false
}

// ListCommands lists available commands for a bot or all bots
func (s *IRCBotSyntax) ListCommands(bot string) map[string][]string {
	if bot != "" {
		result := make(map[string][]string)
		if commands, exists := s.AllCommands[strings.ToLower(bot)]; exists {
			keys := make([]string, 0, len(commands))
			for key := range commands {
				keys = append(keys, key)
			}
			result[bot] = keys
		}
		return result
	}

	result := make(map[string][]string)
	for k, v := range s.AllCommands {
		keys := make([]string, 0, len(v))
		for key := range v {
			keys = append(keys, key)
		}
		result[k] = keys
	}
	return result
}

// GenerateScriptTemplate generates a script template for a bot
func (s *IRCBotSyntax) GenerateScriptTemplate(bot, purpose string) string {
	purposeUnderscored := strings.ReplaceAll(purpose, " ", "_")
	purposeTitle := strings.Title(strings.ReplaceAll(purpose, " ", ""))

	templates := map[string]string{
		"pbot": fmt.Sprintf(`# pbot applet - %s
# Place in ~/.pbot/applets/

use strict;
use warnings;

sub %s {
    my ($self, $from, $to, $args) = @_;
    
    # Your code here
    return "Result: $args";
}

1;
`, purpose, purposeUnderscored),
		"limnoria": fmt.Sprintf(`# Limnoria plugin - %s
# Place in plugins/%s/

from supybot import utils, plugins, ircutils, callbacks
from supybot.commands import *

class %s(callbacks.Plugin):
    """%s"""
    
    threaded = True
    
    def %s(self, irc, msg, args):
        """<args>"""
        irc.reply("Hello from %s!")
    
Class = %s
`, purpose, purposeTitle, purposeTitle, purpose, purposeUnderscored, purpose, purposeTitle),
		"eggdrop": fmt.Sprintf(`# Eggdrop Tcl script - %s
# Add to eggdrop.conf: source scripts/%s.tcl

proc %s {nick uhost hand chan arg} {
    putserv "PRIVMSG $chan :Hello $nick, this is %s!"
}

bind pub - !%s %s
`, purpose, purposeUnderscored, purposeUnderscored, purpose, purposeUnderscored, purposeUnderscored),
	}

	if template, exists := templates[strings.ToLower(bot)]; exists {
		return template
	}
	return "# Unknown bot"
}

// Helper function to create pointer to string
func stringPtr(s string) *string {
	return &s
}

func main() {
	var bot, command, template string
	var list bool

	flag.StringVar(&bot, "bot", "", "Bot type (pbot, limnoria, eggdrop)")
	flag.StringVar(&command, "command", "", "Command to look up")
	flag.BoolVar(&list, "list", false, "List all commands")
	flag.StringVar(&template, "template", "", "Generate script template for purpose")
	flag.Parse()

	if bot == "" {
		fmt.Println("Error: --bot is required")
		os.Exit(1)
	}

	syntax := NewIRCBotSyntax()

	if list {
		commands := syntax.ListCommands(bot)
		jsonData, _ := json.MarshalIndent(commands, "", "  ")
		fmt.Println(string(jsonData))
	} else if command != "" {
		cmd, found := syntax.GetCommand(bot, command)
		if found {
			fmt.Printf("Bot: %s\n", cmd.Bot)
			fmt.Printf("Command: %s\n", cmd.Command)
			fmt.Printf("Syntax: %s\n", cmd.Syntax)
			fmt.Printf("Example: %s\n", cmd.Example)
			fmt.Printf("Description: %s\n", cmd.Description)
			if cmd.Permission != nil {
				fmt.Printf("Permission: %s\n", *cmd.Permission)
			}
		} else {
			fmt.Printf("Command not found: %s\n", command)
			fmt.Println("Available commands:")
			cmds := syntax.ListCommands(bot)
			jsonData, _ := json.MarshalIndent(cmds, "", "  ")
			fmt.Println(string(jsonData))
		}
	} else if template != "" {
		tmpl := syntax.GenerateScriptTemplate(bot, template)
		fmt.Println(tmpl)
	}
}
