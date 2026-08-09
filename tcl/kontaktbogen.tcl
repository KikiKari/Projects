#!/usr/bin/env tclsh
# kontaktbogen.html — portiert nach tcl
# Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# kontaktbogen.tcl - Erzeugt eine HTML-Datei mit Bild-Kontaktbögen
# Portiert von kontaktbogen.html nach Tcl 8.6

proc write_kontaktbogen {filename} {
    set f [open $filename w]
    
    # HTML-Kopf und Styles
    puts $f {<!DOCTYPE html>
<html lang="de"><head><meta charset="utf-8"><title>Kontaktbogen — Project-Landingpage Assets</title>
<style>
  :root{--bg:#FAF8F4;--ink:#1B1A17;--muted:#6E6A61;--line:#E5E1D8;--accent:#A8542F;--accent-2:#2E7D7B;--surface:#fff}
  *{box-sizing:border-box}
  body{margin:0;font-family:'Hanken Grotesk',system-ui,sans-serif;background:var(--bg);color:var(--ink);line-height:1.5}
  header{padding:2.5rem 2rem 1rem;border-bottom:1px solid var(--line);background:var(--surface);position:sticky;top:0;z-index:10}
  header h1{margin:0 0 .5rem;font-family:'Newsreader',Georgia,serif;font-weight:400;font-size:2.25rem}
  header p{margin:.25rem 0;color:var(--muted);max-width:80ch}
  .legend{display:flex;gap:1rem;flex-wrap:wrap;margin-top:.75rem;font-size:.8125rem}
  .pill{padding:.15rem .6rem;border-radius:999px;border:1px solid var(--line);background:#fff}
  .pill.pflicht{border-color:var(--accent);color:var(--accent);font-weight:600}
  .pill.auswahl{border-color:var(--accent-2);color:var(--accent-2);font-weight:600}
  main{padding:2rem;max-width:1400px;margin:0 auto}
  section{margin:2.5rem 0}
  section h2{font-family:'Newsreader',serif;font-weight:400;font-size:1.5rem;margin:0 0 .25rem;display:flex;align-items:center;gap:.75rem}
  section .sub{color:var(--muted);font-size:.875rem;margin:0 0 1.25rem}
  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:1rem}
  .card{background:var(--surface);border:1px solid var(--line);border-radius:10px;overflow:hidden;display:flex;flex-direction:column}
  .card .imgwrap{aspect-ratio:1;background:#f1eee7;display:flex;align-items:center;justify-content:center;overflow:hidden}
  .card img{width:100%;height:100%;object-fit:contain;background:#fff}
  .card .meta{padding:.6rem .75rem .75rem;font-size:.78125rem}
  .card .name{font-family:'JetBrains Mono',monospace;font-size:.6875rem;color:var(--muted);word-break:break-all;line-height:1.3;margin-bottom:.35rem}
  .card .dims{color:var(--muted);font-size:.6875rem;margin-bottom:.35rem}
  .card .prompt{color:var(--ink);font-size:.75rem;line-height:1.35;font-style:italic;border-top:1px solid var(--line);padding-top:.4rem;margin-top:.35rem;max-height:5.5em;overflow:hidden}
  .tag{display:inline-block;padding:.1rem .45rem;border-radius:999px;font-size:.6875rem;background:#F1EEE7;color:var(--muted);margin-right:.25rem}
  .tag.p{background:#F1E5DD;color:var(--accent)}
  .tag.a{background:#DEEDEC;color:var(--accent-2)}
</style></head>
<body>
<header>
  <h1>Kontaktbogen — Project-Landingpage Bildbestand</h1>
  <p>Alle vorhandenen HighRes-Bilder aus deiner Design-Referenz, dem laufenden Codex-Repo und den Anhängen. Kategorisiert nach Verwendungszweck. Bitte markiere pro Kategorie welche Assets in die finale Umsetzung sollen und wo du Erweiterung wünschst.</p>
  <div class="legend">
    <span class="pill pflicht">PFLICHT — muss ins finale Design</span>
    <span class="pill auswahl">AUSWAHL nötig — mehrere Kandidaten</span>
    <span class="pill">Referenz — nur Ästhetik, nicht direkt verwendet</span>
    <span class="pill">Vorhanden — schon im Repo eingebaut</span>
  </div>
</header>
<main>}

    # Kategorie: Seerosen
    puts $f {
<section id="cat-seerose"><h2>Seerosen (Pixabay/Unsplash) <span class="tag a">AUSWAHL nötig</span> <span class="tag">5 Bilder</span></h2><p class="sub">Kandidaten für 3D-Textur / Alpha</p><div class="grid">}
    set seerosen_cards [list \
        [list "water_lily_01_pixabay_1510707_original.jpg" "5184×3456 px · 1253 KB" "examples" "" "thumb_water_lily_01_pixabay_1510707_original.webp"] \
        [list "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg" "1280×960 px · 570 KB" "pending-approval" "" "thumb_candidate-10-pixabay-4602155-wide-real-pond-lily-pads.webp"] \
        [list "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg" "1280×951 px · 495 KB" "pending-approval" "" "thumb_candidate-11-pixabay-5904414-giant-water-lily-3d-depth.webp"] \
        [list "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg" "2400×1600 px · 425 KB" "pending-approval" "" "thumb_candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.webp"] \
        [list "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg" "1280×853 px · 248 KB" "pending-approval" "" "thumb_candidate-09-pixabay-6403860-red-water-lily-water-closeup.webp"] \
    ]
    foreach card $seerosen_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: WaveSpeed 4K Hero
    puts $f {
<section id="cat-wavespeed_hero"><h2>WaveSpeed 4K Hero <span class="tag p">PFLICHT-Kandidat</span> <span class="tag">2 Bilder</span></h2><p class="sub">Bereits generierter Hero-Hintergrund</p><div class="grid">}
    set hero_cards [list \
        [list "hero-meadow.png" "5504×3072 px · 18908 KB" "media" "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..." "thumb_hero-meadow.webp"] \
        [list "hero-meadow.webp" "5504×3072 px · 836 KB" "media" "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..." "thumb_hero-meadow.webp"] \
    ]
    foreach card $hero_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: WaveSpeed 4K Glaskugel
    puts $f {
<section id="cat-wavespeed_orb"><h2>WaveSpeed 4K Glaskugel <span class="tag p">PFLICHT-Kandidat</span> <span class="tag">2 Bilder</span></h2><p class="sub">Referenz-Glaskugel für 3D-Material</p><div class="grid">}
    set orb_cards [list \
        [list "glass-orb.png" "4096×4096 px · 18805 KB" "media" "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..." "thumb_glass-orb.webp"] \
        [list "glass-orb.webp" "4096×4096 px · 730 KB" "media" "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..." "thumb_glass-orb.webp"] \
    ]
    foreach card $orb_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: WaveSpeed 4K Sektionen
    puts $f {
<section id="cat-wavespeed_projects"><h2>WaveSpeed 4K Sektionen <span class="tag ">Vorhanden</span> <span class="tag">6 Bilder</span></h2><p class="sub">Section-Backgrounds (Claude/Perplexity)</p><div class="grid">}
    set section_cards [list \
        [list "perplexity-projects.png" "4800×3584 px · 21947 KB" "media" "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..." "thumb_perplexity-projects.webp"] \
        [list "claude-projects.png" "4800×3584 px · 20711 KB" "media" "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..." "thumb_claude-projects.webp"] \
        [list "og-projects.png" "5504×3072 px · 18199 KB" "media" "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..." "thumb_og-projects.webp"] \
        [list "perplexity-projects.webp" "4800×3584 px · 1805 KB" "media" "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..." "thumb_perplexity-projects.webp"] \
        [list "claude-projects.webp" "4800×3584 px · 1114 KB" "media" "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..." "thumb_claude-projects.webp"] \
        [list "og-projects.webp" "5504×3072 px · 819 KB" "media" "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..." "thumb_og-projects.webp"] \
    ]
    foreach card $section_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: WaveSpeed 4K Zusatz
    puts $f {
<section id="cat-wavespeed_section"><h2>WaveSpeed 4K Zusatz <span class="tag ">Vorhanden</span> <span class="tag">4 Bilder</span></h2><p class="sub">CTA / Feature-Spotlight</p><div class="grid">}
    set zusatz_cards [list \
        [list "feature-spotlight.png" "4800×3584 px · 18688 KB" "media" "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..." "thumb_feature-spotlight.webp"] \
        [list "cta-background.png" "5504×3072 px · 15543 KB" "media" "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..." "thumb_cta-background.webp"] \
        [list "feature-spotlight.webp" "4800×3584 px · 1315 KB" "media" "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..." "thumb_feature-spotlight.webp"] \
        [list "cta-background.webp" "5504×3072 px · 730 KB" "media" "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..." "thumb_cta-background.webp"] \
    ]
    foreach card $zusatz_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: Studio-Varianten Glaskugel
    puts $f {
<section id="cat-studio_variant"><h2>Studio-Varianten Glaskugel <span class="tag ">Referenz</span> <span class="tag">8 Bilder</span></h2><p class="sub">Beleuchtungsstudien für Glas</p><div class="grid">}
    set studio_cards [list \
        [list "var6_flat_lay.png" "1672×941 px · 3173 KB" "examples" "" "thumb_var6_flat_lay.webp"] \
        [list "var8_natural_light_outdoor.png" "1672×941 px · 2481 KB" "examples" "" "thumb_var8_natural_light_outdoor.webp"] \
        [list "var5_closeup_detail.png" "1672×941 px · 1863 KB" "examples" "" "thumb_var5_closeup_detail.webp"] \
        [list "var4_dramatic_lighting.png" "1672×941 px · 1573 KB" "examples" "" "thumb_var4_dramatic_lighting.webp"] \
        [list "var2_studio_white2.png" "1672×941 px · 1285 KB" "examples" "" "thumb_var2_studio_white2.webp"] \
        [list "var1_studio_white.png" "1672×941 px · 1259 KB" "examples" "" "thumb_var1_studio_white.webp"] \
        [list "var8_natural_light_outdoor.jpg" "1672×941 px · 800 KB" "7634afec188f40caa502423fce3ef2ea" "" "thumb_var8_natural_light_outdoor.webp"] \
        [list "var4_dramatic_lighting.jpg" "1672×941 px · 386 KB" "7634afec188f40caa502423fce3ef2ea" "" "thumb_var4_dramatic_lighting.webp"] \
    ]
    foreach card $studio_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: Glasobjekt-Referenz
    puts $f {
<section id="cat-glasobjekt"><h2>Glasobjekt-Referenz <span class="tag ">Referenz</span> <span class="tag">2 Bilder</span></h2><p class="sub">Materialstudie Glas</p><div class="grid">}
    set glas_cards [list \
        [list "element_01_glass_bowl.png" "1024×1024 px · 1485 KB" "examples" "" "thumb_element_01_glass_bowl.webp"] \
        [list "element_01_glass_bowl.jpg" "1024×1024 px · 126 KB" "7634afec188f40caa502423fce3ef2ea" "" "thumb_element_01_glass_bowl.webp"] \
    ]
    foreach card $glas_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: Perlen/Beads
    puts $f {
<section id="cat-perle"><h2>Perlen/Beads <span class="tag ">Referenz</span> <span class="tag">4 Bilder</span></h2><p class="sub">Materialstudie klein/rund</p><div class="grid">}
    set perle_cards [list \
        [list "element_02_beads_group.png" "1024×1024 px · 1751 KB" "examples" "" "thumb_element_02_beads_group.webp"] \
        [list "element_03_single_bead.png" "1024×1024 px · 1473 KB" "examples" "" "thumb_element_03_single_bead.webp"] \
        [list "element_02_beads_group.jpg" "1024×1024 px · 284 KB" "7634afec188f40caa502423fce3ef2ea" "" "thumb_element_02_beads_group.webp"] \
        [list "element_03_single_bead.jpg" "1024×1024 px · 127 KB" "7634afec188f40caa502423fce3ef2ea" "" "thumb_element_03_single_bead.webp"] \
    ]
    foreach card $perle_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: Pfingstrosen-Kompositionen
    puts $f {
<section id="cat-peonie_ref"><h2>Pfingstrosen-Kompositionen <span class="tag ">Referenz</span> <span class="tag">4 Bilder</span></h2><p class="sub">Referenz-Look; nicht direkt nutzbar</p><div class="grid">}
    set peonie_cards [list \
        [list "comp_02_peonies_warm.png" "1024×1536 px · 2500 KB" "examples" "" "thumb_comp_02_peonies_warm.webp"] \
        [list "comp_01_peonies_dark.png" "1024×1535 px · 2124 KB" "examples" "" "thumb_comp_01_peonies_dark.webp"] \
        [list "comp_02_peonies_warm.jpg" "1024×1536 px · 761 KB" "7634afec188f40caa502423fce3ef2ea" "" "thumb_comp_02_peonies_warm.webp"] \
        [list "comp_01_peonies_dark.jpg" "1024×1535 px · 642 KB" "7634afec188f40caa502423fce3ef2ea" "" "thumb_comp_01_peonies_dark.webp"] \
    ]
    foreach card $peonie_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: Feder
    puts $f {
<section id="cat-feder"><h2>Feder <span class="tag ">Referenz</span> <span class="tag">1 Bilder</span></h2><p class="sub">Referenz Element</p><div class="grid">}
    set feder_cards [list \
        [list "element_04_feather.png" "1024×1536 px · 2384 KB" "examples" "" "thumb_element_04_feather.webp"] \
    ]
    foreach card $feder_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: Unsplash Referenzen
    puts $f {
<section id="cat-ref_unsplash"><h2>Unsplash Referenzen <span class="tag ">Referenz</span> <span class="tag">3 Bilder</span></h2><p class="sub">Ästhetik-Referenz</p><div class="grid">}
    set unsplash_cards [list \
        [list "katya-azimova-j945b6ttc7s-unsplash.jpg" "4659×6989 px · 8535 KB" "examples" "" "thumb_katya-azimova-j945b6ttc7s-unsplash.webp"] \
        [list "anita-austvika-GnO2S8c7slQ-unsplash.jpg" "4912×7360 px · 7049 KB" "examples" "" "thumb_anita-austvika-GnO2S8c7slQ-unsplash.webp"] \
        [list "salvus-CiH1lH1u4dc-unsplash.jpg" "3840×2160 px · 530 KB" "examples" "" "thumb_salvus-CiH1lH1u4dc-unsplash.webp"] \
    ]
    foreach card $unsplash_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: Sonstiges
    puts $f {
<section id="cat-sonstiges"><h2>Sonstiges <span class="tag "></span> <span class="tag">1 Bilder</span></h2><p class="sub"></p><div class="grid">}
    set sonstige_cards [list \
        [list "candidate-08-pixabay-1510707-original.jpg" "5184×3456 px · 1253 KB" "pending-approval" "" "thumb_candidate-08-pixabay-1510707-original.webp"] \
    ]
    foreach card $sonstige_cards {
        lassign $card name dims folder prompt thumb
        write_card $f $name $dims $folder $prompt $thumb
    }
    puts $f {</div></section>}

    # Kategorie: Weltkugel-Frames
    puts $f {
<section id="cat-globe_frame"><h2>Weltkugel-Frames <span class="tag ">Vorhanden (Frames)</span> <span class="tag">9 Bilder</span></h2><p class="sub">Bereits verwendet in globe-hero</p><div class="grid">}
    set frame_cards [list \
        [list "frame-02.png" "?×? px · 98 KB" "media" "" ""] \
        [list "frame-01.png" "?×? px · 92 KB" "media" "" ""] \
        [list "frame-04.png" "?×? px · 86 KB" "media" "" ""] \
        [list "frame-05.png" "?×? px · 73 KB" "media" "" ""] \
        [list "frame-03.png" "?×? px · 71 KB" "media" "" ""] \
        [list "frame-06.png" "?×? px · 37 KB" "media" "" ""] \
        [list "frame-09.png" "?×? px · 37 KB" "media" "" ""] \
        [list "frame-08.png" "?×? px · 29 KB" "media" "" ""] \
        [list "frame-07.png" "?×? px · 27 KB" "media" "" ""] \
    ]
    foreach card $frame_cards {
        lassign $card name dims folder prompt thumb
        write_card_no_thumb $f $name $dims $folder $prompt
    }
    puts $f {</div></section>}

    # Kategorie: Screenshots
    puts $f {
<section id="cat-screenshot"><h2>Screenshots <span class="tag ">Referenz</span> <span class="tag">4 Bilder</span></h2><p class="sub">Referenz aus Anhang</p><div class="grid">}
    set screenshot_cards [list \
        [list "image-3.jpg" "?×? px · 121 KB" "7634afec188f40caa502423fce3ef2ea" "" ""] \
        [list "image-4.jpg" "?×? px · 118 KB" "7634afec188f40caa502423fce3ef2ea" "" ""] \
        [list "image-2.jpg" "?×? px · 109 KB" "7634afec188f40caa502423fce3ef2ea" "" ""] \
        [list "image.jpg" "?×? px · 104 KB" "7634afec188f40caa502423fce3ef2ea" "" ""] \
    ]
    foreach card $screenshot_cards {
        lassign $card name dims folder prompt thumb
        write_card_no_thumb $f $name $dims $folder $prompt
    }
    puts $f {</div></section>}

    # Abschluss
    puts $f {</main></body></html>}
    close $f
}

# Hilfsprozedur für Karten mit Thumbnail
proc write_card {f name dims folder prompt thumb} {
    puts $f "      <div class=\"card\">
        <div class=\"imgwrap\"><img src=\"thumbs/$thumb\" alt=\"$name\" loading=\"lazy\"></div>
        <div class=\"meta\">
          <div class=\"name\">$name</div>
          <div class=\"dims\">$dims</div>"
    if {$folder ne ""} {
        puts $f "          <div class=\"folder\">$folder</div>"
    }
    if {$prompt ne ""} {
        puts $f "          <div class=\"prompt\">$prompt</div>"
    }
    puts $f "        </div>
      </div>"
}

# Hilfsprozedur für Karten ohne Thumbnail
proc write_card_no_thumb {f name dims folder prompt} {
    puts $f "      <div class=\"card\">
        <div class=\"imgwrap\"><div style=\"color:#999\">kein Thumbnail</div></div>
        <div class=\"meta\">
          <div class=\"name\">$name</div>
          <div class=\"dims\">$dims</div>"
    if {$folder ne ""} {
        puts $f "          <div class=\"folder\">$folder</div>"
    }
    if {$prompt ne ""} {
        puts $f "          <div class=\"prompt\">$prompt</div>"
    }
    puts $f "        </div>
      </div>"
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Aufruf: [info script] <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_kontaktbogen $output_file
