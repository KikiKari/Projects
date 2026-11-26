#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "c691f299acdcbbb045a1902b9264beb1aa7d5dbd2eb472f9058da0218b4c3432", "source_sha256": "ea0eb33b2baa2fe609d171d70b4b6f712df52229f647c3ac02833fc01d629d35", "target_language": "tcl"}
# gateway-dashboard.html — portiert nach tcl
# Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Script zur Erzeugung der gateway-dashboard.html
# Dieses Skript generiert dynamisch das HTML-Dokument basierend auf strukturierten Daten.

proc generate_html {filename} {
    set fp [open $filename w]
    
    # HTML-Kopf und grundlegende Struktur
    puts $fp {<!DOCTYPE html>}
    puts $fp {<html lang="en">}
    puts $fp {<head>}
    puts $fp {  <meta charset="UTF-8">}
    puts $fp {  <meta name="viewport" content="width=device-width, initial-scale=1.0">}
    puts $fp {  <title>OpenClaw — Gateway Dashboard</title>}
    puts $fp {  <link rel="stylesheet" href="gateway-styles.css">}
    puts $fp {</head>}
    puts $fp {<body>}
    
    # Header-Bereich
    puts $fp {  <header>}
    puts $fp {    <h1>OpenClaw Cluster</h1>}
    puts $fp {    <span id="cluster-status" class="badge">Checking...</span>}
    puts $fp {  </header>}
    
    # Hauptinhalt
    puts $fp {  <main>}
    
    # Grid-Sektion mit Gateways
    puts $fp {    <section class="grid">}
    
    # Gateway 1
    puts $fp {      <div class="card" id="gw1">}
    puts $fp {        <h2>Gateway 1</h2>}
    puts $fp {        <p class="endpoint">gateway1.openclaw.internal</p>}
    puts $fp {        <div class="status-dot"></div>}
    puts $fp {      </div>}
    
    # Gateway 2
    puts $fp {      <div class="card" id="gw2">}
    puts $fp {        <h2>Gateway 2</h2>}
    puts $fp {        <p class="endpoint">gateway2.openclaw.internal</p>}
    puts $fp {        <div class="status-dot"></div>}
    puts $fp {      </div>}
    
    puts $fp {    </section>}
    
    # Metrik-Tabelle
    puts $fp {    <section class="metrics">}
    puts $fp {      <h2>Node Metrics</h2>}
    puts $fp {      <table>}
    puts $fp {        <thead>}
    puts $fp {          <tr><th>Node</th><th>Latency</th><th>Requests</th><th>Status</th></tr>}
    puts $fp {        </thead>}
    puts $fp {        <tbody id="metrics-body">}
    puts $fp {          <tr><td colspan="4">Loading...</td></tr>}
    puts $fp {        </tbody>}
    puts $fp {      </table>}
    puts $fp {    </section>}
    
    puts $fp {  </main>}
    
    # JavaScript-Bereich
    puts $fp {  <script>}
    puts $fp {    const GATEWAY_URL = window.OPENCLAW_URL || "http://localhost:8080";}
    puts $fp {}
    puts $fp {    async function pollStatus() \{}
    puts $fp {      try \{}
    puts $fp {        const res = await fetch(\`\${GATEWAY_URL}/health\`);}
    puts $fp {        const ok = res.ok;}
    puts $fp {        document.getElementById("cluster-status").textContent = ok ? "Online" : "Degraded";}
    puts $fp {        document.getElementById("cluster-status").className = \`badge \$\{ok ? "ok" : "warn"\}\`;}
    puts $fp {        document.querySelectorAll(".status-dot").forEach(d => d.className = \`status-dot \$\{ok ? "green" : "red"\}\`);}
    puts $fp {      \} catch \{}
    puts $fp {        document.getElementById("cluster-status").textContent = "Offline";}
    puts $fp {        document.getElementById("cluster-status").className = "badge error";}
    puts $fp {      \}}
    puts $fp {    \}}
    puts $fp {}
    puts $fp {    pollStatus();}
    puts $fp {    setInterval(pollStatus, 5000);}
    puts $fp {  </script>}
    
    # Abschluss des HTML-Dokuments
    puts $fp {</body>}
    puts $fp {</html>}
    
    close $fp
}

# Prüfen auf Kommandozeilenargument
if {$argc != 1} {
    puts stderr "Verwendung: $argv0 <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
generate_html $output_file
puts "HTML-Dokument wurde erfolgreich in '$output_file' geschrieben."
