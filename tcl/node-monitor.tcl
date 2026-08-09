#!/usr/bin/env tclsh
# node-monitor.html — portiert nach tcl
# Quelle: html, OpenClaw@main:examples/node-monitor.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate node-monitor.html
# This script creates the HTML file with embedded CSS and JavaScript

proc generate_html {filename} {
    set fp [open $filename w]
    
    puts $fp {<!DOCTYPE html>}
    puts $fp {<html lang="en">}
    puts $fp {<head>}
    puts $fp {  <meta charset="UTF-8">}
    puts $fp {  <meta name="viewport" content="width=device-width, initial-scale=1.0">}
    puts $fp {  <title>OpenClaw — Live Node Monitor</title>}
    puts $fp {  <style>}
    puts $fp {    :root { --bg: #0d1117; --surface: #161b22; --border: #30363d;}
    puts $fp {            --text: #e6edf3; --green: #3fb950; --red: #f85149; --accent: #58a6ff; \}}
    puts $fp {    * { box-sizing: border-box; margin: 0; padding: 0; \}}
    puts $fp {    body { background: var(--bg); color: var(--text);}
    puts $fp {           font-family: -apple-system, sans-serif; padding: 1.5rem; \}}
    puts $fp {    h1   { color: var(--accent); margin-bottom: 1rem; font-size: 1.2rem; \}}
    puts $fp {    canvas { display: block; border: 1px solid var(--border);}
    puts $fp {             border-radius: 8px; background: var(--surface); \}}
    puts $fp {    #log { margin-top: 1rem; height: 140px; overflow-y: auto;}
    puts $fp {           background: var(--surface); border: 1px solid var(--border);}
    puts $fp {           border-radius: 8px; padding: .75rem; font-size: .78rem;}
    puts $fp {           font-family: monospace; color: #8b949e; \}}
    puts $fp {    #log .err { color: var(--red); \}}
    puts $fp {    #log .ok  { color: var(--green); \}}
    puts $fp {  </style>}
    puts $fp {</head>}
    puts $fp {<body>}
    puts $fp {  <h1>OpenClaw — Live Node Monitor</h1>}
    puts $fp {  <canvas id="canvas" width="640" height="220"></canvas>}
    puts $fp {  <div id="log"></div>}
    puts $fp {}
    puts $fp {  <script>}
    puts $fp {    /* HTML5 Canvas — animated node topology */}
    puts $fp {    const canvas = document.getElementById("canvas");}
    puts $fp {    const ctx    = canvas.getContext("2d");}
    puts $fp {    const log    = document.getElementById("log");}
    puts $fp {    const GATEWAY_URL = window.OPENCLAW_WS || "ws://localhost:8080/ws";}
    puts $fp {}
    puts $fp {    const nodes = [}
    puts $fp {      { id: "GW1", x: 160, y: 110, status: "unknown" },}
    puts $fp {      { id: "GW2", x: 480, y: 110, status: "unknown" },}
    puts $fp {      { id: "HUB", x: 320, y:  55, status: "ok"      },}
    puts $fp {    ];}
    puts $fp {    const edges = [[0,2],[1,2]];}
    puts $fp {}
    puts $fp {    let pulse = 0;}
    puts $fp {}
    puts $fp {    function drawNode(n) \{}
    puts $fp {      const color = n.status === "ok" ? "#3fb950" : n.status === "error" ? "#f85149" : "#8b949e";}
    puts $fp {      ctx.beginPath();}
    puts $fp {      ctx.arc(n.x, n.y, 22 + (n.status === "ok" ? Math.sin(pulse) * 3 : 0), 0, Math.PI * 2);}
    puts $fp {      ctx.strokeStyle = color;}
    puts $fp {      ctx.lineWidth = 2;}
    puts $fp {      ctx.stroke();}
    puts $fp {      ctx.fillStyle = "#161b22";}
    puts $fp {      ctx.fill();}
    puts $fp {      ctx.fillStyle = color;}
    puts $fp {      ctx.font = "bold 11px monospace";}
    puts $fp {      ctx.textAlign = "center";}
    puts $fp {      ctx.textBaseline = "middle";}
    puts $fp {      ctx.fillText(n.id, n.x, n.y);}
    puts $fp {    \}}
    puts $fp {}
    puts $fp {    function drawEdge(a, b, active) \{}
    puts $fp {      ctx.beginPath();}
    puts $fp {      ctx.moveTo(nodes[a].x, nodes[a].y);}
    puts $fp {      ctx.lineTo(nodes[b].x, nodes[b].y);}
    puts $fp {      ctx.strokeStyle = active ? "#3fb95066" : "#30363d";}
    puts $fp {      ctx.lineWidth = active ? 2 : 1;}
    puts $fp {      ctx.setLineDash(active ? [] : [4, 4]);}
    puts $fp {      ctx.stroke();}
    puts $fp {      ctx.setLineDash([]);}
    puts $fp {    \}}
    puts $fp {}
    puts $fp {    function render() \{}
    puts $fp {      ctx.clearRect(0, 0, canvas.width, canvas.height);}
    puts $fp {      edges.forEach(([a, b]) => drawEdge(a, b, nodes[a].status === "ok" && nodes[b].status === "ok"));}
    puts $fp {      nodes.forEach(drawNode);}
    puts $fp {      pulse += 0.07;}
    puts $fp {      requestAnimationFrame(render);}
    puts $fp {    \}}
    puts $fp {    render();}
    puts $fp {}
    puts $fp {    function addLog(msg, type = "") \{}
    puts $fp {      const el = document.createElement("div");}
    puts $fp {      el.className = type;}
    puts $fp {      el.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;}
    puts $fp {      log.prepend(el);}
    puts $fp {      if (log.children.length > 60) log.lastChild.remove();}
    puts $fp {    \}}
    puts $fp {}
    puts $fp {    /* HTML5 WebSocket — real-time gateway events */}
    puts $fp {    function connectWS() \{}
    puts $fp {      const ws = new WebSocket(GATEWAY_URL);}
    puts $fp {      ws.onopen  = () => { addLog("WebSocket connected", "ok"); nodes[2].status = "ok"; \};}
    puts $fp {      ws.onclose = () => { addLog("WebSocket closed — retrying in 3s", "err");}
    puts $fp {                           nodes.forEach(n => n.status = "error");}
    puts $fp {                           setTimeout(connectWS, 3000); \};}
    puts $fp {      ws.onerror = () => addLog("WebSocket error", "err");}
    puts $fp {      ws.onmessage = ({ data }) => \{}
    puts $fp {        try \{}
    puts $fp {          const { node, status, latency } = JSON.parse(data);}
    puts $fp {          const n = nodes.find(n => n.id === node);}
    puts $fp {          if (n) n.status = status;}
    puts $fp {          addLog(`${node} — ${status} (${latency}ms)`, status === "ok" ? "ok" : "err");}
    puts $fp {        \} catch \{ addLog(data); \}}
    puts $fp {      \};}
    puts $fp {    \}}
    puts $fp {}
    puts $fp {    /* HTML5 Server-Sent Events — fallback */}
    puts $fp {    function connectSSE() \{}
    puts $fp {      const es = new EventSource(GATEWAY_URL.replace("ws","http").replace("/ws","/events"));}
    puts $fp {      es.onmessage = ({ data }) => addLog(`SSE: ${data}`, "ok");}
    puts $fp {      es.onerror   = () => addLog("SSE stream error", "err");}
    puts $fp {    \}}
    puts $fp {}
    puts $fp {    /* HTML5 localStorage — persist last known state */}
    puts $fp {    window.addEventListener("beforeunload", () =>}
    puts $fp {      localStorage.setItem("openclaw-nodes", JSON.stringify(nodes)));}
    puts $fp {    const saved = localStorage.getItem("openclaw-nodes");}
    puts $fp {    if (saved) JSON.parse(saved).forEach((s, i) => nodes[i].status = s.status);}
    puts $fp {}
    puts $fp {    "WebSocket" in window ? connectWS() : connectSSE();}
    puts $fp {  </script>}
    puts $fp {</body>}
    puts $fp {</html>}
    
    close $fp
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

set output_file [lindex $argv 0]
generate_html $output_file
puts "Generated $output_file"
