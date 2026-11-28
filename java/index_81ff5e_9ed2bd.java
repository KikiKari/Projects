// abstraction-provenance: {"artifact_sha256": "6e9e3233604ac46a4c4e353dffb2db025ed3d259be1a7d8782444a00572bf49d", "source_sha256": "9ed2bdeb80b99c649aeb5bf47416f21d76279e40bca0b04d2f75f7e1afd3a910", "target_language": "java"}
// index_81ff5e.css — portiert nach java
// Quelle: css, Projects@abstractions:css/index_81ff5e.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

public class CssGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java CssGenerator <output-file>");
            System.exit(1);
        }
        
        try {
            generateCss(args[0]);
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static void generateCss(String outputFile) throws IOException {
        StringBuilder css = new StringBuilder();
        
        // Add comments
        css.append("/* abstraction-provenance: {\"artifact_sha256\": \"6c7bf507504ec73409a080d09a27627c41cdd58e5cad63094e66d411e563bbf9\", \"source_sha256\": \"81ff5e370288082827f95b7b3dc2b94ce16d7710bcedcfd099f0ea81805a7d12\", \"target_language\": \"css\"} */\n");
        css.append("/* index.html — portiert nach css */\n");
        css.append("/* Quelle: html, Projects@secret-vault-public:secret-vault-public/index.html */\n");
        css.append("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");
        
        // :root rule
        Map<String, String> rootProperties = new LinkedHashMap<>();
        rootProperties.put("color-scheme", "light");
        rootProperties.put("--ink", "#1b1c1f");
        rootProperties.put("--muted", "#6c6e75");
        rootProperties.put("--faint", "#9a9ca3");
        rootProperties.put("--card", "#fff");
        rootProperties.put("--line", "#e9eaee");
        rootProperties.put("--accent", "#5b5bd6");
        rootProperties.put("--accent2", "#7c5cff");
        rootProperties.put("--ok", "#22a06b");
        rootProperties.put("--err", "#e0533d");
        rootProperties.put("--radius", "16px");
        rootProperties.put("--shadow", "0 1px 2px rgba(20, 20, 40, 0.04), 0 6px 20px rgba(20, 20, 40, 0.06)");
        
        css.append(":root {\n");
        for (Map.Entry<String, String> prop : rootProperties.entrySet()) {
            css.append("  ").append(prop.getKey()).append(": ").append(prop.getValue()).append(";\n");
        }
        css.append("}\n\n");
        
        // Universal selector
        css.append("* {\n");
        css.append("  box-sizing: border-box;\n");
        css.append("}\n\n");
        
        // Body rule
        css.append("body {\n");
        css.append("  margin: 0;\n");
        css.append("  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif;\n");
        css.append("  color: var(--ink);\n");
        css.append("  min-height: 100vh;\n");
        css.append("  background: radial-gradient(1100px 560px at 100% -10%, #e8ecff 0%, rgba(232, 236, 255, 0) 55%),\n");
        css.append("    linear-gradient(180deg, #eef1f6, #f7f7f8 42%);\n");
        css.append("  background-attachment: fixed;\n");
        css.append("}\n\n");
        
        // Wrap rule
        css.append(".wrap {\n");
        css.append("  max-width: 820px;\n");
        css.append("  margin: 0 auto;\n");
        css.append("  padding: 24px 18px 70px;\n");
        css.append("}\n\n");
        
        // Brand rule
        css.append(".brand {\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: 12px;\n");
        css.append("  margin-bottom: 4px;\n");
        css.append("}\n\n");
        
        // Mark rule
        css.append(".mark {\n");
        css.append("  width: 32px;\n");
        css.append("  height: 32px;\n");
        css.append("  border-radius: 9px;\n");
        css.append("  background: linear-gradient(135deg, var(--accent), var(--accent2));\n");
        css.append("  box-shadow: 0 4px 12px rgba(91, 91, 214, 0.35);\n");
        css.append("  position: relative;\n");
        css.append("  flex: 0 0 auto;\n");
        css.append("}\n\n");
        
        // Mark:after pseudo-element
        css.append(".mark:after {\n");
        css.append("  content: \"\";\n");
        css.append("  position: absolute;\n");
        css.append("  inset: 8px;\n");
        css.append("  border-radius: 4px;\n");
        css.append("  border: 2px solid rgba(255, 255, 255, 0.92);\n");
        css.append("}\n\n");
        
        // H1 rule
        css.append("h1 {\n");
        css.append("  font-size: 21px;\n");
        css.append("  margin: 0;\n");
        css.append("  font-weight: 700;\n");
        css.append("}\n\n");
        
        // Sub rule
        css.append(".sub {\n");
        css.append("  color: var(--muted);\n");
        css.append("  font-size: 13px;\n");
        css.append("  margin: 2px 0 16px;\n");
        css.append("}\n\n");
        
        // Card rule
        css.append(".card {\n");
        css.append("  background: var(--card);\n");
        css.append("  border: 1px solid var(--line);\n");
        css.append("  border-radius: var(--radius);\n");
        css.append("  box-shadow: var(--shadow);\n");
        css.append("  padding: 16px;\n");
        css.append("  margin-bottom: 14px;\n");
        css.append("}\n\n");
        
        // Card h2 rule
        css.append(".card h2 {\n");
        css.append("  font-size: 14px;\n");
        css.append("  margin: 0 0 10px;\n");
        css.append("}\n\n");
        
        // Label.lab rule
        css.append("label.lab {\n");
        css.append("  display: block;\n");
        css.append("  font-size: 12px;\n");
        css.append("  font-weight: 600;\n");
        css.append("  color: var(--muted);\n");
        css.append("  margin: 8px 0 3px;\n");
        css.append("}\n\n");
        
        // Input and textarea rules
        css.append("input,\ntextarea {\n");
        css.append("  width: 100%;\n");
        css.append("  font-size: 13px;\n");
        css.append("  padding: 8px 10px;\n");
        css.append("  border: 1px solid var(--line);\n");
        css.append("  border-radius: 9px;\n");
        css.append("  font-family: ui-monospace, Menlo, Consolas, monospace;\n");
        css.append("  background: #fff;\n");
        css.append("}\n\n");
        
        // Textarea rule
        css.append("textarea {\n");
        css.append("  min-height: 90px;\n");
        css.append("  white-space: pre;\n");
        css.append("  overflow: auto;\n");
        css.append("}\n\n");
        
        // Row rule
        css.append(".row {\n");
        css.append("  display: flex;\n");
        css.append("  gap: 8px;\n");
        css.append("  flex-wrap: wrap;\n");
        css.append("  align-items: center;\n");
        css.append("}\n\n");
        
        // Btn rule
        css.append(".btn {\n");
        css.append("  font-size: 13px;\n");
        css.append("  font-weight: 600;\n");
        css.append("  padding: 8px 14px;\n");
        css.append("  border: 1px solid var(--line);\n");
        css.append("  border-radius: 10px;\n");
        css.append("  background: #fff;\n");
        css.append("  cursor: pointer;\n");
        css.append("  box-shadow: var(--shadow);\n");
        css.append("  transition: transform 0.1s;\n");
        css.append("}\n\n");
        
        // Btn:hover rule
        css.append(".btn:hover {\n");
        css.append("  transform: translateY(-1px);\n");
        css.append("}\n\n");
        
        // Btn.primary rule
        css.append(".btn.primary {\n");
        css.append("  background: linear-gradient(135deg, var(--accent), var(--accent2));\n");
        css.append("  color: #fff;\n");
        css.append("  border-color: transparent;\n");
        css.append("}\n\n");
        
        // Btn.sm rule
        css.append(".btn.sm {\n");
        css.append("  padding: 5px 9px;\n");
        css.append("  font-size: 12px;\n");
        css.append("}\n\n");
        
        // Msg rule
        css.append(".msg {\n");
        css.append("  font-size: 12px;\n");
        css.append("  margin-left: 6px;\n");
        css.append("}\n\n");
        
        // Msg.ok rule
        css.append(".msg.ok {\n");
        css.append("  color: var(--ok);\n");
        css.append("}\n\n");
        
        // Msg.err rule
        css.append(".msg.err {\n");
        css.append("  color: var(--err);\n");
        css.append("}\n\n");
        
        // Prov rule
        css.append(".prov {\n");
        css.append("  border: 1px solid var(--line);\n");
        css.append("  border-radius: 12px;\n");
        css.append("  padding: 10px 12px;\n");
        css.append("  margin-bottom: 10px;\n");
        css.append("}\n\n");
        
        // Prov h3 rule
        css.append(".prov h3 {\n");
        css.append("  margin: 0 0 6px;\n");
        css.append("  font-size: 13.5px;\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: 8px;\n");
        css.append("}\n\n");
        
        // Kv rule
        css.append(".kv {\n");
        css.append("  display: grid;\n");
        css.append("  grid-template-columns: 180px 1fr auto;\n");
        css.append("  gap: 6px;\n");
        css.append("  margin: 4px 0;\n");
        css.append("  align-items: center;\n");
        css.append("}\n\n");
        
        // Kv input rule
        css.append(".kv input {\n");
        css.append("  font-size: 12px;\n");
        css.append("  padding: 5px 7px;\n");
        css.append("}\n\n");
        
        // Kv .k rule
        css.append(".kv .k {\n");
        css.append("  color: var(--muted);\n");
        css.append("  font-weight: 600;\n");
        css.append("}\n\n");
        
        // Muted rule
        css.append(".muted {\n");
        css.append("  color: var(--faint);\n");
        css.append("  font-size: 13px;\n");
        css.append("}\n\n");
        
        // Hide rule
        css.append(".hide {\n");
        css.append("  display: none;\n");
        css.append("}\n\n");
        
        // Foot rule
        css.append(".foot {\n");
        css.append("  color: var(--faint);\n");
        css.append("  font-size: 11.5px;\n");
        css.append("  text-align: center;\n");
        css.append("  margin-top: 18px;\n");
        css.append("  line-height: 1.5;\n");
        css.append("}\n\n");
        
        // A rule
        css.append("a {\n");
        css.append("  color: var(--accent);\n");
        css.append("}\n");
        
        // Write to file
        try (FileWriter writer = new FileWriter(outputFile)) {
            writer.write(css.toString());
        }
    }
}
