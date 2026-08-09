#!/usr/bin/env perl
# find-sessions.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
# auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

my $socket_name = "";
my $socket_path = "";
my $query = "";
my $scan_all = 0;
my $help = 0;

my $socket_dir = $ENV{CLAWDBOT_TMUX_SOCKET_DIR} || ($ENV{TMPDIR} || "/tmp") . "/clawdbot-tmux-sockets";

GetOptions(
    "socket|L=s"      => \$socket_name,
    "socket-path|S=s" => \$socket_path,
    "all|A"           => \$scan_all,
    "query|q=s"       => \$query,
    "help|h"          => \$help,
) or pod2usage(2);

if ($help) {
    usage();
    exit 0;
}

if ($scan_all && ($socket_name || $socket_path)) {
    print STDERR "Cannot combine --all with -L or -S\n";
    exit 1;
}

if ($socket_name && $socket_path) {
    print STDERR "Use either -L or -S, not both\n";
    exit 1;
}

unless (qx(which tmux 2>/dev/null)) {
    print STDERR "tmux not found in PATH\n";
    exit 1;
}

sub list_sessions {
    my ($label, @tmux_args) = @_;
    my @tmux_cmd = ("tmux", @tmux_args);

    my $sessions_output = `@tmux_cmd list-sessions -F '\#{session_name}\t\#{session_attached}\t\#{session_created_string}' 2>/dev/null`;
    my $exit_code = $?;

    if ($exit_code != 0) {
        print STDERR "No tmux server found on $label\n";
        return 1;
    }

    my @sessions = split /\n/, $sessions_output;
    chomp @sessions;

    if ($query) {
        @sessions = grep { index(lc($_), lc($query)) != -1 } @sessions;
    }

    if (@sessions == 0) {
        print "No sessions found on $label\n";
        return 0;
    }

    print "Sessions on $label:\n";
    for my $session (@sessions) {
        my ($name, $attached, $created) = split /\t/, $session;
        my $attached_label = ($attached == 1) ? "attached" : "detached";
        printf '  - %s (%s, started %s)' . "\n", $name, $attached_label, $created;
    }

    return 0;
}

if ($scan_all) {
    unless (-d $socket_dir) {
        print STDERR "Socket directory not found: $socket_dir\n";
        exit 1;
    }

    opendir(my $dh, $socket_dir) or die "Could not open directory '$socket_dir': $!";
    my @sockets = map { "$socket_dir/$_" } grep { -S "$socket_dir/$_" } readdir($dh);
    closedir $dh;

    if (@sockets == 0) {
        print STDERR "No sockets found under $socket_dir\n";
        exit 1;
    }

    my $exit_code = 0;
    for my $sock (@sockets) {
        my $result = list_sessions("socket path '$sock'", "-S", $sock);
        $exit_code = $result if $result != 0;
    }
    exit $exit_code;
}

my @tmux_cmd = ("tmux");
my $socket_label = "default socket";

if ($socket_name) {
    push @tmux_cmd, "-L", $socket_name;
    $socket_label = "socket name '$socket_name'";
} elsif ($socket_path) {
    push @tmux_cmd, "-S", $socket_path;
    $socket_label = "socket path '$socket_path'";
}

list_sessions($socket_label, @tmux_cmd[1..$#tmux_cmd]);

sub usage {
    print <<'USAGE';
Usage: find-sessions.sh [-L socket-name|-S socket-path|-A] [-q pattern]

List tmux sessions on a socket (default tmux socket if none provided).

Options:
  -L, --socket       tmux socket name (passed to tmux -L)
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
  -q, --query        case-insensitive substring to filter session names
  -h, --help         show this help
USAGE
}

__END__

=head1 NAME

find-sessions.pl - List tmux sessions on a socket

=head1 SYNOPSIS

find-sessions.pl [options]

 Options:
   -L, --socket       tmux socket name (passed to tmux -L)
   -S, --socket-path  tmux socket path (passed to tmux -S)
   -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
   -q, --query        case-insensitive substring to filter session names
   -h, --help         show this help

=cut
