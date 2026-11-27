// abstraction-provenance: {"artifact_sha256": "97efbe34649e53cc774ecb2b1c42fc554f8f2bb1f0a8071dc3e80604980a75f3", "source_sha256": "ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe", "target_language": "fsharp"}
// node-monitor.html — portiert nach fsharp
// Quelle: html, OpenClaw@main:examples/node-monitor.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

// F# Port of node-monitor.html
// Generates the HTML page programmatically and writes it to a file

open System
open System.IO
open System.Text

let generateHtmlContent() =
    let sb = StringBuilder()
    
    // HTML structure with embedded CSS and JavaScript
    sb.AppendLine("<!DOCTYPE html>")
      .AppendLine("<html lang=\"en\">")
      .AppendLine("<head>")
      .AppendLine("  <meta charset=\"UTF-8\">")
      .AppendLine("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">")
      .AppendLine("  <title>OpenClaw — Live Node Monitor</title>")
      .AppendLine("  <style>")
      .AppendLine("    :root { --bg: #0d1117; --surface: #161b22; --border: #30363d;")
      .AppendLine("            --text: #e6edf3; --green: #3fb950; --red: #f85149; --accent: #58a6ff; }")
      .AppendLine("    * { box-sizing: border-box; margin: 0; padding: 0; }")
      .AppendLine("    body { background: var(--bg); color: var(--text);")
      .AppendLine("           font-family: -apple-system, sans-serif; padding: 1.5rem; }")
      .AppendLine("    h1   { color: var(--accent); margin-bottom: 1rem; font-size: 1.2rem; }")
      .AppendLine("    canvas { display: block; border: 1px solid var(--border);")
      .AppendLine("             border-radius: 8px; background: var(--surface); }")
      .AppendLine("    #log { margin-top: 1rem; height: 140px; overflow-y: auto;")
      .AppendLine("           background: var(--surface); border: 1px solid var(--border);")
      .AppendLine("           border-radius: 8px; padding: .75rem; font-size: .78rem;")
      .AppendLine("           font-family: monospace; color: #8b949e; }")
      .AppendLine("    #log .err { color: var(--red); }")
      .AppendLine("    #log .ok  { color: var(--green); }")
      .AppendLine("  </style>")
      .AppendLine("</head>")
      .AppendLine("<body>")
      .AppendLine("  <h1>OpenClaw — Live Node Monitor</h1>")
      .AppendLine("  <canvas id=\"canvas\" width=\"640\" height=\"220\"></canvas>")
      .AppendLine("  <div id=\"log\"></div>")
      .AppendLine("")
      .AppendLine("  <script>")
      .AppendLine("    /* HTML5 Canvas — animated node topology */")
      .AppendLine("    const canvas = document.getElementById(\"canvas\");")
      .AppendLine("    const ctx    = canvas.getContext(\"2d\");")
      .AppendLine("    const log    = document.getElementById(\"log\");")
      .AppendLine("    const GATEWAY_URL = window.OPENCLAW_WS || \"ws://localhost:8080/ws\";")
      .AppendLine("")
      .AppendLine("    const nodes = [")
      .AppendLine("      { id: \"GW1\", x: 160, y: 110, status: \"unknown\" },")
      .AppendLine("      { id: \"GW2\", x: 480, y: 110, status: \"unknown\" },")
      .AppendLine("      { id: \"HUB\", x: 320, y:  55, status: \"ok\"      },")
      .AppendLine("    ];")
      .AppendLine("    const edges = [[0,2],[1,2]];")
      .AppendLine("")
      .AppendLine("    let pulse = 0;")
      .AppendLine("")
      .AppendLine("    function drawNode(n) {")
      .AppendLine("      const color = n.status === \"ok\" ? \"#3fb950\" : n.status === \"error\" ? \"#f85149\" : \"#8b949e\";")
      .AppendLine("      ctx.beginPath();")
      .AppendLine("      ctx.arc(n.x, n.y, 22 + (n.status === \"ok\" ? Math.sin(pulse) * 3 : 0), 0, Math.PI * 2);")
      .AppendLine("      ctx.strokeStyle = color;")
      .AppendLine("      ctx.lineWidth = 2;")
      .AppendLine("      ctx.stroke();")
      .AppendLine("      ctx.fillStyle = \"#161b22\";")
      .AppendLine("      ctx.fill();")
      .AppendLine("      ctx.fillStyle = color;")
      .AppendLine("      ctx.font = \"bold 11px monospace\";")
      .AppendLine("      ctx.textAlign = \"center\";")
      .AppendLine("      ctx.textBaseline = \"middle\";")
      .AppendLine("      ctx.fillText(n.id, n.x, n.y);")
      .AppendLine("    }")
      .AppendLine("")
      .AppendLine("    function drawEdge(a, b, active) {")
      .AppendLine("      ctx.beginPath();")
      .AppendLine("      ctx.moveTo(nodes[a].x, nodes[a].y);")
      .AppendLine("      ctx.lineTo(nodes[b].x, nodes[b].y);")
      .AppendLine("      ctx.strokeStyle = active ? \"#3fb95066\" : \"#30363d\";")
      .AppendLine("      ctx.lineWidth = active ? 2 : 1;")
      .AppendLine("      ctx.setLineDash(active ? [] : [4, 4]);")
      .AppendLine("      ctx.stroke();")
      .AppendLine("      ctx.setLineDash([]);")
      .AppendLine("    }")
      .AppendLine("")
      .AppendLine("    function render() {")
      .AppendLine("      ctx.clearRect(0, 0, canvas.width, canvas.height);")
      .AppendLine("      edges.forEach(([a, b]) => drawEdge(a, b, nodes[a].status === \"ok\" && nodes[b].status === \"ok\"));")
      .AppendLine("      nodes.forEach(drawNode);")
      .AppendLine("      pulse += 0.07;")
      .AppendLine("      requestAnimationFrame(render);")
      .AppendLine("    }")
      .AppendLine("    render();")
      .AppendLine("")
      .AppendLine("    function addLog(msg, type = \"\") {")
      .AppendLine("      const el = document.createElement(\"div\");")
      .AppendLine("      el.className = type;")
      .AppendLine("      el.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;")
      .AppendLine("      log.prepend(el);")
      .AppendLine("      if (log.children.length > 60) log.lastChild.remove();")
      .AppendLine("    }")
      .AppendLine("")
      .AppendLine("    /* HTML5 WebSocket — real-time gateway events */")
      .AppendLine("    function connectWS() {")
      .AppendLine("      const ws = new WebSocket(GATEWAY_URL);")
      .AppendLine("      ws.onopen  = () => { addLog(\"WebSocket connected\", \"ok\"); nodes[2].status = \"ok\"; };")
      .AppendLine("      ws.onclose = () => { addLog(\"WebSocket closed — retrying in 3s\", \"err\");")
      .AppendLine("                           nodes.forEach(n => n.status = \"error\");")
      .AppendLine("                           setTimeout(connectWS, 3000); };")
      .AppendLine("      ws.onerror = () => addLog(\"WebSocket error\", \"err\");")
      .AppendLine("      ws.onmessage = ({ data }) => {")
      .AppendLine("        try {")
      .AppendLine("          const { node, status, latency } = JSON.parse(data);")
      .AppendLine("          const n = nodes.find(n => n.id === node);")
      .AppendLine("          if (n) n.status = status;")
      .AppendLine("          addLog(`${node} — ${status} (${latency}ms)`," +
                        " status === \"ok\" ? \"ok\" : \"err\");")
      .AppendLine("        } catch { addLog(data); }")
      .AppendLine("      };")
      .AppendLine("    }")
      .AppendLine("")
      .AppendLine("    /* HTML5 Server-Sent Events — fallback */")
      .AppendLine("    function connectSSE() {")
      .AppendLine("      const es = new EventSource(GATEWAY_URL.replace(\"ws\",\"http\").replace(\"/ws\",\"/events\"));")
      .AppendLine("      es.onmessage = ({ data }) => addLog(`SSE: ${data}`, \"ok\");")
      .AppendLine("      es.onerror   = () => addLog(\"SSE stream error\", \"err\");")
      .AppendLine("    }")
      .AppendLine("")
      .AppendLine("    /* HTML5 localStorage — persist last known state */")
      .AppendLine("    window.addEventListener(\"beforeunload\", () =>")
      .AppendLine("      localStorage.setItem(\"openclaw-nodes\", JSON.stringify(nodes)));")
      .AppendLine("    const saved = localStorage.getItem(\"openclaw-nodes\");")
      .AppendLine("    if (saved) JSON.parse(saved).forEach((s, i) => nodes[i].status = s.status);")
      .AppendLine("")
      .AppendLine("    \"WebSocket\" in window ? connectWS() : connectSSE();")
      .AppendLine("  </script>")
      .AppendLine("</body>")
      .AppendLine("</html>")
    
    sb.ToString()

[<EntryPoint>]
let main argv =
    try
        let filename = 
            if argv.Length > 0 then argv.[0] 
            else "node-monitor.html"
            
        let content = generateHtmlContent()
        File.WriteAllText(filename, content)
        printfn "HTML file generated: %s" filename
        0
    with
    | ex ->
        eprintfn "Error generating HTML file: %s" ex.Message
        1
