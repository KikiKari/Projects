#!/usr/bin/env perl
# sandbox-setup.sh — portiert nach perl5
# Quelle: shell, Onboarding@main:scripts/sandbox-setup.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Temp qw(tempfile);

my $SKIP_HEAVY = 0;
$SKIP_HEAVY = 1 if @ARGV && $ARGV[0] eq '--skip-heavy';

my $script_dir = dirname(abs_path(__FILE__));
my $project_root = dirname($script_dir);
chdir($project_root) or die "Konnte nicht in Projektverzeichnis wechseln: $!";

sub log_msg {
    my ($msg) = @_;
    print "[sandbox-setup] $msg\n";
}

log_msg("Node-Dependencies (npm install) …");
system('npm', 'install', '--no-audit', '--no-fund');
if ($? != 0) {
    log_msg("FEHLER: npm install fehlgeschlagen");
    exit 1;
}

log_msg("Python-Dependencies (backend/requirements-dev.txt) …");
system('pip3', 'install', '--quiet', '-r', 'backend/requirements-dev.txt');
if ($? != 0) {
    log_msg("FEHLER: pip install fehlgeschlagen");
    exit 1;
}

my $APT_UPDATED = 0;

sub apt_install {
    my ($pkg, $bin) = @_;
    if (`which $bin 2>/dev/null`) {
        my $version_output = `$bin -version 2>&1`;
        my $first_line = (split /\n/, $version_output)[0];
        log_msg("$pkg bereits vorhanden ($first_line)");
        return;
    }
    log_msg("Installiere $pkg …");
    unless ($APT_UPDATED) {
        $ENV{DEBIAN_FRONTEND} = 'noninteractive';
        system('apt-get', 'update', '-qq');
        $APT_UPDATED = 1 if $? == 0;
    }
    $ENV{DEBIAN_FRONTEND} = 'noninteractive';
    open(my $fh, '>', '/dev/null') or die "Konnte /dev/null nicht öffnen: $!";
    system("apt-get install -y -qq $pkg > /dev/null 2>&1");
    unless ($? == 0) {
        log_msg("WARNUNG: $pkg konnte nicht installiert werden (Netzwerk-Policy?) — Medien-Schritte ggf. eingeschränkt");
    }
}

apt_install('ffmpeg', 'ffmpeg');
apt_install('imagemagick', 'convert');
if (!$SKIP_HEAVY) {
    apt_install('gimp', 'gimp');
    apt_install('blender', 'blender');
}

apt_install('xvfb', 'Xvfb');
apt_install('x11-utils', 'xdpyinfo');
apt_install('libnss3-tools', 'certutil');

unless (`which google-chrome-stable 2>/dev/null`) {
    log_msg("Installiere Google Chrome Stable …");
    my ($fh, $tmp_deb) = tempfile(SUFFIX => '.deb');
    close($fh);
    my $curl_result = system("curl -fsSL -o \"$tmp_deb\" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb");
    if ($curl_result == 0) {
        $ENV{DEBIAN_FRONTEND} = 'noninteractive';
        my $install_result = system("apt-get install -y -qq \"$tmp_deb\" > /dev/null 2>&1");
        if ($install_result == 0) {
            my $chrome_version = `google-chrome-stable --version 2>/dev/null`;
            chomp($chrome_version);
            log_msg("Chrome installiert: $chrome_version");
        } else {
            log_msg("WARNUNG: Chrome-Installation fehlgeschlagen");
        }
    } else {
        log_msg("WARNUNG: Chrome-Download fehlgeschlagen (Netzwerk-Policy?)");
    }
    unlink($tmp_deb);
}

if (`which certutil 2>/dev/null` && -f "/root/.ccr/ca-bundle.crt") {
    system("mkdir -p \$HOME/.pki/nssdb");
    system("certutil -d sql:\$HOME/.pki/nssdb -N --empty-password 2>/dev/null");
    my $cert_check = `certutil -d sql:\$HOME/.pki/nssdb -L 2>/dev/null | grep -q ccr-proxy-ca; echo \$?`;
    chomp($cert_check);
    if ($cert_check ne '0') {
        system("certutil -d sql:\$HOME/.pki/nssdb -A -t \"C,,\" -n ccr-proxy-ca -i /root/.ccr/ca-bundle.crt 2>/dev/null");
        if ($? == 0) {
            log_msg("Proxy-CA in Chrome-NSS-Store importiert");
        }
    }
}

if (-d "node_modules" && !(-l "node_modules/playwright" || -e "node_modules/playwright")) {
    if (`which npm 2>/dev/null`) {
        my $result = system("npm install --no-audit --no-fund --no-save playwright > /dev/null 2>&1");
        if ($result == 0) {
            log_msg("Playwright (Node) installiert");
        } else {
            log_msg("WARNUNG: Playwright-npm-Install fehlgeschlagen");
        }
    }
}

if (`git rev-parse --is-inside-work-tree 2>/dev/null`) {
    system("git config credential.\"https://x-access-token\@github.com\".helper \"!\$(pwd)/.claude/git-credential-pat.sh\"");
    system("git remote set-url --push origin \"https://x-access-token\@github.com/KikiKari/Onboarding.git\"");
    log_msg("Git-Push-Route: direkt zu github.com (PAT via Credential-Helper)");
}

if (`which dockerd 2>/dev/null` && `docker info 2>/dev/null` eq '') {
    log_msg("Starte Docker-Daemon (Registry-Mirror: mirror.gcr.io) …");
    system("mkdir -p /etc/docker");
    unless (-f "/etc/docker/daemon.json") {
        open(my $fh, '>', '/etc/docker/daemon.json') or die "Konnte daemon.json nicht erstellen: $!";
        print $fh '{"registry-mirrors":["https://mirror.gcr.io"]}';
        close($fh);
    }
    system("(dockerd > /tmp/dockerd.log 2>&1 &)");
    for (1..15) {
        last if system("docker info > /dev/null 2>&1") == 0;
        sleep(1);
    }
    if (system("docker info > /dev/null 2>&1") == 0) {
        log_msg("Docker-Daemon läuft");
    } else {
        log_msg("WARNUNG: Docker-Daemon nicht gestartet");
    }
}

log_msg("Fertig. Versionen:");
my $node_version = `node --version`;
chomp($node_version);
print "[sandbox-setup]   node $node_version\n";

my $python_version = `python3 --version`;
chomp($python_version);
print "[sandbox-setup]   $python_version\n";

if (`which ffmpeg 2>/dev/null`) {
    my $ffmpeg_version = `ffmpeg -version 2>/dev/null | head -1`;
    chomp($ffmpeg_version);
    print "[sandbox-setup]   $ffmpeg_version\n";
}

if (`which convert 2>/dev/null`) {
    my $convert_version = `convert -version 2>/dev/null | head -1`;
    chomp($convert_version);
    print "[sandbox-setup]   $convert_version\n";
}

if (`which gimp 2>/dev/null`) {
    my $gimp_version = `gimp --version 2>/dev/null | head -1`;
    chomp($gimp_version);
    print "[sandbox-setup]   $gimp_version\n";
}

if (`which blender 2>/dev/null`) {
    my $blender_version = `blender --version 2>/dev/null | head -1`;
    chomp($blender_version);
    print "[sandbox-setup]   $blender_version\n";
}

exit 0;
