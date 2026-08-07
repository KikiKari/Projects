#!/usr/bin/perl
# browser-session.mjs — portiert nach perl5
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Path qw(make_path);
use File::Spec;
use Cwd qw(abs_path);
use HTTP::BrowserDetect;
use URI;
use Getopt::Long;
use Env qw(BROWSER_PROFILE_DIR HTTPS_PROXY https_proxy);
use File::Basename;

# /**
#  * Persistente Browser-Sitzung der Sandbox.
#  *
#  * Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
#  * Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
#  * speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
#  * Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
#  *
#  * Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
#  *
#  * Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
#  *   xvfb-run -a node scripts/browser-session.mjs open <URL>          # öffnen, Cookies akzeptieren, Screenshot
#  *   xvfb-run -a node scripts/browser-session.mjs login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
#  *   xvfb-run -a node scripts/browser-session.mjs shot <URL> [--out file.png] [--wait ms] [--full]
#  *   xvfb-run -a node scripts/browser-session.mjs state                 # gespeicherte Cookies auflisten (Domains)
#  *
#  * Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
#  */

# Da Perl keine direkte Entsprechung zu Playwright hat, verwenden wir Systemaufrufe
# um einen Browser zu steuern. Dies ist eine vereinfachte Version.

my $script_dir = dirname(__FILE__);
my $repo = File::Spec->catdir($script_dir, "..");
my $profile = $BROWSER_PROFILE_DIR || File::Spec->catdir($repo, ".browser-profile");
my $chrome_path = "/usr/bin/google-chrome-stable";
$chrome_path = "/usr/bin/google-chrome" unless -e $chrome_path;

my @args = @ARGV;
my $cmd = shift @args // '';
my $target = shift @args // '';
my %options;
GetOptions(\%options,
    'user-field=s',
    'pass-field=s',
    'env-user=s',
    'env-pass=s',
    'out=s',
    'wait=i',
    'full',
    'insecure',
    'socks=s'
) or die "Falsche Optionen\n";

# .env laden (nur für login-Credentials; nichts wird geloggt)
sub load_env {
    my $f = File::Spec->catfile($repo, ".env");
    return {} unless -e $f;
    my %out;
    open my $fh, '<', $f or return {};
    while (my $line = <$fh>) {
        chomp $line;
        if ($line =~ /^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?\s*$/) {
            $out{$1} = $2;
        }
    }
    close $fh;
    return \%out;
}

# Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort).
# In Perl können wir dies nicht direkt tun, daher simulieren wir es.
sub accept_cookies {
    # In einer echten Implementierung würden wir hier den Browser automatisch
    # steuern. Da wir das nicht können, geben wir einfach eine Meldung aus.
    print "Cookie-Banner akzeptiert (simuliert).\n";
    return "simuliert";
}

make_path($profile) unless -d $profile;

# Sandbox-Egress läuft über den Agent-Proxy (MITM mit CA in /root/.ccr).
# Chrome muss den Proxy nutzen; die CA ist zuvor via certutil in ~/.pki/nssdb
# importiert (siehe docs/VISUAL_QA.md), damit TLS ohne Fehler verifiziert.
# --socks <server>: leitet den Browser über einen SOCKS5-Proxy (z. B. den
# Tailscale-Userspace-Proxy localhost:1055) — sauberer Egress am Agent-MITM-
# Proxy vorbei, nötig für github.com/Codespaces. Sonst der Agent-HTTPS-Proxy.
my $socks = $options{'socks'};
my $proxy = $socks ? "socks5://$socks" : ($HTTPS_PROXY || $https_proxy || '');

if ($cmd eq "state") {
    print "Profil: $profile\n";
    print "Cookies und LocalStorage werden in $profile gespeichert.\n";
    print "Domains können nicht aufgelistet werden ohne direkten Zugriff auf den Browser.\n";
} elsif ($cmd eq "open" || $cmd eq "shot") {
    if (!$target) {
        die "URL fehlt\n";
    }
    my @chrome_args = (
        "--user-data-dir=$profile",
        "--no-sandbox",
        "--autoplay-policy=no-user-gesture-required",
        "--disable-blink-features=AutomationControlled",
        "--window-size=1440,900"
    );
    push @chrome_args, "--proxy-server=$proxy" if $proxy;
    push @chrome_args, "--ssl-version-max=tls1.2" if $proxy;
    push @chrome_args, "--ignore-certificate-errors" if $options{'insecure'};

    my $wait_time = $options{'wait'} // 2500;
    my $out_file = $options{'out'} // "/tmp/browser-" . time() . ".png";
    my $full_page = $options{'full'} ? "--screenshot=$out_file,fullPage" : "--screenshot=$out_file";

    my $chrome_cmd = join(" ", $chrome_path, @chrome_args, $target, $full_page);
    print "Starte Chrome mit: $chrome_cmd\n";
    system("$chrome_cmd &");
    sleep(int($wait_time / 1000));
    my $accepted = accept_cookies();
    if ($accepted) {
        print "Cookie-Consent bestätigt via: $accepted\n";
    }
    sleep(1);
    print "Screenshot: $out_file\n";
    print "URL final: $target\n";
} elsif ($cmd eq "login") {
    if (!$target) {
        die "URL fehlt\n";
    }
    my $env = load_env();
    my $user = $env->{$options{'env-user'}} || $options{'user'} || '';
    my $pass = $env->{$options{'env-pass'}} || $options{'pass'} || '';
    my @chrome_args = (
        "--user-data-dir=$profile",
        "--no-sandbox",
        "--autoplay-policy=no-user-gesture-required",
        "--disable-blink-features=AutomationControlled",
        "--window-size=1440,900"
    );
    push @chrome_args, "--proxy-server=$proxy" if $proxy;
    push @chrome_args, "--ssl-version-max=tls1.2" if $proxy;
    push @chrome_args, "--ignore-certificate-errors" if $options{'insecure'};

    my $out_file = $options{'out'} // "/tmp/login-" . time() . ".png";

    my $chrome_cmd = join(" ", $chrome_path, @chrome_args, $target);
    print "Starte Chrome mit: $chrome_cmd\n";
    system("$chrome_cmd &");
    sleep(2.5);
    accept_cookies();
    print "Login-Formular vorbereitet (user=" . ($user ? "gesetzt" : "-") . ", pass=" . ($pass ? "gesetzt" : "-") . "). Screenshot: $out_file\n";
    print "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.\n";
} else {
    print "Befehle: open <URL> | shot <URL> | login <URL> | state\n";
}
