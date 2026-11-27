// abstraction-provenance: {"artifact_sha256": "91a8115f23e10284de0c45cbfef57e615400f2db5e25c05c14110824b261c54a", "source_sha256": "ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe", "target_language": "c"}
// node-monitor.html — portiert nach c
// Quelle: html, OpenClaw@main:examples/node-monitor.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_html_file(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        return;
    }

    fprintf(file,
        "<!DOCTYPE html>\n"
        "<html lang=\"en\">\n"
        "<head>\n"
        "  <meta charset=\"UTF-8\">\n"
        "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
        "  <title>OpenClaw — Live Node Monitor</title>\n"
        "  <style>\n"
        "    :root { --bg: #0d1117; --surface: #161b22; --border: #30363d;\n"
        "            --text: #e6edf3; --green: #3fb950; --red: #f85149; --accent: #58a6ff; }\n"
        "    * { box-sizing: border-box; margin: 0; padding: 0; }\n"
        "    body { background: var(--bg); color: var(--text);\n"
        "           font-family: -apple-system, sans-serif; padding: 1.5rem; }\n"
        "    h1   { color: var(--accent); margin-bottom: 1rem; font-size: 1.2rem; }\n"
        "    canvas { display: block; border: 1px solid var(--border);\n"
        "             border-radius: 8px; background: var(--surface); }\n"
        "    #log { margin-top: 1rem; height: 140px; overflow-y: auto;\n"
        "           background: var(--surface); border: 1px solid var(--border);\n"
        "           border-radius: 8px; padding: .75rem; font-size: .78rem;\n"
        "           font-family: monospace; color: #8b949e; }\n"
        "    #log .err { color: var(--red); }\n"
        "    #log .ok  { color: var(--green); }\n"
        "  </style>\n"
        "</head>\n"
        "<body>\n"
        "  <h1>OpenClaw — Live Node Monitor</h1>\n"
        "  <canvas id=\"canvas\" width=\"640\" height=\"220\"></canvas>\n"
        "  <div id=\"log\"></div>\n"
        "\n"
        "  <script>\n"
        "    /* HTML5 Canvas — animated node topology */\n"
        "    const canvas = document.getElementById(\"canvas\");\n"
        "    const ctx    = canvas.getContext(\"2d\");\n"
        "    const log    = document.getElementById(\"log\");\n"
        "    const GATEWAY_URL = window.OPENCLAW_WS || \"ws://localhost:8080/ws\";\n"
        "\n"
        "    const nodes = [\n"
        "      { id: \"GW1\", x: 160, y: 110, status: \"unknown\" },\n"
        "      { id: \"GW2\", x: 480, y: 110, status: \"unknown\" },\n"
        "      { id: \"HUB\", x: 320, y:  55, status: \"ok\"      },\n"
        "    ];\n"
        "    const edges = [[0,2],[1,2]];\n"
        "\n"
        "    let pulse = 0;\n"
        "\n"
        "    function drawNode(n) {\n"
        "      const color = n.status === \"ok\" ? \"#3fb950\" : n.status === \"error\" ? \"#f85149\" : \"#8b949e\";\n"
        "      ctx.beginPath();\n"
        "      ctx.arc(n.x, n.y, 22 + (n.status === \"ok\" ? Math.sin(pulse) * 3 : 0), 0, Math.PI * 2);\n"
        "      ctx.strokeStyle = color;\n"
        "      ctx.lineWidth = 2;\n"
        "      ctx.stroke();\n"
        "      ctx.fillStyle = \"#161b22\";\n"
        "      ctx.fill();\n"
        "      ctx.fillStyle = color;\n"
        "      ctx.font = \"bold 11px monospace\";\n"
        "      ctx.textAlign = \"center\";\n"
        "      ctx.textBaseline = \"middle\";\n"
        "      ctx.fillText(n.id, n.x, n.y);\n"
        "    }\n"
        "\n"
        "    function drawEdge(a, b, active) {\n"
        "      ctx.beginPath();\n"
        "      ctx.moveTo(nodes[a].x, nodes[a].y);\n"
        "      ctx.lineTo(nodes[b].x, nodes[b].y);\n"
        "      ctx.strokeStyle = active ? \"#3fb95066\" : \"#30363d\";\n"
        "      ctx.lineWidth = active ? 2 : 1;\n"
        "      ctx.setLineDash(active ? [] : [4, 4]);\n"
        "      ctx.stroke();\n"
        "      ctx.setLineDash([]);\n"
        "    }\n"
        "\n"
        "    function render() {\n"
        "      ctx.clearRect(0, 0, canvas.width, canvas.height);\n"
        "      edges.forEach(([a, b]) => drawEdge(a, b, nodes[a].status === \"ok\" && nodes[b].status === \"ok\"));\n"
        "      nodes.forEach(drawNode);\n"
        "      pulse += 0.07;\n"
        "      requestAnimationFrame(render);\n"
        "    }\n"
        "    render();\n"
        "\n"
        "    function addLog(msg, type = \"\") {\n"
        "      const el = document.createElement(\"div\");\n"
        "      el.className = type;\n"
        "      el.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;\n"
        "      log.prepend(el);\n"
        "      if (log.children.length > 60) log.lastChild.remove();\n"
        "    }\n"
        "\n"
        "    /* HTML5 WebSocket — real-time gateway events */\n"
        "    function connectWS() {\n"
        "      const ws = new WebSocket(GATEWAY_URL);\n"
        "      ws.onopen  = () => { addLog(\"WebSocket connected\", \"ok\"); nodes[2].status = \"ok\"; };\n"
        "      ws.onclose = () => { addLog(\"WebSocket closed — retrying in 3s\", \"err\");\n"
        "                           nodes.forEach(n => n.status = \"error\");\n"
        "                           setTimeout(connectWS, 3000); };\n"
        "      ws.onerror = () => addLog(\"WebSocket error\", \"err\");\n"
        "      ws.onmessage = ({ data }) => {\n"
        "        try {\n"
        "          const { node, status, latency } = JSON.parse(data);\n"
        "          const n = nodes.find(n => n.id === node);\n"
        "          if (n) n.status = status;\n"
        "          addLog(`${node} — ${status} (${latency}ms)`, status === \"ok\" ? \"ok\" : \"err\");\n"
        "        } catch { addLog(data); }\n"
        "      };\n"
        "    }\n"
        "\n"
        "    /* HTML5 Server-Sent Events — fallback */\n"
        "    function connectSSE() {\n"
        "      const es = new EventSource(GATEWAY_URL.replace(\"ws\",\"http\").replace(\"/ws\",\"/events\"));\n"
        "      es.onmessage = ({ data }) => addLog(`SSE: ${data}`, \"ok\");\n"
        "      es.onerror   = () => addLog(\"SSE stream error\", \"err\");\n"
        "    }\n"
        "\n"
        "    /* HTML5 localStorage — persist last known state */\n"
        "    window.addEventListener(\"beforeunload\", () =>\n"
        "      localStorage.setItem(\"openclaw-nodes\", JSON.stringify(nodes)));\n"
        "    const saved = localStorage.getItem(\"openclaw-nodes\");\n"
        "    if (saved) JSON.parse(saved).forEach((s, i) => nodes[i].status = s.status);\n"
        "\n"
        "    \"WebSocket\" in window ? connectWS() : connectSSE();\n"
        "  </script>\n"
        "</body>\n"
        "</html>\n"
    );

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_filename>\n", argv[0]);
        return 1;
    }

    write_html_file(argv[1]);
    return 0;
}
