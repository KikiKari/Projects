// abstraction-provenance: {"artifact_sha256": "106ec900fcebe45f0fa945be8938a56a9ac47b101467d301c67ca95357560331", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "java"}
// icon-controls.css — portiert nach java
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class IconControlsGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java IconControlsGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try (FileWriter writer = new FileWriter(outputFile)) {
            generateCSS(writer);
        } catch (IOException e) {
            System.err.println("Error writing to file: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static void generateCSS(FileWriter writer) throws IOException {
        // Define icon styles
        String[] styles = {"plastisch", "glass", "linear"};
        
        for (String style : styles) {
            writer.write("html[data-icon-style=\"" + style + "\"] {");
            
            String[] iconNames = {
                "auto-chat-refresh-counter", "browser", "captions", "chat-counter",
                "fullscreen", "mute", "off", "on", "pip", "play", "player",
                "protection-slider", "recommendation-counter", "report",
                "reset", "settings", "status", "stop", "unmute", "volume-slider"
            };
            
            for (String iconName : iconNames) {
                writer.write("--icon-" + iconName + ":url(\"icons/" + style + "/" + iconName + ".png\");");
            }
            
            writer.write("}\n");
        }
        
        // Button and control styles
        writer.write("button[data-control-icon]::before,.control-icon::before { content:\"\"; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }\n");
        writer.write("button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }\n");
        writer.write("button[data-control-icon][hidden] { display:none; }\n");
        
        // Checkbox styles
        writer.write("input[type=\"checkbox\"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }\n");
        writer.write("input[type=\"checkbox\"]:checked { background-image:var(--icon-on); }\n");
        writer.write("input[type=\"checkbox\"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }\n");
        writer.write("input[type=\"checkbox\"]:disabled { opacity:.45; cursor:default; }\n");
        
        // Control icon styles
        writer.write(".control-icon { display:inline-flex; align-items:center; }\n");
        writer.write("input[type=\"range\"] { min-height:32px; }\n");
        writer.write(".icon-style-setting { display:flex; align-items:center; gap:8px; }\n");
        
        // Data control icon mappings
        String[] controlIcons = {
            "auto-chat-refresh-counter", "browser", "captions", "chat-counter",
            "fullscreen", "mute", "off", "on", "pip", "play", "player",
            "protection-slider", "recommendation-counter", "report",
            "reset", "settings", "status", "stop", "unmute", "volume-slider"
        };
        
        for (String icon : controlIcons) {
            writer.write("[data-control-icon=\"" + icon + "\"] { --control-icon:var(--icon-" + icon + "); }\n");
        }
    }
}
