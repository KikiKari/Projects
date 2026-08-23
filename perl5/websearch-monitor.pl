#!/usr/bin/perl
# websearch-monitor.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-monitor.sh
# auch in: OpenClaw@gateway2:scripts/websearch-monitor.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use URI::Escape;

# Web Search Script: Server-Monitoring mit Tavily
# Verwendung: ./websearch-monitor.pl [TOPIC]

my $topic = $ARGV[0] // "Linux kernel security updates";

# Security-News prüfen
print "Prüfe: $topic\n";

# Versuche zuerst Tavily CLI
if (qx(which tvly 2>/dev/null)) {
    my $cmd = "tvly search " . escapeshellarg($topic) . " --topic news --time-range week --max-results 5 --include-answer advanced 2>/dev/null";
    my $output = qx($cmd);
    if ($output) {
        eval {
            my $json = decode_json($output);
            print $json->{answer} // "Keine Zusammenfassung verfügbar";
            print "\n";
        };
        if ($@) {
            print "Keine Zusammenfassung verfügbar\n";
        }
    }
} else {
    # Fallback zu einfacher Web-Suche
    my $ua = LWP::UserAgent->new;
    my $url = "http://localhost:8888/search?q=" . uri_escape($topic) . "&format=json";
    my $response = $ua->get($url);
    
    if ($response->is_success) {
        my $content = $response->decoded_content;
        eval {
            my $json = decode_json($content);
            my @results = @{$json->{results} // []};
            my @limited = splice(@results, 0, 3);
            for my $item (@limited) {
                print $item->{title} . "\n" . $item->{url} . "\n";
            }
        };
        if ($@) {
            print "Fehler beim Parsen der SearXNG-Ergebnisse\n";
        }
    } else {
        print "SearXNG nicht verfügbar\n";
    }
}

sub escapeshellarg {
    my ($input) = @_;
    $input =~ s/'/'\\''/g;
    return "'$input'";
}
