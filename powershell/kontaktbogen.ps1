#!/usr/bin/env pwsh
# kontaktbogen.html — portiert nach powershell
# Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Generates an HTML contact sheet for project landing page assets.

.DESCRIPTION
This script generates an HTML document that displays a categorized gallery of images
with metadata, mimicking the structure and styling of the original kontaktbogen.html.
The output is written to a specified file.

.PARAMETER OutputPath
The path to the output HTML file.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Define CSS styles as a string
$css = @"
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
"@

# Define the HTML structure with PowerShell here-strings for readability
$html = @"
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>Kontaktbogen — Project-Landingpage Assets</title>
  <style>
$css
  </style>
</head>
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
"@

# Function to generate a section
function New-Section {
    param (
        [string]$Id,
        [string]$Title,
        [string]$Subtitle,
        [array]$Cards
    )

    $sectionHtml = "    <section id=`"$Id`">`n"
    $sectionHtml += "      <h2>$Title</h2>`n"
    if ($Subtitle) {
        $sectionHtml += "      <p class=`"sub`">$Subtitle</p>`n"
    }
    $sectionHtml += "      <div class=`"grid`">`n"

    foreach ($card in $Cards) {
        $sectionHtml += "        <div class=`"card`">`n"
        $sectionHtml += "          <div class=`"imgwrap`">`n"
        if ($card.Thumbnail) {
            $sectionHtml += "            <img src=`"$($card.Thumbnail)`" alt=`"$($card.Alt)`" loading=`"lazy`">`n"
        } else {
            $sectionHtml += "            <div style=`"color:#999`">kein Thumbnail</div>`n"
        }
        $sectionHtml += "          </div>`n"
        $sectionHtml += "          <div class=`"meta`">`n"
        $sectionHtml += "            <div class=`"name`">$($card.Name)</div>`n"
        $sectionHtml += "            <div class=`"dims`">$($card.Dimensions)</div>`n"
        if ($card.Prompt) {
            # Truncate prompt if too long, similar to original HTML
            $truncatedPrompt = if ($card.Prompt.Length -gt 100) { $card.Prompt.Substring(0, 100) + "..." } else { $card.Prompt }
            $sectionHtml += "            <div class=`"prompt`">$truncatedPrompt</div>`n"
        }
        $sectionHtml += "          </div>`n"
        $sectionHtml += "        </div>`n"
    }

    $sectionHtml += "      </div>`n"
    $sectionHtml += "    </section>`n"
    return $sectionHtml
}

# Define all sections and their cards as PowerShell objects
$sections = @(
    @{
        Id = "cat-seerose"
        Title = "Seerosen (Pixabay/Unsplash) <span class=`"tag a`">AUSWAHL nötig</span> <span class=`"tag`">5 Bilder</span>"
        Subtitle = "Kandidaten für 3D-Textur / Alpha"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_water_lily_01_pixabay_1510707_original.webp"; Alt = "water_lily_01_pixabay_1510707_original.jpg"; Name = "water_lily_01_pixabay_1510707_original.jpg"; Dimensions = "5184×3456 px · 1253 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_candidate-10-pixabay-4602155-wide-real-pond-lily-pads.webp"; Alt = "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg"; Name = "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg"; Dimensions = "1280×960 px · 570 KB · <code>pending-approval</code>" }
            @{ Thumbnail = "thumbs/thumb_candidate-11-pixabay-5904414-giant-water-lily-3d-depth.webp"; Alt = "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg"; Name = "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg"; Dimensions = "1280×951 px · 495 KB · <code>pending-approval</code>" }
            @{ Thumbnail = "thumbs/thumb_candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.webp"; Alt = "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg"; Name = "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg"; Dimensions = "2400×1600 px · 425 KB · <code>pending-approval</code>" }
            @{ Thumbnail = "thumbs/thumb_candidate-09-pixabay-6403860-red-water-lily-water-closeup.webp"; Alt = "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg"; Name = "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg"; Dimensions = "1280×853 px · 248 KB · <code>pending-approval</code>" }
        )
    },
    @{
        Id = "cat-wavespeed_hero"
        Title = "WaveSpeed 4K Hero <span class=`"tag p`">PFLICHT-Kandidat</span> <span class=`"tag`">2 Bilder</span>"
        Subtitle = "Bereits generierter Hero-Hintergrund"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_hero-meadow.webp"; Alt = "hero-meadow.png"; Name = "hero-meadow.png"; Dimensions = "5504×3072 px · 18908 KB · <code>media</code>"; Prompt = "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..." }
            @{ Thumbnail = "thumbs/thumb_hero-meadow.webp"; Alt = "hero-meadow.webp"; Name = "hero-meadow.webp"; Dimensions = "5504×3072 px · 836 KB · <code>media</code>"; Prompt = "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..." }
        )
    },
    @{
        Id = "cat-wavespeed_orb"
        Title = "WaveSpeed 4K Glaskugel <span class=`"tag p`">PFLICHT-Kandidat</span> <span class=`"tag`">2 Bilder</span>"
        Subtitle = "Referenz-Glaskugel für 3D-Material"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_glass-orb.webp"; Alt = "glass-orb.png"; Name = "glass-orb.png"; Dimensions = "4096×4096 px · 18805 KB · <code>media</code>"; Prompt = "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..." }
            @{ Thumbnail = "thumbs/thumb_glass-orb.webp"; Alt = "glass-orb.webp"; Name = "glass-orb.webp"; Dimensions = "4096×4096 px · 730 KB · <code>media</code>"; Prompt = "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..." }
        )
    },
    @{
        Id = "cat-wavespeed_projects"
        Title = "WaveSpeed 4K Sektionen <span class=`"tag`">Vorhanden</span> <span class=`"tag`">6 Bilder</span>"
        Subtitle = "Section-Backgrounds (Claude/Perplexity)"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_perplexity-projects.webp"; Alt = "perplexity-projects.png"; Name = "perplexity-projects.png"; Dimensions = "4800×3584 px · 21947 KB · <code>media</code>"; Prompt = "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..." }
            @{ Thumbnail = "thumbs/thumb_claude-projects.webp"; Alt = "claude-projects.png"; Name = "claude-projects.png"; Dimensions = "4800×3584 px · 20711 KB · <code>media</code>"; Prompt = "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..." }
            @{ Thumbnail = "thumbs/thumb_og-projects.webp"; Alt = "og-projects.png"; Name = "og-projects.png"; Dimensions = "5504×3072 px · 18199 KB · <code>media</code>"; Prompt = "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..." }
            @{ Thumbnail = "thumbs/thumb_perplexity-projects.webp"; Alt = "perplexity-projects.webp"; Name = "perplexity-projects.webp"; Dimensions = "4800×3584 px · 1805 KB · <code>media</code>"; Prompt = "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..." }
            @{ Thumbnail = "thumbs/thumb_claude-projects.webp"; Alt = "claude-projects.webp"; Name = "claude-projects.webp"; Dimensions = "4800×3584 px · 1114 KB · <code>media</code>"; Prompt = "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..." }
            @{ Thumbnail = "thumbs/thumb_og-projects.webp"; Alt = "og-projects.webp"; Name = "og-projects.webp"; Dimensions = "5504×3072 px · 819 KB · <code>media</code>"; Prompt = "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..." }
        )
    },
    @{
        Id = "cat-wavespeed_section"
        Title = "WaveSpeed 4K Zusatz <span class=`"tag`">Vorhanden</span> <span class=`"tag`">4 Bilder</span>"
        Subtitle = "CTA / Feature-Spotlight"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_feature-spotlight.webp"; Alt = "feature-spotlight.png"; Name = "feature-spotlight.png"; Dimensions = "4800×3584 px · 18688 KB · <code>media</code>"; Prompt = "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..." }
            @{ Thumbnail = "thumbs/thumb_cta-background.webp"; Alt = "cta-background.png"; Name = "cta-background.png"; Dimensions = "5504×3072 px · 15543 KB · <code>media</code>"; Prompt = "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..." }
            @{ Thumbnail = "thumbs/thumb_feature-spotlight.webp"; Alt = "feature-spotlight.webp"; Name = "feature-spotlight.webp"; Dimensions = "4800×3584 px · 1315 KB · <code>media</code>"; Prompt = "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..." }
            @{ Thumbnail = "thumbs/thumb_cta-background.webp"; Alt = "cta-background.webp"; Name = "cta-background.webp"; Dimensions = "5504×3072 px · 730 KB · <code>media</code>"; Prompt = "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..." }
        )
    },
    @{
        Id = "cat-studio_variant"
        Title = "Studio-Varianten Glaskugel <span class=`"tag`">Referenz</span> <span class=`"tag`">8 Bilder</span>"
        Subtitle = "Beleuchtungsstudien für Glas"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_var6_flat_lay.webp"; Alt = "var6_flat_lay.png"; Name = "var6_flat_lay.png"; Dimensions = "1672×941 px · 3173 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_var8_natural_light_outdoor.webp"; Alt = "var8_natural_light_outdoor.png"; Name = "var8_natural_light_outdoor.png"; Dimensions = "1672×941 px · 2481 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_var5_closeup_detail.webp"; Alt = "var5_closeup_detail.png"; Name = "var5_closeup_detail.png"; Dimensions = "1672×941 px · 1863 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_var4_dramatic_lighting.webp"; Alt = "var4_dramatic_lighting.png"; Name = "var4_dramatic_lighting.png"; Dimensions = "1672×941 px · 1573 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_var2_studio_white2.webp"; Alt = "var2_studio_white2.png"; Name = "var2_studio_white2.png"; Dimensions = "1672×941 px · 1285 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_var1_studio_white.webp"; Alt = "var1_studio_white.png"; Name = "var1_studio_white.png"; Dimensions = "1672×941 px · 1259 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_var8_natural_light_outdoor.webp"; Alt = "var8_natural_light_outdoor.jpg"; Name = "var8_natural_light_outdoor.jpg"; Dimensions = "1672×941 px · 800 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
            @{ Thumbnail = "thumbs/thumb_var4_dramatic_lighting.webp"; Alt = "var4_dramatic_lighting.jpg"; Name = "var4_dramatic_lighting.jpg"; Dimensions = "1672×941 px · 386 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
        )
    },
    @{
        Id = "cat-glasobjekt"
        Title = "Glasobjekt-Referenz <span class=`"tag`">Referenz</span> <span class=`"tag`">2 Bilder</span>"
        Subtitle = "Materialstudie Glas"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_element_01_glass_bowl.webp"; Alt = "element_01_glass_bowl.png"; Name = "element_01_glass_bowl.png"; Dimensions = "1024×1024 px · 1485 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_element_01_glass_bowl.webp"; Alt = "element_01_glass_bowl.jpg"; Name = "element_01_glass_bowl.jpg"; Dimensions = "1024×1024 px · 126 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
        )
    },
    @{
        Id = "cat-perle"
        Title = "Perlen/Beads <span class=`"tag`">Referenz</span> <span class=`"tag`">4 Bilder</span>"
        Subtitle = "Materialstudie klein/rund"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_element_02_beads_group.webp"; Alt = "element_02_beads_group.png"; Name = "element_02_beads_group.png"; Dimensions = "1024×1024 px · 1751 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_element_03_single_bead.webp"; Alt = "element_03_single_bead.png"; Name = "element_03_single_bead.png"; Dimensions = "1024×1024 px · 1473 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_element_02_beads_group.webp"; Alt = "element_02_beads_group.jpg"; Name = "element_02_beads_group.jpg"; Dimensions = "1024×1024 px · 284 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
            @{ Thumbnail = "thumbs/thumb_element_03_single_bead.webp"; Alt = "element_03_single_bead.jpg"; Name = "element_03_single_bead.jpg"; Dimensions = "1024×1024 px · 127 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
        )
    },
    @{
        Id = "cat-peonie_ref"
        Title = "Pfingstrosen-Kompositionen <span class=`"tag`">Referenz</span> <span class=`"tag`">4 Bilder</span>"
        Subtitle = "Referenz-Look; nicht direkt nutzbar"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_comp_02_peonies_warm.webp"; Alt = "comp_02_peonies_warm.png"; Name = "comp_02_peonies_warm.png"; Dimensions = "1024×1536 px · 2500 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_comp_01_peonies_dark.webp"; Alt = "comp_01_peonies_dark.png"; Name = "comp_01_peonies_dark.png"; Dimensions = "1024×1535 px · 2124 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_comp_02_peonies_warm.webp"; Alt = "comp_02_peonies_warm.jpg"; Name = "comp_02_peonies_warm.jpg"; Dimensions = "1024×1536 px · 761 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
            @{ Thumbnail = "thumbs/thumb_comp_01_peonies_dark.webp"; Alt = "comp_01_peonies_dark.jpg"; Name = "comp_01_peonies_dark.jpg"; Dimensions = "1024×1535 px · 642 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
        )
    },
    @{
        Id = "cat-feder"
        Title = "Feder <span class=`"tag`">Referenz</span> <span class=`"tag`">1 Bilder</span>"
        Subtitle = "Referenz Element"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_element_04_feather.webp"; Alt = "element_04_feather.png"; Name = "element_04_feather.png"; Dimensions = "1024×1536 px · 2384 KB · <code>examples</code>" }
        )
    },
    @{
        Id = "cat-ref_unsplash"
        Title = "Unsplash Referenzen <span class=`"tag`">Referenz</span> <span class=`"tag`">3 Bilder</span>"
        Subtitle = "Ästhetik-Referenz"
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_katya-azimova-j945b6ttc7s-unsplash.webp"; Alt = "katya-azimova-j945b6ttc7s-unsplash.jpg"; Name = "katya-azimova-j945b6ttc7s-unsplash.jpg"; Dimensions = "4659×6989 px · 8535 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_anita-austvika-GnO2S8c7slQ-unsplash.webp"; Alt = "anita-austvika-GnO2S8c7slQ-unsplash.jpg"; Name = "anita-austvika-GnO2S8c7slQ-unsplash.jpg"; Dimensions = "4912×7360 px · 7049 KB · <code>examples</code>" }
            @{ Thumbnail = "thumbs/thumb_salvus-CiH1lH1u4dc-unsplash.webp"; Alt = "salvus-CiH1lH1u4dc-unsplash.jpg"; Name = "salvus-CiH1lH1u4dc-unsplash.jpg"; Dimensions = "3840×2160 px · 530 KB · <code>examples</code>" }
        )
    },
    @{
        Id = "cat-sonstiges"
        Title = "Sonstiges <span class=`"tag`"></span> <span class=`"tag`">1 Bilder</span>"
        Subtitle = ""
        Cards = @(
            @{ Thumbnail = "thumbs/thumb_candidate-08-pixabay-1510707-original.webp"; Alt = "candidate-08-pixabay-1510707-original.jpg"; Name = "candidate-08-pixabay-1510707-original.jpg"; Dimensions = "5184×3456 px · 1253 KB · <code>pending-approval</code>" }
        )
    },
    @{
        Id = "cat-globe_frame"
        Title = "Weltkugel-Frames <span class=`"tag`">Vorhanden (Frames)</span> <span class=`"tag`">9 Bilder</span>"
        Subtitle = "Bereits verwendet in globe-hero"
        Cards = @(
            @{ Name = "frame-02.png"; Dimensions = "?×? px · 98 KB · <code>media</code>" }
            @{ Name = "frame-01.png"; Dimensions = "?×? px · 92 KB · <code>media</code>" }
            @{ Name = "frame-04.png"; Dimensions = "?×? px · 86 KB · <code>media</code>" }
            @{ Name = "frame-05.png"; Dimensions = "?×? px · 73 KB · <code>media</code>" }
            @{ Name = "frame-03.png"; Dimensions = "?×? px · 71 KB · <code>media</code>" }
            @{ Name = "frame-06.png"; Dimensions = "?×? px · 37 KB · <code>media</code>" }
            @{ Name = "frame-09.png"; Dimensions = "?×? px · 37 KB · <code>media</code>" }
            @{ Name = "frame-08.png"; Dimensions = "?×? px · 29 KB · <code>media</code>" }
            @{ Name = "frame-07.png"; Dimensions = "?×? px · 27 KB · <code>media</code>" }
        )
    },
    @{
        Id = "cat-screenshot"
        Title = "Screenshots <span class=`"tag`">Referenz</span> <span class=`"tag`">4 Bilder</span>"
        Subtitle = "Referenz aus Anhang"
        Cards = @(
            @{ Name = "image-3.jpg"; Dimensions = "?×? px · 121 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
            @{ Name = "image-4.jpg"; Dimensions = "?×? px · 118 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
            @{ Name = "image-2.jpg"; Dimensions = "?×? px · 109 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
            @{ Name = "image.jpg"; Dimensions = "?×? px · 104 KB · <code>7634afec188f40caa502423fce3ef2ea</code>" }
        )
    }
)

# Generate HTML for each section
foreach ($section in $sections) {
    $cardsHtml = ""
    foreach ($card in $section.Cards) {
        $cardsHtml += "        <div class=`"card`">`n"
        $cardsHtml += "          <div class=`"imgwrap`">`n"
        if ($card.Thumbnail) {
            $cardsHtml += "            <img src=`"$($card.Thumbnail)`" alt=`"$($card.Alt)`" loading=`"lazy`">`n"
        } else {
            $cardsHtml += "            <div style=`"color:#999`">kein Thumbnail</div>`n"
        }
        $cardsHtml += "          </div>`n"
        $cardsHtml += "          <div class=`"meta`">`n"
        $cardsHtml += "            <div class=`"name`">$($card.Name)</div>`n"
        $cardsHtml += "            <div class=`"dims`">$($card.Dimensions)</div>`n"
        if ($card.Prompt) {
            # Truncate prompt if too long, similar to original HTML
            $truncatedPrompt = if ($card.Prompt.Length -gt 100) { $card.Prompt.Substring(0, 100) + "..." } else { $card.Prompt }
            $cardsHtml += "            <div class=`"prompt`">$truncatedPrompt</div>`n"
        }
        $cardsHtml += "          </div>`n"
        $cardsHtml += "        </div>`n"
    }

    $html += "    <section id=`"$($section.Id)`">`n"
    $html += "      <h2>$($section.Title)</h2>`n"
    if ($section.Subtitle) {
        $html += "      <p class=`"sub`">$($section.Subtitle)</p>`n"
    }
    $html += "      <div class=`"grid`">`n"
    $html += $cardsHtml
    $html += "      </div>`n"
    $html += "    </section>`n"
}

# Close the main and body tags
$html += @"
  </main>
</body>
</html>
"@

# Write the HTML to the specified output file
$html | Out-File -FilePath $OutputPath -Encoding utf8

Write-Output "HTML contact sheet generated successfully at $OutputPath"
