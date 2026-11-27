#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "c4d559524b337c310fddcc0bda89546a3c667653add897ac2bbd971c7b6114ea", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "tcl"}
# kontaktbogen.html — portiert nach tcl
# Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Script zur Erzeugung der kontaktbogen.html
# Portiert von HTML zu dynamischer Tcl-Erzeugung

proc write_kontaktbogen {filename} {
    set fp [open $filename w]
    
    # Schreibe DOCTYPE und HTML-Grundgerüst
    puts $fp "<!DOCTYPE html>"
    puts $fp "<html lang=\"de\"><head><meta charset=\"utf-8\"><title>Kontaktbogen — Project-Landingpage Assets</title>"
    
    # CSS Styles inline einbetten
    puts $fp "<style>"
    puts $fp "  :root{--bg:#FAF8F4;--ink:#1B1A17;--muted:#6E6A61;--line:#E5E1D8;--accent:#A8542F;--accent-2:#2E7D7B;--surface:#fff}"
    puts $fp "  *{box-sizing:border-box}"
    puts $fp "  body{margin:0;font-family:'Hanken Grotesk',system-ui,sans-serif;background:var(--bg);color:var(--ink);line-height:1.5}"
    puts $fp "  header{padding:2.5rem 2rem 1rem;border-bottom:1px solid var(--line);background:var(--surface);position:sticky;top:0;z-index:10}"
    puts $fp "  header h1{margin:0 0 .5rem;font-family:'Newsreader',Georgia,serif;font-weight:400;font-size:2.25rem}"
    puts $fp "  header p{margin:.25rem 0;color:var(--muted);max-width:80ch}"
    puts $fp "  .legend{display:flex;gap:1rem;flex-wrap:wrap;margin-top:.75rem;font-size:.8125rem}"
    puts $fp "  .pill{padding:.15rem .6rem;border-radius:999px;border:1px solid var(--line);background:#fff}"
    puts $fp "  .pill.pflicht{border-color:var(--accent);color:var(--accent);font-weight:600}"
    puts $fp "  .pill.auswahl{border-color:var(--accent-2);color:var(--accent-2);font-weight:600}"
    puts $fp "  main{padding:2rem;max-width:1400px;margin:0 auto}"
    puts $fp "  section{margin:2.5rem 0}"
    puts $fp "  section h2{font-family:'Newsreader',serif;font-weight:400;font-size:1.5rem;margin:0 0 .25rem;display:flex;align-items:center;gap:.75rem}"
    puts $fp "  section .sub{color:var(--muted);font-size:.875rem;margin:0 0 1.25rem}"
    puts $fp "  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:1rem}"
    puts $fp "  .card{background:var(--surface);border:1px solid var(--line);border-radius:10px;overflow:hidden;display:flex;flex-direction:column}"
    puts $fp "  .card .imgwrap{aspect-ratio:1;background:#f1eee7;display:flex;align-items:center;justify-content:center;overflow:hidden}"
    puts $fp "  .card img{width:100%;height:100%;object-fit:contain;background:#fff}"
    puts $fp "  .card .meta{padding:.6rem .75rem .75rem;font-size:.78125rem}"
    puts $fp "  .card .name{font-family:'JetBrains Mono',monospace;font-size:.6875rem;color:var(--muted);word-break:break-all;line-height:1.3;margin-bottom:.35rem}"
    puts $fp "  .card .dims{color:var(--muted);font-size:.6875rem;margin-bottom:.35rem}"
    puts $fp "  .card .prompt{color:var(--ink);font-size:.75rem;line-height:1.35;font-style:italic;border-top:1px solid var(--line);padding-top:.4rem;margin-top:.35rem;max-height:5.5em;overflow:hidden}"
    puts $fp "  .tag{display:inline-block;padding:.1rem .45rem;border-radius:999px;font-size:.6875rem;background:#F1EEE7;color:var(--muted);margin-right:.25rem}"
    puts $fp "  .tag.p{background:#F1E5DD;color:var(--accent)}"
    puts $fp "  .tag.a{background:#DEEDEC;color:var(--accent-2)}"
    puts $fp "</style></head>"
    puts $fp "<body>"
    
    # Header-Bereich
    puts $fp "<header>"
    puts $fp "  <h1>Kontaktbogen — Project-Landingpage Bildbestand</h1>"
    puts $fp "  <p>Alle vorhandenen HighRes-Bilder aus deiner Design-Referenz, dem laufenden Codex-Repo und den Anhängen. Kategorisiert nach Verwendungszweck. Bitte markiere pro Kategorie welche Assets in die finale Umsetzung sollen und wo du Erweiterung wünschst.</p>"
    puts $fp "  <div class=\"legend\">"
    puts $fp "    <span class=\"pill pflicht\">PFLICHT — muss ins finale Design</span>"
    puts $fp "    <span class=\"pill auswahl\">AUSWAHL nötig — mehrere Kandidaten</span>"
    puts $fp "    <span class=\"pill\">Referenz — nur Ästhetik, nicht direkt verwendet</span>"
    puts $fp "    <span class=\"pill\">Vorhanden — schon im Repo eingebaut</span>"
    puts $fp "  </div>"
    puts $fp "</header>"
    
    # Main Content
    puts $fp "<main>"
    
    # Kategorie: Seerosen
    puts $fp "<section id=\"cat-seerose\"><h2>Seerosen (Pixabay/Unsplash) <span class=\"tag a\">AUSWAHL nötig</span> <span class=\"tag\">5 Bilder</span></h2><p class=\"sub\">Kandidaten für 3D-Textur / Alpha</p><div class=\"grid\">"
    foreach item {
        {water_lily_01_pixabay_1510707_original.jpg 5184x3456 1253 examples}
        {candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg 1280x960 570 pending-approval}
        {candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg 1280x951 495 pending-approval}
        {candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg 2400x1600 425 pending-approval}
        {candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg 1280x853 248 pending-approval}
    } {
        lassign $item name dims kb folder
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: WaveSpeed 4K Hero
    puts $fp "<section id=\"cat-wavespeed_hero\"><h2>WaveSpeed 4K Hero <span class=\"tag p\">PFLICHT-Kandidat</span> <span class=\"tag\">2 Bilder</span></h2><p class=\"sub\">Bereits generierter Hero-Hintergrund</p><div class=\"grid\">"
    foreach item {
        {hero-meadow.png 5504x3072 18908 media "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..."}
        {hero-meadow.webp 5504x3072 836 media "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..."}
    } {
        lassign $item name dims kb folder prompt
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "          <div class=\"prompt\">$prompt</div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: WaveSpeed 4K Glaskugel
    puts $fp "<section id=\"cat-wavespeed_orb\"><h2>WaveSpeed 4K Glaskugel <span class=\"tag p\">PFLICHT-Kandidat</span> <span class=\"tag\">2 Bilder</span></h2><p class=\"sub\">Referenz-Glaskugel für 3D-Material</p><div class=\"grid\">"
    foreach item {
        {glass-orb.png 4096x4096 18805 media "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..."}
        {glass-orb.webp 4096x4096 730 media "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..."}
    } {
        lassign $item name dims kb folder prompt
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "          <div class=\"prompt\">$prompt</div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: WaveSpeed 4K Sektionen
    puts $fp "<section id=\"cat-wavespeed_projects\"><h2>WaveSpeed 4K Sektionen <span class=\"tag \">Vorhanden</span> <span class=\"tag\">6 Bilder</span></h2><p class=\"sub\">Section-Backgrounds (Claude/Perplexity)</p><div class=\"grid\">"
    foreach item {
        {perplexity-projects.png 4800x3584 21947 media "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..."}
        {claude-projects.png 4800x3584 20711 media "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..."}
        {og-projects.png 5504x3072 18199 media "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..."}
        {perplexity-projects.webp 4800x3584 1805 media "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..."}
        {claude-projects.webp 4800x3584 1114 media "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..."}
        {og-projects.webp 5504x3072 819 media "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..."}
    } {
        lassign $item name dims kb folder prompt
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "          <div class=\"prompt\">$prompt</div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: WaveSpeed 4K Zusatz
    puts $fp "<section id=\"cat-wavespeed_section\"><h2>WaveSpeed 4K Zusatz <span class=\"tag \">Vorhanden</span> <span class=\"tag\">4 Bilder</span></h2><p class=\"sub\">CTA / Feature-Spotlight</p><div class=\"grid\">"
    foreach item {
        {feature-spotlight.png 4800x3584 18688 media "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..."}
        {cta-background.png 5504x3072 15543 media "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..."}
        {feature-spotlight.webp 4800x3584 1315 media "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..."}
        {cta-background.webp 5504x3072 730 media "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..."}
    } {
        lassign $item name dims kb folder prompt
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "          <div class=\"prompt\">$prompt</div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: Studio-Varianten Glaskugel
    puts $fp "<section id=\"cat-studio_variant\"><h2>Studio-Varianten Glaskugel <span class=\"tag \">Referenz</span> <span class=\"tag\">8 Bilder</span></h2><p class=\"sub\">Beleuchtungsstudien für Glas</p><div class=\"grid\">"
    foreach item {
        {var6_flat_lay.png 1672x941 3173 examples}
        {var8_natural_light_outdoor.png 1672x941 2481 examples}
        {var5_closeup_detail.png 1672x941 1863 examples}
        {var4_dramatic_lighting.png 1672x941 1573 examples}
        {var2_studio_white2.png 1672x941 1285 examples}
        {var1_studio_white.png 1672x941 1259 examples}
        {var8_natural_light_outdoor.jpg 1672x941 800 7634afec188f40caa502423fce3ef2ea}
        {var4_dramatic_lighting.jpg 1672x941 386 7634afec188f40caa502423fce3ef2ea}
    } {
        lassign $item name dims kb folder
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: Glasobjekt-Referenz
    puts $fp "<section id=\"cat-glasobjekt\"><h2>Glasobjekt-Referenz <span class=\"tag \">Referenz</span> <span class=\"tag\">2 Bilder</span></h2><p class=\"sub\">Materialstudie Glas</p><div class=\"grid\">"
    foreach item {
        {element_01_glass_bowl.png 1024x1024 1485 examples}
        {element_01_glass_bowl.jpg 1024x1024 126 7634afec188f40caa502423fce3ef2ea}
    } {
        lassign $item name dims kb folder
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: Perlen/Beads
    puts $fp "<section id=\"cat-perle\"><h2>Perlen/Beads <span class=\"tag \">Referenz</span> <span class=\"tag\">4 Bilder</span></h2><p class=\"sub\">Materialstudie klein/rund</p><div class=\"grid\">"
    foreach item {
        {element_02_beads_group.png 1024x1024 1751 examples}
        {element_03_single_bead.png 1024x1024 1473 examples}
        {element_02_beads_group.jpg 1024x1024 284 7634afec188f40caa502423fce3ef2ea}
        {element_03_single_bead.jpg 1024x1024 127 7634afec188f40caa502423fce3ef2ea}
    } {
        lassign $item name dims kb folder
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: Pfingstrosen-Kompositionen
    puts $fp "<section id=\"cat-peonie_ref\"><h2>Pfingstrosen-Kompositionen <span class=\"tag \">Referenz</span> <span class=\"tag\">4 Bilder</span></h2><p class=\"sub\">Referenz-Look; nicht direkt nutzbar</p><div class=\"grid\">"
    foreach item {
        {comp_02_peonies_warm.png 1024x1536 2500 examples}
        {comp_01_peonies_dark.png 1024x1535 2124 examples}
        {comp_02_peonies_warm.jpg 1024x1536 761 7634afec188f40caa502423fce3ef2ea}
        {comp_01_peonies_dark.jpg 1024x1535 642 7634afec188f40caa502423fce3ef2ea}
    } {
        lassign $item name dims kb folder
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: Feder
    puts $fp "<section id=\"cat-feder\"><h2>Feder <span class=\"tag \">Referenz</span> <span class=\"tag\">1 Bilder</span></h2><p class=\"sub\">Referenz Element</p><div class=\"grid\">"
    foreach item {
        {element_04_feather.png 1024x1536 2384 examples}
    } {
        lassign $item name dims kb folder
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: Unsplash Referenzen
    puts $fp "<section id=\"cat-ref_unsplash\"><h2>Unsplash Referenzen <span class=\"tag \">Referenz</span> <span class=\"tag\">3 Bilder</span></h2><p class=\"sub\">Ästhetik-Referenz</p><div class=\"grid\">"
    foreach item {
        {katya-azimova-j945b6ttc7s-unsplash.jpg 4659x6989 8535 examples}
        {anita-austvika-GnO2S8c7slQ-unsplash.jpg 4912x7360 7049 examples}
        {salvus-CiH1lH1u4dc-unsplash.jpg 3840x2160 530 examples}
    } {
        lassign $item name dims kb folder
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: Sonstiges
    puts $fp "<section id=\"cat-sonstiges\"><h2>Sonstiges <span class=\"tag \"></span> <span class=\"tag\">1 Bilder</span></h2><p class=\"sub\"></p><div class=\"grid\">"
    foreach item {
        {candidate-08-pixabay-1510707-original.jpg 5184x3456 1253 pending-approval}
    } {
        lassign $item name dims kb folder
        set thumb "thumbs/thumb_[file rootname $name].webp"
        set alt "$name"
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><img src=\"$thumb\" alt=\"$alt\" loading=\"lazy\"></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: Weltkugel-Frames
    puts $fp "<section id=\"cat-globe_frame\"><h2>Weltkugel-Frames <span class=\"tag \">Vorhanden (Frames)</span> <span class=\"tag\">9 Bilder</span></h2><p class=\"sub\">Bereits verwendet in globe-hero</p><div class=\"grid\">"
    foreach item {
        {frame-02.png "?x?" 98 media}
        {frame-01.png "?x?" 92 media}
        {frame-04.png "?x?" 86 media}
        {frame-05.png "?x?" 73 media}
        {frame-03.png "?x?" 71 media}
        {frame-06.png "?x?" 37 media}
        {frame-09.png "?x?" 37 media}
        {frame-08.png "?x?" 29 media}
        {frame-07.png "?x?" 27 media}
    } {
        lassign $item name dims kb folder
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><div style=\"color:#999\">kein Thumbnail</div></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Kategorie: Screenshots
    puts $fp "<section id=\"cat-screenshot\"><h2>Screenshots <span class=\"tag \">Referenz</span> <span class=\"tag\">4 Bilder</span></h2><p class=\"sub\">Referenz aus Anhang</p><div class=\"grid\">"
    foreach item {
        {image-3.jpg "?x?" 121 7634afec188f40caa502423fce3ef2ea}
        {image-4.jpg "?x?" 118 7634afec188f40caa502423fce3ef2ea}
        {image-2.jpg "?x?" 109 7634afec188f40caa502423fce3ef2ea}
        {image.jpg "?x?" 104 7634afec188f40caa502423fce3ef2ea}
    } {
        lassign $item name dims kb folder
        puts $fp "      <div class=\"card\">"
        puts $fp "        <div class=\"imgwrap\"><div style=\"color:#999\">kein Thumbnail</div></div>"
        puts $fp "        <div class=\"meta\">"
        puts $fp "          <div class=\"name\">$name</div>"
        puts $fp "          <div class=\"dims\">${dims}px · ${kb}KB · <code>$folder</code></div>"
        puts $fp "        </div>"
        puts $fp "      </div>"
    }
    puts $fp "</div></section>"
    
    # Abschluss der Hauptsektion und des Dokuments
    puts $fp "</main></body></html>"
    
    close $fp
}

# Hauptprogramm - prüfe Kommandozeilenargumente
if {$argc != 1} {
    puts stderr "Verwendung: [info script] <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_kontaktbogen $output_file
