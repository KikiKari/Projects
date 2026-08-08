#!/usr/bin/perl
# TelegramMonitorCompanion.ps1 — portiert nach perl5
# Quelle: powershell, Projects@Telegram-Monitor:TelegramMonitorCompanion.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use File::Path qw(make_path);
use File::Slurp qw(read_file write_file);
use Config;
use HTTP::Tiny;
use Time::HiRes qw(sleep);
use Cwd qw(abs_path);
use FindBin qw($RealBin);

# Telegram Monitor Companion — Starter
#
# Startet den lokalen Monitor im Hintergrund (kein Konsolenfenster), wartet,
# bis der Port wirklich antwortet, und oeffnet die Oberflaeche als eigenes
# Fenster ohne Adressleiste. Laeuft der Monitor schon, wird er nicht erneut
# gestartet — dann wird nur das Fenster geoeffnet.
#
# Aufruf:
#   perl TelegramMonitorCompanion.pl              starten und oeffnen
#   perl TelegramMonitorCompanion.pl --stop        beenden
#   perl TelegramMonitorCompanion.pl --status      nachsehen, ob er laeuft
#   perl TelegramMonitorCompanion.pl --port 9000   anderer Port
#   perl TelegramMonitorCompanion.pl --console     mit sichtbarem Fenster (Fehlersuche)

my $port     = 8765;
my $interval = 120;
my $stop     = 0;
my $status   = 0;
my $console  = 0;
my $no_browser = 0;

GetOptions(
    'port=i'     => \$port,
    'interval=i' => \$interval,
    'stop'       => \$stop,
    'status'     => \$status,
    'console'    => \$console,
    'no-browser' => \$no_browser,
) or die "Ungueltige Optionen\n";

my $root     = $RealBin;
my $pid_file = File::Spec->catfile($root, 'data', 'companion.pid');
my $log_file = File::Spec->catfile($root, 'data', 'companion.log');
my $url      = "http://127.0.0.1:$port";

sub write_step {
    my ($msg) = @_;
    print "  $msg\n";
}

sub test_monitor {
    my $http = HTTP::Tiny->new(timeout => 2);
    my $response = $http->get("$url/api/status");
    return $response->{success} && $response->{status} == 200;
}

sub get_monitor_process {
    return unless -f $pid_file;
    my $content = read_file($pid_file);
    chomp $content;
    return unless $content =~ /^\d+$/;
    my $pid = $content;
    # Prüfen, ob der Prozess existiert
    if ($^O eq 'MSWin32') {
        my $output = `tasklist /fi "PID eq $pid" 2>nul`;
        return $output =~ /\b$pid\b/ ? $pid : undef;
    } else {
        return kill(0, $pid) ? $pid : undef;
    }
}

# ---------------------------------------------------------------- beenden ---
if ($stop) {
    my $pid = get_monitor_process();
    if ($pid) {
        if ($^O eq 'MSWin32') {
            system("taskkill /F /PID $pid >nul 2>&1");
        } else {
            kill('TERM', $pid);
        }
        write_step("Monitor beendet (PID $pid).");
    } else {
        write_step('Es lief kein Monitor aus diesem Starter.');
    }
    unlink $pid_file if -f $pid_file;
    exit 0;
}

# ----------------------------------------------------------------- Status ---
if ($status) {
    if (test_monitor()) {
        my $pid = get_monitor_process();
        my $msg = "Monitor laeuft auf $url";
        $msg .= "  (PID $pid)" if $pid;
        write_step($msg);
    } else {
        write_step("Auf $url antwortet nichts.");
    }
    exit 0;
}

# ------------------------------------------------------------------ Start ---
print "\n";
print "  Telegram Monitor Companion\n";
print "  --------------------------\n";

# Python suchen: erst py-Starter, dann python im Pfad.
my ($exe, @pre);
for my $candidate (
    { e => 'py',     a => ['-3'] },
    { e => 'python', a => [] },
    { e => 'python3', a => [] }
) {
    my $cmd = $candidate->{e};
    my @args = @{$candidate->{a}};
    # Prüfen, ob das Kommando existiert
    my $found = 0;
    if ($^O eq 'MSWin32') {
        $found = `where $cmd 2>nul`;
    } else {
        $found = `which $cmd 2>/dev/null`;
    }
    if ($found) {
        $exe = $cmd;
        @pre = @args;
        last;
    }
}

if (!$exe) {
    print "\n";
    print "  Python wurde nicht gefunden.\n";
    print "  Herunterladen: https://www.python.org/downloads/\n";
    print "  Beim Installieren \"Add python.exe to PATH\" ankreuzen.\n";
    print "\n";
    print "  Eingabetaste zum Schliessen\n";
    <STDIN>;
    exit 1;
}
write_step("Python: $exe " . join(' ', @pre));

if (test_monitor()) {
    write_step("Monitor laeuft bereits auf $url — wird nicht erneut gestartet.");
} else {
    make_path(File::Spec->catdir($root, 'data')) unless -d File::Spec->catdir($root, 'data');

    my @args = (@pre, 'server.py', '--port', $port, '--poll-interval', $interval, '--no-browser');

    my $pid;
    if ($console) {
        # Starte mit sichtbarem Fenster
        my $cmd = join(' ', $exe, @args);
        $pid = fork();
        if (!defined $pid) {
            die "Fehler beim Forken: $!";
        } elsif ($pid == 0) {
            # Kindprozess
            chdir($root) or die "chdir failed: $!";
            exec($cmd) or die "exec failed: $!";
        }
        # Elternprozess
    } else {
        # Ohne Fenster, Ausgabe in die Protokolldatei
        my $cmd = join(' ', $exe, @args);
        my $stdout_log = $log_file;
        my $stderr_log = "$log_file.err";
        $pid = fork();
        if (!defined $pid) {
            die "Fehler beim Forken: $!";
        } elsif ($pid == 0) {
            # Kindprozess
            chdir($root) or die "chdir failed: $!";
            open(STDOUT, '>', $stdout_log) or die "Kann $stdout_log nicht oeffnen: $!";
            open(STDERR, '>', $stderr_log) or die "Kann $stderr_log nicht oeffnen: $!";
            exec($cmd) or die "exec failed: $!";
        }
        # Elternprozess
    }

    # PID speichern
    write_file($pid_file, "$pid\n");
    write_step("Gestartet (PID $pid), warte auf Antwort ...");

    my $ok = 0;
    for my $i (1..40) {
        sleep(0.5);
        if (test_monitor()) {
            $ok = 1;
            last;
        }
        # Prüfen, ob der Prozess noch läuft
        if ($^O eq 'MSWin32') {
            my $output = `tasklist /fi "PID eq $pid" 2>nul`;
            last unless $output =~ /\b$pid\b/;
        } else {
            last unless kill(0, $pid);
        }
    }

    if (!$ok) {
        print "\n";
        print "  Der Monitor hat nicht geantwortet.\n";
        my $stderr_log = "$log_file.err";
        if (-f $stderr_log) {
            print "  Letzte Zeilen der Fehlerausgabe:\n";
            open my $fh, '<', $stderr_log or die "Kann $stderr_log nicht oeffnen: $!";
            my @lines = <$fh>;
            close $fh;
            @lines = @lines[-15..-1] if @lines > 15;
            for my $line (@lines) {
                chomp $line;
                print "    $line\n";
            }
        }
        print "\n";
        print "  Nochmal mit sichtbarem Fenster:  perl TelegramMonitorCompanion.pl --console\n";
        print "  Eingabetaste zum Schliessen\n";
        <STDIN>;
        exit 1;
    }
    write_step('Antwortet.');
}

if ($no_browser) {
    write_step("Bereit: $url");
    exit 0;
}

# Als eigenes Fenster oeffnen (App-Modus), sonst normaler Tab.
my $edge   = "$ENV{ProgramFiles}\\Microsoft\\Edge\\Application\\msedge.exe";
my $chrome = "$ENV{ProgramFiles(x86)}\\Google\\Chrome\\Application\\chrome.exe";

if (-f $edge) {
    system("start", "", "\"$edge\"", "--app=$url");
    write_step('Als eigenes Fenster geoeffnet (Edge).');
} elsif (-f $chrome) {
    system("start", "", "\"$chrome\"", "--app=$url");
    write_step('Als eigenes Fenster geoeffnet (Chrome).');
} else {
    system("start", "", $url);
    write_step('Im Standardbrowser geoeffnet.');
}

print "\n";
print "  Laeuft im Hintergrund auf $url\n";
print "  Beenden:  perl TelegramMonitorCompanion.pl --stop\n";
print "\n";
