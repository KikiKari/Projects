#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "3260ef191188bb9bc985aa04dc2840abf0b4f86c0792b9fbb1641d033dc5ec01", "source_sha256": "ea0eb33b2baa2fe609d171d70b4b6f712df52229f647c3ac02833fc01d629d35", "target_language": "perl5"}
# gateway-dashboard.html — portiert nach perl5
# Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Function to generate the HTML dashboard content
sub generate_dashboard_html {
    my $html = <<'EOF';
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OpenClaw — Gateway Dashboard</title>
  <link rel="stylesheet" href="gateway-styles.css">
</head>
<body>
  <header>
    <h1>OpenClaw Cluster</h1>
    <span id="cluster-status" class="badge">Checking...</span>
  </header>

  <main>
    <section class="grid">
      <div class="card" id="gw1">
        <h2>Gateway 1</h2>
        <p class="endpoint">gateway1.openclaw.internal</p>
        <div class="status-dot"></div>
      </div>
      <div class="card" id="gw2">
        <h2>Gateway 2</h2>
        <p class="endpoint">gateway2.openclaw.internal</p>
        <div class="status-dot"></div>
      </div>
    </section>

    <section class="metrics">
      <h2>Node Metrics</h2>
      <table>
        <thead>
          <tr><th>Node</th><th>Latency</th><th>Requests</th><th>Status</th></tr>
        </thead>
        <tbody id="metrics-body">
          <tr><td colspan="4">Loading...</td></tr>
        </tbody>
      </table>
    </section>
  </main>

  <script>
    const GATEWAY_URL = window.OPENCLAW_URL || "http://localhost:8080";

    async function pollStatus() {
      try {
        const res = await fetch(`${GATEWAY_URL}/health`);
        const ok = res.ok;
        document.getElementById("cluster-status").textContent = ok ? "Online" : "Degraded";
        document.getElementById("cluster-status").className = `badge ${ok ? "ok" : "warn"}`;
        document.querySelectorAll(".status-dot").forEach(d => d.className = `status-dot ${ok ? "green" : "red"}`);
      } catch {
        document.getElementById("cluster-status").textContent = "Offline";
        document.getElementById("cluster-status").className = "badge error";
      }
    }

    pollStatus();
    setInterval(pollStatus, 5000);
  </script>
</body>
</html>
EOF
    return $html;
}

# Main execution
sub main {
    my ($output_file) = @_;

    if (!defined $output_file) {
        print "Usage: $0 <output-file>\n";
        exit 1;
    }

    my $content = generate_dashboard_html();

    open(my $fh, '>', $output_file) or die "Could not open file '$output_file': $!";
    print $fh $content;
    close($fh);

    print "Dashboard HTML written to $output_file\n";
}

# Run main with command line arguments
main(@ARGV);
