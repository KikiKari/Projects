// abstraction-provenance: {"artifact_sha256": "770e093c22b40d732bc3335baecdf2c771c1d733e8c5e324defebaad841acb84", "source_sha256": "9be2a45ff3b835da1be1793cc88c8cb54d6a2456cf2ccc358c8243df836440e3", "target_language": "java"}
// status-overview-panel.css — portiert nach java
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview-panel.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;

public class StatusOverviewPanel {
    
    public static void generateCSS(String outputPath) throws IOException {
        try (FileWriter writer = new FileWriter(outputPath)) {
            // .overview-row
            writer.write(".overview-row { ");
            writer.write("display: grid; ");
            writer.write("grid-template-columns: 24px minmax(0, 1fr) 11px 22px auto; ");
            writer.write("gap: 7px; ");
            writer.write("align-items: center; ");
            writer.write("margin: 6px 0; ");
            writer.write("}\n");
            
            // .overview-row input
            writer.write(".overview-row input { ");
            writer.write("min-width: 0; ");
            writer.write("width: 100%; ");
            writer.write("}\n");
            
            // .overview-state
            writer.write(".overview-state { ");
            writer.write("width: 11px; ");
            writer.write("height: 11px; ");
            writer.write("border-radius: 50%; ");
            writer.write("background: #888; ");
            writer.write("}\n");
            
            // .overview-state.online
            writer.write(".overview-state.online { ");
            writer.write("background: var(--good); ");
            writer.write("box-shadow: 0 0 0 3px color-mix(in srgb, var(--good) 15%, transparent); ");
            writer.write("}\n");
            
            // .overview-state.offline
            writer.write(".overview-state.offline { ");
            writer.write("background: var(--bad); ");
            writer.write("box-shadow: 0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent); ");
            writer.write("}\n");
            
            // .overview-state.checking, .overview-state.error
            writer.write(".overview-state.checking, .overview-state.error { ");
            writer.write("background: var(--warn); ");
            writer.write("}\n");
            
            // .overview-count
            writer.write(".overview-count { ");
            writer.write("font-size: 11px; ");
            writer.write("text-align: center; ");
            writer.write("font-variant-numeric: tabular-nums; ");
            writer.write("}\n");
            
            // .overview-actions
            writer.write(".overview-actions { ");
            writer.write("display: grid; ");
            writer.write("grid-template-columns: 44px repeat(2, minmax(0, 1fr)); ");
            writer.write("gap: 6px; ");
            writer.write("align-items: stretch; ");
            writer.write("}\n");
            
            // .overview-actions button
            writer.write(".overview-actions button { ");
            writer.write("min-width: 0; ");
            writer.write("padding: 8px 2px; ");
            writer.write("font-size: 11px; ");
            writer.write("white-space: nowrap; ");
            writer.write("}\n");
            
            // #overview-rows
            writer.write("#overview-rows { ");
            writer.write("display: flex; ");
            writer.write("flex-direction: column; ");
            writer.write("}\n");
            
            // .monitor-settings > label:not(.option-row)
            writer.write(".monitor-settings > label:not(.option-row) { ");
            writer.write("display: block; ");
            writer.write("margin: 12px 0; ");
            writer.write("}\n");
            
            // .monitor-settings .option-row input
            writer.write(".monitor-settings .option-row input { ");
            writer.write("appearance: auto; ");
            writer.write("width: 13px; ");
            writer.write("height: 13px; ");
            writer.write("min-width: 13px; ");
            writer.write("background: none; ");
            writer.write("}\n");
            
            // .overview-link
            writer.write(".overview-link { ");
            writer.write("padding: 8px 0; ");
            writer.write("border-bottom: 1px solid #bbb; ");
            writer.write("overflow-wrap: anywhere; ");
            writer.write("}\n");
            
            // .overview-link p
            writer.write(".overview-link p { ");
            writer.write("margin: 4px 0; ");
            writer.write("}\n");
            
            // .overview-row .overview-retry
            writer.write(".overview-row .overview-retry { ");
            writer.write("width: 24px; ");
            writer.write("min-width: 24px; ");
            writer.write("height: 26px; ");
            writer.write("min-height: 26px; ");
            writer.write("padding: 0; ");
            writer.write("background-image: var(--icon-reset); ");
            writer.write("background-size: 20px; ");
            writer.write("background-position: center; ");
            writer.write("background-repeat: no-repeat; ");
            writer.write("}\n");
            
            // .top-setting input
            writer.write(".top-setting input { ");
            writer.write("appearance: auto; ");
            writer.write("-webkit-appearance: checkbox; ");
            writer.write("width: 13px; ");
            writer.write("height: 13px; ");
            writer.write("min-width: 13px; ");
            writer.write("background: none; ");
            writer.write("}\n");
            
            // .overview-visually-hidden
            writer.write(".overview-visually-hidden { ");
            writer.write("position: absolute; ");
            writer.write("width: 1px; ");
            writer.write("height: 1px; ");
            writer.write("padding: 0; ");
            writer.write("margin: -1px; ");
            writer.write("overflow: hidden; ");
            writer.write("clip: rect(0, 0, 0, 0); ");
            writer.write("white-space: nowrap; ");
            writer.write("border: 0; ");
            writer.write("}\n");
            
            // .overview-row[hidden]
            writer.write(".overview-row[hidden] { ");
            writer.write("display: none; ");
            writer.write("}\n");
        }
    }
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java StatusOverviewPanel <output-file-path>");
            System.exit(1);
        }
        
        try {
            generateCSS(args[0]);
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            System.exit(1);
        }
    }
}
