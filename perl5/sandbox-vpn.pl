#!/usr/bin/env perl
# sandbox-vpn.sh — portiert nach perl5
# Quelle: shell, Onboarding@main:scripts/sandbox-vpn.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

# Bringt die Sandbox reproduzierbar in das Tailscale-Tailnet des Nutzers —
# als Brücke am Agent-MITM-Proxy vorbei (sauberer Egress via SOCKS5) und mit
# Tailscale-SSH, damit die eigenen Geräte des Nutzers in die Sandbox kommen.
#
# Nutzt den WIEDERVERWENDBAREN Auth-Key aus der .env (nichts committet).
# userspace-networking: verändert NICHT die Host-Routen/den Agent-Proxy dieser
# Session; stellt einen SOCKS5-Proxy auf localhost:1055 bereit.
#
# Aufruf: scripts/sandbox-vpn.sh   (idempotent; No-op ohne Auth-Key/tailscale)

# Change to the parent directory of this script
my $script_dir = dirname(abs_path($0));
chdir("$script_dir/..") or die "Cannot change directory: $!";

sub log_message {
    my ($message) = @_;
    printf "[sandbox-vpn] %s\n", $message;
}

# Read Auth-Key from .env (without sourcing the entire .env)
my $key = "";
if (-f ".env") {
    open(my $fh, '<', '.env') or die "Could not open .env: $!";
    while (my $line = <$fh>) {
        if ($line =~ /^TAILSCALE_AUTH_KEY="(.*)"/) {
            $key = $1;
            last;
        }
    }
    close($fh);
}

if (!$key) {
    log_message("kein TAILSCALE_AUTH_KEY in .env — überspringe VPN");
    exit 0;
}

# Install Tailscale if not present
unless (`which tailscale 2>/dev/null`) {
    log_message("installiere Tailscale …");
    system("curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1");
    if ($? != 0) {
        log_message("WARNUNG: Tailscale-Install fehlgeschlagen");
        exit 0;
    }
}

# Start tailscaled in userspace mode (SOCKS5 + HTTP-Proxy for Tailnet-Egress)
my $tailscale_status = system("tailscale status >/dev/null 2>&1");
if ($tailscale_status != 0) {
    log_message("starte tailscaled (userspace, SOCKS5 localhost:1055) …");
    system("mkdir -p /var/lib/tailscale");
    
    my $cmd = "nohup tailscaled --tun=userspace-networking " .
              "--socks5-server=localhost:1055 " .
              "--outbound-http-proxy-listen=localhost:1056 " .
              "--statedir=/var/lib/tailscale >/tmp/tailscaled.log 2>&1 &";
    system($cmd);
    sleep(4);
}

# Join the tailnet with Tailscale SSH enabled
my $status_output = `tailscale status 2>/dev/null`;
if ($status_output !~ /claude-sandbox/) {
    log_message("tailscale up (hostname=claude-sandbox, --ssh) …");
    my $up_cmd = "tailscale up --authkey=\"$key\" --hostname=claude-sandbox --ssh --accept-routes >/dev/null 2>&1";
    my $result = system($up_cmd);
    if ($result != 0) {
        log_message("WARNUNG: tailscale up fehlgeschlagen");
    }
} else {
    system("tailscale set --ssh >/dev/null 2>&1");
}

# Check final status and report
$tailscale_status = system("tailscale status >/dev/null 2>&1");
if ($tailscale_status == 0) {
    my $ip_output = `tailscale ip -4 2>/dev/null`;
    my @ips = split /\n/, $ip_output;
    my $ip = $ips[0] // "?";
    log_message("im Tailnet: claude-sandbox $ip · SSH aktiv · SOCKS5 localhost:1055");
}

exit 0;
