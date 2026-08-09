#!/usr/bin/env python3
# node-monitor.html — portiert nach python
# Quelle: html, OpenClaw@main:examples/node-monitor.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import sys
import json
from datetime import datetime
from html import escape

def generate_html():
    html_parts = []
    
    # DOCTYPE and html tag
    html_parts.append('<!DOCTYPE html>')
    html_parts.append('<html lang="en">')
    
    # Head section
    html_parts.append('<head>')
    html_parts.append('  <meta charset="UTF-8">')
    html_parts.append('  <meta name="viewport" content="width=device-width, initial-scale=1.0">')
    html_parts.append('  <title>OpenClaw — Live Node Monitor</title>')
    html_parts.append('  <style>')
    html_parts.append('    :root { --bg: #0d1117; --surface: #161b22; --border: #30363d;')
    html_parts.append('            --text: #e6edf3; --green: #3fb950; --red: #f85149; --accent: #58a6ff; }')
    html_parts.append('    * { box-sizing: border-box; margin: 0; padding: 0; }')
    html_parts.append('    body { background: var(--bg); color: var(--text);')
    html_parts.append('           font-family: -apple-system, sans-serif; padding: 1.5rem; }')
    html_parts.append('    h1   { color: var(--accent); margin-bottom: 1rem; font-size: 1.2rem; }')
    html_parts.append('    canvas { display: block; border: 1px solid var(--border);')
    html_parts.append('             border-radius: 8px; background: var(--surface); }')
    html_parts.append('    #log { margin-top: 1rem; height: 140px; overflow-y: auto;')
    html_parts.append('           background: var(--surface); border: 1px solid var(--border);')
    html_parts.append('           border-radius: 8px; padding: .75rem; font-size: .78rem;')
    html_parts.append('           font-family: monospace; color: #8b949e; }')
    html_parts.append('    #log .err { color: var(--red); }')
    html_parts.append('    #log .ok  { color: var(--green); }')
    html_parts.append('  </style>')
    html_parts.append('</head>')
    
    # Body section
    html_parts.append('<body>')
    html_parts.append('  <h1>OpenClaw — Live Node Monitor</h1>')
    html_parts.append('  <canvas id="canvas" width="640" height="220"></canvas>')
    html_parts.append('  <div id="log"></div>')
    
    # Script section
    html_parts.append('')
    html_parts.append('  <script>')
    html_parts.append('    /* HTML5 Canvas — animated node topology */')
    html_parts.append('    const canvas = document.getElementById("canvas");')
    html_parts.append('    const ctx    = canvas.getContext("2d");')
    html_parts.append('    const log    = document.getElementById("log");')
    html_parts.append('    const GATEWAY_URL = window.OPENCLAW_WS || "ws://localhost:8080/ws";')
    html_parts.append('')
    html_parts.append('    const nodes = [')
    html_parts.append('      { id: "GW1", x: 160, y: 110, status: "unknown" },')
    html_parts.append('      { id: "GW2", x: 480, y: 110, status: "unknown" },')
    html_parts.append('      { id: "HUB", x: 320, y:  55, status: "ok"      },')
    html_parts.append('    ];')
    html_parts.append('    const edges = [[0,2],[1,2]];')
    html_parts.append('')
    html_parts.append('    let pulse = 0;')
    html_parts.append('')
    html_parts.append('    function drawNode(n) {')
    html_parts.append('      const color = n.status === "ok" ? "#3fb950" : n.status === "error" ? "#f85149" : "#8b949e";')
    html_parts.append('      ctx.beginPath();')
    html_parts.append('      ctx.arc(n.x, n.y, 22 + (n.status === "ok" ? Math.sin(pulse) * 3 : 0), 0, Math.PI * 2);')
    html_parts.append('      ctx.strokeStyle = color;')
    html_parts.append('      ctx.lineWidth = 2;')
    html_parts.append('      ctx.stroke();')
    html_parts.append('      ctx.fillStyle = "#161b22";')
    html_parts.append('      ctx.fill();')
    html_parts.append('      ctx.fillStyle = color;')
    html_parts.append('      ctx.font = "bold 11px monospace";')
    html_parts.append('      ctx.textAlign = "center";')
    html_parts.append('      ctx.textBaseline = "middle";')
    html_parts.append('      ctx.fillText(n.id, n.x, n.y);')
    html_parts.append('    }')
    html_parts.append('')
    html_parts.append('    function drawEdge(a, b, active) {')
    html_parts.append('      ctx.beginPath();')
    html_parts.append('      ctx.moveTo(nodes[a].x, nodes[a].y);')
    html_parts.append('      ctx.lineTo(nodes[b].x, nodes[b].y);')
    html_parts.append('      ctx.strokeStyle = active ? "#3fb95066" : "#30363d";')
    html_parts.append('      ctx.lineWidth = active ? 2 : 1;')
    html_parts.append('      ctx.setLineDash(active ? [] : [4, 4]);')
    html_parts.append('      ctx.stroke();')
    html_parts.append('      ctx.setLineDash([]);')
    html_parts.append('    }')
    html_parts.append('')
    html_parts.append('    function render() {')
    html_parts.append('      ctx.clearRect(0, 0, canvas.width, canvas.height);')
    html_parts.append('      edges.forEach(([a, b]) => drawEdge(a, b, nodes[a].status === "ok" && nodes[b].status === "ok"));')
    html_parts.append('      nodes.forEach(drawNode);')
    html_parts.append('      pulse += 0.07;')
    html_parts.append('      requestAnimationFrame(render);')
    html_parts.append('    }')
    html_parts.append('    render();')
    html_parts.append('')
    html_parts.append('    function addLog(msg, type = "") {')
    html_parts.append('      const el = document.createElement("div");')
    html_parts.append('      el.className = type;')
    html_parts.append('      el.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;')
    html_parts.append('      log.prepend(el);')
    html_parts.append('      if (log.children.length > 60) log.lastChild.remove();')
    html_parts.append('    }')
    html_parts.append('')
    html_parts.append('    /* HTML5 WebSocket — real-time gateway events */')
    html_parts.append('    function connectWS() {')
    html_parts.append('      const ws = new WebSocket(GATEWAY_URL);')
    html_parts.append('      ws.onopen  = () => { addLog("WebSocket connected", "ok"); nodes[2].status = "ok"; };')
    html_parts.append('      ws.onclose = () => { addLog("WebSocket closed — retrying in 3s", "err");')
    html_parts.append('                           nodes.forEach(n => n.status = "error");')
    html_parts.append('                           setTimeout(connectWS, 3000); };')
    html_parts.append('      ws.onerror = () => addLog("WebSocket error", "err");')
    html_parts.append('      ws.onmessage = ({ data }) => {')
    html_parts.append('        try {')
    html_parts.append('          const { node, status, latency } = JSON.parse(data);')
    html_parts.append('          const n = nodes.find(n => n.id === node);')
    html_parts.append('          if (n) n.status = status;')
    html_parts.append('          addLog(`${node} — ${status} (${latency}ms)`, status === "ok" ? "ok" : "err");')
    html_parts.append('        } catch { addLog(data); }')
    html_parts.append('      };')
    html_parts.append('    }')
    html_parts.append('')
    html_parts.append('    /* HTML5 Server-Sent Events — fallback */')
    html_parts.append('    function connectSSE() {')
    html_parts.append('      const es = new EventSource(GATEWAY_URL.replace("ws","http").replace("/ws","/events"));')
    html_parts.append('      es.onmessage = ({ data }) => addLog(`SSE: ${data}`, "ok");')
    html_parts.append('      es.onerror   = () => addLog("SSE stream error", "err");')
    html_parts.append('    }')
    html_parts.append('')
    html_parts.append('    /* HTML5 localStorage — persist last known state */')
    html_parts.append('    window.addEventListener("beforeunload", () =>')
    html_parts.append('      localStorage.setItem("openclaw-nodes", JSON.stringify(nodes)));')
    html_parts.append('    const saved = localStorage.getItem("openclaw-nodes");')
    html_parts.append('    if (saved) JSON.parse(saved).forEach((s, i) => nodes[i].status = s.status);')
    html_parts.append('')
    html_parts.append('    "WebSocket" in window ? connectWS() : connectSSE();')
    html_parts.append('  </script>')
    html_parts.append('</body>')
    html_parts.append('</html>')
    
    return '\n'.join(html_parts)

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 node-monitor.py <output-file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    try:
        html_content = generate_html()
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"HTML file generated successfully: {output_file}")
    except Exception as e:
        print(f"Error generating HTML file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
