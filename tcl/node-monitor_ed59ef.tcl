#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "6aa631948f04400ff9b96841807c3c22bfbc69cc40c5093091e579c6d6119546", "source_sha256": "ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe", "target_language": "tcl"}
# node-monitor.html — portiert nach tcl
# Quelle: html, OpenClaw@main:examples/node-monitor.html
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

proc generate_html {} {
    set html {}

    # HTML Header
    append html {<!DOCTYPE html>}
    append html {\n<html lang="en">}
    append html {\n<head>}
    append html {\n  <meta charset="UTF-8">}
    append html {\n  <meta name="viewport" content="width=device-width, initial-scale=1.0">}
    append html {\n  <title>OpenClaw — Live Node Monitor</title>}
    append html {\n  <style>}
    append html {\n    :root \{ --bg: #0d1117; --surface: #161b22; --border: #30363d;}
    append html {\n            --text: #e6edf3; --green: #3fb950; --red: #f85149; --accent: #58a6ff; \}}
    append html {\n    * \{ box-sizing: border-box; margin: 0; padding: 0; \}}
    append html {\n    body \{ background: var(--bg); color: var(--text);}
    append html {\n           font-family: -apple-system, sans-serif; padding: 1.5rem; \}}
    append html {\n    h1   \{ color: var(--accent); margin-bottom: 1rem; font-size: 1.2rem; \}}
    append html {\n    canvas \{ display: block; border: 1px solid var(--border);}
    append html {\n             border-radius: 8px; background: var(--surface); \}}
    append html {\n    #log \{ margin-top: 1rem; height: 140px; overflow-y: auto;}
    append html {\n           background: var(--surface); border: 1px solid var(--border);}
    append html {\n           border-radius: 8px; padding: .75rem; font-size: .78rem;}
    append html {\n           font-family: monospace; color: #8b949e; \}}
    append html {\n    #log .err \{ color: var(--red); \}}
    append html {\n    #log .ok  \{ color: var(--green); \}}
    append html {\n  </style>}
    append html {\n</head>}
    append html {\n<body>}
    append html {\n  <h1>OpenClaw — Live Node Monitor</h1>}
    append html {\n  <canvas id="canvas" width="640" height="220"></canvas>}
    append html {\n  <div id="log"></div>}

    # JavaScript Section
    append html {\n\n  <script>}
    append html {\n    /* HTML5 Canvas — animated node topology */}
    append html {\n    const canvas = document.getElementById("canvas");}
    append html {\n    const ctx    = canvas.getContext("2d");}
    append html {\n    const log    = document.getElementById("log");}
    append html {\n    const GATEWAY_URL = window.OPENCLAW_WS || "ws://localhost:8080/ws";}
    append html {\n}
    append html {\n    const nodes = [}
    append html {\n      \{ id: "GW1", x: 160, y: 110, status: "unknown" \},}
    append html {\n      \{ id: "GW2", x: 480, y: 110, status: "unknown" \},}
    append html {\n      \{ id: "HUB", x: 320, y:  55, status: "ok"      \},}
    append html {\n    ];}
    append html {\n    const edges = [[0,2],[1,2]];}
    append html {\n}
    append html {\n    let pulse = 0;}
    append html {\n}
    append html {\n    function drawNode(n) \{}
    append html {\n      const color = n.status === "ok" ? "#3fb950" : n.status === "error" ? "#f85149" : "#8b949e";}
    append html {\n      ctx.beginPath();}
    append html {\n      ctx.arc(n.x, n.y, 22 + (n.status === "ok" ? Math.sin(pulse) * 3 : 0), 0, Math.PI * 2);}
    append html {\n      ctx.strokeStyle = color;}
    append html {\n      ctx.lineWidth = 2;}
    append html {\n      ctx.stroke();}
    append html {\n      ctx.fillStyle = "#161b22";}
    append html {\n      ctx.fill();}
    append html {\n      ctx.fillStyle = color;}
    append html {\n      ctx.font = "bold 11px monospace";}
    append html {\n      ctx.textAlign = "center";}
    append html {\n      ctx.textBaseline = "middle";}
    append html {\n      ctx.fillText(n.id, n.x, n.y);}
    append html {\n    \}}
    append html {\n}
    append html {\n    function drawEdge(a, b, active) \{}
    append html {\n      ctx.beginPath();}
    append html {\n      ctx.moveTo(nodes[a].x, nodes[a].y);}
    append html {\n      ctx.lineTo(nodes[b].x, nodes[b].y);}
    append html {\n      ctx.strokeStyle = active ? "#3fb95066" : "#30363d";}
    append html {\n      ctx.lineWidth = active ? 2 : 1;}
    append html {\n      ctx.setLineDash(active ? [] : [4, 4]);}
    append html {\n      ctx.stroke();}
    append html {\n      ctx.setLineDash([]);}
    append html {\n    \}}
    append html {\n}
    append html {\n    function render() \{}
    append html {\n      ctx.clearRect(0, 0, canvas.width, canvas.height);}
    append html {\n      edges.forEach(([a, b]) => drawEdge(a, b, nodes[a].status === "ok" && nodes[b].status === "ok"));}
    append html {\n      nodes.forEach(drawNode);}
    append html {\n      pulse += 0.07;}
    append html {\n      requestAnimationFrame(render);}
    append html {\n    \}}
    append html {\n    render();}
    append html {\n}
    append html {\n    function addLog(msg, type = "") \{}
    append html {\n      const el = document.createElement("div");}
    append html {\n      el.className = type;}
    append html {\n      el.textContent = \`[\$\{new Date().toLocaleTimeString()\}] \$\{msg}\`;}
    append html {\n      log.prepend(el);}
    append html {\n      if (log.children.length > 60) log.lastChild.remove();}
    append html {\n    \}}
    append html {\n}
    append html {\n    /* HTML5 WebSocket — real-time gateway events */}
    append html {\n    function connectWS() \{}
    append html {\n      const ws = new WebSocket(GATEWAY_URL);}
    append html {\n      ws.onopen  = () => \{ addLog("WebSocket connected", "ok"); nodes[2].status = "ok"; \};}
    append html {\n      ws.onclose = () => \{ addLog("WebSocket closed — retrying in 3s", "err");}
    append html {\n                           nodes.forEach(n => n.status = "error");}
    append html {\n                           setTimeout(connectWS, 3000); \};}
    append html {\n      ws.onerror = () => addLog("WebSocket error", "err");}
    append html {\n      ws.onmessage = (\{ data \}) => \{}
    append html {\n        try \{}
    append html {\n          const \{ node, status, latency \} = JSON.parse(data);}
    append html {\n          const n = nodes.find(n => n.id === node);}
    append html {\n          if (n) n.status = status;}
    append html {\n          addLog(\`\$\{node\} — \$\{status\} (\$\{latency\}ms)\`, status === "ok" ? "ok" : "err");}
    append html {\n        \} catch \{ addLog(data); \}}
    append html {\n      \};}
    append html {\n    \}}
    append html {\n}
    append html {\n    /* HTML5 Server-Sent Events — fallback */}
    append html {\n    function connectSSE() \{}
    append html {\n      const es = new EventSource(GATEWAY_URL.replace("ws","http").replace("/ws","/events"));}
    append html {\n      es.onmessage = (\{ data \}) => addLog(\`SSE: \$\{data\}\`, "ok");}
    append html {\n      es.onerror   = () => addLog("SSE stream error", "err");}
    append html {\n    \}}
    append html {\n}
    append html {\n    /* HTML5 localStorage — persist last known state */}
    append html {\n    window.addEventListener("beforeunload", () =>}
    append html {\n      localStorage.setItem("openclaw-nodes", JSON.stringify(nodes)));}
    append html {\n    const saved = localStorage.getItem("openclaw-nodes");}
    append html {\n    if (saved) JSON.parse(saved).forEach((s, i) => nodes[i].status = s.status);}
    append html {\n}
    append html {\n    "WebSocket" in window ? connectWS() : connectSSE();}
    append html {\n  </script>}
    append html {\n</body>}
    append html {\n</html>}

    return $html
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

set output_file [lindex $argv 0]
set html_content [generate_html]

if {[catch {open $output_file w} file_handle]} {
    puts stderr "Error: Could not open file '$output_file' for writing"
    exit 1
}

puts $file_handle $html_content
close $file_handle

puts "HTML file generated successfully: $output_file"
