#!/usr/bin/perl
# irc_bot_syntax.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;

# IRC Bot command syntax reference.
# Sources:
# - pbot: https://github.com/pragma-/pbot
# - Limnoria: https://docs.limnoria.net/
# - Eggdrop: https://docs.eggheads.org/

package BotCommand {
    sub new {
        my ($class, %args) = @_;
        my $self = {
            bot         => $args{bot},
            command     => $args{command},
            syntax      => $args{syntax},
            example     => $args{example},
            description => $args{description},
            permission  => $args{permission} // undef,
        };
        bless $self, $class;
        return $self;
    }
}

package IRCBotSyntax {
    # pbot commands
    my %PBOT_COMMANDS = (
        "keyword add" => BotCommand->new(
            bot         => "pbot",
            command     => "keyword add",
            syntax      => "keyword add <keyword> <text>",
            example     => "keyword add hello Hello, World!",
            description => "Add a keyword trigger",
            permission  => "admin"
        ),
        "fact add" => BotCommand->new(
            bot         => "pbot",
            command     => "fact add",
            syntax      => "fact add <channel> <subject> <text>",
            example     => "fact add #channel python Python is a programming language",
            description => "Add a factoid",
            permission  => " whitelisted"
        ),
        "ban" => BotCommand->new(
            bot         => "pbot",
            command     => "ban",
            syntax      => "ban <nick|mask> [duration] [reason]",
            example     => "ban spambot 1h Spamming",
            description => "Ban a user",
            permission  => "op"
        ),
    );
    
    # Limnoria commands
    my %LIMNORIA_COMMANDS = (
        "config channel" => BotCommand->new(
            bot         => "limnoria",
            command     => "config channel",
            syntax      => "config channel <#channel> <plugin>.<variable> <value>",
            example     => "config channel #bot supybot.plugins.Channel.enabled True",
            description => "Configure channel-specific settings",
            permission  => "admin"
        ),
        "load" => BotCommand->new(
            bot         => "limnoria",
            command     => "load",
            syntax      => "load <plugin>",
            example     => "load User",
            description => "Load a plugin",
            permission  => "owner"
        ),
        "aka add" => BotCommand->new(
            bot         => "limnoria",
            command     => "aka add",
            syntax      => "aka add <name> <command>",
            example     => "aka add hi say Hello \$nick!",
            description => "Create command alias",
            permission  => "admin"
        ),
    );
    
    # Eggdrop commands
    my %EGGDROP_COMMANDS = (
        "bind" => BotCommand->new(
            bot         => "eggdrop",
            command     => "bind",
            syntax      => "bind <type> <flags> <keyword> <proc>",
            example     => "bind pub - !hello pub_hello",
            description => "Bind a command to a Tcl procedure",
            permission  => "n/a (script)"
        ),
        "putserv" => BotCommand->new(
            bot         => "eggdrop",
            command     => "putserv",
            syntax      => "putserv <text>",
            example     => "putserv PRIVMSG #channel :Hello World",
            description => "Send raw IRC command",
            permission  => "n/a (script)"
        ),
        "setudef" => BotCommand->new(
            bot         => "eggdrop",
            command     => "setudef",
            syntax      => "setudef <type> <name>",
            example     => "setudef str bot_setting",
            description => "Define user-defined variable",
            permission  => "n/a (script)"
        ),
    );
    
    my %ALL_COMMANDS = (
        "pbot"      => \%PBOT_COMMANDS,
        "limnoria"  => \%LIMNORIA_COMMANDS,
        "eggdrop"   => \%EGGDROP_COMMANDS,
    );
    
    sub new {
        my ($class) = @_;
        my $self = {
            all_commands => \%ALL_COMMANDS,
        };
        bless $self, $class;
        return $self;
    }
    
    # Get command syntax for a specific bot
    sub get_command {
        my ($self, $bot, $command) = @_;
        $bot = lc($bot);
        $command = lc($command);
        
        my $bot_commands = $self->{all_commands}->{$bot} // {};
        return $bot_commands->{$command};
    }
    
    # List available commands for a bot or all bots
    sub list_commands {
        my ($self, $bot) = @_;
        if (defined $bot) {
            my $commands = $self->{all_commands}->{lc($bot)} // {};
            return { $bot => [keys %$commands] };
        }
        my %result;
        for my $b (keys %{$self->{all_commands}}) {
            $result{$b} = [keys %{$self->{all_commands}->{$b}}];
        }
        return \%result;
    }
    
    # Generate a script template for a bot
    sub generate_script_template {
        my ($self, $bot, $purpose) = @_;
        $bot = lc($bot);
        
        if ($bot eq "pbot") {
            my $template = "# pbot applet - $purpose\n";
            $template .= "# Place in ~/.pbot/applets/\n\n";
            $template .= "use strict;\nuse warnings;\n\n";
            $template .= "sub " . lc($purpose) =~ s/\s+/_/gr . " {\n";
            $template .= "    my (\$self, \$from, \$to, \$args) = \@_;\n\n";
            $template .= "    # Your code here\n";
            $template .= "    return \"Result: \$args\";\n";
            $template .= "}\n\n1;\n";
            return $template;
        }
        elsif ($bot eq "limnoria") {
            my $class_name = $purpose =~ s/\s+//gr;
            $class_name = ucfirst($class_name);
            my $method_name = lc($purpose) =~ s/\s+/_/gr;
            
            my $template = "# Limnoria plugin - $purpose\n";
            $template .= "# Place in plugins/${class_name}/\n\n";
            $template .= "from supybot import utils, plugins, ircutils, callbacks\n";
            $template .= "from supybot.commands import *\n\n";
            $template .= "class ${class_name}(callbacks.Plugin):\n";
            $template .= "    \"\"\"$purpose\"\"\"\n\n";
            $template .= "    threaded = True\n\n";
            $template .= "    def ${method_name}(self, irc, msg, args):\n";
            $template .= "        \"\"\"<args>\"\"\"\n";
            $template .= "        irc.reply(\"Hello from $purpose!\")\n\n";
            $template .= "Class = $class_name\n";
            return $template;
        }
        elsif ($bot eq "eggdrop") {
            my $proc_name = lc($purpose) =~ s/\s+/_/gr;
            
            my $template = "# Eggdrop Tcl script - $purpose\n";
            $template .= "# Add to eggdrop.conf: source scripts/${proc_name}.tcl\n\n";
            $template .= "proc $proc_name {nick uhost hand chan arg} {\n";
            $template .= "    putserv \"PRIVMSG \$chan :Hello \$nick, this is $purpose!\"\n";
            $template .= "}\n\n";
            $template .= "bind pub - !$proc_name $proc_name\n";
            return $template;
        }
        else {
            return "# Unknown bot";
        }
    }
}

# Main function
sub main {
    use Getopt::Long;
    
    my $bot;
    my $command;
    my $list = 0;
    my $template;
    
    GetOptions(
        "bot=s"      => \$bot,
        "command=s"  => \$command,
        "list"       => \$list,
        "template=s" => \$template,
    ) or die "Error in command line arguments\n";
    
    die "Bot is required\n" unless defined $bot;
    die "Invalid bot: $bot\n" unless $bot =~ /^(pbot|limnoria|eggdrop)$/i;
    
    my $syntax = IRCBotSyntax->new();
    
    if ($list) {
        my $commands = $syntax->list_commands($bot);
        print to_json($commands, { pretty => 1 });
    }
    elsif (defined $command) {
        my $cmd = $syntax->get_command($bot, $command);
        if ($cmd) {
            print "Bot: " . $cmd->{bot} . "\n";
            print "Command: " . $cmd->{command} . "\n";
            print "Syntax: " . $cmd->{syntax} . "\n";
            print "Example: " . $cmd->{example} . "\n";
            print "Description: " . $cmd->{description} . "\n";
            if (defined $cmd->{permission}) {
                print "Permission: " . $cmd->{permission} . "\n";
            }
        } else {
            print "Command not found: $command\n";
            print "Available commands:\n";
            my $cmds = $syntax->list_commands($bot);
            print to_json($cmds, { pretty => 1 });
        }
    }
    elsif (defined $template) {
        my $tpl = $syntax->generate_script_template($bot, $template);
        print $tpl;
    }
}

main() if !caller;
