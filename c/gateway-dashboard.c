// abstraction-provenance: {"artifact_sha256": "e95b75aaf31bc12e59b05a625a10b72bbff862267cc4e9ab10070340aab7b212", "source_sha256": "ea0eb33b2baa2fe609d171d70b4b6f712df52229f647c3ac02833fc01d629d35", "target_language": "c"}
// gateway-dashboard.html — portiert nach c
// Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_html_header(FILE *file) {
    fprintf(file, "<!DOCTYPE html>\n");
    fprintf(file, "<html lang=\"en\">\n");
    fprintf(file, "<head>\n");
    fprintf(file, "  <meta charset=\"UTF-8\">\n");
    fprintf(file, "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
    fprintf(file, "  <title>OpenClaw — Gateway Dashboard</title>\n");
    fprintf(file, "  <link rel=\"stylesheet\" href=\"gateway-styles.css\">\n");
    fprintf(file, "</head>\n");
    fprintf(file, "<body>\n");
}

void write_html_footer(FILE *file) {
    fprintf(file, "</body>\n");
    fprintf(file, "</html>\n");
}

void write_header_section(FILE *file) {
    fprintf(file, "  <header>\n");
    fprintf(file, "    <h1>OpenClaw Cluster</h1>\n");
    fprintf(file, "    <span id=\"cluster-status\" class=\"badge\">Checking...</span>\n");
    fprintf(file, "  </header>\n\n");
}

void write_main_content(FILE *file) {
    fprintf(file, "  <main>\n");
    fprintf(file, "    <section class=\"grid\">\n");
    fprintf(file, "      <div class=\"card\" id=\"gw1\">\n");
    fprintf(file, "        <h2>Gateway 1</h2>\n");
    fprintf(file, "        <p class=\"endpoint\">gateway1.openclaw.internal</p>\n");
    fprintf(file, "        <div class=\"status-dot\"></div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div class=\"card\" id=\"gw2\">\n");
    fprintf(file, "        <h2>Gateway 2</h2>\n");
    fprintf(file, "        <p class=\"endpoint\">gateway2.openclaw.internal</p>\n");
    fprintf(file, "        <div class=\"status-dot\"></div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "    </section>\n\n");
    
    fprintf(file, "    <section class=\"metrics\">\n");
    fprintf(file, "      <h2>Node Metrics</h2>\n");
    fprintf(file, "      <table>\n");
    fprintf(file, "        <thead>\n");
    fprintf(file, "          <tr><th>Node</th><th>Latency</th><th>Requests</th><th>Status</th></tr>\n");
    fprintf(file, "        </thead>\n");
    fprintf(file, "        <tbody id=\"metrics-body\">\n");
    fprintf(file, "          <tr><td colspan=\"4\">Loading...</td></tr>\n");
    fprintf(file, "        </tbody>\n");
    fprintf(file, "      </table>\n");
    fprintf(file, "    </section>\n");
    fprintf(file, "  </main>\n\n");
}

void write_javascript_section(FILE *file) {
    fprintf(file, "  <script>\n");
    fprintf(file, "    const GATEWAY_URL = window.OPENCLAW_URL || \"http://localhost:8080\";\n\n");
    fprintf(file, "    async function pollStatus() {\n");
    fprintf(file, "      try {\n");
    fprintf(file, "        const res = await fetch(`${GATEWAY_URL}/health`);\n");
    fprintf(file, "        const ok = res.ok;\n");
    fprintf(file, "        document.getElementById(\"cluster-status\").textContent = ok ? \"Online\" : \"Degraded\";\n");
    fprintf(file, "        document.getElementById(\"cluster-status\").className = `badge ${ok ? \"ok\" : \"warn\"}`;\n");
    fprintf(file, "        document.querySelectorAll(\".status-dot\").forEach(d => d.className = `status-dot ${ok ? \"green\" : \"red\"}`);\n");
    fprintf(file, "      } catch {\n");
    fprintf(file, "        document.getElementById(\"cluster-status\").textContent = \"Offline\";\n");
    fprintf(file, "        document.getElementById(\"cluster-status\").className = \"badge error\";\n");
    fprintf(file, "      }\n");
    fprintf(file, "    }\n\n");
    fprintf(file, "    pollStatus();\n");
    fprintf(file, "    setInterval(pollStatus, 5000);\n");
    fprintf(file, "  </script>\n");
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
        return 1;
    }

    FILE *output_file = fopen(argv[1], "w");
    if (!output_file) {
        perror("Error opening file");
        return 1;
    }

    write_html_header(output_file);
    write_header_section(output_file);
    write_main_content(output_file);
    write_javascript_section(output_file);
    write_html_footer(output_file);

    fclose(output_file);
    return 0;
}
