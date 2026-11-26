#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "ba3851d95b0374fa60d1a492c894d6c208cb329875df9a9c0b6478d8a8ab0a18", "source_sha256": "a137d03b3b37332439a1592831d60479ff86315c7e6d6ed7da0fb799db0f13f7", "target_language": "perl5"}
# find-sessions.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
# auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use POSIX qw(strftime);

my $usage = <<'USAGE';
Usage: find-sessions.sh [-L socket-name|-S socket-path|-A] [-q pattern]

List tmux sessions on a socket (default tmux socket if none provided).

Options:
  -L, --socket       tmux socket name (passed to tmux -L)
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
  -q, --query        case-insensitive substring to filter session names
  -h, --help         show this help
USAGE

my ($socket_name, $socket_path, $query);
my $scan_all = 0;
my $help = 0;

GetOptions(
    'socket|L=s' => \$socket_name,
    'socket-path|S=s' => \$socket_path,
    'all|A' => \$scan_all,
    'query|q=s' => \$query,
    'help|h' => \$help,
) or die "Invalid options\n$usage";

if ($help) {
    print $usage;
    exit 0;
}

my $socket_dir = $ENV{CLAWDBOT_TMUX_SOCKET_DIR} // ($ENV{TMPDIR} // '/tmp') . '/clawdbot-tmux-sockets';

if ($scan_all && ($socket_name || $socket_path)) {
    die "Cannot combine --all with -L or -S\n";
}

if ($socket_name && $socket_path) {
    die "Use either -L or -S, not both\n";
}

# Check if tmux is available
system('which tmux > /dev/null 2>&1') == 0
    or die "tmux not found in PATH\n";

sub list_sessions {
    my ($label, @tmux_args) = @_;
    
    my @cmd = ('tmux', @tmux_args, 'list-sessions', '-F', '#{session_name}\t#{session_attached}\t#{session_created_string}');
    
    # Capture output and errors
    my $output = `@cmd 2>/dev/null`;
    my $exit_code = $? >> 8;
    
    if ($exit_code != 0) {
        warn "No tmux server found on $label\n";
        return 1;
    }
    
    # Filter by query if provided
    if ($query) {
        my @lines = split /\n/, $output;
        my @filtered_lines = grep { index(lc($_), lc($query)) >= 0 } @lines;
        $output = join("\n", @filtered_lines) . "\n";
    }
    
    chomp $output;
    
    if (!$output) {
        print "No sessions found on $label\n";
        return 0;
    }
    
    print "Sessions on $label:\n";
    
    my @lines = split /\n/, $output;
    foreach my $line (@lines) {
        chomp $line;
        my ($name, $attached, $created) = split /\t/, $line;
        
        my $attached_label = ($attached eq "1") ? "attached" : "detached";
        printf '  - %s (%s, started %s)%s', $name, $attached_label, $created, "\n";
    }
    
    return 0;
}

if ($scan_all) {
    if (!-d $socket_dir) {
        die "Socket directory not found: $socket_dir\n";
    }
    
    opendir(my $dh, $socket_dir) or die "Cannot open directory $socket_dir: $!\n";
    my @sockets = readdir($dh);
    closedir($dh);
    
    @sockets = map { File::Spec->catfile($socket_dir, $_) } grep { !/^\.\.?$/ } @sockets;
    
    if (@sockets == 0) {
        die "No sockets found under $socket_dir\n";
    }
    
    my $exit_code = 0;
    foreach my $sock (@sockets) {
        if (-S $sock) {
            my $result = list_sessions("socket path '$sock'", '-S', $sock);
            $exit_code = $result if $result != 0;
        }
    }
    exit $exit_code;
}

my @tmux_cmd = ();
my $socket_label = "default socket";

if ($socket_name) {
    push @tmux_cmd, '-L', $socket_name;
    $socket_label = "socket name '$socket_name'";
} elsif ($socket_path) {
    push @tmux_cmd, '-S', $socket_path;
    $socket_label = "socket path '$socket_path'";
}

list_sessions($socket_label, @tmux_cmd);
