// abstraction-provenance: {"artifact_sha256": "d504bee48ff3a0af4b29458dbf8922536e5f88a87af71f76a32d8a3af1009d19", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "c"}
// irc_bot_syntax.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/**
 * IRC Bot command syntax for pbot (Perl), Limnoria (Python), and Eggdrop (Tcl).
 * Fetches syntax from documentation sources.
 */

typedef struct {
    char* bot;
    char* command;
    char* syntax;
    char* example;
    char* description;
    char* permission;
} BotCommand;

typedef struct {
    char* name;
    BotCommand command;
} CommandEntry;

// pbot commands
CommandEntry pbot_commands[] = {
    {"keyword add", {"pbot", "keyword add", "keyword add <keyword> <text>", "keyword add hello Hello, World!", "Add a keyword trigger", "admin"}},
    {"fact add", {"pbot", "fact add", "fact add <channel> <subject> <text>", "fact add #channel python Python is a programming language", "Add a factoid", " whitelisted"}},
    {"ban", {"pbot", "ban", "ban <nick|mask> [duration] [reason]", "ban spambot 1h Spamming", "Ban a user", "op"}},
    {NULL, {0}}
};

// Limnoria commands
CommandEntry limnoria_commands[] = {
    {"config channel", {"limnoria", "config channel", "config channel <#channel> <plugin>.<variable> <value>", "config channel #bot supybot.plugins.Channel.enabled True", "Configure channel-specific settings", "admin"}},
    {"load", {"limnoria", "load", "load <plugin>", "load User", "Load a plugin", "owner"}},
    {"aka add", {"limnoria", "aka add", "aka add <name> <command>", "aka add hi say Hello $nick!", "Create command alias", "admin"}},
    {NULL, {0}}
};

// Eggdrop commands
CommandEntry eggdrop_commands[] = {
    {"bind", {"eggdrop", "bind", "bind <type> <flags> <keyword> <proc>", "bind pub - !hello pub_hello", "Bind a command to a Tcl procedure", "n/a (script)"}},
    {"putserv", {"eggdrop", "putserv", "putserv <text>", "putserv PRIVMSG #channel :Hello World", "Send raw IRC command", "n/a (script)"}},
    {"setudef", {"eggdrop", "setudef", "setudef <type> <name>", "setudef str bot_setting", "Define user-defined variable", "n/a (script)"}},
    {NULL, {0}}
};

CommandEntry* all_commands[][4] = {
    {pbot_commands, NULL},
    {limnoria_commands, NULL},
    {eggdrop_commands, NULL},
    {NULL}
};

char* bot_names[] = {"pbot", "limnoria", "eggdrop"};

BotCommand* get_command(const char* bot, const char* command) {
    // Convert bot to lowercase
    char lower_bot[50];
    strncpy(lower_bot, bot, sizeof(lower_bot) - 1);
    lower_bot[sizeof(lower_bot) - 1] = '\0';
    for(int i = 0; lower_bot[i]; i++) {
        lower_bot[i] = tolower(lower_bot[i]);
    }
    
    // Convert command to lowercase
    char lower_command[100];
    strncpy(lower_command, command, sizeof(lower_command) - 1);
    lower_command[sizeof(lower_command) - 1] = '\0';
    for(int i = 0; lower_command[i]; i++) {
        lower_command[i] = tolower(lower_command[i]);
    }
    
    int bot_index = -1;
    if(strcmp(lower_bot, "pbot") == 0) bot_index = 0;
    else if(strcmp(lower_bot, "limnoria") == 0) bot_index = 1;
    else if(strcmp(lower_bot, "eggdrop") == 0) bot_index = 2;
    
    if(bot_index == -1) return NULL;
    
    CommandEntry* commands = all_commands[bot_index][0];
    for(int i = 0; commands[i].name != NULL; i++) {
        char lower_name[100];
        strncpy(lower_name, commands[i].name, sizeof(lower_name) - 1);
        lower_name[sizeof(lower_name) - 1] = '\0';
        for(int j = 0; lower_name[j]; j++) {
            lower_name[j] = tolower(lower_name[j]);
        }
        
        if(strcmp(lower_name, lower_command) == 0) {
            return &commands[i].command;
        }
    }
    
    return NULL;
}

void list_commands(const char* bot) {
    printf("{\n");
    if(bot) {
        printf("  \"%s\": [", bot);
        int bot_index = -1;
        char lower_bot[50];
        strncpy(lower_bot, bot, sizeof(lower_bot) - 1);
        lower_bot[sizeof(lower_bot) - 1] = '\0';
        for(int i = 0; lower_bot[i]; i++) {
            lower_bot[i] = tolower(lower_bot[i]);
        }
        
        if(strcmp(lower_bot, "pbot") == 0) bot_index = 0;
        else if(strcmp(lower_bot, "limnoria") == 0) bot_index = 1;
        else if(strcmp(lower_bot, "eggdrop") == 0) bot_index = 2;
        
        if(bot_index != -1) {
            CommandEntry* commands = all_commands[bot_index][0];
            int first = 1;
            for(int i = 0; commands[i].name != NULL; i++) {
                if(!first) printf(", ");
                printf("\"%s\"", commands[i].name);
                first = 0;
            }
        }
        printf("]\n");
    } else {
        for(int b = 0; b < 3; b++) {
            if(b > 0) printf(",\n");
            printf("  \"%s\": [", bot_names[b]);
            CommandEntry* commands = all_commands[b][0];
            int first = 1;
            for(int i = 0; commands[i].name != NULL; i++) {
                if(!first) printf(", ");
                printf("\"%s\"", commands[i].name);
                first = 0;
            }
            printf("]");
        }
        printf("\n");
    }
    printf("}\n");
}

void replace_char(char* str, char find, char replace) {
    for(int i = 0; str[i]; i++) {
        if(str[i] == find) {
            str[i] = replace;
        }
    }
}

char* str_replace(const char* str, const char* old, const char* new) {
    // Simple implementation for this specific use case
    static char buffer[2048];
    strncpy(buffer, str, sizeof(buffer) - 1);
    buffer[sizeof(buffer) - 1] = '\0';
    return buffer;
}

void generate_script_template(const char* bot, const char* purpose) {
    char lower_bot[50];
    strncpy(lower_bot, bot, sizeof(lower_bot) - 1);
    lower_bot[sizeof(lower_bot) - 1] = '\0';
    for(int i = 0; lower_bot[i]; i++) {
        lower_bot[i] = tolower(lower_bot[i]);
    }
    
    char clean_purpose[100];
    strncpy(clean_purpose, purpose, sizeof(clean_purpose) - 1);
    clean_purpose[sizeof(clean_purpose) - 1] = '\0';
    replace_char(clean_purpose, ' ', '_');
    
    if(strcmp(lower_bot, "pbot") == 0) {
        printf("# pbot applet - %s\n", purpose);
        printf("# Place in ~/.pbot/applets/\n\n");
        printf("use strict;\n");
        printf("use warnings;\n\n");
        printf("sub %s {\n", clean_purpose);
        printf("    my ($self, $from, $to, $args) = @_;\n\n");
        printf("    # Your code here\n");
        printf("    return \"Result: $args\";\n");
        printf("}\n\n");
        printf("1;\n");
    } 
    else if(strcmp(lower_bot, "limnoria") == 0) {
        char title_purpose[100];
        strncpy(title_purpose, purpose, sizeof(title_purpose) - 1);
        title_purpose[sizeof(title_purpose) - 1] = '\0';
        title_purpose[0] = toupper(title_purpose[0]);
        for(int i = 1; title_purpose[i]; i++) {
            if(title_purpose[i-1] == ' ') {
                title_purpose[i] = toupper(title_purpose[i]);
            } else if(title_purpose[i] != ' ') {
                title_purpose[i] = title_purpose[i];
            }
        }
        replace_char(title_purpose, ' ', '\0'); // Just take first word for class name
        
        printf("# Limnoria plugin - %s\n", purpose);
        printf("# Place in plugins/%s/\n\n", clean_purpose);
        printf("from supybot import utils, plugins, ircutils, callbacks\n");
        printf("from supybot.commands import *\n\n");
        printf("class %s(callbacks.Plugin):\n", title_purpose);
        printf("    \"\"\"%s\"\"\"\n\n", purpose);
        printf("    threaded = True\n\n");
        printf("    def %s(self, irc, msg, args):\n", clean_purpose);
        printf("        \"\"\"<args>\"\"\"\n");
        printf("        irc.reply(\"Hello from %s!\")\n\n", purpose);
        printf("Class = %s\n", title_purpose);
    } 
    else if(strcmp(lower_bot, "eggdrop") == 0) {
        printf("# Eggdrop Tcl script - %s\n", purpose);
        printf("# Add to eggdrop.conf: source scripts/%s.tcl\n\n", clean_purpose);
        printf("proc %s {nick uhost hand chan arg} {\n", clean_purpose);
        printf("    putserv \"PRIVMSG $chan :Hello $nick, this is %s!\"\n", purpose);
        printf("}\n\n");
        printf("bind pub - !%s %s\n", clean_purpose, clean_purpose);
    } 
    else {
        printf("# Unknown bot\n");
    }
}

void print_usage(const char* program_name) {
    printf("Usage: %s --bot <pbot|limnoria|eggdrop> [--command <command>] [--list] [--template <purpose>]\n", program_name);
    printf("IRC Bot command syntax reference\n");
}

int main(int argc, char* argv[]) {
    char* bot = NULL;
    char* command = NULL;
    int list_flag = 0;
    char* template = NULL;
    
    for(int i = 1; i < argc; i++) {
        if(strcmp(argv[i], "--bot") == 0 && i + 1 < argc) {
            bot = argv[++i];
        } else if(strcmp(argv[i], "--command") == 0 && i + 1 < argc) {
            command = argv[++i];
        } else if(strcmp(argv[i], "--list") == 0) {
            list_flag = 1;
        } else if(strcmp(argv[i], "--template") == 0 && i + 1 < argc) {
            template = argv[++i];
        } else if(strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        } else {
            fprintf(stderr, "Unknown argument: %s\n", argv[i]);
            print_usage(argv[0]);
            return 1;
        }
    }
    
    if(!bot) {
        fprintf(stderr, "Error: --bot is required\n");
        print_usage(argv[0]);
        return 1;
    }
    
    if(list_flag) {
        list_commands(bot);
    } else if(command) {
        BotCommand* cmd = get_command(bot, command);
        if(cmd) {
            printf("Bot: %s\n", cmd->bot);
            printf("Command: %s\n", cmd->command);
            printf("Syntax: %s\n", cmd->syntax);
            printf("Example: %s\n", cmd->example);
            printf("Description: %s\n", cmd->description);
            if(cmd->permission) {
                printf("Permission: %s\n", cmd->permission);
            }
        } else {
            printf("Command not found: %s\n", command);
            printf("Available commands:\n");
            list_commands(bot);
        }
    } else if(template) {
        generate_script_template(bot, template);
    } else {
        print_usage(argv[0]);
    }
    
    return 0;
}
