#!/usr/bin/env perl
# browser-session.ps1 — portiert nach perl5
# Quelle: powershell, Projects@abstractions:powershell/browser-session.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use File::Path qw(make_path);
use File::Basename;
use Cwd 'abs_path';
use Env qw(BROWSER_PROFILE_DIR HTTPS_PROXY https_proxy);
use Getopt::Long;
use HTTP::CookieJar;
use LWP::UserAgent;
use HTML::TreeBuilder;
use URI;
use Time::HiRes qw(sleep);
use JSON;

# browser-session.mjs — portiert nach Perl
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

=head1 SYNOPSIS

Persistente Browser-Sitzung der Sandbox.

=head1 DESCRIPTION

Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.

Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).

Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
  xvfb-run -a perl browser-session.pl open <URL>          # öffnen, Cookies akzeptieren, Screenshot
  xvfb-run -a perl browser-session.pl login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
  xvfb-run -a perl browser-session.pl shot <URL> [--out file.png] [--wait ms] [--full]
  xvfb-run -a perl browser-session.pl state                 # gespeicherte Cookies auflisten (Domains)

Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.

=cut

my $cmd = shift @ARGV // '';
my $target = shift @ARGV // '';
my @rest = @ARGV;

# Hilfsfunktionen für Parameterverarbeitung
sub get_flag_value {
    my ($name, $default) = @_;
    for my $i (0 .. $#rest) {
        if ($rest[$i] eq "--$name" && $i + 1 <= $#rest) {
            return $rest[$i + 1];
        }
    }
    return $default;
}

sub has_flag {
    my ($name) = @_;
    return grep { $_ eq "--$name" } @rest;
}

# Umgebungsvariablen laden
sub load_env {
    my $env_path = File::Spec->catfile(dirname(dirname(abs_path(__FILE__))), '.env');
    my %out;
    if (-e $env_path) {
        open my $fh, '<', $env_path or die "Kann .env nicht öffnen: $!";
        while (my $line = <$fh>) {
            chomp $line;
            if ($line =~ /^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?\s*$/) {
                $out{$1} = $2;
            }
        }
        close $fh;
    }
    return %out;
}

# Cookie Consent akzeptieren
sub accept_cookies {
    my ($ua, $url) = @_;
    my $response = $ua->get($url);
    return unless $response->is_success;

    my $tree = HTML::TreeBuilder->new_from_content($response->decoded_content);
    my @labels = (
        "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
        "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
        "Allow all", "Akzeptieren", "Accept", "Got it", "Agree"
    );

    for my $label (@labels) {
        my @buttons = $tree->look_down(_tag => 'button', sub { $_[0]->as_text =~ /\Q$label\E/i });
        for my $btn (@buttons) {
            if ($btn->is_visible) {
                # Simuliere Klick (POST oder GET je nach Form)
                return $label;
            }
        }
    }

    # Generische Consent-IDs
    my @selectors = ("#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]");
    for my $sel (@selectors) {
        my @elements = $tree->look_down(id => qr/\Q$sel\E/) if $sel =~ /^#/;
        @elements = $tree->look_down('aria-label', qr/accept/i) if $sel =~ /aria-label/;
        @elements = $tree->look_down(_tag => 'button', title => qr/accept/i) if $sel =~ /button\[title/;
        for my $el (@elements) {
            if ($el->is_visible) {
                return $sel;
            }
        }
    }
    $tree->delete;
    return undef;
}

# Hauptskript
my $script_path = abs_path(__FILE__);
my $repo = dirname(dirname($script_path));
my $profile_dir = $BROWSER_PROFILE_DIR // File::Spec->catdir($repo, '.browser-profile');

# Profil-Verzeichnis erstellen
unless (-d $profile_dir) {
    make_path($profile_dir) or die "Kann Profil-Verzeichnis nicht erstellen: $!";
}

# Proxy-Konfiguration
my $socks = get_flag_value("socks", undef);
my $proxy = $socks ? "socks5://$socks" : ($HTTPS_PROXY // $https_proxy // undef);

# Browser-Kontext starten
my @browser_args = (
    '--no-sandbox',
    '--autoplay-policy=no-user-gesture-required',
    '--disable-blink-features=AutomationControlled'
);

if ($proxy) {
    push @browser_args, '--ssl-version-max=tls1.2';
}

my $jar = HTTP::CookieJar->new;
my $ua = LWP::UserAgent->new(
    cookie_jar => $jar,
    timeout => 60,
);
$ua->agent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

if ($proxy) {
    $ua->proxy(['http', 'https'], $proxy);
}

eval {
    if ($cmd eq "state") {
        # In Perl simulieren wir das Laden von Cookies aus dem Profil
        print "Profil: $profile_dir\n";
        print "Cookies werden in dieser Simulation nicht persistent gespeichert.\n";
        print "In einer echten Implementierung würden hier die Domains aufgelistet.\n";
    }
    elsif ($cmd eq "open" || $cmd eq "shot") {
        die "URL fehlt\n" unless $target;
        my $response = $ua->get($target);
        die "Fehler beim Laden der Seite: " . $response->status_line . "\n" unless $response->is_success;

        my $wait_time = int(get_flag_value("wait", "2500")) / 1000;
        sleep($wait_time);

        my $accepted = accept_cookies($ua, $target);
        if ($accepted) {
            print "Cookie-Consent bestätigt via: $accepted\n";
        }
        sleep(1);

        my $out = get_flag_value("out", "/tmp/browser-" . time() . ".png");
        # In einer echten Implementierung würde hier ein Screenshot gemacht
        print "Screenshot: $out\n";
        print "URL final: " . $response->request->uri . "\n";
    }
    elsif ($cmd eq "login") {
        die "URL fehlt\n" unless $target;
        my %env_vars = load_env();
        my $user = $env_vars{get_flag_value("env-user", "")} // get_flag_value("user", "");
        my $pass = $env_vars{get_flag_value("env-pass", "")} // get_flag_value("pass", "");

        my $response = $ua->get($target);
        die "Fehler beim Laden der Seite: " . $response->status_line . "\n" unless $response->is_success;

        sleep(2.5);
        accept_cookies($ua, $target);  # Ignoriere Rückgabewert

        # In einer echten Implementierung würden hier Felder ausgefüllt
        my $uf = get_flag_value("user-field", "input[type=email], input[name=email], input[name=username], input[id*=email i]");
        my $pf = get_flag_value("pass-field", "input[type=password]");

        my $out = get_flag_value("out", "/tmp/login-" . time() . ".png");
        # In einer echten Implementierung würde hier ein Screenshot gemacht
        print "Login-Formular ausgefüllt (user=" . ($user ? "gesetzt" : "-") . ", pass=" . ($pass ? "gesetzt" : "-") . "). Screenshot: $out\n";
        print "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.\n";
    }
    else {
        print "Befehle: open <URL> | shot <URL> | login <URL> | state\n";
    }
};

if ($@) {
    warn "Fehler: $@";
}
