// abstraction-provenance: {"artifact_sha256": "52fe01edc93403bed58c467fd638d8f0e01558b180d2ad50fd6839e678297199", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "java"}
// kontaktbogen.html — portiert nach java
// Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.util.*;

public class KontaktbogenGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Bitte geben Sie den Ausgabedateipfad als Parameter an.");
            System.exit(1);
        }
        
        String outputPath = args[0];
        
        try {
            generateKontaktbogen(outputPath);
            System.out.println("Kontaktbogen erfolgreich generiert: " + outputPath);
        } catch (IOException e) {
            System.err.println("Fehler beim Generieren des Kontaktbogens: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void generateKontaktbogen(String outputPath) throws IOException {
        try (PrintWriter writer = new PrintWriter(new FileWriter(outputPath))) {
            writeHtmlHeader(writer);
            writeHeaderSection(writer);
            writeMainContent(writer);
            writeHtmlFooter(writer);
        }
    }

    private static void writeHtmlHeader(PrintWriter writer) {
        writer.println("<!DOCTYPE html>");
        writer.println("<html lang=\"de\"><head><meta charset=\"utf-8\"><title>Kontaktbogen — Project-Landingpage Assets</title>");
        writer.println("<style>");
        writer.println("  :root{--bg:#FAF8F4;--ink:#1B1A17;--muted:#6E6A61;--line:#E5E1D8;--accent:#A8542F;--accent-2:#2E7D7B;--surface:#fff}");
        writer.println("  *{box-sizing:border-box}");
        writer.println("  body{margin:0;font-family:'Hanken Grotesk',system-ui,sans-serif;background:var(--bg);color:var(--ink);line-height:1.5}");
        writer.println("  header{padding:2.5rem 2rem 1rem;border-bottom:1px solid var(--line);background:var(--surface);position:sticky;top:0;z-index:10}");
        writer.println("  header h1{margin:0 0 .5rem;font-family:'Newsreader',Georgia,serif;font-weight:400;font-size:2.25rem}");
        writer.println("  header p{margin:.25rem 0;color:var(--muted);max-width:80ch}");
        writer.println("  .legend{display:flex;gap:1rem;flex-wrap:wrap;margin-top:.75rem;font-size:.8125rem}");
        writer.println("  .pill{padding:.15rem .6rem;border-radius:999px;border:1px solid var(--line);background:#fff}");
        writer.println("  .pill.pflicht{border-color:var(--accent);color:var(--accent);font-weight:600}");
        writer.println("  .pill.auswahl{border-color:var(--accent-2);color:var(--accent-2);font-weight:600}");
        writer.println("  main{padding:2rem;max-width:1400px;margin:0 auto}");
        writer.println("  section{margin:2.5rem 0}");
        writer.println("  section h2{font-family:'Newsreader',serif;font-weight:400;font-size:1.5rem;margin:0 0 .25rem;display:flex;align-items:center;gap:.75rem}");
        writer.println("  section .sub{color:var(--muted);font-size:.875rem;margin:0 0 1.25rem}");
        writer.println("  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:1rem}");
        writer.println("  .card{background:var(--surface);border:1px solid var(--line);border-radius:10px;overflow:hidden;display:flex;flex-direction:column}");
        writer.println("  .card .imgwrap{aspect-ratio:1;background:#f1eee7;display:flex;align-items:center;justify-content:center;overflow:hidden}");
        writer.println("  .card img{width:100%;height:100%;object-fit:contain;background:#fff}");
        writer.println("  .card .meta{padding:.6rem .75rem .75rem;font-size:.78125rem}");
        writer.println("  .card .name{font-family:'JetBrains Mono',monospace;font-size:.6875rem;color:var(--muted);word-break:break-all;line-height:1.3;margin-bottom:.35rem}");
        writer.println("  .card .dims{color:var(--muted);font-size:.6875rem;margin-bottom:.35rem}");
        writer.println("  .card .prompt{color:var(--ink);font-size:.75rem;line-height:1.35;font-style:italic;border-top:1px solid var(--line);padding-top:.4rem;margin-top:.35rem;max-height:5.5em;overflow:hidden}");
        writer.println("  .tag{display:inline-block;padding:.1rem .45rem;border-radius:999px;font-size:.6875rem;background:#F1EEE7;color:var(--muted);margin-right:.25rem}");
        writer.println("  .tag.p{background:#F1E5DD;color:var(--accent)}");
        writer.println("  .tag.a{background:#DEEDEC;color:var(--accent-2)}");
        writer.println("</style></head>");
        writer.println("<body>");
    }

    private static void writeHeaderSection(PrintWriter writer) {
        writer.println("<header>");
        writer.println("  <h1>Kontaktbogen — Project-Landingpage Bildbestand</h1>");
        writer.println("  <p>Alle vorhandenen HighRes-Bilder aus deiner Design-Referenz, dem laufenden Codex-Repo und den Anhängen. Kategorisiert nach Verwendungszweck. Bitte markiere pro Kategorie welche Assets in die finale Umsetzung sollen und wo du Erweiterung wünschst.</p>");
        writer.println("  <div class=\"legend\">");
        writer.println("    <span class=\"pill pflicht\">PFLICHT — muss ins finale Design</span>");
        writer.println("    <span class=\"pill auswahl\">AUSWAHL nötig — mehrere Kandidaten</span>");
        writer.println("    <span class=\"pill\">Referenz — nur Ästhetik, nicht direkt verwendet</span>");
        writer.println("    <span class=\"pill\">Vorhanden — schon im Repo eingebaut</span>");
        writer.println("  </div>");
        writer.println("</header>");
    }

    private static void writeMainContent(PrintWriter writer) {
        writer.println("<main>");
        
        // Seerosen Section
        writer.println("<section id=\"cat-seerose\"><h2>Seerosen (Pixabay/Unsplash) <span class=\"tag a\">AUSWAHL nötig</span> <span class=\"tag\">5 Bilder</span></h2><p class=\"sub\">Kandidaten für 3D-Textur / Alpha</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_water_lily_01_pixabay_1510707_original.webp", "water_lily_01_pixabay_1510707_original.jpg", "water_lily_01_pixabay_1510707_original.jpg", "5184×3456 px · 1253 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_candidate-10-pixabay-4602155-wide-real-pond-lily-pads.webp", "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg", "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg", "1280×960 px · 570 KB · <code>pending-approval</code>", "");
        writeImageCard(writer, "thumbs/thumb_candidate-11-pixabay-5904414-giant-water-lily-3d-depth.webp", "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg", "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg", "1280×951 px · 495 KB · <code>pending-approval</code>", "");
        writeImageCard(writer, "thumbs/thumb_candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.webp", "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg", "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg", "2400×1600 px · 425 KB · <code>pending-approval</code>", "");
        writeImageCard(writer, "thumbs/thumb_candidate-09-pixabay-6403860-red-water-lily-water-closeup.webp", "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg", "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg", "1280×853 px · 248 KB · <code>pending-approval</code>", "");
        writer.println("</div></section>");
        
        // WaveSpeed 4K Hero Section
        writer.println("<section id=\"cat-wavespeed_hero\"><h2>WaveSpeed 4K Hero <span class=\"tag p\">PFLICHT-Kandidat</span> <span class=\"tag\">2 Bilder</span></h2><p class=\"sub\">Bereits generierter Hero-Hintergrund</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_hero-meadow.webp", "hero-meadow.png", "hero-meadow.png", "5504×3072 px · 18908 KB · <code>media</code>", "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g...");
        writeImageCard(writer, "thumbs/thumb_hero-meadow.webp", "hero-meadow.webp", "hero-meadow.webp", "5504×3072 px · 836 KB · <code>media</code>", "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g...");
        writer.println("</div></section>");
        
        // WaveSpeed 4K Glaskugel Section
        writer.println("<section id=\"cat-wavespeed_orb\"><h2>WaveSpeed 4K Glaskugel <span class=\"tag p\">PFLICHT-Kandidat</span> <span class=\"tag\">2 Bilder</span></h2><p class=\"sub\">Referenz-Glaskugel für 3D-Material</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_glass-orb.webp", "glass-orb.png", "glass-orb.png", "4096×4096 px · 18805 KB · <code>media</code>", "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h...");
        writeImageCard(writer, "thumbs/thumb_glass-orb.webp", "glass-orb.webp", "glass-orb.webp", "4096×4096 px · 730 KB · <code>media</code>", "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h...");
        writer.println("</div></section>");
        
        // WaveSpeed 4K Sektionen Section
        writer.println("<section id=\"cat-wavespeed_projects\"><h2>WaveSpeed 4K Sektionen <span class=\"tag \">Vorhanden</span> <span class=\"tag\">6 Bilder</span></h2><p class=\"sub\">Section-Backgrounds (Claude/Perplexity)</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_perplexity-projects.webp", "perplexity-projects.png", "perplexity-projects.png", "4800×3584 px · 21947 KB · <code>media</code>", "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac...");
        writeImageCard(writer, "thumbs/thumb_claude-projects.webp", "claude-projects.png", "claude-projects.png", "4800×3584 px · 20711 KB · <code>media</code>", "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ...");
        writeImageCard(writer, "thumbs/thumb_og-projects.webp", "og-projects.png", "og-projects.png", "5504×3072 px · 18199 KB · <code>media</code>", "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet...");
        writeImageCard(writer, "thumbs/thumb_perplexity-projects.webp", "perplexity-projects.webp", "perplexity-projects.webp", "4800×3584 px · 1805 KB · <code>media</code>", "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac...");
        writeImageCard(writer, "thumbs/thumb_claude-projects.webp", "claude-projects.webp", "claude-projects.webp", "4800×3584 px · 1114 KB · <code>media</code>", "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ...");
        writeImageCard(writer, "thumbs/thumb_og-projects.webp", "og-projects.webp", "og-projects.webp", "5504×3072 px · 819 KB · <code>media</code>", "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet...");
        writer.println("</div></section>");
        
        // WaveSpeed 4K Zusatz Section
        writer.println("<section id=\"cat-wavespeed_section\"><h2>WaveSpeed 4K Zusatz <span class=\"tag \">Vorhanden</span> <span class=\"tag\">4 Bilder</span></h2><p class=\"sub\">CTA / Feature-Spotlight</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_feature-spotlight.webp", "feature-spotlight.png", "feature-spotlight.png", "4800×3584 px · 18688 KB · <code>media</code>", "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n...");
        writeImageCard(writer, "thumbs/thumb_cta-background.webp", "cta-background.png", "cta-background.png", "5504×3072 px · 15543 KB · <code>media</code>", "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h...");
        writeImageCard(writer, "thumbs/thumb_feature-spotlight.webp", "feature-spotlight.webp", "feature-spotlight.webp", "4800×3584 px · 1315 KB · <code>media</code>", "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n...");
        writeImageCard(writer, "thumbs/thumb_cta-background.webp", "cta-background.webp", "cta-background.webp", "5504×3072 px · 730 KB · <code>media</code>", "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h...");
        writer.println("</div></section>");
        
        // Studio-Varianten Glaskugel Section
        writer.println("<section id=\"cat-studio_variant\"><h2>Studio-Varianten Glaskugel <span class=\"tag \">Referenz</span> <span class=\"tag\">8 Bilder</span></h2><p class=\"sub\">Beleuchtungsstudien für Glas</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_var6_flat_lay.webp", "var6_flat_lay.png", "var6_flat_lay.png", "1672×941 px · 3173 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_var8_natural_light_outdoor.webp", "var8_natural_light_outdoor.png", "var8_natural_light_outdoor.png", "1672×941 px · 2481 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_var5_closeup_detail.webp", "var5_closeup_detail.png", "var5_closeup_detail.png", "1672×941 px · 1863 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_var4_dramatic_lighting.webp", "var4_dramatic_lighting.png", "var4_dramatic_lighting.png", "1672×941 px · 1573 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_var2_studio_white2.webp", "var2_studio_white2.png", "var2_studio_white2.png", "1672×941 px · 1285 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_var1_studio_white.webp", "var1_studio_white.png", "var1_studio_white.png", "1672×941 px · 1259 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_var8_natural_light_outdoor.webp", "var8_natural_light_outdoor.jpg", "var8_natural_light_outdoor.jpg", "1672×941 px · 800 KB · <code>7634afec188f40caa502423fce3ef2ea</code>", "");
        writeImageCard(writer, "thumbs/thumb_var4_dramatic_lighting.webp", "var4_dramatic_lighting.jpg", "var4_dramatic_lighting.jpg", "1672×941 px · 386 KB · <code>7634afec188f40caa502423fce3ef2ea</code>", "");
        writer.println("</div></section>");
        
        // Glasobjekt-Referenz Section
        writer.println("<section id=\"cat-glasobjekt\"><h2>Glasobjekt-Referenz <span class=\"tag \">Referenz</span> <span class=\"tag\">2 Bilder</span></h2><p class=\"sub\">Materialstudie Glas</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_element_01_glass_bowl.webp", "element_01_glass_bowl.png", "element_01_glass_bowl.png", "1024×1024 px · 1485 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_element_01_glass_bowl.webp", "element_01_glass_bowl.jpg", "element_01_glass_bowl.jpg", "1024×1024 px · 126 KB · <code>7634afec188f40caa502423fce3ef2ea</code>", "");
        writer.println("</div></section>");
        
        // Perlen/Beads Section
        writer.println("<section id=\"cat-perle\"><h2>Perlen/Beads <span class=\"tag \">Referenz</span> <span class=\"tag\">4 Bilder</span></h2><p class=\"sub\">Materialstudie klein/rund</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_element_02_beads_group.webp", "element_02_beads_group.png", "element_02_beads_group.png", "1024×1024 px · 1751 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_element_03_single_bead.webp", "element_03_single_bead.png", "element_03_single_bead.png", "1024×1024 px · 1473 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_element_02_beads_group.webp", "element_02_beads_group.jpg", "element_02_beads_group.jpg", "1024×1024 px · 284 KB · <code>7634afec188f40caa502423fce3ef2ea</code>", "");
        writeImageCard(writer, "thumbs/thumb_element_03_single_bead.webp", "element_03_single_bead.jpg", "element_03_single_bead.jpg", "1024×1024 px · 127 KB · <code>7634afec188f40caa502423fce3ef2ea</code>", "");
        writer.println("</div></section>");
        
        // Pfingstrosen-Kompositionen Section
        writer.println("<section id=\"cat-peonie_ref\"><h2>Pfingstrosen-Kompositionen <span class=\"tag \">Referenz</span> <span class=\"tag\">4 Bilder</span></h2><p class=\"sub\">Referenz-Look; nicht direkt nutzbar</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_comp_02_peonies_warm.webp", "comp_02_peonies_warm.png", "comp_02_peonies_warm.png", "1024×1536 px · 2500 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_comp_01_peonies_dark.webp", "comp_01_peonies_dark.png", "comp_01_peonies_dark.png", "1024×1535 px · 2124 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_comp_02_peonies_warm.webp", "comp_02_peonies_warm.jpg", "comp_02_peonies_warm.jpg", "1024×1536 px · 761 KB · <code>7634afec188f40caa502423fce3ef2ea</code>", "");
        writeImageCard(writer, "thumbs/thumb_comp_01_peonies_dark.webp", "comp_01_peonies_dark.jpg", "comp_01_peonies_dark.jpg", "1024×1535 px · 642 KB · <code>7634afec188f40caa502423fce3ef2ea</code>", "");
        writer.println("</div></section>");
        
        // Feder Section
        writer.println("<section id=\"cat-feder\"><h2>Feder <span class=\"tag \">Referenz</span> <span class=\"tag\">1 Bilder</span></h2><p class=\"sub\">Referenz Element</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_element_04_feather.webp", "element_04_feather.png", "element_04_feather.png", "1024×1536 px · 2384 KB · <code>examples</code>", "");
        writer.println("</div></section>");
        
        // Unsplash Referenzen Section
        writer.println("<section id=\"cat-ref_unsplash\"><h2>Unsplash Referenzen <span class=\"tag \">Referenz</span> <span class=\"tag\">3 Bilder</span></h2><p class=\"sub\">Ästhetik-Referenz</p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_katya-azimova-j945b6ttc7s-unsplash.webp", "katya-azimova-j945b6ttc7s-unsplash.jpg", "katya-azimova-j945b6ttc7s-unsplash.jpg", "4659×6989 px · 8535 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_anita-austvika-GnO2S8c7slQ-unsplash.webp", "anita-austvika-GnO2S8c7slQ-unsplash.jpg", "anita-austvika-GnO2S8c7slQ-unsplash.jpg", "4912×7360 px · 7049 KB · <code>examples</code>", "");
        writeImageCard(writer, "thumbs/thumb_salvus-CiH1lH1u4dc-unsplash.webp", "salvus-CiH1lH1u4dc-unsplash.jpg", "salvus-CiH1lH1u4dc-unsplash.jpg", "3840×2160 px · 530 KB · <code>examples</code>", "");
        writer.println("</div></section>");
        
        // Sonstiges Section
        writer.println("<section id=\"cat-sonstiges\"><h2>Sonstiges <span class=\"tag \"></span> <span class=\"tag\">1 Bilder</span></h2><p class=\"sub\"></p><div class=\"grid\">");
        writeImageCard(writer, "thumbs/thumb_candidate-08-pixabay-1510707-original.webp", "candidate-08-pixabay-1510707-original.jpg", "candidate-08-pixabay-1510707-original.jpg", "5184×3456 px · 1253 KB · <code>pending-approval</code>", "");
        writer.println("</div></section>");
        
        // Weltkugel-Frames Section
        writer.println("<section id=\"cat-globe_frame\"><h2>Weltkugel-Frames <span class=\"tag \">Vorhanden (Frames)</span> <span class=\"tag\">9 Bilder</span></h2><p class=\"sub\">Bereits verwendet in globe-hero</p><div class=\"grid\">");
        writeNoThumbnailCard(writer, "frame-02.png", "?×? px · 98 KB · <code>media</code>");
        writeNoThumbnailCard(writer, "frame-01.png", "?×? px · 92 KB · <code>media</code>");
        writeNoThumbnailCard(writer, "frame-04.png", "?×? px · 86 KB · <code>media</code>");
        writeNoThumbnailCard(writer, "frame-05.png", "?×? px · 73 KB · <code>media</code>");
        writeNoThumbnailCard(writer, "frame-03.png", "?×? px · 71 KB · <code>media</code>");
        writeNoThumbnailCard(writer, "frame-06.png", "?×? px · 37 KB · <code>media</code>");
        writeNoThumbnailCard(writer, "frame-09.png", "?×? px · 37 KB · <code>media</code>");
        writeNoThumbnailCard(writer, "frame-08.png", "?×? px · 29 KB · <code>media</code>");
        writeNoThumbnailCard(writer, "frame-07.png", "?×? px · 27 KB · <code>media</code>");
        writer.println("</div></section>");
        
        // Screenshots Section
        writer.println("<section id=\"cat-screenshot\"><h2>Screenshots <span class=\"tag \">Referenz</span> <span class=\"tag\">4 Bilder</span></h2><p class=\"sub\">Referenz aus Anhang</p><div class=\"grid\">");
        writeNoThumbnailCard(writer, "image-3.jpg", "?×? px · 121 KB · <code>7634afec188f40caa502423fce3ef2ea</code>");
        writeNoThumbnailCard(writer, "image-4.jpg", "?×? px · 118 KB · <code>7634afec188f40caa502423fce3ef2ea</code>");
        writeNoThumbnailCard(writer, "image-2.jpg", "?×? px · 109 KB · <code>7634afec188f40caa502423fce3ef2ea</code>");
        writeNoThumbnailCard(writer, "image.jpg", "?×? px · 104 KB · <code>7634afec188f40caa502423fce3ef2ea</code>");
        writer.println("</div></section>");
        
        writer.println("</main>");
    }

    private static void writeHtmlFooter(PrintWriter writer) {
        writer.println("</body></html>");
    }

    private static void writeImageCard(PrintWriter writer, String thumbSrc, String altText, String name, String dims, String prompt) {
        writer.println("      <div class=\"card\">");
        writer.println("        <div class=\"imgwrap\"><img src=\"" + thumbSrc + "\" alt=\"" + altText + "\" loading=\"lazy\"></div>");
        writer.println("        <div class=\"meta\">");
        writer.println("          <div class=\"name\">" + name + "</div>");
        writer.println("          <div class=\"dims\">" + dims + "</div>");
        if (!prompt.isEmpty()) {
            writer.println("          <div class=\"prompt\">" + prompt + "</div>");
        }
        writer.println("        </div>");
        writer.println("      </div>");
    }

    private static void writeNoThumbnailCard(PrintWriter writer, String name, String dims) {
        writer.println("      <div class=\"card\">");
        writer.println("        <div class=\"imgwrap\"><div style=\"color:#999\">kein Thumbnail</div></div>");
        writer.println("        <div class=\"meta\">");
        writer.println("          <div class=\"name\">" + name + "</div>");
        writer.println("          <div class=\"dims\">" + dims + "</div>");
        writer.println("        </div>");
        writer.println("      </div>");
    }
}
