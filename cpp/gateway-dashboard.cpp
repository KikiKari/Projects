// abstraction-provenance: {"artifact_sha256": "ec32e3913e340cb3de5741cb055f91fb475a123132b85056e53d40e44e4b9859", "source_sha256": "ea0eb33b2baa2fe609d171d70b4b6f712df52229f647c3ac02833fc01d629d35", "target_language": "cpp"}
// gateway-dashboard.html — portiert nach cpp
// Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void writeHTML(const std::string& filename) {
    std::ofstream file(filename);
    
    file << "<!DOCTYPE html>\n";
    file << "<html lang=\"en\">\n";
    file << "<head>\n";
    file << "  <meta charset=\"UTF-8\">\n";
    file << "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n";
    file << "  <title>OpenClaw — Gateway Dashboard</title>\n";
    file << "  <link rel=\"stylesheet\" href=\"gateway-styles.css\">\n";
    file << "</head>\n";
    file << "<body>\n";
    file << "  <header>\n";
    file << "    <h1>OpenClaw Cluster</h1>\n";
    file << "    <span id=\"cluster-status\" class=\"badge\">Checking...</span>\n";
    file << "  </header>\n";
    file << "\n";
    file << "  <main>\n";
    file << "    <section class=\"grid\">\n";
    file << "      <div class=\"card\" id=\"gw1\">\n";
    file << "        <h2>Gateway 1</h2>\n";
    file << "        <p class=\"endpoint\">gateway1.openclaw.internal</p>\n";
    file << "        <div class=\"status-dot\"></div>\n";
    file << "      </div>\n";
    file << "      <div class=\"card\" id=\"gw2\">\n";
    file << "        <h2>Gateway 2</h2>\n";
    file << "        <p class=\"endpoint\">gateway2.openclaw.internal</p>\n";
    file << "        <div class=\"status-dot\"></div>\n";
    file << "      </div>\n";
    file << "    </section>\n";
    file << "\n";
    file << "    <section class=\"metrics\">\n";
    file << "      <h2>Node Metrics</h2>\n";
    file << "      <table>\n";
    file << "        <thead>\n";
    file << "          <tr><th>Node</th><th>Latency</th><th>Requests</th><th>Status</th></tr>\n";
    file << "        </thead>\n";
    file << "        <tbody id=\"metrics-body\">\n";
    file << "          <tr><td colspan=\"4\">Loading...</td></tr>\n";
    file << "        </tbody>\n";
    file << "      </table>\n";
    file << "    </section>\n";
    file << "  </main>\n";
    file << "\n";
    file << "  <script>\n";
    file << "    const GATEWAY_URL = window.OPENCLAW_URL || \"http://localhost:8080\";\n";
    file << "\n";
    file << "    async function pollStatus() {\n";
    file << "      try {\n";
    file << "        const res = await fetch(`${GATEWAY_URL}/health`);\n";
    file << "        const ok = res.ok;\n";
    file << "        document.getElementById(\"cluster-status\").textContent = ok ? \"Online\" : \"Degraded\";\n";
    file << "        document.getElementById(\"cluster-status\").className = `badge ${ok ? \"ok\" : \"warn\"}`;\n";
    file << "        document.querySelectorAll(\".status-dot\").forEach(d => d.className = `status-dot ${ok ? \"green\" : \"red\"}`);\n";
    file << "      } catch {\n";
    file << "        document.getElementById(\"cluster-status\").textContent = \"Offline\";\n";
    file << "        document.getElementById(\"cluster-status\").className = \"badge error\";\n";
    file << "      }\n";
    file << "    }\n";
    file << "\n";
    file << "    pollStatus();\n";
    file << "    setInterval(pollStatus, 5000);\n";
    file << "  </script>\n";
    file << "</body>\n";
    file << "</html>\n";
    
    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output_filename>\n";
        return 1;
    }
    
    writeHTML(argv[1]);
    return 0;
}
