#!/usr/bin/perl
# wait-for-text.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/wait-for-text.sh
# auch in: OpenClaw@gateway2:skills/tmux/scripts/wait-for-text.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

my $target = "";
my $pattern = "";
my $grep_flag = "-E";
my $timeout = 15;
my $interval = 0.5;
my $lines = 1000;
my $help = 0;

GetOptions(
    'target|t=s'   => \$target,
    'pattern|p=s'  => \$pattern,
    'fixed|F'      => sub { $grep_flag = "-F" },
    'timeout|T=i'  => \$timeout,
    'interval|i=f' => \$interval,
    'lines|l=i'    => \$lines,
    'help|h'       => \$help,
) or pod2usage(2);

pod2usage(0) if $help;

if (!$target || !$pattern) {
    print STDERR "target and pattern are required\n";
    pod2usage(1);
}

# End time in epoch seconds (integer, good enough for polling)
my $start_epoch = time();
my $deadline = $start_epoch + $timeout;

while (1) {
    # -J joins wrapped lines, -S uses negative index to read last N lines
    my $pane_text = `tmux capture-pane -p -J -t "$target" -S "-$lines" 2>/dev/null` // "";

    my $found = 0;
    if ($grep_flag eq "-F") {
        # Fixed string search
        for my $line (split /\n/, $pane_text) {
            if (index($line, $pattern) != -1) {
                $found = 1;
                last;
            }
        }
    } else {
        # Regex search
        my $re_pattern = $pattern;
        $re_pattern =~ s/\\/\\\\/g;
        $re_pattern =~ s/\$/\\\$/g;
        $re_pattern =~ s/\^/\\\^/g;
        $re_pattern =~ s/\./\\\./g;
        $re_pattern =~ s/\[/\\\[/g;
        $re_pattern =~ s/\]/\\\]/g;
        $re_pattern =~ s/\(/\\\(/g;
        $re_pattern =~ s/\)/\\\)/g;
        $re_pattern =~ s/\{/\\\{/g;
        $re_pattern =~ s/\}/\\\}/g;
        $re_pattern =~ s/\|/\\\|/g;
        $re_pattern =~ s/\+/\\\+/g;
        $re_pattern =~ s/\*/\\\*/g;
        $re_pattern =~ s/\?/\\\?/g;
        for my $line (split /\n/, $pane_text) {
            if ($line =~ /$re_pattern/) {
                $found = 1;
                last;
            }
        }
    }

    if ($found) {
        exit 0;
    }

    my $now = time();
    if ($now >= $deadline) {
        print STDERR "Timed out after ${timeout}s waiting for pattern: $pattern\n";
        print STDERR "Last ${lines} lines from $target:\n";
        print STDERR $pane_text;
        exit 1;
    }

    select(undef, undef, undef, $interval);
}

__END__

=head1 SYNOPSIS

wait-for-text.pl -t target -p pattern [options]

Poll a tmux pane for text and exit when found.

=head1 OPTIONS

=over 4

=item B<-t, --target>

tmux target (session:window.pane), required

=item B<-p, --pattern>

regex pattern to look for, required

=item B<-F, --fixed>

treat pattern as a fixed string (grep -F)

=item B<-T, --timeout>

seconds to wait (integer, default: 15)

=item B<-i, --interval>

poll interval in seconds (default: 0.5)

=item B<-l, --lines>

number of history lines to inspect (integer, default: 1000)

=item B<-h, --help>

show this help

=back

=cut
