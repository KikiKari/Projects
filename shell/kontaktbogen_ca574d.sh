#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "c50ef1f6e719b0410644a2dbb30a32556278ae16e326140d74e173acadeb2e0c", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "shell"}
# kontaktbogen.html — portiert nach shell
# Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Funktion zur Erstellung eines Bildkarten-Elements
create_card() {
    local thumb="$1"
    local alt="$2"
    local name="$3"
    local dims="$4"
    local size="$5"
    local code="$6"
    local prompt="$7"

    cat <<EOF
      <div class="card">
        <div class="imgwrap"><img src="thumbs/${thumb}" alt="${alt}" loading="lazy"></div>
        <div class="meta">
          <div class="name">${name}</div>
          <div class="dims">${dims} px · ${size} KB · <code>${code}</code></div>
EOF

    if [ -n "$prompt" ]; then
        # Kürzen des Prompts auf maximal 100 Zeichen plus Auslassungspunkte
        local short_prompt="${prompt:0:100}"
        if [ "${#prompt}" -gt 100 ]; then
            short_prompt="${short_prompt}..."
        fi
        echo "          <div class=\"prompt\">${short_prompt}</div>"
    fi

    echo "        </div>"
    echo "      </div>"
}

# Funktion zur Erstellung einer Sektion
create_section() {
    local id="$1"
    local title="$2"
    local tag_type="$3"
    local tag_text="$4"
    local count="$5"
    local subtitle="$6"
    shift 6
    local cards=("$@")

    cat <<EOF
<section id="${id}"><h2>${title} <span class="tag ${tag_type}">${tag_text}</span> <span class="tag">${count} Bilder</span></h2><p class="sub">${subtitle}</p><div class="grid">
EOF

    local i
    for ((i=0; i<${#cards[@]}; i+=7)); do
        create_card "${cards[i]}" "${cards[i+1]}" "${cards[i+2]}" "${cards[i+3]}" "${cards[i+4]}" "${cards[i+5]}" "${cards[i+6]}"
    done

    echo "</div></section>"
}

# Hauptfunktion zur Generierung der HTML-Datei
main() {
    local output_file="${1:-kontaktbogen.html}"

    cat > "$output_file" <<'EOF'
<!DOCTYPE html>
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
<main>
EOF

    # Seerosen
    create_section \
        "cat-seerose" \
        "Seerosen (Pixabay/Unsplash)" \
        "a" \
        "AUSWAHL nötig" \
        "5" \
        "Kandidaten für 3D-Textur / Alpha" \
        "thumb_water_lily_01_pixabay_1510707_original.webp" "water_lily_01_pixabay_1510707_original.jpg" "water_lily_01_pixabay_1510707_original.jpg" "5184×3456" "1253" "examples" "" \
        "thumb_candidate-10-pixabay-4602155-wide-real-pond-lily-pads.webp" "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg" "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg" "1280×960" "570" "pending-approval" "" \
        "thumb_candidate-11-pixabay-5904414-giant-water-lily-3d-depth.webp" "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg" "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg" "1280×951" "495" "pending-approval" "" \
        "thumb_candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.webp" "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg" "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg" "2400×1600" "425" "pending-approval" "" \
        "thumb_candidate-09-pixabay-6403860-red-water-lily-water-closeup.webp" "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg" "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg" "1280×853" "248" "pending-approval" ""

    # WaveSpeed 4K Hero
    create_section \
        "cat-wavespeed_hero" \
        "WaveSpeed 4K Hero" \
        "p" \
        "PFLICHT-Kandidat" \
        "2" \
        "Bereits generierter Hero-Hintergrund" \
        "thumb_hero-meadow.webp" "hero-meadow.png" "hero-meadow.png" "5504×3072" "18908" "media" "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..." \
        "thumb_hero-meadow.webp" "hero-meadow.webp" "hero-meadow.webp" "5504×3072" "836" "media" "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..."

    # WaveSpeed 4K Glaskugel
    create_section \
        "cat-wavespeed_orb" \
        "WaveSpeed 4K Glaskugel" \
        "p" \
        "PFLICHT-Kandidat" \
        "2" \
        "Referenz-Glaskugel für 3D-Material" \
        "thumb_glass-orb.webp" "glass-orb.png" "glass-orb.png" "4096×4096" "18805" "media" "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..." \
        "thumb_glass-orb.webp" "glass-orb.webp" "glass-orb.webp" "4096×4096" "730" "media" "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..."

    # WaveSpeed 4K Sektionen
    create_section \
        "cat-wavespeed_projects" \
        "WaveSpeed 4K Sektionen" \
        "" \
        "Vorhanden" \
        "6" \
        "Section-Backgrounds (Claude/Perplexity)" \
        "thumb_perplexity-projects.webp" "perplexity-projects.png" "perplexity-projects.png" "4800×3584" "21947" "media" "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..." \
        "thumb_claude-projects.webp" "claude-projects.png" "claude-projects.png" "4800×3584" "20711" "media" "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..." \
        "thumb_og-projects.webp" "og-projects.png" "og-projects.png" "5504×3072" "18199" "media" "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..." \
        "thumb_perplexity-projects.webp" "perplexity-projects.webp" "perplexity-projects.webp" "4800×3584" "1805" "media" "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..." \
        "thumb_claude-projects.webp" "claude-projects.webp" "claude-projects.webp" "4800×3584" "1114" "media" "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..." \
        "thumb_og-projects.webp" "og-projects.webp" "og-projects.webp" "5504×3072" "819" "media" "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..."

    # WaveSpeed 4K Zusatz
    create_section \
        "cat-wavespeed_section" \
        "WaveSpeed 4K Zusatz" \
        "" \
        "Vorhanden" \
        "4" \
        "CTA / Feature-Spotlight" \
        "thumb_feature-spotlight.webp" "feature-spotlight.png" "feature-spotlight.png" "4800×3584" "18688" "media" "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..." \
        "thumb_cta-background.webp" "cta-background.png" "cta-background.png" "5504×3072" "15543" "media" "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..." \
        "thumb_feature-spotlight.webp" "feature-spotlight.webp" "feature-spotlight.webp" "4800×3584" "1315" "media" "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..." \
        "thumb_cta-background.webp" "cta-background.webp" "cta-background.webp" "5504×3072" "730" "media" "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..."

    # Studio-Varianten Glaskugel
    create_section \
        "cat-studio_variant" \
        "Studio-Varianten Glaskugel" \
        "" \
        "Referenz" \
        "8" \
        "Beleuchtungsstudien für Glas" \
        "thumb_var6_flat_lay.webp" "var6_flat_lay.png" "var6_flat_lay.png" "1672×941" "3173" "examples" "" \
        "thumb_var8_natural_light_outdoor.webp" "var8_natural_light_outdoor.png" "var8_natural_light_outdoor.png" "1672×941" "2481" "examples" "" \
        "thumb_var5_closeup_detail.webp" "var5_closeup_detail.png" "var5_closeup_detail.png" "1672×941" "1863" "examples" "" \
        "thumb_var4_dramatic_lighting.webp" "var4_dramatic_lighting.png" "var4_dramatic_lighting.png" "1672×941" "1573" "examples" "" \
        "thumb_var2_studio_white2.webp" "var2_studio_white2.png" "var2_studio_white2.png" "1672×941" "1285" "examples" "" \
        "thumb_var1_studio_white.webp" "var1_studio_white.png" "var1_studio_white.png" "1672×941" "1259" "examples" "" \
        "thumb_var8_natural_light_outdoor.webp" "var8_natural_light_outdoor.jpg" "var8_natural_light_outdoor.jpg" "1672×941" "800" "7634afec188f40caa502423fce3ef2ea" "" \
        "thumb_var4_dramatic_lighting.webp" "var4_dramatic_lighting.jpg" "var4_dramatic_lighting.jpg" "1672×941" "386" "7634afec188f40caa502423fce3ef2ea" ""

    # Glasobjekt-Referenz
    create_section \
        "cat-glasobjekt" \
        "Glasobjekt-Referenz" \
        "" \
        "Referenz" \
        "2" \
        "Materialstudie Glas" \
        "thumb_element_01_glass_bowl.webp" "element_01_glass_bowl.png" "element_01_glass_bowl.png" "1024×1024" "1485" "examples" "" \
        "thumb_element_01_glass_bowl.webp" "element_01_glass_bowl.jpg" "element_01_glass_bowl.jpg" "1024×1024" "126" "7634afec188f40caa502423fce3ef2ea" ""

    # Perlen/Beads
    create_section \
        "cat-perle" \
        "Perlen/Beads" \
        "" \
        "Referenz" \
        "4" \
        "Materialstudie klein/rund" \
        "thumb_element_02_beads_group.webp" "element_02_beads_group.png" "element_02_beads_group.png" "1024×1024" "1751" "examples" "" \
        "thumb_element_03_single_bead.webp" "element_03_single_bead.png" "element_03_single_bead.png" "1024×1024" "1473" "examples" "" \
        "thumb_element_02_beads_group.webp" "element_02_beads_group.jpg" "element_02_beads_group.jpg" "1024×1024" "284" "7634afec188f40caa502423fce3ef2ea" "" \
        "thumb_element_03_single_bead.webp" "element_03_single_bead.jpg" "element_03_single_bead.jpg" "1024×1024" "127" "7634afec188f40caa502423fce3ef2ea" ""

    # Pfingstrosen-Kompositionen
    create_section \
        "cat-peonie_ref" \
        "Pfingstrosen-Kompositionen" \
        "" \
        "Referenz" \
        "4" \
        "Referenz-Look; nicht direkt nutzbar" \
        "thumb_comp_02_peonies_warm.webp" "comp_02_peonies_warm.png" "comp_02_peonies_warm.png" "1024×1536" "2500" "examples" "" \
        "thumb_comp_01_peonies_dark.webp" "comp_01_peonies_dark.png" "comp_01_peonies_dark.png" "1024×1535" "2124" "examples" "" \
        "thumb_comp_02_peonies_warm.webp" "comp_02_peonies_warm.jpg" "comp_02_peonies_warm.jpg" "1024×1536" "761" "7634afec188f40caa502423fce3ef2ea" "" \
        "thumb_comp_01_peonies_dark.webp" "comp_01_peonies_dark.jpg" "comp_01_peonies_dark.jpg" "1024×1535" "642" "7634afec188f40caa502423fce3ef2ea" ""

    # Feder
    create_section \
        "cat-feder" \
        "Feder" \
        "" \
        "Referenz" \
        "1" \
        "Referenz Element" \
        "thumb_element_04_feather.webp" "element_04_feather.png" "element_04_feather.png" "1024×1536" "2384" "examples" ""

    # Unsplash Referenzen
    create_section \
        "cat-ref_unsplash" \
        "Unsplash Referenzen" \
        "" \
        "Referenz" \
        "3" \
        "Ästhetik-Referenz" \
        "thumb_katya-azimova-j945b6ttc7s-unsplash.webp" "katya-azimova-j945b6ttc7s-unsplash.jpg" "katya-azimova-j945b6ttc7s-unsplash.jpg" "4659×6989" "8535" "examples" "" \
        "thumb_anita-austvika-GnO2S8c7slQ-unsplash.webp" "anita-austvika-GnO2S8c7slQ-unsplash.jpg" "anita-austvika-GnO2S8c7slQ-unsplash.jpg" "4912×7360" "7049" "examples" "" \
        "thumb_salvus-CiH1lH1u4dc-unsplash.webp" "salvus-CiH1lH1u4dc-unsplash.jpg" "salvus-CiH1lH1u4dc-unsplash.jpg" "3840×2160" "530" "examples" ""

    # Sonstiges
    create_section \
        "cat-sonstiges" \
        "Sonstiges" \
        "" \
        "" \
        "1" \
        "" \
        "thumb_candidate-08-pixabay-1510707-original.webp" "candidate-08-pixabay-1510707-original.jpg" "candidate-08-pixabay-1510707-original.jpg" "5184×3456" "1253" "pending-approval" ""

    # Weltkugel-Frames
    create_section_no_thumb \
        "cat-globe_frame" \
        "Weltkugel-Frames" \
        "" \
        "Vorhanden (Frames)" \
        "9" \
        "Bereits verwendet in globe-hero" \
        "frame-02.png" "?" "?" "98" "media" "" \
        "frame-01.png" "?" "?" "92" "media" "" \
        "frame-04.png" "?" "?" "86" "media" "" \
        "frame-05.png" "?" "?" "73" "media" "" \
        "frame-03.png" "?" "?" "71" "media" "" \
        "frame-06.png" "?" "?" "37" "media" "" \
        "frame-09.png" "?" "?" "37" "media" "" \
        "frame-08.png" "?" "?" "29" "media" "" \
        "frame-07.png" "?" "?" "27" "media" ""

    # Screenshots
    create_section_no_thumb \
        "cat-screenshot" \
        "Screenshots" \
        "" \
        "Referenz" \
        "4" \
        "Referenz aus Anhang" \
        "image-3.jpg" "?" "?" "121" "7634afec188f40caa502423fce3ef2ea" "" \
        "image-4.jpg" "?" "?" "118" "7634afec188f40caa502423fce3ef2ea" "" \
        "image-2.jpg" "?" "?" "109" "7634afec188f40caa502423fce3ef2ea" "" \
        "image.jpg" "?" "?" "104" "7634afec188f40caa502423fce3ef2ea" ""

    cat >> "$output_file" <<'EOF'
</main></body></html>
EOF

    echo "HTML file generated: $output_file"
}

# Funktion zur Erstellung einer Sektion ohne Thumbnails
create_section_no_thumb() {
    local id="$1"
    local title="$2"
    local tag_type="$3"
    local tag_text="$4"
    local count="$5"
    local subtitle="$6"
    shift 6
    local cards=("$@")

    cat <<EOF
<section id="${id}"><h2>${title} <span class="tag ${tag_type}">${tag_text}</span> <span class="tag">${count} Bilder</span></h2><p class="sub">${subtitle}</p><div class="grid">
EOF

    local i
    for ((i=0; i<${#cards[@]}; i+=7)); do
        local name="${cards[i]}"
        local width="${cards[i+1]}"
        local height="${cards[i+2]}"
        local size="${cards[i+3]}"
        local code="${cards[i+4]}"
        local prompt="${cards[i+5]}"

        cat <<EOF
      <div class="card">
        <div class="imgwrap"><div style="color:#999">kein Thumbnail</div></div>
        <div class="meta">
          <div class="name">${name}</div>
          <div class="dims">${width}×${height} px · ${size} KB · <code>${code}</code></div>
EOF

        if [ -n "$prompt" ]; then
            # Kürzen des Prompts auf maximal 100 Zeichen plus Auslassungspunkte
            local short_prompt="${prompt:0:100}"
            if [ "${#prompt}" -gt 100 ]; then
                short_prompt="${short_prompt}..."
            fi
            echo "          <div class=\"prompt\">${short_prompt}</div>"
        fi

        echo "        </div>"
        echo "      </div>"
    done

    echo "</div></section>"
}

# Skript ausführen
main "$@"
