#!/usr/bin/perl
# background.js — portiert nach perl5
# Quelle: javascript, Projects@Telegram-Monitor:plugin/extension/background.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON::PP;
use LWP::UserAgent;
use HTTP::Request;
use Time::HiRes qw(sleep);

# Hintergrunddienst: prüft im Turnus und meldet den Livegang.
# Läuft ohne offenen Tab — der Browser weckt den Dienst über einen Alarm.

# Da Perl keine direkte Entsprechung zu WebExtensions hat, simulieren wir
# den Ablauf mit einem einfachen Daemon-ähnlichen Skript.

my $ALARM = 'ttc-check';
my $api_base = 'http://127.0.0.1:8765';
my $ua = LWP::UserAgent->new;

# Globale Variablen für Einstellungen
my %settings = (
    user     => '',
    minutes  => 2,
    notify   => 1,
    lastLive => 0,
);

# Dummy-Klasse für TikTokCompanion
package TikTokCompanion;
sub new {
    my ($class, $args) = @_;
    return bless {
        apiBase => $args->{apiBase} || 'http://127.0.0.1:8765',
        user    => '',
    }, $class;
}

sub refresh {
    my ($self) = @_;
    my $url = $self->{apiBase} . "/user/" . $self->{user};
    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    if ($res->is_success) {
        my $data = decode_json($res->decoded_content);
        return $data;
    } else {
        die "API Fehler: " . $res->status_line;
    }
}

package main;

sub load_settings {
    # In einer echten Implementierung würden diese aus einer Datei oder DB kommen
    # Hier simulieren wir sie mit festen Werten
    return %settings;
}

sub save_settings {
    my ($new_settings) = @_;
    %settings = %$new_settings;
}

sub schedule {
    my ($minutes) = @_;
    # In einer echten Implementierung würde hier ein Alarm geplant werden
    # Hier simulieren wir es durch eine Schleife
    print "Alarm eingerichtet: alle $minutes Minuten\n" if $minutes > 0;
}

sub check {
    my %s = load_settings();
    my $user = $s{user};
    return unless $user;

    my $companion = TikTokCompanion->new({ apiBase => $api_base });
    $companion->{user} = $user;

    my $st;
    eval {
        $st = $companion->refresh();
    };
    if ($@) {
        print "Fehler beim Abrufen des Status: $@\n";
        return;
    }

    return unless $st && exists $st->{live};

    my $isLive = $st->{live} ? 1 : 0;
    $settings{lastLive} = $isLive;
    $settings{lastState} = $st;

    print "Status: " . ($isLive ? "LIVE" : "offline") . "\n";

    if ($isLive && !$s{lastLive} && $s{notify}) {
        print "Benachrichtigung: \@$user ist live\n";
        if ($st->{title}) {
            print "Titel: $st->{title}\n";
        } else {
            print "Die Sendung läuft.\n";
        }
    }
}

# Initialer Aufruf
schedule($settings{minutes});
check();

# Endlosschleife für periodische Prüfung
while (1) {
    sleep($settings{minutes} * 60);
    check();
}
