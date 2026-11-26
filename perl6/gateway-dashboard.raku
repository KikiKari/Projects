#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "511d1fc509b5ae71e28c8087b97cd3c311012a6d1351a4bc9c0ff805f48269b5", "source_sha256": "ea0eb33b2baa2fe609d171d70b4b6f712df52229f647c3ac02833fc01d629d35", "target_language": "perl6"}
# gateway-dashboard.html — portiert nach perl6
# Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use v6;

sub MAIN($output-file) {
    # Erzeuge das HTML-Dokument programmatisch
    my $html = q:to/HTML/;
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
    HTML

    # Schreibe das generierte HTML in die angegebene Datei
    spurt($output-file, $html);
}
