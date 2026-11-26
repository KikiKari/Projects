// abstraction-provenance: {"artifact_sha256": "679ef450190df3620f234937d9517349fc5e0b87f23713c0fc66ae28b728f530", "source_sha256": "dbaea8c95e59c0899e7e4b8d3cced26cf954364749b998f1841e8d3d5f745baf", "target_language": "java"}
// architecture3d.css — portiert nach java
// Quelle: css, Projects@TikTok-Live-Companion:site/src/architecture3d.css
// auch in: Projects@TikTok-Live-Companion-Android:site/src/architecture3d.css
// auch in: Projects@TikTok-Live-Companion-iOS:site/src/architecture3d.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/src/architecture3d.css
// auch in: 1 weiteren Fundstellen
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class Architecture3DGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java Architecture3DGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        generateCSS(outputFile);
    }

    private static void generateCSS(String outputFile) {
        StringBuilder css = new StringBuilder();
        
        // :root { color-scheme: light; }
        css.append(":root { color-scheme: light; }\n");
        
        // .architecture-3d-page
        css.append(".architecture-3d-page { ")
           .append("min-height: 100vh; ")
           .append("overflow-x: hidden; ")
           .append("background: #fffdf9; ")
           .append("color: #14223c; ")
           .append("padding-bottom: 48px; ")
           .append("}\n");
        
        // .architecture-3d-header
        css.append(".architecture-3d-header { ")
           .append("min-height: 70px; ")
           .append("display: flex; ")
           .append("align-items: center; ")
           .append("justify-content: space-between; ")
           .append("gap: 20px; ")
           .append("padding: 12px max(22px, calc((100vw - 1240px)/2)); ")
           .append("border-bottom: 1px solid #d9e2ec; ")
           .append("background: rgba(255,253,249,.96); ")
           .append("}\n");
        
        // .architecture-3d-header a
        css.append(".architecture-3d-header a { ")
           .append("color: #14223c; ")
           .append("text-decoration: none; ")
           .append("font-weight: 800; ")
           .append("}\n");
        
        // .architecture-3d-header b
        css.append(".architecture-3d-header b { ")
           .append("color: #e5384f; ")
           .append("}\n");
        
        // .architecture-3d-header nav
        css.append(".architecture-3d-header nav { ")
           .append("display: flex; ")
           .append("gap: 20px; ")
           .append("}\n");
        
        // Common intro, workspace, legend, note styles
        css.append(".architecture-3d-intro, ")
           .append(".architecture-3d-workspace, ")
           .append(".architecture-3d-legend, ")
           .append(".architecture-3d-note { ")
           .append("width: min(1240px, calc(100% - 36px)); ")
           .append("margin-inline: auto; ")
           .append("}\n");
        
        // .architecture-3d-intro
        css.append(".architecture-3d-intro { ")
           .append("padding: 54px 0 26px; ")
           .append("}\n");
        
        // .architecture-3d-intro h1
        css.append(".architecture-3d-intro h1 { ")
           .append("margin: 5px 0 15px; ")
           .append("font-size: clamp(2.35rem, 5vw, 4.3rem); ")
           .append("line-height: 1.02; ")
           .append("letter-spacing: -.05em; ")
           .append("}\n");
        
        // .architecture-3d-intro > p:last-child
        css.append(".architecture-3d-intro > p:last-child { ")
           .append("max-width: 820px; ")
           .append("color: #526078; ")
           .append("font-size: 1.05rem; ")
           .append("line-height: 1.7; ")
           .append("}\n");
        
        // .architecture-3d-eyebrow
        css.append(".architecture-3d-eyebrow { ")
           .append("margin: 0; ")
           .append("color: #0c8f9d; ")
           .append("font-size: .73rem; ")
           .append("font-weight: 900; ")
           .append("letter-spacing: .14em; ")
           .append("}\n");
        
        // .architecture-3d-workspace
        css.append(".architecture-3d-workspace { ")
           .append("display: grid; ")
           .append("grid-template-columns: minmax(0, 1fr) 290px; ")
           .append("gap: 18px; ")
           .append("}\n");
        
        // .architecture-3d-scene-shell
        css.append(".architecture-3d-scene-shell { ")
           .append("min-height: 650px; ")
           .append("position: relative; ")
           .append("overflow: hidden; ")
           .append("border-radius: 16px; ")
           .append("background: #0f1729; ")
           .append("box-shadow: 0 20px 55px rgba(16,29,52,.22); ")
           .append("}\n");
        
        // .architecture-3d-scene
        css.append(".architecture-3d-scene { ")
           .append("position: absolute; ")
           .append("inset: 0; ")
           .append("opacity: 0; ")
           .append("transition: opacity .18s ease; ")
           .append("touch-action: pan-y; ")
           .append("}\n");
        
        // .architecture-3d-scene.is-ready
        css.append(".architecture-3d-scene.is-ready { ")
           .append("opacity: 1; ")
           .append("}\n");
        
        // .architecture-3d-scene canvas
        css.append(".architecture-3d-scene canvas { ")
           .append("display: block; ")
           .append("width: 100%; ")
           .append("height: 100%; ")
           .append("}\n");
        
        // .architecture-3d-scene:focus-visible
        css.append(".architecture-3d-scene:focus-visible { ")
           .append("outline: 3px solid #25c5d2; ")
           .append("outline-offset: -5px; ")
           .append("}\n");
        
        // .architecture-3d-fallback
        css.append(".architecture-3d-fallback { ")
           .append("position: absolute; ")
           .append("inset: 0; ")
           .append("width: 100%; ")
           .append("height: 100%; ")
           .append("object-fit: contain; ")
           .append("background: #0f1729; ")
           .append("}\n");
        
        // .architecture-3d-controls
        css.append(".architecture-3d-controls { ")
           .append("position: absolute; ")
           .append("right: 14px; ")
           .append("top: 14px; ")
           .append("display: flex; ")
           .append("gap: 8px; ")
           .append("z-index: 4; ")
           .append("}\n");
        
        // .architecture-3d-controls button, .architecture-3d-step button
        css.append(".architecture-3d-controls button, ")
           .append(".architecture-3d-step button { ")
           .append("min-height: 44px; ")
           .append("border: 1px solid #60708a; ")
           .append("border-radius: 9px; ")
           .append("background: rgba(15,23,41,.88); ")
           .append("color: white; ")
           .append("padding: 9px 13px; ")
           .append("font-weight: 800; ")
           .append("cursor: pointer; ")
           .append("}\n");
        
        // .architecture-3d-inspector
        css.append(".architecture-3d-inspector { ")
           .append("align-self: stretch; ")
           .append("padding: 24px; ")
           .append("border: 1px solid #d4dee8; ")
           .append("border-radius: 16px; ")
           .append("background: white; ")
           .append("}\n");
        
        // .architecture-3d-inspector h2
        css.append(".architecture-3d-inspector h2 { ")
           .append("margin: 9px 0; ")
           .append("font-size: 1.45rem; ")
           .append("}\n");
        
        // .architecture-3d-inspector > p:not(.architecture-3d-eyebrow)
        css.append(".architecture-3d-inspector > p:not(.architecture-3d-eyebrow) { ")
           .append("color: #526078; ")
           .append("min-height: 48px; ")
           .append("}\n");
        
        // .architecture-3d-inspector dl
        css.append(".architecture-3d-inspector dl { ")
           .append("margin: 25px 0; ")
           .append("}\n");
        
        // .architecture-3d-inspector dl div
        css.append(".architecture-3d-inspector dl div { ")
           .append("padding: 12px 0; ")
           .append("border-bottom: 1px solid #e2e8f0; ")
           .append("}\n");
        
        // .architecture-3d-inspector dt
        css.append(".architecture-3d-inspector dt { ")
           .append("color: #758198; ")
           .append("font-size: .74rem; ")
           .append("text-transform: uppercase; ")
           .append("letter-spacing: .08em; ")
           .append("}\n");
        
        // .architecture-3d-inspector dd
        css.append(".architecture-3d-inspector dd { ")
           .append("margin: 4px 0 0; ")
           .append("font-weight: 800; ")
           .append("overflow-wrap: anywhere; ")
           .append("}\n");
        
        // .architecture-3d-step
        css.append(".architecture-3d-step { ")
           .append("display: grid; ")
           .append("grid-template-columns: 1fr 1fr; ")
           .append("gap: 8px; ")
           .append("}\n");
        
        // .architecture-3d-step button
        css.append(".architecture-3d-step button { ")
           .append("background: #14223c; ")
           .append("}\n");
        
        // .architecture-3d-legend
        css.append(".architecture-3d-legend { ")
           .append("display: flex; ")
           .append("flex-wrap: wrap; ")
           .append("gap: 24px; ")
           .append("padding: 23px 0 10px; ")
           .append("}\n");
        
        // .architecture-3d-legend span
        css.append(".architecture-3d-legend span { ")
           .append("display: inline-flex; ")
           .append("align-items: center; ")
           .append("gap: 9px; ")
           .append("font-size: .85rem; ")
           .append("font-weight: 750; ")
           .append("}\n");
        
        // .architecture-3d-legend i
        css.append(".architecture-3d-legend i { ")
           .append("width: 30px; ")
           .append("height: 4px; ")
           .append("display: inline-block; ")
           .append("background: #25c5d2; ")
           .append("}\n");
        
        // .architecture-3d-legend i.audio
        css.append(".architecture-3d-legend i.audio { ")
           .append("background: #ff557a; ")
           .append("}\n");
        
        // .architecture-3d-legend i.token
        css.append(".architecture-3d-legend i.token { ")
           .append("background: repeating-linear-gradient(90deg,#e9a12d 0 7px,transparent 7px 11px); ")
           .append("}\n");
        
        // .architecture-3d-note
        css.append(".architecture-3d-note { ")
           .append("color: #66758a; ")
           .append("font-size: .82rem; ")
           .append("}\n");
        
        // Media query for max-width: 820px
        css.append("@media (max-width: 820px) {\n")
           .append("  .architecture-3d-workspace { grid-template-columns: 1fr; }\n")
           .append("  .architecture-3d-scene-shell { min-height: 520px; }\n")
           .append("  .architecture-3d-inspector { order: 2; }\n")
           .append("}\n");
        
        // Media query for max-width: 520px
        css.append("@media (max-width: 520px) {\n")
           .append("  .architecture-3d-header { padding-inline: 16px; gap: 8px; font-size: .82rem; }\n")
           .append("  .architecture-3d-header nav { gap: 10px; }\n")
           .append("  .architecture-3d-intro { padding-top: 35px; }\n")
           .append("  .architecture-3d-intro h1 { font-size: clamp(2rem, 10vw, 2.75rem); overflow-wrap: anywhere; }\n")
           .append("  .architecture-3d-intro > p:last-child { overflow-wrap: anywhere; }\n")
           .append("  .architecture-3d-scene-shell { min-height: 460px; }\n")
           .append("  .architecture-3d-controls { left: 10px; right: 10px; justify-content: space-between; }\n")
           .append("  .architecture-3d-controls button { min-width: 44px; padding-inline: 8px; font-size: .77rem; }\n")
           .append("  .architecture-3d-legend { display: grid; gap: 12px; }\n")
           .append("}\n");
        
        // Media query for prefers-reduced-motion
        css.append("@media (prefers-reduced-motion: reduce) { ")
           .append(".architecture-3d-scene { transition: none; } ")
           .append("}\n");
        
        try (FileWriter writer = new FileWriter(outputFile)) {
            writer.write(css.toString());
        } catch (IOException e) {
            System.err.println("Error writing to file: " + e.getMessage());
            System.exit(1);
        }
    }
}
