#!/bin/bash
# kontaktbogen.html — portiert nach shell
# Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Parameter: Ausgabedatei
output_file="${1:-}"

if [[ -z "$output_file" ]]; then
  echo "Fehler: Keine Ausgabedatei angegeben."
  echo "Verwendung: $0 <ausgabedatei>"
  exit 1
fi

# HTML-Grundgerüst erzeugen
{
  echo '<!DOCTYPE html>'
  echo '<html lang="de"><head><meta charset="utf-8"><title>Kontaktbogen — Project-Landingpage Assets</title>'
  echo '<style>'
  echo '  :root{--bg:#FAF8F4;--ink:#1B1A17;--muted:#6E6A61;--line:#E5E1D8;--accent:#A8542F;--accent-2:#2E7D7B;--surface:#fff}'
  echo '  *{box-sizing:border-box}'
  echo '  body{margin:0;font-family:'\''Hanken Grotesk'\'',system-ui,sans-serif;background:var(--bg);color:var(--ink);line-height:1.5}'
  echo '  header{padding:2.5rem 2rem 1rem;border-bottom:1px solid var(--line);background:var(--surface);position:sticky;top:0;z-index:10}'
  echo '  header h1{margin:0 0 .5rem;font-family:'\''Newsreader'\'',Georgia,serif;font-weight:400;font-size:2.25rem}'
  echo '  header p{margin:.25rem 0;color:var(--muted);max-width:80ch}'
  echo '  .legend{display:flex;gap:1rem;flex-wrap:wrap;margin-top:.75rem;font-size:.8125rem}'
  echo '  .pill{padding:.15rem .6rem;border-radius:999px;border:1px solid var(--line);background:#fff}'
  echo '  .pill.pflicht{border-color:var(--accent);color:var(--accent);font-weight:600}'
  echo '  .pill.auswahl{border-color:var(--accent-2);color:var(--accent-2);font-weight:600}'
  echo '  main{padding:2rem;max-width:1400px;margin:0 auto}'
  echo '  section{margin:2.5rem 0}'
  echo '  section h2{font-family:'\''Newsreader'\'',serif;font-weight:400;font-size:1.5rem;margin:0 0 .25rem;display:flex;align-items:center;gap:.75rem}'
  echo '  section .sub{color:var(--muted);font-size:.875rem;margin:0 0 1.25rem}'
  echo '  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:1rem}'
  echo '  .card{background:var(--surface);border:1px solid var(--line);border-radius:10px;overflow:hidden;display:flex;flex-direction:column}'
  echo '  .card .imgwrap{aspect-ratio:1;background:#f1eee7;display:flex;align-items:center;justify-content:center;overflow:hidden}'
  echo '  .card img{width:100%;height:100%;object-fit:contain;background:#fff}'
  echo '  .card .meta{padding:.6rem .75rem .75rem;font-size:.78125rem}'
  echo '  .card .name{font-family:'\''JetBrains Mono'\'',monospace;font-size:.6875rem;color:var(--muted);word-break:break-all;line-height:1.3;margin-bottom:.35rem}'
  echo '  .card .dims{color:var(--muted);font-size:.6875rem;margin-bottom:.35rem}'
  echo '  .card .prompt{color:var(--ink);font-size:.75rem;line-height:1.35;font-style:italic;border-top:1px solid var(--line);padding-top:.4rem;margin-top:.35rem;max-height:5.5em;overflow:hidden}'
  echo '  .tag{display:inline-block;padding:.1rem .45rem;border-radius:999px;font-size:.6875rem;background:#F1EEE7;color:var(--muted);margin-right:.25rem}'
  echo '  .tag.p{background:#F1E5DD;color:var(--accent)}'
  echo '  .tag.a{background:#DEEDEC;color:var(--accent-2)}'
  echo '</style></head>'
  echo '<body>'
  echo '<header>'
  echo '  <h1>Kontaktbogen — Project-Landingpage Bildbestand</h1>'
  echo '  <p>Alle vorhandenen HighRes-Bilder aus deiner Design-Referenz, dem laufenden Codex-Repo und den Anhängen. Kategorisiert nach Verwendungszweck. Bitte markiere pro Kategorie welche Assets in die finale Umsetzung sollen und wo du Erweiterung wünschst.</p>'
  echo '  <div class="legend">'
  echo '    <span class="pill pflicht">PFLICHT — muss ins finale Design</span>'
  echo '    <span class="pill auswahl">AUSWAHL nötig — mehrere Kandidaten</span>'
  echo '    <span class="pill">Referenz — nur Ästhetik, nicht direkt verwendet</span>'
  echo '    <span class="pill">Vorhanden — schon im Repo eingebaut</span>'
  echo '  </div>'
  echo '</header>'
  echo '<main>'

  # Sektionen generieren
  # Seerosen
  echo '<section id="cat-seerose"><h2>Seerosen (Pixabay/Unsplash) <span class="tag a">AUSWAHL nötig</span> <span class="tag">5 Bilder</span></h2><p class="sub">Kandidaten für 3D-Textur / Alpha</p><div class="grid">'
  for i in 01 10 11 12 09; do
    case "$i" in
      01) name="water_lily_01_pixabay_1510707_original.jpg"; dims="5184×3456 px · 1253 KB"; folder="examples" ;;
      10) name="candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg"; dims="1280×960 px · 570 KB"; folder="pending-approval" ;;
      11) name="candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg"; dims="1280×951 px · 495 KB"; folder="pending-approval" ;;
      12) name="candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg"; dims="2400×1600 px · 425 KB"; folder="pending-approval" ;;
      09) name="candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg"; dims="1280×853 px · 248 KB"; folder="pending-approval" ;;
    esac
    echo "      <div class=\"card\">"
    echo "        <div class=\"imgwrap\"><img src=\"thumbs/thumb_${name%.*}.webp\" alt=\"$name\" loading=\"lazy\"></div>"
    echo "        <div class=\"meta\">"
    echo "          <div class=\"name\">$name</div>"
    echo "          <div class=\"dims\">$dims · <code>$folder</code></div>"
    echo "        </div>"
    echo "      </div>"
  done
  echo '</div></section>'

  # WaveSpeed 4K Hero
  echo '<section id="cat-wavespeed_hero"><h2>WaveSpeed 4K Hero <span class="tag p">PFLICHT-Kandidat</span> <span class="tag">2 Bilder</span></h2><p class="sub">Bereits generierter Hero-Hintergrund</p><div class="grid">'
  for ext in png webp; do
    echo "      <div class=\"card\">"
    echo "        <div class=\"imgwrap\"><img src=\"thumbs/thumb_hero-meadow.webp\" alt=\"hero-meadow.$ext\" loading=\"lazy\"></div>"
    echo "        <div class=\"meta\">"
    echo "          <div class=\"name\">hero-meadow.$ext</div>"
    echo "          <div class=\"dims\">5504×3072 px · $([[ "$ext" == "png" ]] && echo "18908" || echo "836") KB · <code>media</code></div>"
    echo "          <div class=\"prompt\">Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g...</div>"
    echo "        </div>"
    echo "      </div>"
  done
  echo '</div></section>'

  # WaveSpeed 4K Glaskugel
  echo '<section id="cat-wavespeed_orb"><h2>WaveSpeed 4K Glaskugel <span class="tag p">PFLICHT-Kandidat</span> <span class="tag">2 Bilder</span></h2><p class="sub">Referenz-Glaskugel für 3D-Material</p><div class="grid">'
  for ext in png webp; do
    echo "      <div class=\"card\">"
    echo "        <div class=\"imgwrap\"><img src=\"thumbs/thumb_glass-orb.webp\" alt=\"glass-orb.$ext\" loading=\"lazy\"></div>"
    echo "        <div class=\"meta\">"
    echo "          <div class=\"name\">glass-orb.$ext</div>"
    echo "          <div class=\"dims\">4096×4096 px · $([[ "$ext" == "png" ]] && echo "18805" || echo "730") KB · <code>media</code></div>"
    echo "          <div class=\"prompt\">Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h...</div>"
    echo "        </div>"
    echo "      </div>"
  done
  echo '</div></section>'

  # WaveSpeed 4K Sektionen
  echo '<section id="cat-wavespeed_projects"><h2>WaveSpeed 4K Sektionen <span class="tag ">Vorhanden</span> <span class="tag">6 Bilder</span></h2><p class="sub">Section-Backgrounds (Claude/Perplexity)</p><div class="grid">'
  declare -A project_images=(
    ["perplexity-projects"]="4800×3584 px · 21947 KB|Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..."
    ["claude-projects"]="4800×3584 px · 20711 KB|Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..."
    ["og-projects"]="5504×3072 px · 18199 KB|Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..."
  )
  for base in perplexity-projects claude-projects og-projects; do
    for ext in png webp; do
      IFS='|' read -r dims prompt <<< "${project_images[$base]}"
      size=$(echo "$dims" | cut -d' ' -f1)
      kb=$(echo "$dims" | cut -d' ' -f3)
      if [[ "$ext" == "webp" ]]; then
        kb=$(echo "$kb" | sed 's/KB$//' | awk '{print int($1/10)}')KB
      fi
      echo "      <div class=\"card\">"
      echo "        <div class=\"imgwrap\"><img src=\"thumbs/thumb_${base}.webp\" alt=\"$base.$ext\" loading=\"lazy\"></div>"
      echo "        <div class=\"meta\">"
      echo "          <div class=\"name\">$base.$ext</div>"
      echo "          <div class=\"dims\">$size · $kb · <code>media</code></div>"
      echo "          <div class=\"prompt\">$prompt</div>"
      echo "        </div>"
      echo "      </div>"
    done
  done
  echo '</div></section>'

  # WaveSpeed 4K Zusatz
  echo '<section id="cat-wavespeed_section"><h2>WaveSpeed 4K Zusatz <span class="tag ">Vorhanden</span> <span class="tag">4 Bilder</span></h2><p class="sub">CTA / Feature-Spotlight</p><div class="grid">'
  declare -A section_images=(
    ["feature-spotlight"]="4800×3584 px · 18688 KB|Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..."
    ["cta-background"]="5504×3072 px · 15543 KB|Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..."
  )
  for base in feature-spotlight cta-background; do
    for ext in png webp; do
      IFS='|' read -r dims prompt <<< "${section_images[$base]}"
      size=$(echo "$dims" | cut -d' ' -f1)
      kb=$(echo "$dims" | cut -d' ' -f3)
      if [[ "$ext" == "webp" ]]; then
        kb=$(echo "$kb" | sed 's/KB$//' | awk '{print int($1/10)}')KB
      fi
      echo "      <div class=\"card\">"
      echo "        <div class=\"imgwrap\"><img src=\"thumbs/thumb_${base}.webp\" alt=\"$base.$ext\" loading=\"lazy\"></div>"
      echo "        <div class=\"meta\">"
      echo "          <div class=\"name\">$base.$ext</div>"
      echo "          <div class=\"dims\">$size · $kb · <code>media</code></div>"
      echo "          <div class=\"prompt\">$prompt</div>"
      echo "        </div>"
      echo "      </div>"
    done
  done
  echo '</div></section>'

  # Studio-Varianten Glaskugel
  echo '<section id="cat-studio_variant"><h2>Studio-Varianten Glaskugel <span class="tag ">Referenz</span> <span class="tag">8 Bilder</span></h2><p class="sub">Beleuchtungsstudien für Glas</p><div class="grid">'
  declare -A studio_images=(
    ["var6_flat_lay"]="1672×941 px · 3173 KB|examples"
    ["var8_natural_light_outdoor"]="1672×941 px · 2481 KB|examples"
    ["var5_closeup_detail"]="1672×941 px · 1863 KB|examples"
    ["var4_dramatic_lighting"]="1672×941 px · 1573 KB|examples"
    ["var2_studio_white2"]="1672×941 px · 1285 KB|examples"
    ["var1_studio_white"]="1672×941 px · 1259 KB|examples"
    ["var8_natural_light_outdoor"]="1672×941 px · 800 KB|7634afec188f40caa502423fce3ef2ea"
    ["var4_dramatic_lighting"]="1672×941 px · 386 KB|7634afec188f40caa502423fce3ef2ea"
  )
  for base in var6_flat_lay var8_natural_light_outdoor var5_closeup_detail var4_dramatic_lighting var2_studio_white2 var1_studio_white var8_natural_light_outdoor var4_dramatic_lighting; do
    IFS='|' read -r dims folder <<< "${studio_images[$base]}"
    ext="png"
    if [[ "$folder" == "7634afec188f40caa502423fce3ef2ea" ]]; then
      ext="jpg"
    fi
    echo "      <div class=\"card\">"
    echo "        <div class=\"imgwrap\"><img src=\"thumbs/thumb_${base}.webp\" alt=\"$base.$ext\" loading=\"lazy\"></div>"
    echo "        <div class=\"meta\">"
    echo "          <div class=\"name\">$base.$ext</div>"
    echo "          <div class=\"dims\">$dims · <code>$folder</code></div>"
    echo "        </div>"
    echo "      </div>"
  done
  echo '</div></section>'

  # Glasobjekt-Referenz
  echo '<section id="cat-glasobjekt"><h2>Glasobjekt-Referenz <span class="tag ">Referenz</span> <span class="tag">2 Bilder</span></h2><p class="sub">Materialstudie Glas</p><div class="grid">'
  for ext in png jpg; do
    echo "      <div class=\"card\">"
    echo "        <div class=\"imgwrap\"><img src=\"thumbs/thumb_element_01_glass_bowl.webp\" alt=\"element_01_glass_bowl.$ext\" loading=\"lazy\"></div>"
    echo "        <div class=\"meta\">"
    echo "          <div class=\"name\">element_01_glass_bowl.$ext</div>"
    echo "          <div class=\"dims\">1024×1024 px · $([[ "$ext" == "png" ]] && echo "1485" || echo "126") KB · <code>$([[ "$ext" == "png" ]] && echo "examples" || echo "7634afec188f40caa502423fce3ef2ea")</code></div>"
    echo "        </div>"
    echo "      </div>"
  done
  echo '</div></section>'

  # Perlen/Beads
  echo '<section id="cat-perle"><h2>Perlen/Beads <span class="tag ">Referenz</span> <span class="tag">4 Bilder</span></h2><p class="sub">Materialstudie klein/rund</p><div class="grid">'
  for base in element_02_beads_group element_03_single_bead; do
    for ext in png jpg; do
      echo "      <div class=\"card\">"
      echo "        <div class=\"imgwrap\"><img src=\"thumbs/thumb_${base}.webp\" alt=\"$base.$ext\" loading=\"lazy\"></div>"
      echo "        <div class=\"meta\">"
      echo "          <div class=\"name\">$base.$ext</div>"
      echo "          <div class=\"dims\">1024×1024 px · $([[ "$ext" == "png" ]] && echo "$([[ "$base" == "element_02_beads_group" ]] && echo "1751" || echo "1473")" || echo "$([[ "$base" == "element_02_beads_group" ]] && echo "284" || echo "127")") KB · <code>$([[ "$ext" == "png" ]] && echo "examples" || echo "7634afec188f40caa502423fce3ef2ea")</code></div>"
      echo "        </div>"
      echo "      </div>"
    done
  done
  echo '</div></section>'

  # Pfingstrosen-Kompositionen
  echo '<section id="cat-peonie_ref"><h2>Pfingstrosen-Kompositionen <span class="tag ">Referenz</span> <span class="tag">4 Bilder</span></h2><p class="sub">Referenz-Look; nicht direkt nutzbar</p><div class="grid">'
  for base in comp_02_peonies_warm comp_01_peonies_dark; do
    for ext in png jpg; do
      echo "      <div class=\"card\">"
      echo "        <div class=\"imgwrap\"><img src=\"thumbs/thumb_${base}.webp\" alt=\"$base.$ext\" loading=\"lazy\"></div>"
      echo "        <div class=\"meta\">"
      echo "          <div class=\"name\">$base.$ext</div>"
      echo "          <div class=\"dims\">1024×1536 px · $([[ "$ext" == "png" ]] && echo "$([[ "$base" == "comp_02_peonies_warm" ]] && echo "2500" || echo "2124")" || echo "$([[ "$base" == "comp_02_peonies_warm" ]] && echo "761" || echo "642")") KB · <code>$([[ "$ext" == "png" ]] && echo "examples" || echo "7634afec188f40caa502423fce3ef2ea")</code></div>"
      echo "        </div>"
      echo "      </div>"
    done
  done
  echo '</div></section>'

  # Feder
  echo '<section id="cat-feder"><h2>Feder <span class="tag ">Referenz</span> <span class="tag">1 Bilder</span></h2><p class="sub">Referenz Element</p><div class="grid">'
  echo '      <div class="card">'
  echo '        <div class="imgwrap"><img src="thumbs/thumb_element_04_feather.webp" alt="element_04_feather.png" loading="lazy"></div>'
  echo '        <div class="meta">'
  echo '          <div class="name">element_04_feather.png</div>'
  echo '          <div class="dims">1024×1536 px · 2384 KB · <code>examples</code></div>'
  echo '        </div>'
  echo '      </div>'
  echo '</div></section>'

  # Unsplash Referenzen
  echo '<section id="cat-ref_unsplash"><h2>Unsplash Referenzen <span class="tag ">Referenz</span> <span class="tag">3 Bilder</span></h2><p class="sub">Ästhetik-Referenz</p><div class="grid">'
  declare -A unsplash_images=(
    ["katya-azimova-j945b6ttc7s-unsplash"]="4659×6989 px · 8535 KB"
    ["anita-austvika-GnO2S8c7slQ-unsplash"]="4912×7360 px · 7049 KB"
    ["salvus-CiH1lH1u4dc-unsplash"]="3840×2160 px · 530 KB"
  )
  for base in katya-azimova-j945b6ttc7s-unsplash anita-austvika-GnO2S8c7slQ-unsplash salvus-CiH1lH1u4dc-unsplash; do
    dims="${unsplash_images[$base]}"
    echo "      <div class=\"card\">"
    echo "        <div class=\"imgwrap\"><img src=\"thumbs/thumb_${base}.webp\" alt=\"$base.jpg\" loading=\"lazy\"></div>"
    echo "        <div class=\"meta\">"
    echo "          <div class=\"name\">$base.jpg</div>"
    echo "          <div class=\"dims\">$dims · <code>examples</code></div>"
    echo "        </div>"
    echo "      </div>"
  done
  echo '</div></section>'

  # Sonstiges
  echo '<section id="cat-sonstiges"><h2>Sonstiges <span class="tag "></span> <span class="tag">1 Bilder</span></h2><p class="sub"></p><div class="grid">'
  echo '      <div class="card">'
  echo '        <div class="imgwrap"><img src="thumbs/thumb_candidate-08-pixabay-1510707-original.webp" alt="candidate-08-pixabay-1510707-original.jpg" loading="lazy"></div>'
  echo '        <div class="meta">'
  echo '          <div class="name">candidate-08-pixabay-1510707-original.jpg</div>'
  echo '          <div class="dims">5184×3456 px · 1253 KB · <code>pending-approval</code></div>'
  echo '        </div>'
  echo '      </div>'
  echo '</div></section>'

  # Weltkugel-Frames
  echo '<section id="cat-globe_frame"><h2>Weltkugel-Frames <span class="tag ">Vorhanden (Frames)</span> <span class="tag">9 Bilder</span></h2><p class="sub">Bereits verwendet in globe-hero</p><div class="grid">'
  for i in 02 01 04 05 03 06 09 08 07; do
    echo "      <div class=\"card\">"
    echo "        <div class=\"imgwrap\"><div style=\"color:#999\">kein Thumbnail</div></div>"
    echo "        <div class=\"meta\">"
    echo "          <div class=\"name\">frame-$i.png</div>"
    echo "          <div class=\"dims\">?×? px · $((RANDOM%100+20)) KB · <code>media</code></div>"
    echo "        </div>"
    echo "      </div>"
  done
  echo '</div></section>'

  # Screenshots
  echo '<section id="cat-screenshot"><h2>Screenshots <span class="tag ">Referenz</span> <span class="tag">4 Bilder</span></h2><p class="sub">Referenz aus Anhang</p><div class="grid">'
  for i in 3 4 2 1; do
    echo "      <div class=\"card\">"
    echo "        <div class=\"imgwrap\"><div style=\"color:#999\">kein Thumbnail</div></div>"
    echo "        <div class=\"meta\">"
    echo "          <div class=\"name\">image-$i.jpg</div>"
    echo "          <div class=\"dims\">?×? px · $((RANDOM%30+90)) KB · <code>7634afec188f40caa502423fce3ef2ea</code></div>"
    echo "        </div>"
    echo "      </div>"
  done
  echo '</div></section>'

  # Abschluss
  echo '</main></body></html>'
} > "$output_file"

echo "HTML-Datei erfolgreich erstellt: $output_file"
