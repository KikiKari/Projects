// abstraction-provenance: {"artifact_sha256": "7af26018a3b9e2df14cfe5271fd1fd11130f44def2c4fcb18fb202e64eb4b79c", "source_sha256": "c1bffd970108bca04ccb5b3a9aee8861acc4c11c8c4c461ea0c573b20c5e2f21", "target_language": "java"}
// index_4051ed.css — portiert nach java
// Quelle: css, Projects@abstractions:css/index_4051ed.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;

public class CSSGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java CSSGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try (FileWriter writer = new FileWriter(outputFile)) {
            writer.write(generateCSS());
        } catch (IOException e) {
            System.err.println("Error writing to file: " + e.getMessage());
            System.exit(1);
        }
    }

    private static String generateCSS() {
        StringBuilder css = new StringBuilder();
        
        // Root variables
        css.append(":root{\n");
        css.append("  --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280;\n");
        css.append("  --accent:#2481cc; --accent-soft:#e8f2fb; --discord:#5865f2; --discord-soft:#eceefe;\n");
        css.append("  --ok:#15803d; --warn:#b45309; --err:#b91c1c;\n");
        css.append("  color-scheme: light;\n");
        css.append("}\n");
        
        // Universal selector
        css.append("*{box-sizing:border-box}\n");
        
        // Body styles
        css.append("body{margin:0;background:var(--bg);color:var(--text);\n");
        css.append("     font:15px/1.5 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n");
        
        // Header styles
        css.append("header{background:var(--card);border-bottom:1px solid var(--line);padding:14px 20px;\n");
        css.append("       display:flex;align-items:center;gap:14px;flex-wrap:wrap;position:sticky;top:0;z-index:5}\n");
        css.append("header h1{font-size:17px;margin:0;font-weight:650}\n");
        
        // Pill styles
        css.append(".pill{font-size:11px;padding:2px 8px;border-radius:99px;background:var(--accent-soft);\n");
        css.append("      color:var(--accent);font-weight:600;white-space:nowrap}\n");
        css.append(".pill.off{background:#f1f2f4;color:var(--muted)}\n");
        css.append(".pill.dc{background:var(--discord-soft);color:var(--discord)}\n");
        
        // Navigation styles
        css.append("nav{display:flex;gap:4px;padding:0 20px;background:var(--card);border-bottom:1px solid var(--line)}\n");
        css.append("nav button{border:0;background:none;padding:11px 14px;font:inherit;font-weight:500;\n");
        css.append("           color:var(--muted);cursor:pointer;border-bottom:2px solid transparent}\n");
        css.append("nav button.active{color:var(--accent);border-bottom-color:var(--accent)}\n");
        
        // Main content styles
        css.append("main{padding:20px;max-width:1080px;margin:0 auto}\n");
        css.append(".panel{display:none} .panel.active{display:block}\n");
        
        // Row styles
        css.append(".row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:14px}\n");
        
        // Input and select styles
        css.append("input,select{padding:9px 11px;border:1px solid var(--line);border-radius:8px;font:inherit;\n");
        css.append("             background:var(--card);min-width:180px}\n");
        css.append("input:focus,select:focus{outline:2px solid var(--accent-soft);border-color:var(--accent)}\n");
        
        // Button styles
        css.append("button.go{background:var(--accent);color:#fff;border:0;border-radius:8px;padding:9px 16px;\n");
        css.append("          font:inherit;font-weight:600;cursor:pointer}\n");
        css.append("button.go.sec{background:var(--card);color:var(--text);border:1px solid var(--line)}\n");
        css.append("button.go.dc{background:var(--discord)}\n");
        css.append("button.go:disabled{opacity:.5;cursor:default}\n");
        
        // Card styles
        css.append(".card{background:var(--card);border:1px solid var(--line);border-radius:12px;\n");
        css.append("      padding:14px 16px;margin-bottom:10px}\n");
        css.append(".card h3{margin:0 0 2px;font-size:15px;display:flex;align-items:center;gap:8px;flex-wrap:wrap}\n");
        css.append(".card .meta{color:var(--muted);font-size:13px}\n");
        css.append(".card .desc{margin-top:7px;font-size:13.5px;white-space:pre-wrap}\n");
        
        // Avatar styles
        css.append(".avatar{width:34px;height:34px;border-radius:50%;object-fit:cover;background:#eceff3;flex:none}\n");
        css.append(".head{display:flex;gap:11px;align-items:flex-start}\n");
        
        // Score and tag styles
        css.append(".score{font-variant-numeric:tabular-nums;font-size:12px;color:var(--muted);\n");
        css.append("       border:1px solid var(--line);border-radius:6px;padding:1px 6px}\n");
        css.append(".tag{font-size:11px;padding:2px 7px;border-radius:5px;background:#f1f2f4;color:var(--muted);font-weight:600}\n");
        css.append(".tag.ok{background:#e7f6ec;color:var(--ok)} .tag.no{background:#fdeceb;color:var(--err)}\n");
        
        // Post styles
        css.append(".post{border-left:3px solid var(--accent-soft);padding:6px 0 6px 11px;margin:9px 0;font-size:13.5px}\n");
        css.append(".post .when{color:var(--muted);font-size:12px}\n");
        css.append(".post .txt{white-space:pre-wrap;margin-top:2px}\n");
        
        // Link styles
        css.append("a{color:var(--accent);text-decoration:none} a:hover{text-decoration:underline}\n");
        
        // Empty state styles
        css.append(".empty{color:var(--muted);padding:22px;text-align:center;border:1px dashed var(--line);border-radius:12px}\n");
        
        // Error styles
        css.append(".err{background:#fdeceb;border:1px solid #f5c6c2;color:var(--err);padding:10px 13px;\n");
        css.append("     border-radius:8px;margin-bottom:12px;font-size:13.5px}\n");
        
        // Spinner styles
        css.append(".spin{color:var(--muted);padding:16px 0}\n");
        
        // Table styles
        css.append("table{width:100%;border-collapse:collapse;font-size:13.5px}\n");
        css.append("th,td{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);vertical-align:top}\n");
        css.append("th{color:var(--muted);font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.03em}\n");
        
        // Code styles
        css.append("code{background:#f1f2f4;padding:1px 5px;border-radius:4px;font-size:12.5px}\n");
        
        // Hint styles
        css.append(".hint{color:var(--muted);font-size:13px;margin:-4px 0 14px}\n");
        
        // Stream styles
        css.append(".stream{max-height:460px;overflow:auto;border:1px solid var(--line);border-radius:10px;\n");
        css.append("        padding:6px 12px;margin-top:10px;background:var(--card)}\n");
        
        // Fresh post styles
        css.append(".post.fresh{border-left-color:var(--ok);background:#f3fbf5}\n");
        css.append(".post.fresh .when::after{content:\" NEU\";color:var(--ok);font-weight:700}\n");
        
        // Dot animation
        css.append(".dot{width:8px;height:8px;border-radius:50%;background:var(--ok);display:inline-block;\n");
        css.append("     margin-right:6px;animation:pulse 2s infinite}\n");
        css.append("@keyframes pulse{0%,100%{opacity:1}50%{opacity:.35}}\n");
        
        // Idle state
        css.append(".idle{background:var(--muted)!important;animation:none}\n");
        
        // TikTok styles
        css.append(".tt-live{background:#fe2c55;color:#fff;font-weight:700;font-size:11px;\n");
        css.append("         padding:2px 9px;border-radius:99px}\n");
        css.append(".tt-off{background:#f1f2f4;color:var(--muted);font-weight:700;font-size:11px;\n");
        css.append("        padding:2px 9px;border-radius:99px}\n");
        css.append(".tt-player{position:relative;width:100%;max-width:340px;aspect-ratio:9/16;background:#000;\n");
        css.append("           border-radius:10px;overflow:hidden;margin-top:10px;border:1px solid var(--line)}\n");
        css.append(".tt-player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}\n");
        
        // Event styles
        css.append(".ev{display:flex;gap:10px;padding:7px 0;border-bottom:1px solid var(--line);font-size:13.5px}\n");
        css.append(".ev:last-child{border-bottom:0}\n");
        css.append(".ev .k{font-weight:650;white-space:nowrap}\n");
        css.append(".ev .k.start{color:#fe2c55} .ev .k.end{color:var(--muted)}\n");
        
        return css.toString();
    }
}
