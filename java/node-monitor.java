// abstraction-provenance: {"artifact_sha256": "4ffb3d971771f75a4aece299f3acb1dfdf7afd76dfea4496d2cd3d69f1111453", "source_sha256": "ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe", "target_language": "java"}
// node-monitor.html — portiert nach java
// Quelle: html, OpenClaw@main:examples/node-monitor.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.util.*;
import java.util.List;
import java.util.concurrent.*;
import javax.swing.*;
import javax.swing.text.*;
import org.json.*;

public class NodeMonitor extends JFrame {
    private static final String VERSION = "1.0";
    private static final String GATEWAY_URL = System.getenv().getOrDefault("OPENCLAW_WS", "ws://localhost:8080/ws");
    
    // Color scheme
    private static final Color BG_COLOR = new Color(13, 17, 23);
    private static final Color SURFACE_COLOR = new Color(22, 27, 34);
    private static final Color BORDER_COLOR = new Color(48, 54, 61);
    private static final Color TEXT_COLOR = new Color(230, 237, 243);
    private static final Color GREEN_COLOR = new Color(63, 185, 80);
    private static final Color RED_COLOR = new Color(248, 81, 73);
    private static final Color ACCENT_COLOR = new Color(88, 166, 255);
    
    private CanvasPanel canvasPanel;
    private LogPanel logPanel;
    private Timer animationTimer;
    private double pulse = 0;
    private List<Node> nodes;
    private List<Edge> edges;
    private WebSocketClient wsClient;
    private ScheduledExecutorService scheduler;
    
    public NodeMonitor() {
        setTitle("OpenClaw — Live Node Monitor");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(660, 420);
        setLocationRelativeTo(null);
        
        initializeComponents();
        setupLayout();
        loadSavedState();
        startAnimation();
        
        scheduler = Executors.newScheduledThreadPool(1);
        connectWebSocket();
    }
    
    private void initializeComponents() {
        nodes = Arrays.asList(
            new Node("GW1", 160, 110, "unknown"),
            new Node("GW2", 480, 110, "unknown"),
            new Node("HUB", 320, 55, "ok")
        );
        
        edges = Arrays.asList(
            new Edge(0, 2),
            new Edge(1, 2)
        );
        
        canvasPanel = new CanvasPanel();
        logPanel = new LogPanel();
    }
    
    private void setupLayout() {
        setLayout(new BorderLayout());
        
        add(canvasPanel, BorderLayout.CENTER);
        
        JScrollPane scrollPane = new JScrollPane(logPanel);
        scrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
        scrollPane.setPreferredSize(new Dimension(640, 140));
        scrollPane.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createEmptyBorder(10, 0, 0, 0),
            BorderFactory.createLineBorder(BORDER_COLOR)
        ));
        ((JComponent) scrollPane.getViewport().getView()).setOpaque(false);
        scrollPane.getViewport().setOpaque(false);
        
        add(scrollPane, BorderLayout.SOUTH);
        
        // Add title label
        JLabel titleLabel = new JLabel("OpenClaw — Live Node Monitor");
        titleLabel.setForeground(ACCENT_COLOR);
        titleLabel.setFont(titleLabel.getFont().deriveFont(Font.BOLD, 14f));
        titleLabel.setBorder(BorderFactory.createEmptyBorder(0, 0, 10, 0));
        add(titleLabel, BorderLayout.NORTH);
    }
    
    private void startAnimation() {
        animationTimer = new Timer(16, e -> {
            pulse += 0.07;
            canvasPanel.repaint();
        });
        animationTimer.start();
    }
    
    private void connectWebSocket() {
        try {
            wsClient = new WebSocketClient(new URI(GATEWAY_URL)) {
                @Override
                public void onOpen(ServerHandshake handshakedata) {
                    SwingUtilities.invokeLater(() -> {
                        addLog("WebSocket connected", "ok");
                        nodes.get(2).status = "ok";
                    });
                }
                
                @Override
                public void onMessage(String message) {
                    SwingUtilities.invokeLater(() -> {
                        try {
                            JSONObject json = new JSONObject(message);
                            String node = json.getString("node");
                            String status = json.getString("status");
                            int latency = json.getInt("latency");
                            
                            for (Node n : nodes) {
                                if (n.id.equals(node)) {
                                    n.status = status;
                                    break;
                                }
                            }
                            
                            addLog(node + " — " + status + " (" + latency + "ms)", 
                                  status.equals("ok") ? "ok" : "err");
                        } catch (Exception ex) {
                            addLog(message);
                        }
                    });
                }
                
                @Override
                public void onClose(int code, String reason, boolean remote) {
                    SwingUtilities.invokeLater(() -> {
                        addLog("WebSocket closed — retrying in 3s", "err");
                        for (Node n : nodes) {
                            n.status = "error";
                        }
                        
                        scheduler.schedule(() -> {
                            try {
                                connectWebSocket();
                            } catch (Exception e) {
                                addLog("Failed to reconnect WebSocket", "err");
                            }
                        }, 3, TimeUnit.SECONDS);
                    });
                }
                
                @Override
                public void onError(Exception ex) {
                    SwingUtilities.invokeLater(() -> {
                        addLog("WebSocket error: " + ex.getMessage(), "err");
                    });
                }
            };
            
            wsClient.connect();
        } catch (URISyntaxException e) {
            addLog("Invalid WebSocket URL: " + e.getMessage(), "err");
        }
    }
    
    private void addLog(String message) {
        addLog(message, "");
    }
    
    private void addLog(String message, String type) {
        logPanel.addMessage("[" + java.time.LocalTime.now().toString() + "] " + message, type);
    }
    
    private void loadSavedState() {
        try {
            String saved = System.getProperty("openclaw.nodes.state", "");
            if (!saved.isEmpty()) {
                JSONArray array = new JSONArray(saved);
                for (int i = 0; i < Math.min(array.length(), nodes.size()); i++) {
                    nodes.get(i).status = array.getJSONObject(i).getString("status");
                }
            }
        } catch (Exception e) {
            // Ignore invalid saved state
        }
    }
    
    private void saveState() {
        try {
            JSONArray array = new JSONArray();
            for (Node node : nodes) {
                JSONObject obj = new JSONObject();
                obj.put("status", node.status);
                array.put(obj);
            }
            System.setProperty("openclaw.nodes.state", array.toString());
        } catch (Exception e) {
            // Ignore save errors
        }
    }
    
    @Override
    public void dispose() {
        saveState();
        if (wsClient != null) {
            wsClient.close();
        }
        if (scheduler != null) {
            scheduler.shutdown();
        }
        if (animationTimer != null) {
            animationTimer.stop();
        }
        super.dispose();
    }
    
    public static void main(String[] args) {
        if (args.length > 0) {
            try {
                Files.write(Paths.get(args[0]), generateHtml().getBytes());
                System.out.println("HTML file generated: " + args[0]);
            } catch (IOException e) {
                System.err.println("Error writing file: " + e.getMessage());
                System.exit(1);
            }
        } else {
            SwingUtilities.invokeLater(() -> {
                try {
                    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeel());
                } catch (Exception e) {
                    // Use default look and feel
                }
                new NodeMonitor().setVisible(true);
            });
        }
    }
    
    private static String generateHtml() {
        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html>\n");
        html.append("<html lang=\"en\">\n");
        html.append("<head>\n");
        html.append("  <meta charset=\"UTF-8\">\n");
        html.append("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
        html.append("  <title>OpenClaw — Live Node Monitor</title>\n");
        html.append("  <style>\n");
        html.append("    :root { --bg: #0d1117; --surface: #161b22; --border: #30363d;\n");
        html.append("            --text: #e6edf3; --green: #3fb950; --red: #f85149; --accent: #58a6ff; }\n");
        html.append("    * { box-sizing: border-box; margin: 0; padding: 0; }\n");
        html.append("    body { background: var(--bg); color: var(--text);\n");
        html.append("           font-family: -apple-system, sans-serif; padding: 1.5rem; }\n");
        html.append("    h1   { color: var(--accent); margin-bottom: 1rem; font-size: 1.2rem; }\n");
        html.append("    canvas { display: block; border: 1px solid var(--border);\n");
        html.append("             border-radius: 8px; background: var(--surface); }\n");
        html.append("    #log { margin-top: 1rem; height: 140px; overflow-y: auto;\n");
        html.append("           background: var(--surface); border: 1px solid var(--border);\n");
        html.append("           border-radius: 8px; padding: .75rem; font-size: .78rem;\n");
        html.append("           font-family: monospace; color: #8b949e; }\n");
        html.append("    #log .err { color: var(--red); }\n");
        html.append("    #log .ok  { color: var(--green); }\n");
        html.append("  </style>\n");
        html.append("</head>\n");
        html.append("<body>\n");
        html.append("  <h1>OpenClaw — Live Node Monitor</h1>\n");
        html.append("  <canvas id=\"canvas\" width=\"640\" height=\"220\"></canvas>\n");
        html.append("  <div id=\"log\"></div>\n");
        html.append("\n");
        html.append("  <script>\n");
        html.append("    /* HTML5 Canvas — animated node topology */\n");
        html.append("    const canvas = document.getElementById(\"canvas\");\n");
        html.append("    const ctx    = canvas.getContext(\"2d\");\n");
        html.append("    const log    = document.getElementById(\"log\");\n");
        html.append("    const GATEWAY_URL = window.OPENCLAW_WS || \"ws://localhost:8080/ws\";\n");
        html.append("\n");
        html.append("    const nodes = [\n");
        html.append("      { id: \"GW1\", x: 160, y: 110, status: \"unknown\" },\n");
        html.append("      { id: \"GW2\", x: 480, y: 110, status: \"unknown\" },\n");
        html.append("      { id: \"HUB\", x: 320, y:  55, status: \"ok\"      },\n");
        html.append("    ];\n");
        html.append("    const edges = [[0,2],[1,2]];\n");
        html.append("\n");
        html.append("    let pulse = 0;\n");
        html.append("\n");
        html.append("    function drawNode(n) {\n");
        html.append("      const color = n.status === \"ok\" ? \"#3fb950\" : n.status === \"error\" ? \"#f85149\" : \"#8b949e\";\n");
        html.append("      ctx.beginPath();\n");
        html.append("      ctx.arc(n.x, n.y, 22 + (n.status === \"ok\" ? Math.sin(pulse) * 3 : 0), 0, Math.PI * 2);\n");
        html.append("      ctx.strokeStyle = color;\n");
        html.append("      ctx.lineWidth = 2;\n");
        html.append("      ctx.stroke();\n");
        html.append("      ctx.fillStyle = \"#161b22\";\n");
        html.append("      ctx.fill();\n");
        html.append("      ctx.fillStyle = color;\n");
        html.append("      ctx.font = \"bold 11px monospace\";\n");
        html.append("      ctx.textAlign = \"center\";\n");
        html.append("      ctx.textBaseline = \"middle\";\n");
        html.append("      ctx.fillText(n.id, n.x, n.y);\n");
        html.append("    }\n");
        html.append("\n");
        html.append("    function drawEdge(a, b, active) {\n");
        html.append("      ctx.beginPath();\n");
        html.append("      ctx.moveTo(nodes[a].x, nodes[a].y);\n");
        html.append("      ctx.lineTo(nodes[b].x, nodes[b].y);\n");
        html.append("      ctx.strokeStyle = active ? \"#3fb95066\" : \"#30363d\";\n");
        html.append("      ctx.lineWidth = active ? 2 : 1;\n");
        html.append("      ctx.setLineDash(active ? [] : [4, 4]);\n");
        html.append("      ctx.stroke();\n");
        html.append("      ctx.setLineDash([]);\n");
        html.append("    }\n");
        html.append("\n");
        html.append("    function render() {\n");
        html.append("      ctx.clearRect(0, 0, canvas.width, canvas.height);\n");
        html.append("      edges.forEach(([a, b]) => drawEdge(a, b, nodes[a].status === \"ok\" && nodes[b].status === \"ok\"));\n");
        html.append("      nodes.forEach(drawNode);\n");
        html.append("      pulse += 0.07;\n");
        html.append("      requestAnimationFrame(render);\n");
        html.append("    }\n");
        html.append("    render();\n");
        html.append("\n");
        html.append("    function addLog(msg, type = \"\") {\n");
        html.append("      const el = document.createElement(\"div\");\n");
        html.append("      el.className = type;\n");
        html.append("      el.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;\n");
        html.append("      log.prepend(el);\n");
        html.append("      if (log.children.length > 60) log.lastChild.remove();\n");
        html.append("    }\n");
        html.append("\n");
        html.append("    /* HTML5 WebSocket — real-time gateway events */\n");
        html.append("    function connectWS() {\n");
        html.append("      const ws = new WebSocket(GATEWAY_URL);\n");
        html.append("      ws.onopen  = () => { addLog(\"WebSocket connected\", \"ok\"); nodes[2].status = \"ok\"; };\n");
        html.append("      ws.onclose = () => { addLog(\"WebSocket closed — retrying in 3s\", \"err\");\n");
        html.append("                           nodes.forEach(n => n.status = \"error\");\n");
        html.append("                           setTimeout(connectWS, 3000); };\n");
        html.append("      ws.onerror = () => addLog(\"WebSocket error\", \"err\");\n");
        html.append("      ws.onmessage = ({ data }) => {\n");
        html.append("        try {\n");
        html.append("          const { node, status, latency } = JSON.parse(data);\n");
        html.append("          const n = nodes.find(n => n.id === node);\n");
        html.append("          if (n) n.status = status;\n");
        html.append("          addLog(`${node} — ${status} (${latency}ms)`, status === \"ok\" ? \"ok\" : \"err\");\n");
        html.append("        } catch { addLog(data); }\n");
        html.append("      };\n");
        html.append("    }\n");
        html.append("\n");
        html.append("    /* HTML5 Server-Sent Events — fallback */\n");
        html.append("    function connectSSE() {\n");
        html.append("      const es = new EventSource(GATEWAY_URL.replace(\"ws\",\"http\").replace(\"/ws\",\"/events\"));\n");
        html.append("      es.onmessage = ({ data }) => addLog(`SSE: ${data}`, \"ok\");\n");
        html.append("      es.onerror   = () => addLog(\"SSE stream error\", \"err\");\n");
        html.append("    }\n");
        html.append("\n");
        html.append("    /* HTML5 localStorage — persist last known state */\n");
        html.append("    window.addEventListener(\"beforeunload\", () =>\n");
        html.append("      localStorage.setItem(\"openclaw-nodes\", JSON.stringify(nodes)));\n");
        html.append("    const saved = localStorage.getItem(\"openclaw-nodes\");\n");
        html.append("    if (saved) JSON.parse(saved).forEach((s, i) => nodes[i].status = s.status);\n");
        html.append("\n");
        html.append("    \"WebSocket\" in window ? connectWS() : connectSSE();\n");
        html.append("  </script>\n");
        html.append("</body>\n");
        html.append("</html>\n");
        
        return html.toString();
    }
    
    // Inner classes
    private class Node {
        String id;
        int x, y;
        String status;
        
        Node(String id, int x, int y, String status) {
            this.id = id;
            this.x = x;
            this.y = y;
            this.status = status;
        }
    }
    
    private class Edge {
        int a, b;
        
        Edge(int a, int b) {
            this.a = a;
            this.b = b;
        }
    }
    
    private class CanvasPanel extends JPanel {
        public CanvasPanel() {
            setPreferredSize(new Dimension(640, 220));
            setBackground(SURFACE_COLOR);
            setBorder(BorderFactory.createLineBorder(BORDER_COLOR));
        }
        
        @Override
        protected void paintComponent(Graphics g) {
            super.paintComponent(g);
            Graphics2D g2d = (Graphics2D) g.create();
            g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            
            // Draw edges
            for (Edge edge : edges) {
                drawEdge(g2d, edge.a, edge.b);
            }
            
            // Draw nodes
            for (Node node : nodes) {
                drawNode(g2d, node);
            }
            
            g2d.dispose();
        }
        
        private void drawNode(Graphics2D g2d, Node n) {
            Color color;
            switch (n.status) {
                case "ok": color = GREEN_COLOR; break;
                case "error": color = RED_COLOR; break;
                default: color = new Color(139, 148, 158); break;
            }
            
            g2d.setColor(color);
            int radius = 22;
            if (n.status.equals("ok")) {
                radius += (int)(Math.sin(pulse) * 3);
            }
            
            g2d.setStroke(new BasicStroke(2));
            g2d.drawOval(n.x - radius, n.y - radius, radius * 2, radius * 2);
            
            g2d.setColor(SURFACE_COLOR);
            g2d.fillOval(n.x - radius, n.y - radius, radius * 2, radius * 2);
            
            g2d.setColor(color);
            Font font = new Font(Font.MONOSPACED, Font.BOLD, 11);
            g2d.setFont(font);
            FontMetrics fm = g2d.getFontMetrics();
            int textWidth = fm.stringWidth(n.id);
            g2d.drawString(n.id, n.x - textWidth/2, n.y + fm.getAscent()/2 - 1);
        }
        
        private void drawEdge(Graphics2D g2d, int aIndex, int bIndex) {
            Node a = nodes.get(aIndex);
            Node b = nodes.get(bIndex);
            boolean active = a.status.equals("ok") && b.status.equals("ok");
            
            if (active) {
                g2d.setColor(new Color(63, 185, 80, 102)); // #3fb95066
                g2d.setStroke(new BasicStroke(2));
            } else {
                g2d.setColor(BORDER_COLOR);
                g2d.setStroke(new BasicStroke(1, BasicStroke.CAP_BUTT, BasicStroke.JOIN_MITER, 10, new float[]{4, 4}, 0));
            }
            
            g2d.drawLine(a.x, a.y, b.x, b.y);
        }
    }
    
    private class LogPanel extends JPanel {
        private final JTextPane textPane;
        private final SimpleAttributeSet defaultStyle;
        private final SimpleAttributeSet errorStyle;
        private final SimpleAttributeSet okStyle;
        
        public LogPanel() {
            setLayout(new BorderLayout());
            setBackground(SURFACE_COLOR);
            
            textPane = new JTextPane();
            textPane.setEditable(false);
            textPane.setBackground(SURFACE_COLOR);
            textPane.setForeground(new Color(139, 148, 158));
            textPane.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
            
            JScrollPane scrollPane = new JScrollPane(textPane);
            scrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
            scrollPane.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
            scrollPane.setBorder(null);
            add(scrollPane, BorderLayout.CENTER);
            
            // Setup styles
            defaultStyle = new SimpleAttributeSet();
            errorStyle = new SimpleAttributeSet();
            StyleConstants.setForeground(errorStyle, RED_COLOR);
            okStyle = new SimpleAttributeSet();
            StyleConstants.setForeground(okStyle, GREEN_COLOR);
        }
        
        public void addMessage(String message, String type) {
            StyledDocument doc = textPane.getStyledDocument();
            try {
                AttributeSet style;
                switch (type) {
                    case "err": style = errorStyle; break;
                    case "ok": style = okStyle; break;
                    default: style = defaultStyle; break;
                }
                
                doc.insertString(0, message + "\n", style);
                
                // Limit to 60 messages
                String[] lines = textPane.getText().split("\n");
                if (lines.length > 60) {
                    int lastNewline = doc.getLength() - 1;
                    while (lastNewline >= 0 && lines.length > 60) {
                        lastNewline = textPane.getText().lastIndexOf('\n', lastNewline - 1);
                        lines = textPane.getText().substring(0, lastNewline + 1).split("\n");
                    }
                    if (lastNewline >= 0) {
                        doc.remove(lastNewline + 1, doc.getLength() - lastNewline - 1);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
