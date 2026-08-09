#!/usr/bin/env pwsh
# gateway-styles.css — portiert nach powershell
# Quelle: css, OpenClaw@main:examples/gateway-styles.css
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Define CSS content as a here-string with proper formatting
$cssContent = @'
/* OpenClaw Gateway Dashboard */

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg:       #0d1117;
  --surface:  #161b22;
  --border:   #30363d;
  --text:     #e6edf3;
  --muted:    #8b949e;
  --green:    #3fb950;
  --yellow:   #d29922;
  --red:      #f85149;
  --accent:   #58a6ff;
}

body {
  background: var(--bg);
  color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  min-height: 100vh;
}

header {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem 2rem;
  border-bottom: 1px solid var(--border);
  background: var(--surface);
}

header h1 { font-size: 1.25rem; color: var(--accent); }

.badge {
  padding: .25rem .75rem;
  border-radius: 999px;
  font-size: .75rem;
  font-weight: 600;
  background: var(--border);
  color: var(--muted);
}
.badge.ok    { background: #1a3a2a; color: var(--green); }
.badge.warn  { background: #3a2e0a; color: var(--yellow); }
.badge.error { background: #3a1010; color: var(--red); }

main { padding: 2rem; max-width: 960px; margin: 0 auto; }

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1.25rem;
  position: relative;
}

.card h2   { font-size: 1rem; margin-bottom: .25rem; }
.card .endpoint { font-size: .8rem; color: var(--muted); }

.status-dot {
  position: absolute;
  top: 1.25rem;
  right: 1.25rem;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--border);
}
.status-dot.green { background: var(--green); box-shadow: 0 0 6px var(--green); }
.status-dot.red   { background: var(--red);   box-shadow: 0 0 6px var(--red); }

.metrics h2 { font-size: 1rem; margin-bottom: 1rem; }

table {
  width: 100%;
  border-collapse: collapse;
  font-size: .875rem;
}
th, td {
  padding: .625rem 1rem;
  text-align: left;
  border-bottom: 1px solid var(--border);
}
th { color: var(--muted); font-weight: 500; }
tr:last-child td { border-bottom: none; }
'@

# Write the CSS content to the specified output file
Set-Content -Path $OutputPath -Value $cssContent -Encoding UTF8

Write-Host "CSS file has been generated at: $OutputPath"
