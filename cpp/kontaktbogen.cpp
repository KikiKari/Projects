// abstraction-provenance: {"artifact_sha256": "d1a8c9589bcd821ae020790d9b692c53e8b9634fe605d49a8c01c8826c34df32", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "cpp"}
// kontaktbogen.html — portiert nach cpp
// Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>

struct ImageData {
    std::string thumb_src;
    std::string alt_text;
    std::string name;
    std::string dimensions;
    std::string size;
    std::string code;
    std::string prompt;
};

struct CategoryData {
    std::string id;
    std::string title;
    std::string subtitle;
    std::vector<std::string> tags;
    std::vector<ImageData> images;
};

class KontaktbogenGenerator {
private:
    std::vector<CategoryData> categories;

public:
    void addCategory(const CategoryData& category) {
        categories.push_back(category);
    }

    void generateHTML(const std::string& filename) {
        std::ofstream file(filename);
        if (!file.is_open()) {
            std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
            return;
        }

        file << "<!DOCTYPE html>\n";
        file << "<html lang=\"de\"><head><meta charset=\"utf-8\"><title>Kontaktbogen — Project-Landingpage Assets</title>\n";
        file << "<style>\n";
        file << "  :root{--bg:#FAF8F4;--ink:#1B1A17;--muted:#6E6A61;--line:#E5E1D8;--accent:#A8542F;--accent-2:#2E7D7B;--surface:#fff}\n";
        file << "  *{box-sizing:border-box}\n";
        file << "  body{margin:0;font-family:'Hanken Grotesk',system-ui,sans-serif;background:var(--bg);color:var(--ink);line-height:1.5}\n";
        file << "  header{padding:2.5rem 2rem 1rem;border-bottom:1px solid var(--line);background:var(--surface);position:sticky;top:0;z-index:10}\n";
        file << "  header h1{margin:0 0 .5rem;font-family:'Newsreader',Georgia,serif;font-weight:400;font-size:2.25rem}\n";
        file << "  header p{margin:.25rem 0;color:var(--muted);max-width:80ch}\n";
        file << "  .legend{display:flex;gap:1rem;flex-wrap:wrap;margin-top:.75rem;font-size:.8125rem}\n";
        file << "  .pill{padding:.15rem .6rem;border-radius:999px;border:1px solid var(--line);background:#fff}\n";
        file << "  .pill.pflicht{border-color:var(--accent);color:var(--accent);font-weight:600}\n";
        file << "  .pill.auswahl{border-color:var(--accent-2);color:var(--accent-2);font-weight:600}\n";
        file << "  main{padding:2rem;max-width:1400px;margin:0 auto}\n";
        file << "  section{margin:2.5rem 0}\n";
        file << "  section h2{font-family:'Newsreader',serif;font-weight:400;font-size:1.5rem;margin:0 0 .25rem;display:flex;align-items:center;gap:.75rem}\n";
        file << "  section .sub{color:var(--muted);font-size:.875rem;margin:0 0 1.25rem}\n";
        file << "  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:1rem}\n";
        file << "  .card{background:var(--surface);border:1px solid var(--line);border-radius:10px;overflow:hidden;display:flex;flex-direction:column}\n";
        file << "  .card .imgwrap{aspect-ratio:1;background:#f1eee7;display:flex;align-items:center;justify-content:center;overflow:hidden}\n";
        file << "  .card img{width:100%;height:100%;object-fit:contain;background:#fff}\n";
        file << "  .card .meta{padding:.6rem .75rem .75rem;font-size:.78125rem}\n";
        file << "  .card .name{font-family:'JetBrains Mono',monospace;font-size:.6875rem;color:var(--muted);word-break:break-all;line-height:1.3;margin-bottom:.35rem}\n";
        file << "  .card .dims{color:var(--muted);font-size:.6875rem;margin-bottom:.35rem}\n";
        file << "  .card .prompt{color:var(--ink);font-size:.75rem;line-height:1.35;font-style:italic;border-top:1px solid var(--line);padding-top:.4rem;margin-top:.35rem;max-height:5.5em;overflow:hidden}\n";
        file << "  .tag{display:inline-block;padding:.1rem .45rem;border-radius:999px;font-size:.6875rem;background:#F1EEE7;color:var(--muted);margin-right:.25rem}\n";
        file << "  .tag.p{background:#F1E5DD;color:var(--accent)}\n";
        file << "  .tag.a{background:#DEEDEC;color:var(--accent-2)}\n";
        file << "</style></head>\n";
        file << "<body>\n";
        file << "<header>\n";
        file << "  <h1>Kontaktbogen — Project-Landingpage Bildbestand</h1>\n";
        file << "  <p>Alle vorhandenen HighRes-Bilder aus deiner Design-Referenz, dem laufenden Codex-Repo und den Anhängen. Kategorisiert nach Verwendungszweck. Bitte markiere pro Kategorie welche Assets in die finale Umsetzung sollen und wo du Erweiterung wünschst.</p>\n";
        file << "  <div class=\"legend\">\n";
        file << "    <span class=\"pill pflicht\">PFLICHT — muss ins finale Design</span>\n";
        file << "    <span class=\"pill auswahl\">AUSWAHL nötig — mehrere Kandidaten</span>\n";
        file << "    <span class=\"pill\">Referenz — nur Ästhetik, nicht direkt verwendet</span>\n";
        file << "    <span class=\"pill\">Vorhanden — schon im Repo eingebaut</span>\n";
        file << "  </div>\n";
        file << "</header>\n";
        file << "<main>\n";

        for (const auto& category : categories) {
            file << "<section id=\"" << category.id << "\"><h2>" << category.title;
            for (const auto& tag : category.tags) {
                file << " " << tag;
            }
            file << "</h2><p class=\"sub\">" << category.subtitle << "</p><div class=\"grid\">\n";
            
            for (const auto& image : category.images) {
                file << "      <div class=\"card\">\n";
                file << "        <div class=\"imgwrap\">";
                if (image.thumb_src.empty()) {
                    file << "<div style=\"color:#999\">kein Thumbnail</div>";
                } else {
                    file << "<img src=\"" << image.thumb_src << "\" alt=\"" << image.alt_text << "\" loading=\"lazy\">";
                }
                file << "</div>\n";
                file << "        <div class=\"meta\">\n";
                file << "          <div class=\"name\">" << image.name << "</div>\n";
                file << "          <div class=\"dims\">" << image.dimensions << " · " << image.size << " · <code>" << image.code << "</code></div>\n";
                if (!image.prompt.empty()) {
                    file << "          <div class=\"prompt\">" << image.prompt << "</div>\n";
                }
                file << "        </div>\n";
                file << "      </div>\n";
            }
            
            file << "</div></section>";
        }

        file << "</main></body></html>\n";
        file.close();
    }
};

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <ausgabedatei.html>" << std::endl;
        return 1;
    }

    KontaktbogenGenerator generator;

    // Seerosen Kategorie
    CategoryData seerose_cat = {
        "cat-seerose",
        "Seerosen (Pixabay/Unsplash) <span class=\"tag a\">AUSWAHL nötig</span> <span class=\"tag\">5 Bilder</span>",
        "Kandidaten für 3D-Textur / Alpha",
        {},
        {
            {"thumbs/thumb_water_lily_01_pixabay_1510707_original.webp", "water_lily_01_pixabay_1510707_original.jpg", "water_lily_01_pixabay_1510707_original.jpg", "5184×3456 px", "1253 KB", "examples", ""},
            {"thumbs/thumb_candidate-10-pixabay-4602155-wide-real-pond-lily-pads.webp", "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg", "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg", "1280×960 px", "570 KB", "pending-approval", ""},
            {"thumbs/thumb_candidate-11-pixabay-5904414-giant-water-lily-3d-depth.webp", "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg", "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg", "1280×951 px", "495 KB", "pending-approval", ""},
            {"thumbs/thumb_candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.webp", "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg", "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg", "2400×1600 px", "425 KB", "pending-approval", ""},
            {"thumbs/thumb_candidate-09-pixabay-6403860-red-water-lily-water-closeup.webp", "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg", "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg", "1280×853 px", "248 KB", "pending-approval", ""}
        }
    };
    generator.addCategory(seerose_cat);

    // WaveSpeed 4K Hero Kategorie
    CategoryData wavespeed_hero_cat = {
        "cat-wavespeed_hero",
        "WaveSpeed 4K Hero <span class=\"tag p\">PFLICHT-Kandidat</span> <span class=\"tag\">2 Bilder</span>",
        "Bereits generierter Hero-Hintergrund",
        {},
        {
            {"thumbs/thumb_hero-meadow.webp", "hero-meadow.png", "hero-meadow.png", "5504×3072 px", "18908 KB", "media", "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..."},
            {"thumbs/thumb_hero-meadow.webp", "hero-meadow.webp", "hero-meadow.webp", "5504×3072 px", "836 KB", "media", "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..."}
        }
    };
    generator.addCategory(wavespeed_hero_cat);

    // WaveSpeed 4K Glaskugel Kategorie
    CategoryData wavespeed_orb_cat = {
        "cat-wavespeed_orb",
        "WaveSpeed 4K Glaskugel <span class=\"tag p\">PFLICHT-Kandidat</span> <span class=\"tag\">2 Bilder</span>",
        "Referenz-Glaskugel für 3D-Material",
        {},
        {
            {"thumbs/thumb_glass-orb.webp", "glass-orb.png", "glass-orb.png", "4096×4096 px", "18805 KB", "media", "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..."},
            {"thumbs/thumb_glass-orb.webp", "glass-orb.webp", "glass-orb.webp", "4096×4096 px", "730 KB", "media", "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..."}
        }
    };
    generator.addCategory(wavespeed_orb_cat);

    // WaveSpeed 4K Sektionen Kategorie
    CategoryData wavespeed_projects_cat = {
        "cat-wavespeed_projects",
        "WaveSpeed 4K Sektionen <span class=\"tag \">Vorhanden</span> <span class=\"tag\">6 Bilder</span>",
        "Section-Backgrounds (Claude/Perplexity)",
        {},
        {
            {"thumbs/thumb_perplexity-projects.webp", "perplexity-projects.png", "perplexity-projects.png", "4800×3584 px", "21947 KB", "media", "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..."},
            {"thumbs/thumb_claude-projects.webp", "claude-projects.png", "claude-projects.png", "4800×3584 px", "20711 KB", "media", "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..."},
            {"thumbs/thumb_og-projects.webp", "og-projects.png", "og-projects.png", "5504×3072 px", "18199 KB", "media", "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..."},
            {"thumbs/thumb_perplexity-projects.webp", "perplexity-projects.webp", "perplexity-projects.webp", "4800×3584 px", "1805 KB", "media", "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..."},
            {"thumbs/thumb_claude-projects.webp", "claude-projects.webp", "claude-projects.webp", "4800×3584 px", "1114 KB", "media", "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..."},
            {"thumbs/thumb_og-projects.webp", "og-projects.webp", "og-projects.webp", "5504×3072 px", "819 KB", "media", "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..."}
        }
    };
    generator.addCategory(wavespeed_projects_cat);

    // WaveSpeed 4K Zusatz Kategorie
    CategoryData wavespeed_section_cat = {
        "cat-wavespeed_section",
        "WaveSpeed 4K Zusatz <span class=\"tag \">Vorhanden</span> <span class=\"tag\">4 Bilder</span>",
        "CTA / Feature-Spotlight",
        {},
        {
            {"thumbs/thumb_feature-spotlight.webp", "feature-spotlight.png", "feature-spotlight.png", "4800×3584 px", "18688 KB", "media", "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..."},
            {"thumbs/thumb_cta-background.webp", "cta-background.png", "cta-background.png", "5504×3072 px", "15543 KB", "media", "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..."},
            {"thumbs/thumb_feature-spotlight.webp", "feature-spotlight.webp", "feature-spotlight.webp", "4800×3584 px", "1315 KB", "media", "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..."},
            {"thumbs/thumb_cta-background.webp", "cta-background.webp", "cta-background.webp", "5504×3072 px", "730 KB", "media", "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..."}
        }
    };
    generator.addCategory(wavespeed_section_cat);

    // Studio-Varianten Glaskugel Kategorie
    CategoryData studio_variant_cat = {
        "cat-studio_variant",
        "Studio-Varianten Glaskugel <span class=\"tag \">Referenz</span> <span class=\"tag\">8 Bilder</span>",
        "Beleuchtungsstudien für Glas",
        {},
        {
            {"thumbs/thumb_var6_flat_lay.webp", "var6_flat_lay.png", "var6_flat_lay.png", "1672×941 px", "3173 KB", "examples", ""},
            {"thumbs/thumb_var8_natural_light_outdoor.webp", "var8_natural_light_outdoor.png", "var8_natural_light_outdoor.png", "1672×941 px", "2481 KB", "examples", ""},
            {"thumbs/thumb_var5_closeup_detail.webp", "var5_closeup_detail.png", "var5_closeup_detail.png", "1672×941 px", "1863 KB", "examples", ""},
            {"thumbs/thumb_var4_dramatic_lighting.webp", "var4_dramatic_lighting.png", "var4_dramatic_lighting.png", "1672×941 px", "1573 KB", "examples", ""},
            {"thumbs/thumb_var2_studio_white2.webp", "var2_studio_white2.png", "var2_studio_white2.png", "1672×941 px", "1285 KB", "examples", ""},
            {"thumbs/thumb_var1_studio_white.webp", "var1_studio_white.png", "var1_studio_white.png", "1672×941 px", "1259 KB", "examples", ""},
            {"thumbs/thumb_var8_natural_light_outdoor.webp", "var8_natural_light_outdoor.jpg", "var8_natural_light_outdoor.jpg", "1672×941 px", "800 KB", "7634afec188f40caa502423fce3ef2ea", ""},
            {"thumbs/thumb_var4_dramatic_lighting.webp", "var4_dramatic_lighting.jpg", "var4_dramatic_lighting.jpg", "1672×941 px", "386 KB", "7634afec188f40caa502423fce3ef2ea", ""}
        }
    };
    generator.addCategory(studio_variant_cat);

    // Glasobjekt-Referenz Kategorie
    CategoryData glasobjekt_cat = {
        "cat-glasobjekt",
        "Glasobjekt-Referenz <span class=\"tag \">Referenz</span> <span class=\"tag\">2 Bilder</span>",
        "Materialstudie Glas",
        {},
        {
            {"thumbs/thumb_element_01_glass_bowl.webp", "element_01_glass_bowl.png", "element_01_glass_bowl.png", "1024×1024 px", "1485 KB", "examples", ""},
            {"thumbs/thumb_element_01_glass_bowl.webp", "element_01_glass_bowl.jpg", "element_01_glass_bowl.jpg", "1024×1024 px", "126 KB", "7634afec188f40caa502423fce3ef2ea", ""}
        }
    };
    generator.addCategory(glasobjekt_cat);

    // Perlen/Beads Kategorie
    CategoryData perle_cat = {
        "cat-perle",
        "Perlen/Beads <span class=\"tag \">Referenz</span> <span class=\"tag\">4 Bilder</span>",
        "Materialstudie klein/rund",
        {},
        {
            {"thumbs/thumb_element_02_beads_group.webp", "element_02_beads_group.png", "element_02_beads_group.png", "1024×1024 px", "1751 KB", "examples", ""},
            {"thumbs/thumb_element_03_single_bead.webp", "element_03_single_bead.png", "element_03_single_bead.png", "1024×1024 px", "1473 KB", "examples", ""},
            {"thumbs/thumb_element_02_beads_group.webp", "element_02_beads_group.jpg", "element_02_beads_group.jpg", "1024×1024 px", "284 KB", "7634afec188f40caa502423fce3ef2ea", ""},
            {"thumbs/thumb_element_03_single_bead.webp", "element_03_single_bead.jpg", "element_03_single_bead.jpg", "1024×1024 px", "127 KB", "7634afec188f40caa502423fce3ef2ea", ""}
        }
    };
    generator.addCategory(perle_cat);

    // Pfingstrosen-Kompositionen Kategorie
    CategoryData peonie_ref_cat = {
        "cat-peonie_ref",
        "Pfingstrosen-Kompositionen <span class=\"tag \">Referenz</span> <span class=\"tag\">4 Bilder</span>",
        "Referenz-Look; nicht direkt nutzbar",
        {},
        {
            {"thumbs/thumb_comp_02_peonies_warm.webp", "comp_02_peonies_warm.png", "comp_02_peonies_warm.png", "1024×1536 px", "2500 KB", "examples", ""},
            {"thumbs/thumb_comp_01_peonies_dark.webp", "comp_01_peonies_dark.png", "comp_01_peonies_dark.png", "1024×1535 px", "2124 KB", "examples", ""},
            {"thumbs/thumb_comp_02_peonies_warm.webp", "comp_02_peonies_warm.jpg", "comp_02_peonies_warm.jpg", "1024×1536 px", "761 KB", "7634afec188f40caa502423fce3ef2ea", ""},
            {"thumbs/thumb_comp_01_peonies_dark.webp", "comp_01_peonies_dark.jpg", "comp_01_peonies_dark.jpg", "1024×1535 px", "642 KB", "7634afec188f40caa502423fce3ef2ea", ""}
        }
    };
    generator.addCategory(peonie_ref_cat);

    // Feder Kategorie
    CategoryData feder_cat = {
        "cat-feder",
        "Feder <span class=\"tag \">Referenz</span> <span class=\"tag\">1 Bilder</span>",
        "Referenz Element",
        {},
        {
            {"thumbs/thumb_element_04_feather.webp", "element_04_feather.png", "element_04_feather.png", "1024×1536 px", "2384 KB", "examples", ""}
        }
    };
    generator.addCategory(feder_cat);

    // Unsplash Referenzen Kategorie
    CategoryData ref_unsplash_cat = {
        "cat-ref_unsplash",
        "Unsplash Referenzen <span class=\"tag \">Referenz</span> <span class=\"tag\">3 Bilder</span>",
        "Ästhetik-Referenz",
        {},
        {
            {"thumbs/thumb_katya-azimova-j945b6ttc7s-unsplash.webp", "katya-azimova-j945b6ttc7s-unsplash.jpg", "katya-azimova-j945b6ttc7s-unsplash.jpg", "4659×6989 px", "8535 KB", "examples", ""},
            {"thumbs/thumb_anita-austvika-GnO2S8c7slQ-unsplash.webp", "anita-austvika-GnO2S8c7slQ-unsplash.jpg", "anita-austvika-GnO2S8c7slQ-unsplash.jpg", "4912×7360 px", "7049 KB", "examples", ""},
            {"thumbs/thumb_salvus-CiH1lH1u4dc-unsplash.webp", "salvus-CiH1lH1u4dc-unsplash.jpg", "salvus-CiH1lH1u4dc-unsplash.jpg", "3840×2160 px", "530 KB", "examples", ""}
        }
    };
    generator.addCategory(ref_unsplash_cat);

    // Sonstiges Kategorie
    CategoryData sonstiges_cat = {
        "cat-sonstiges",
        "Sonstiges <span class=\"tag \"></span> <span class=\"tag\">1 Bilder</span>",
        "",
        {},
        {
            {"thumbs/thumb_candidate-08-pixabay-1510707-original.webp", "candidate-08-pixabay-1510707-original.jpg", "candidate-08-pixabay-1510707-original.jpg", "5184×3456 px", "1253 KB", "pending-approval", ""}
        }
    };
    generator.addCategory(sonstiges_cat);

    // Weltkugel-Frames Kategorie
    CategoryData globe_frame_cat = {
        "cat-globe_frame",
        "Weltkugel-Frames <span class=\"tag \">Vorhanden (Frames)</span> <span class=\"tag\">9 Bilder</span>",
        "Bereits verwendet in globe-hero",
        {},
        {
            {"", "", "frame-02.png", "?×? px", "98 KB", "media", ""},
            {"", "", "frame-01.png", "?×? px", "92 KB", "media", ""},
            {"", "", "frame-04.png", "?×? px", "86 KB", "media", ""},
            {"", "", "frame-05.png", "?×? px", "73 KB", "media", ""},
            {"", "", "frame-03.png", "?×? px", "71 KB", "media", ""},
            {"", "", "frame-06.png", "?×? px", "37 KB", "media", ""},
            {"", "", "frame-09.png", "?×? px", "37 KB", "media", ""},
            {"", "", "frame-08.png", "?×? px", "29 KB", "media", ""},
            {"", "", "frame-07.png", "?×? px", "27 KB", "media", ""}
        }
    };
    generator.addCategory(globe_frame_cat);

    // Screenshots Kategorie
    CategoryData screenshot_cat = {
        "cat-screenshot",
        "Screenshots <span class=\"tag \">Referenz</span> <span class=\"tag\">4 Bilder</span>",
        "Referenz aus Anhang",
        {},
        {
            {"", "", "image-3.jpg", "?×? px", "121 KB", "7634afec188f40caa502423fce3ef2ea", ""},
            {"", "", "image-4.jpg", "?×? px", "118 KB", "7634afec188f40caa502423fce3ef2ea", ""},
            {"", "", "image-2.jpg", "?×? px", "109 KB", "7634afec188f40caa502423fce3ef2ea", ""},
            {"", "", "image.jpg", "?×? px", "104 KB", "7634afec188f40caa502423fce3ef2ea", ""}
        }
    };
    generator.addCategory(screenshot_cat);

    generator.generateHTML(argv[1]);
    return 0;
}
