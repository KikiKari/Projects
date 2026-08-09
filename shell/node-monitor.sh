#!/bin/bash
# node-monitor.html — portiert nach shell
# Quelle: html, OpenClaw@main:examples/node-monitor.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Parameter: Ausgabedatei
output_file="${1:-node-monitor.html}"

# HTML-Struktur erzeugen
cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OpenClaw — Live Node Monitor</title>
  <style>
    :root { --bg: #0d1117; --surface: #161b22; --border: #30363d;
            --text: #e6edf3; --green: #3fb950; --red: #f85149; --accent: #58a6ff; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: var(--bg); color: var(--text);
           font-family: -apple-system, sans-serif; padding: 1.5rem; }
    h1   { color: var(--accent); margin-bottom: 1rem; font-size: 1.2rem; }
    canvas { display: block; border: 1px solid var(--border);
             border-radius: 8px; background: var(--surface); }
    #log { margin-top: 1rem; height: 140px; overflow-y: auto;
           background: var(--surface); border: 1px solid var(--border);
           border-radius: 8px; padding: .75rem; font-size: .78rem;
           font-family: monospace; color: #8b949e; }
    #log .err { color: var(--red); }
    #log .ok  { color: var(--green); }
  </style>
</head>
<body>
  <h1>OpenClaw — Live Node Monitor</h1>
  <canvas id="canvas" width="640" height="220"></canvas>
  <div id="log"></div>

  <script>
    /* HTML5 Canvas — animated node topology */
    const canvas = document.getElementById("canvas");
    const ctx    = canvas.getContext("2d");
    const log    = document.getElementById("log");
    const GATEWAY_URL = window.OPENCLAW_WS || "ws://localhost:8080/ws";

    const nodes = [
      { id: "GW1", x: 160, y: 110, status: "unknown" },
      { id: "GW2", x: 480, y: 110, status: "unknown" },
      { id: "HUB", x: 320, y:  55, status: "ok"      },
    ];
    const edges = [[0,2],[1,2]];

    let pulse = 0;

    function drawNode(n) {
      const color = n.status === "ok" ? "#3fb950" : n.status === "error" ? "#f85149" : "#8b949e";
      ctx.beginPath();
      ctx.arc(n.x, n.y, 22 + (n.status === "ok" ? Math.sin(pulse) * 3 : 0), 0, Math.PI * 2);
      ctx.strokeStyle = color;
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.fillStyle = "#161b22";
      ctx.fill();
      ctx.fillStyle = color;
      ctx.font = "bold 11px monospace";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(n.id, n.x, n.y);
    }

    function drawEdge(a, b, active) {
      ctx.beginPath();
      ctx.moveTo(nodes[a].x, nodes[a].y);
      ctx.lineTo(nodes[b].x, nodes[b].y);
      ctx.strokeStyle = active ? "#3fb95066" : "#30363d";
      ctx.lineWidth = active ? 2 : 1;
      ctx.setLineDash(active ? [] : [4, 4]);
      ctx.stroke();
      ctx.setLineDash([]);
    }

    function render() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      edges.forEach(([a, b]) => drawEdge(a, b, nodes[a].status === "ok" && nodes[b].status === "ok"));
      nodes.forEach(drawNode);
      pulse += 0.07;
      requestAnimationFrame(render);
    }
    render();

    function addLog(msg, type = "") {
      const el = document.createElement("div");
      el.className = type;
      el.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;
      log.prepend(el);
      if (log.children.length > 60) log.lastChild.remove();
    }

    /* HTML5 WebSocket — real-time gateway events */
    function connectWS() {
      const ws = new WebSocket(GATEWAY_URL);
      ws.onopen  = () => { addLog("WebSocket connected", "ok"); nodes[2].status = "ok"; };
      ws.onclose = () => { addLog("WebSocket closed — retrying in 3s", "err");
                           nodes.forEach(n => n.status = "error");
                           setTimeout(connectWS, 3000); };
      ws.onerror = () => addLog("WebSocket error", "err");
      ws.onmessage = ({ data }) => {
        try {
          const { node, status, latency } = JSON.parse(data);
          const n = nodes.find(n => n.id === node);
          if (n) n.status = status;
          addLog(`${node} — ${status} (${latency}ms)`, status === "ok" ? "ok" : "err");
        } catch { addLog(data); }
      };
    }

    /* HTML5 Server-Sent Events — fallback */
    function connectSSE() {
      const es = new EventSource(GATEWAY_URL.replace("ws","http").replace("/ws","/events"));
      es.onmessage = ({ data }) => addLog(`SSE: ${data}`, "ok");
      es.onerror   = () => addLog("SSE stream error", "err");
    }

    /* HTML5 localStorage — persist last known state */
    window.addEventListener("beforeunload", () =>
      localStorage.setItem("openclaw-nodes", JSON.stringify(nodes)));
    const saved = localStorage.getItem("openclaw-nodes");
    if (saved) JSON.parse(saved).forEach((s, i) => nodes[i].status = s.status);

    "WebSocket" in window ? connectWS() : connectSSE();
  </script>
</body>
</html>
EOF

echo "HTML-Dokument wurde in '$output_file' erstellt."
