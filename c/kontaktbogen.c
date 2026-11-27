// abstraction-provenance: {"artifact_sha256": "25dc24c11c036b38be28cf2fe08b6ee2f6fcec24a3b00fac0a4442a3296bb260", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "c"}
// kontaktbogen.html — portiert nach c
// Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Struktur für ein Bild
typedef struct {
    char* src;
    char* alt;
    char* name;
    char* dims;
    char* code;
    char* prompt;
} Image;

// Struktur für eine Kategorie
typedef struct {
    char* id;
    char* title;
    char* subtitle;
    char* tag1_class;
    char* tag1_text;
    char* tag2_text;
    Image* images;
    int image_count;
} Category;

void write_html_header(FILE* file) {
    fprintf(file, "<!DOCTYPE html>\n");
    fprintf(file, "<html lang=\"de\"><head><meta charset=\"utf-8\"><title>Kontaktbogen — Project-Landingpage Assets</title>\n");
    fprintf(file, "<style>\n");
    fprintf(file, "  :root{--bg:#FAF8F4;--ink:#1B1A17;--muted:#6E6A61;--line:#E5E1D8;--accent:#A8542F;--accent-2:#2E7D7B;--surface:#fff}\n");
    fprintf(file, "  *{box-sizing:border-box}\n");
    fprintf(file, "  body{margin:0;font-family:'Hanken Grotesk',system-ui,sans-serif;background:var(--bg);color:var(--ink);line-height:1.5}\n");
    fprintf(file, "  header{padding:2.5rem 2rem 1rem;border-bottom:1px solid var(--line);background:var(--surface);position:sticky;top:0;z-index:10}\n");
    fprintf(file, "  header h1{margin:0 0 .5rem;font-family:'Newsreader',Georgia,serif;font-weight:400;font-size:2.25rem}\n");
    fprintf(file, "  header p{margin:.25rem 0;color:var(--muted);max-width:80ch}\n");
    fprintf(file, "  .legend{display:flex;gap:1rem;flex-wrap:wrap;margin-top:.75rem;font-size:.8125rem}\n");
    fprintf(file, "  .pill{padding:.15rem .6rem;border-radius:999px;border:1px solid var(--line);background:#fff}\n");
    fprintf(file, "  .pill.pflicht{border-color:var(--accent);color:var(--accent);font-weight:600}\n");
    fprintf(file, "  .pill.auswahl{border-color:var(--accent-2);color:var(--accent-2);font-weight:600}\n");
    fprintf(file, "  main{padding:2rem;max-width:1400px;margin:0 auto}\n");
    fprintf(file, "  section{margin:2.5rem 0}\n");
    fprintf(file, "  section h2{font-family:'Newsreader',serif;font-weight:400;font-size:1.5rem;margin:0 0 .25rem;display:flex;align-items:center;gap:.75rem}\n");
    fprintf(file, "  section .sub{color:var(--muted);font-size:.875rem;margin:0 0 1.25rem}\n");
    fprintf(file, "  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:1rem}\n");
    fprintf(file, "  .card{background:var(--surface);border:1px solid var(--line);border-radius:10px;overflow:hidden;display:flex;flex-direction:column}\n");
    fprintf(file, "  .card .imgwrap{aspect-ratio:1;background:#f1eee7;display:flex;align-items:center;justify-content:center;overflow:hidden}\n");
    fprintf(file, "  .card img{width:100%%;height:100%%;object-fit:contain;background:#fff}\n");
    fprintf(file, "  .card .meta{padding:.6rem .75rem .75rem;font-size:.78125rem}\n");
    fprintf(file, "  .card .name{font-family:'JetBrains Mono',monospace;font-size:.6875rem;color:var(--muted);word-break:break-all;line-height:1.3;margin-bottom:.35rem}\n");
    fprintf(file, "  .card .dims{color:var(--muted);font-size:.6875rem;margin-bottom:.35rem}\n");
    fprintf(file, "  .card .prompt{color:var(--ink);font-size:.75rem;line-height:1.35;font-style:italic;border-top:1px solid var(--line);padding-top:.4rem;margin-top:.35rem;max-height:5.5em;overflow:hidden}\n");
    fprintf(file, "  .tag{display:inline-block;padding:.1rem .45rem;border-radius:999px;font-size:.6875rem;background:#F1EEE7;color:var(--muted);margin-right:.25rem}\n");
    fprintf(file, "  .tag.p{background:#F1E5DD;color:var(--accent)}\n");
    fprintf(file, "  .tag.a{background:#DEEDEC;color:var(--accent-2)}\n");
    fprintf(file, "</style></head>\n");
    fprintf(file, "<body>\n");
    fprintf(file, "<header>\n");
    fprintf(file, "  <h1>Kontaktbogen — Project-Landingpage Bildbestand</h1>\n");
    fprintf(file, "  <p>Alle vorhandenen HighRes-Bilder aus deiner Design-Referenz, dem laufenden Codex-Repo und den Anhängen. Kategorisiert nach Verwendungszweck. Bitte markiere pro Kategorie welche Assets in die finale Umsetzung sollen und wo du Erweiterung wünschst.</p>\n");
    fprintf(file, "  <div class=\"legend\">\n");
    fprintf(file, "    <span class=\"pill pflicht\">PFLICHT — muss ins finale Design</span>\n");
    fprintf(file, "    <span class=\"pill auswahl\">AUSWAHL nötig — mehrere Kandidaten</span>\n");
    fprintf(file, "    <span class=\"pill\">Referenz — nur Ästhetik, nicht direkt verwendet</span>\n");
    fprintf(file, "    <span class=\"pill\">Vorhanden — schon im Repo eingebaut</span>\n");
    fprintf(file, "  </div>\n");
    fprintf(file, "</header>\n");
    fprintf(file, "<main>\n");
}

void write_html_footer(FILE* file) {
    fprintf(file, "</main></body></html>\n");
}

void write_category(FILE* file, Category* cat) {
    fprintf(file, "<section id=\"%s\"><h2>%s", cat->id, cat->title);
    
    if (cat->tag1_class && strlen(cat->tag1_class) > 0) {
        fprintf(file, " <span class=\"tag %s\">%s</span>", cat->tag1_class, cat->tag1_text);
    } else if (cat->tag1_text && strlen(cat->tag1_text) > 0) {
        fprintf(file, " <span class=\"tag\">%s</span>", cat->tag1_text);
    }
    
    if (cat->tag2_text && strlen(cat->tag2_text) > 0) {
        fprintf(file, " <span class=\"tag\">%s</span>", cat->tag2_text);
    }
    
    fprintf(file, "</h2>");
    
    if (cat->subtitle && strlen(cat->subtitle) > 0) {
        fprintf(file, "<p class=\"sub\">%s</p>", cat->subtitle);
    }
    
    fprintf(file, "<div class=\"grid\">\n");
    
    for (int i = 0; i < cat->image_count; i++) {
        Image* img = &cat->images[i];
        fprintf(file, "      <div class=\"card\">\n");
        
        if (strcmp(img->src, "kein_thumbnail") == 0) {
            fprintf(file, "        <div class=\"imgwrap\"><div style=\"color:#999\">kein Thumbnail</div></div>\n");
        } else {
            fprintf(file, "        <div class=\"imgwrap\"><img src=\"%s\" alt=\"%s\" loading=\"lazy\"></div>\n", img->src, img->alt);
        }
        
        fprintf(file, "        <div class=\"meta\">\n");
        fprintf(file, "          <div class=\"name\">%s</div>\n", img->name);
        fprintf(file, "          <div class=\"dims\">%s", img->dims);
        
        if (img->code && strlen(img->code) > 0) {
            fprintf(file, " · <code>%s</code>", img->code);
        }
        
        fprintf(file, "</div>\n");
        
        if (img->prompt && strlen(img->prompt) > 0) {
            fprintf(file, "          <div class=\"prompt\">%s</div>\n", img->prompt);
        }
        
        fprintf(file, "        </div>\n");
        fprintf(file, "      </div>\n");
    }
    
    fprintf(file, "</div></section>");
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Verwendung: %s <ausgabedatei>\n", argv[0]);
        return 1;
    }
    
    FILE* file = fopen(argv[1], "w");
    if (!file) {
        printf("Fehler beim Öffnen der Datei %s\n", argv[1]);
        return 1;
    }
    
    // Kategorien und Bilder definieren
    Category categories[14];
    
    // Seerosen
    Image seerosen_images[5] = {
        {"thumbs/thumb_water_lily_01_pixabay_1510707_original.webp", "water_lily_01_pixabay_1510707_original.jpg", "water_lily_01_pixabay_1510707_original.jpg", "5184×3456 px · 1253 KB", "examples", ""},
        {"thumbs/thumb_candidate-10-pixabay-4602155-wide-real-pond-lily-pads.webp", "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg", "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg", "1280×960 px · 570 KB", "pending-approval", ""},
        {"thumbs/thumb_candidate-11-pixabay-5904414-giant-water-lily-3d-depth.webp", "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg", "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg", "1280×951 px · 495 KB", "pending-approval", ""},
        {"thumbs/thumb_candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.webp", "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg", "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg", "2400×1600 px · 425 KB", "pending-approval", ""},
        {"thumbs/thumb_candidate-09-pixabay-6403860-red-water-lily-water-closeup.webp", "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg", "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg", "1280×853 px · 248 KB", "pending-approval", ""}
    };
    categories[0] = (Category){"cat-seerose", "Seerosen (Pixabay/Unsplash)", "Kandidaten für 3D-Textur / Alpha", "a", "AUSWAHL nötig", "5 Bilder", seerosen_images, 5};
    
    // WaveSpeed 4K Hero
    Image wavespeed_hero_images[2] = {
        {"thumbs/thumb_hero-meadow.webp", "hero-meadow.png", "hero-meadow.png", "5504×3072 px · 18908 KB", "media", "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..."},
        {"thumbs/thumb_hero-meadow.webp", "hero-meadow.webp", "hero-meadow.webp", "5504×3072 px · 836 KB", "media", "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..."}
    };
    categories[1] = (Category){"cat-wavespeed_hero", "WaveSpeed 4K Hero", "Bereits generierter Hero-Hintergrund", "p", "PFLICHT-Kandidat", "2 Bilder", wavespeed_hero_images, 2};
    
    // WaveSpeed 4K Glaskugel
    Image wavespeed_orb_images[2] = {
        {"thumbs/thumb_glass-orb.webp", "glass-orb.png", "glass-orb.png", "4096×4096 px · 18805 KB", "media", "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..."},
        {"thumbs/thumb_glass-orb.webp", "glass-orb.webp", "glass-orb.webp", "4096×4096 px · 730 KB", "media", "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..."}
    };
    categories[2] = (Category){"cat-wavespeed_orb", "WaveSpeed 4K Glaskugel", "Referenz-Glaskugel für 3D-Material", "p", "PFLICHT-Kandidat", "2 Bilder", wavespeed_orb_images, 2};
    
    // WaveSpeed 4K Sektionen
    Image wavespeed_projects_images[6] = {
        {"thumbs/thumb_perplexity-projects.webp", "perplexity-projects.png", "perplexity-projects.png", "4800×3584 px · 21947 KB", "media", "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..."},
        {"thumbs/thumb_claude-projects.webp", "claude-projects.png", "claude-projects.png", "4800×3584 px · 20711 KB", "media", "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..."},
        {"thumbs/thumb_og-projects.webp", "og-projects.png", "og-projects.png", "5504×3072 px · 18199 KB", "media", "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..."},
        {"thumbs/thumb_perplexity-projects.webp", "perplexity-projects.webp", "perplexity-projects.webp", "4800×3584 px · 1805 KB", "media", "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..."},
        {"thumbs/thumb_claude-projects.webp", "claude-projects.webp", "claude-projects.webp", "4800×3584 px · 1114 KB", "media", "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..."},
        {"thumbs/thumb_og-projects.webp", "og-projects.webp", "og-projects.webp", "5504×3072 px · 819 KB", "media", "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..."}
    };
    categories[3] = (Category){"cat-wavespeed_projects", "WaveSpeed 4K Sektionen", "Section-Backgrounds (Claude/Perplexity)", "", "Vorhanden", "6 Bilder", wavespeed_projects_images, 6};
    
    // WaveSpeed 4K Zusatz
    Image wavespeed_section_images[4] = {
        {"thumbs/thumb_feature-spotlight.webp", "feature-spotlight.png", "feature-spotlight.png", "4800×3584 px · 18688 KB", "media", "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..."},
        {"thumbs/thumb_cta-background.webp", "cta-background.png", "cta-background.png", "5504×3072 px · 15543 KB", "media", "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..."},
        {"thumbs/thumb_feature-spotlight.webp", "feature-spotlight.webp", "feature-spotlight.webp", "4800×3584 px · 1315 KB", "media", "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..."},
        {"thumbs/thumb_cta-background.webp", "cta-background.webp", "cta-background.webp", "5504×3072 px · 730 KB", "media", "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..."}
    };
    categories[4] = (Category){"cat-wavespeed_section", "WaveSpeed 4K Zusatz", "CTA / Feature-Spotlight", "", "Vorhanden", "4 Bilder", wavespeed_section_images, 4};
    
    // Studio-Varianten Glaskugel
    Image studio_variant_images[8] = {
        {"thumbs/thumb_var6_flat_lay.webp", "var6_flat_lay.png", "var6_flat_lay.png", "1672×941 px · 3173 KB", "examples", ""},
        {"thumbs/thumb_var8_natural_light_outdoor.webp", "var8_natural_light_outdoor.png", "var8_natural_light_outdoor.png", "1672×941 px · 2481 KB", "examples", ""},
        {"thumbs/thumb_var5_closeup_detail.webp", "var5_closeup_detail.png", "var5_closeup_detail.png", "1672×941 px · 1863 KB", "examples", ""},
        {"thumbs/thumb_var4_dramatic_lighting.webp", "var4_dramatic_lighting.png", "var4_dramatic_lighting.png", "1672×941 px · 1573 KB", "examples", ""},
        {"thumbs/thumb_var2_studio_white2.webp", "var2_studio_white2.png", "var2_studio_white2.png", "1672×941 px · 1285 KB", "examples", ""},
        {"thumbs/thumb_var1_studio_white.webp", "var1_studio_white.png", "var1_studio_white.png", "1672×941 px · 1259 KB", "examples", ""},
        {"thumbs/thumb_var8_natural_light_outdoor.webp", "var8_natural_light_outdoor.jpg", "var8_natural_light_outdoor.jpg", "1672×941 px · 800 KB", "7634afec188f40caa502423fce3ef2ea", ""},
        {"thumbs/thumb_var4_dramatic_lighting.webp", "var4_dramatic_lighting.jpg", "var4_dramatic_lighting.jpg", "1672×941 px · 386 KB", "7634afec188f40caa502423fce3ef2ea", ""}
    };
    categories[5] = (Category){"cat-studio_variant", "Studio-Varianten Glaskugel", "Beleuchtungsstudien für Glas", "", "Referenz", "8 Bilder", studio_variant_images, 8};
    
    // Glasobjekt-Referenz
    Image glasobjekt_images[2] = {
        {"thumbs/thumb_element_01_glass_bowl.webp", "element_01_glass_bowl.png", "element_01_glass_bowl.png", "1024×1024 px · 1485 KB", "examples", ""},
        {"thumbs/thumb_element_01_glass_bowl.webp", "element_01_glass_bowl.jpg", "element_01_glass_bowl.jpg", "1024×1024 px · 126 KB", "7634afec188f40caa502423fce3ef2ea", ""}
    };
    categories[6] = (Category){"cat-glasobjekt", "Glasobjekt-Referenz", "Materialstudie Glas", "", "Referenz", "2 Bilder", glasobjekt_images, 2};
    
    // Perlen/Beads
    Image perle_images[4] = {
        {"thumbs/thumb_element_02_beads_group.webp", "element_02_beads_group.png", "element_02_beads_group.png", "1024×1024 px · 1751 KB", "examples", ""},
        {"thumbs/thumb_element_03_single_bead.webp", "element_03_single_bead.png", "element_03_single_bead.png", "1024×1024 px · 1473 KB", "examples", ""},
        {"thumbs/thumb_element_02_beads_group.webp", "element_02_beads_group.jpg", "element_02_beads_group.jpg", "1024×1024 px · 284 KB", "7634afec188f40caa502423fce3ef2ea", ""},
        {"thumbs/thumb_element_03_single_bead.webp", "element_03_single_bead.jpg", "element_03_single_bead.jpg", "1024×1024 px · 127 KB", "7634afec188f40caa502423fce3ef2ea", ""}
    };
    categories[7] = (Category){"cat-perle", "Perlen/Beads", "Materialstudie klein/rund", "", "Referenz", "4 Bilder", perle_images, 4};
    
    // Pfingstrosen-Kompositionen
    Image peonie_ref_images[4] = {
        {"thumbs/thumb_comp_02_peonies_warm.webp", "comp_02_peonies_warm.png", "comp_02_peonies_warm.png", "1024×1536 px · 2500 KB", "examples", ""},
        {"thumbs/thumb_comp_01_peonies_dark.webp", "comp_01_peonies_dark.png", "comp_01_peonies_dark.png", "1024×1535 px · 2124 KB", "examples", ""},
        {"thumbs/thumb_comp_02_peonies_warm.webp", "comp_02_peonies_warm.jpg", "comp_02_peonies_warm.jpg", "1024×1536 px · 761 KB", "7634afec188f40caa502423fce3ef2ea", ""},
        {"thumbs/thumb_comp_01_peonies_dark.webp", "comp_01_peonies_dark.jpg", "comp_01_peonies_dark.jpg", "1024×1535 px · 642 KB", "7634afec188f40caa502423fce3ef2ea", ""}
    };
    categories[8] = (Category){"cat-peonie_ref", "Pfingstrosen-Kompositionen", "Referenz-Look; nicht direkt nutzbar", "", "Referenz", "4 Bilder", peonie_ref_images, 4};
    
    // Feder
    Image feder_images[1] = {
        {"thumbs/thumb_element_04_feather.webp", "element_04_feather.png", "element_04_feather.png", "1024×1536 px · 2384 KB", "examples", ""}
    };
    categories[9] = (Category){"cat-feder", "Feder", "Referenz Element", "", "Referenz", "1 Bilder", feder_images, 1};
    
    // Unsplash Referenzen
    Image ref_unsplash_images[3] = {
        {"thumbs/thumb_katya-azimova-j945b6ttc7s-unsplash.webp", "katya-azimova-j945b6ttc7s-unsplash.jpg", "katya-azimova-j945b6ttc7s-unsplash.jpg", "4659×6989 px · 8535 KB", "examples", ""},
        {"thumbs/thumb_anita-austvika-GnO2S8c7slQ-unsplash.webp", "anita-austvika-GnO2S8c7slQ-unsplash.jpg", "anita-austvika-GnO2S8c7slQ-unsplash.jpg", "4912×7360 px · 7049 KB", "examples", ""},
        {"thumbs/thumb_salvus-CiH1lH1u4dc-unsplash.webp", "salvus-CiH1lH1u4dc-unsplash.jpg", "salvus-CiH1lH1u4dc-unsplash.jpg", "3840×2160 px · 530 KB", "examples", ""}
    };
    categories[10] = (Category){"cat-ref_unsplash", "Unsplash Referenzen", "Ästhetik-Referenz", "", "Referenz", "3 Bilder", ref_unsplash_images, 3};
    
    // Sonstiges
    Image sonstiges_images[1] = {
        {"thumbs/thumb_candidate-08-pixabay-1510707-original.webp", "candidate-08-pixabay-1510707-original.jpg", "candidate-08-pixabay-1510707-original.jpg", "5184×3456 px · 1253 KB", "pending-approval", ""}
    };
    categories[11] = (Category){"cat-sonstiges", "Sonstiges", "", "", "", "1 Bilder", sonstiges_images, 1};
    
    // Weltkugel-Frames
    Image globe_frame_images[9];
    for (int i = 0; i < 9; i++) {
        globe_frame_images[i] = (Image){"kein_thumbnail", "", "", "?×? px · 0 KB", "media", ""};
    }
    globe_frame_images[0].name = "frame-02.png";
    globe_frame_images[0].dims = "?×? px · 98 KB";
    globe_frame_images[1].name = "frame-01.png";
    globe_frame_images[1].dims = "?×? px · 92 KB";
    globe_frame_images[2].name = "frame-04.png";
    globe_frame_images[2].dims = "?×? px · 86 KB";
    globe_frame_images[3].name = "frame-05.png";
    globe_frame_images[3].dims = "?×? px · 73 KB";
    globe_frame_images[4].name = "frame-03.png";
    globe_frame_images[4].dims = "?×? px · 71 KB";
    globe_frame_images[5].name = "frame-06.png";
    globe_frame_images[5].dims = "?×? px · 37 KB";
    globe_frame_images[6].name = "frame-09.png";
    globe_frame_images[6].dims = "?×? px · 37 KB";
    globe_frame_images[7].name = "frame-08.png";
    globe_frame_images[7].dims = "?×? px · 29 KB";
    globe_frame_images[8].name = "frame-07.png";
    globe_frame_images[8].dims = "?×? px · 27 KB";
    
    categories[12] = (Category){"cat-globe_frame", "Weltkugel-Frames", "Bereits verwendet in globe-hero", "", "Vorhanden (Frames)", "9 Bilder", globe_frame_images, 9};
    
    // Screenshots
    Image screenshot_images[4];
    for (int i = 0; i < 4; i++) {
        screenshot_images[i] = (Image){"kein_thumbnail", "", "", "?×? px · 0 KB", "7634afec188f40caa502423fce3ef2ea", ""};
    }
    screenshot_images[0].name = "image-3.jpg";
    screenshot_images[0].dims = "?×? px · 121 KB";
    screenshot_images[1].name = "image-4.jpg";
    screenshot_images[1].dims = "?×? px · 118 KB";
    screenshot_images[2].name = "image-2.jpg";
    screenshot_images[2].dims = "?×? px · 109 KB";
    screenshot_images[3].name = "image.jpg";
    screenshot_images[3].dims = "?×? px · 104 KB";
    
    categories[13] = (Category){"cat-screenshot", "Screenshots", "Referenz aus Anhang", "", "Referenz", "4 Bilder", screenshot_images, 4};
    
    // HTML generieren
    write_html_header(file);
    
    for (int i = 0; i < 14; i++) {
        write_category(file, &categories[i]);
    }
    
    write_html_footer(file);
    
    fclose(file);
    
    return 0;
}
