#!/usr/bin/env tclsh
# gateway-dashboard.html — portiert nach tcl
# Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate gateway-dashboard.html
# This script creates the HTML structure programmatically and writes it to a file.

proc generate_dashboard {filename} {
    set html [list]
    
    # DOCTYPE and html tag
    lappend html {<!DOCTYPE html>}
    lappend html {<html lang="en">}
    
    # Head section
    lappend html {<head>}
    lappend html {  <meta charset="UTF-8">}
    lappend html {  <meta name="viewport" content="width=device-width, initial-scale=1.0">}
    lappend html {  <title>OpenClaw — Gateway Dashboard</title>}
    lappend html {  <link rel="stylesheet" href="gateway-styles.css">}
    lappend html {</head>}
    
    # Body start
    lappend html {<body>}
    
    # Header section
    lappend html {  <header>}
    lappend html {    <h1>OpenClaw Cluster</h1>}
    lappend html {    <span id="cluster-status" class="badge">Checking...</span>}
    lappend html {  </header>}
    
    # Main content
    lappend html {  <main>}
    
    # Grid section
    lappend html {    <section class="grid">}
    lappend html {      <div class="card" id="gw1">}
    lappend html {        <h2>Gateway 1</h2>}
    lappend html {        <p class="endpoint">gateway1.openclaw.internal</p>}
    lappend html {        <div class="status-dot"></div>}
    lappend html {      </div>}
    lappend html {      <div class="card" id="gw2">}
    lappend html {        <h2>Gateway 2</h2>}
    lappend html {        <p class="endpoint">gateway2.openclaw.internal</p>}
    lappend html {        <div class="status-dot"></div>}
    lappend html {      </div>}
    lappend html {    </section>}
    
    # Metrics section
    lappend html {    <section class="metrics">}
    lappend html {      <h2>Node Metrics</h2>}
    lappend html {      <table>}
    lappend html {        <thead>}
    lappend html {          <tr><th>Node</th><th>Latency</th><th>Requests</th><th>Status</th></tr>}
    lappend html {        </thead>}
    lappend html {        <tbody id="metrics-body">}
    lappend html {          <tr><td colspan="4">Loading...</td></tr>}
    lappend html {        </tbody>}
    lappend html {      </table>}
    lappend html {    </section>}
    
    lappend html {  </main>}
    
    # Script section
    lappend html {  <script>}
    lappend html {    const GATEWAY_URL = window.OPENCLAW_URL || "http://localhost:8080";}
    lappend html {}
    lappend html {    async function pollStatus() \{}
    lappend html {      try \{}
    lappend html {        const res = await fetch(\`\${GATEWAY_URL}/health\`);}
    lappend html {        const ok = res.ok;}
    lappend html {        document.getElementById("cluster-status").textContent = ok ? "Online" : "Degraded";}
    lappend html {        document.getElementById("cluster-status").className = \`badge \${ok ? "ok" : "warn"}\`;}
    lappend html {        document.querySelectorAll(".status-dot").forEach(d => d.className = \`status-dot \${ok ? "green" : "red"}\`);}
    lappend html {      \} catch \{}
    lappend html {        document.getElementById("cluster-status").textContent = "Offline";}
    lappend html {        document.getElementById("cluster-status").className = "badge error";}
    lappend html {      \}}
    lappend html {    \}}
    lappend html {}
    lappend html {    pollStatus();}
    lappend html {    setInterval(pollStatus, 5000);}
    lappend html {  </script>}
    
    # Close body and html
    lappend html {</body>}
    lappend html {</html>}
    
    # Join all lines with newlines
    set content [join $html "\n"]
    
    # Write to file
    set fh [open $filename w]
    puts $fh $content
    close $fh
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

set output_file [lindex $argv 0]
generate_dashboard $output_file
