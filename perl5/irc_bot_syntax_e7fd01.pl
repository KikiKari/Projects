#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "d2056c7f3acccb07a99b71bdd64c64ca2ccdd68b98d1ba67d3956e481ce63c5d", "source_sha256": "e7fd0186c81e698f59895dc87d98d60489bddd55b4ee6f4ba864c23613d06f6b", "target_language": "perl5"}
# irc_bot_syntax.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/irc_bot_syntax.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/irc_bot_syntax.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;

# IRC Bot command syntax reference.
# Sources:
# - pbot: https://github.com/pragma-/pbot
# - Limnoria: https://docs.limnoria.net/
# - Eggdrop: https://docs.eggheads.org/

package BotCommand;
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

package IRCBotSyntax;

sub new {
    my $class = shift;
    my $self = {};

    # Define pbot commands
    $self->{PBOT_COMMANDS} = {
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
    };

    # Define limnoria commands
    $self->{LIMNORIA_COMMANDS} = {
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
    };

    # Define eggdrop commands
    $self->{EGGDROP_COMMANDS} = {
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
    };

    # All commands grouped by bot
    $self->{ALL_COMMANDS} = {
        "pbot"      => $self->{PBOT_COMMANDS},
        "limnoria"  => $self->{LIMNORIA_COMMANDS},
        "eggdrop"   => $self->{EGGDROP_COMMANDS},
    };

    bless $self, $class;
    return $self;
}

# Get command syntax for a specific bot
sub get_command {
    my ($self, $bot, $command) = @_;
    $bot = lc($bot);
    $command = lc($command);

    my $bot_commands = $self->{ALL_COMMANDS}{$bot} || {};
    return $bot_commands->{$command};
}

# List available commands for a bot or all bots
sub list_commands {
    my ($self, $bot) = @_;
    if (defined $bot) {
        my $commands = $self->{ALL_COMMANDS}{lc($bot)} || {};
        return { $bot => [sort keys %$commands] };
    } else {
        my $result = {};
        for my $b (keys %{$self->{ALL_COMMANDS}}) {
            $result->{$b} = [sort keys %{$self->{ALL_COMMANDS}{$b}}];
        }
        return $result;
    }
}

# Generate a script template for a bot
sub generate_script_template {
    my ($self, $bot, $purpose) = @_;
    $bot = lc($bot);

    if ($bot eq "pbot") {
        my $safe_purpose = $purpose;
        $safe_purpose =~ s/\s+/_/g;
        return <<"EOF";
# pbot applet - $purpose
# Place in ~/.pbot/applets/

use strict;
use warnings;

sub $safe_purpose {
    my (\$self, \$from, \$to, \$args) = \@_;
    
    # Your code here
    return "Result: \$args";
}

1;
EOF
    } elsif ($bot eq "limnoria") {
        my $safe_purpose = $purpose;
        $safe_purpose =~ s/\s+//g;
        my $title_case = ucfirst(lc($safe_purpose));
        return <<"EOF";
# Limnoria plugin - $purpose
# Place in plugins/${safe_purpose}/

from supybot import utils, plugins, ircutils, callbacks
from supybot.commands import *

class ${title_case}(callbacks.Plugin):
    \"\"\"$purpose\"\"\"
    
    threaded = True
    
    def ${\lc($safe_purpose)}(self, irc, msg, args):
        \"\"\"<args>\"\"\"
        irc.reply("Hello from $purpose!")
    
Class = $title_case
EOF
    } elsif ($bot eq "eggdrop") {
        my $safe_purpose = $purpose;
        $safe_purpose =~ s/\s+/_/g;
        return <<"EOF";
# Eggdrop Tcl script - $purpose
# Add to eggdrop.conf: source scripts/${safe_purpose}.tcl

proc $safe_purpose {nick uhost hand chan arg} {
    putserv "PRIVMSG \$chan :Hello \$nick, this is $purpose!"
}

bind pub - !$safe_purpose $safe_purpose
EOF
    } else {
        return "# Unknown bot";
    }
}

# Main function
sub main {
    use Getopt::Long;
    use Pod::Usage;

    my %args = (
        bot      => '',
        command  => undef,
        list     => 0,
        template => undef,
        help     => 0,
    );

    GetOptions(
        'bot=s'      => \$args{bot},
        'command=s'  => \$args{command},
        'list'       => \$args{list},
        'template=s' => \$args{template},
        'help'       => \$args{help},
    ) or pod2usage(2);

    pod2usage(1) if $args{help};

    unless ($args{bot}) {
        print STDERR "Error: --bot is required\n";
        exit 1;
    }

    my $syntax = IRCBotSyntax->new();

    if ($args{list}) {
        my $commands = $syntax->list_commands($args{bot});
        print to_json($commands, { pretty => 1 });
    } elsif ($args{command}) {
        my $cmd = $syntax->get_command($args{bot}, $args{command});
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
            print "Command not found: $args{command}\n";
            print "Available commands:\n";
            my $cmds = $syntax->list_commands($args{bot});
            print to_json($cmds, { pretty => 1 });
        }
    } elsif ($args{template}) {
        my $template = $syntax->generate_script_template($args{bot}, $args{template});
        print $template;
    }
}

main() unless caller;

1;

__END__

=head1 NAME

irc_bot_syntax.pl - IRC Bot command syntax reference

=head1 SYNOPSIS

irc_bot_syntax.pl --bot <bot> [--command <command>] [--list] [--template <purpose>]

=head1 OPTIONS

=over 4

=item B<--bot>

Specify the bot type (pbot, limnoria, eggdrop)

=item B<--command>

Look up syntax for a specific command

=item B<--list>

List all commands for the specified bot

=item B<--template>

Generate script template for a given purpose

=back

=cut
