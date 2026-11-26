#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "e7bc0d70faee28ff9fd4deb9a8d60f8b88d75b07b093298a9b4a9985973a8fb5", "source_sha256": "ea0eb33b2baa2fe609d171d70b4b6f712df52229f647c3ac02833fc01d629d35", "target_language": "lua"}
-- gateway-dashboard.html — portiert nach lua
-- Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function generate_html(output_file)
  local html_content = [[
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
]]

  local file = io.open(output_file, "w")
  if not file then
    print("Error: Could not open file " .. output_file .. " for writing.")
    os.exit(1)
  end

  file:write(html_content)
  file:close()
  print("HTML file generated successfully: " .. output_file)
end

-- Main execution
if #arg ~= 1 then
  print("Usage: " .. arg[0] .. " <output-file>")
  os.exit(1)
end

generate_html(arg[1])
