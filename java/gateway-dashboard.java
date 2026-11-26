// abstraction-provenance: {"artifact_sha256": "92f84f797dc9a1014cd12020577019c6374343edf5643be5d3a0047850fbf8e6", "source_sha256": "ea0eb33b2baa2fe609d171d70b4b6f712df52229f647c3ac02833fc01d629d35", "target_language": "java"}
// gateway-dashboard.html — portiert nach java
// Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class GatewayDashboardGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java GatewayDashboardGenerator <output-file>");
            System.exit(1);
        }

        String outputFile = args[0];
        generateDashboard(outputFile);
    }

    private static void generateDashboard(String outputFile) {
        StringBuilder html = new StringBuilder();
        
        // Begin HTML document
        html.append("<!DOCTYPE html>\n");
        html.append("<html lang=\"en\">\n");
        html.append("<head>\n");
        html.append("  <meta charset=\"UTF-8\">\n");
        html.append("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
        html.append("  <title>OpenClaw — Gateway Dashboard</title>\n");
        html.append("  <link rel=\"stylesheet\" href=\"gateway-styles.css\">\n");
        html.append("</head>\n");
        html.append("<body>\n");
        
        // Header section
        html.append("  <header>\n");
        html.append("    <h1>OpenClaw Cluster</h1>\n");
        html.append("    <span id=\"cluster-status\" class=\"badge\">Checking...</span>\n");
        html.append("  </header>\n");
        
        // Main content
        html.append("  <main>\n");
        
        // Gateway grid section
        html.append("    <section class=\"grid\">\n");
        html.append("      <div class=\"card\" id=\"gw1\">\n");
        html.append("        <h2>Gateway 1</h2>\n");
        html.append("        <p class=\"endpoint\">gateway1.openclaw.internal</p>\n");
        html.append("        <div class=\"status-dot\"></div>\n");
        html.append("      </div>\n");
        html.append("      <div class=\"card\" id=\"gw2\">\n");
        html.append("        <h2>Gateway 2</h2>\n");
        html.append("        <p class=\"endpoint\">gateway2.openclaw.internal</p>\n");
        html.append("        <div class=\"status-dot\"></div>\n");
        html.append("      </div>\n");
        html.append("    </section>\n");
        
        // Metrics section
        html.append("    <section class=\"metrics\">\n");
        html.append("      <h2>Node Metrics</h2>\n");
        html.append("      <table>\n");
        html.append("        <thead>\n");
        html.append("          <tr><th>Node</th><th>Latency</th><th>Requests</th><th>Status</th></tr>\n");
        html.append("        </thead>\n");
        html.append("        <tbody id=\"metrics-body\">\n");
        html.append("          <tr><td colspan=\"4\">Loading...</td></tr>\n");
        html.append("        </tbody>\n");
        html.append("      </table>\n");
        html.append("    </section>\n");
        
        html.append("  </main>\n");
        
        // JavaScript section
        html.append("  <script>\n");
        html.append("    const GATEWAY_URL = window.OPENCLAW_URL || \"http://localhost:8080\";\n\n");
        html.append("    async function pollStatus() {\n");
        html.append("      try {\n");
        html.append("        const res = await fetch(`${GATEWAY_URL}/health`);\n");
        html.append("        const ok = res.ok;\n");
        html.append("        document.getElementById(\"cluster-status\").textContent = ok ? \"Online\" : \"Degraded\";\n");
        html.append("        document.getElementById(\"cluster-status\").className = `badge ${ok ? \"ok\" : \"warn\"}`;\n");
        html.append("        document.querySelectorAll(\".status-dot\").forEach(d => d.className = `status-dot ${ok ? \"green\" : \"red\"}`);\n");
        html.append("      } catch {\n");
        html.append("        document.getElementById(\"cluster-status\").textContent = \"Offline\";\n");
        html.append("        document.getElementById(\"cluster-status\").className = \"badge error\";\n");
        html.append("      }\n");
        html.append("    }\n\n");
        html.append("    pollStatus();\n");
        html.append("    setInterval(pollStatus, 5000);\n");
        html.append("  </script>\n");
        
        // End HTML document
        html.append("</body>\n");
        html.append("</html>\n");
        
        // Write to file
        try (FileWriter writer = new FileWriter(outputFile)) {
            writer.write(html.toString());
        } catch (IOException e) {
            System.err.println("Error writing to file: " + e.getMessage());
            System.exit(1);
        }
    }
}
