#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "a6bfe714914b93ba986e4f3964586b7663659830665fd6fd30231014f575e1c2", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "ruby"}
# kontaktbogen.html — portiert nach ruby
# Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

require 'erb'

# Datenstruktur für die Kontaktbogen-Inhalte
class KontaktbogenData
  attr_accessor :categories

  def initialize
    @categories = []
  end

  def add_category(id, title, tags, subtitle, images)
    @categories << {
      id: id,
      title: title,
      tags: tags,
      subtitle: subtitle,
      images: images
    }
  end
end

# Template für den HTML-Output
def generate_html(data)
  template = <<-HTML
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>Kontaktbogen — Project-Landingpage Assets</title>
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
    <% data.categories.each do |category| %>
    <section id="<%= category[:id] %>">
      <h2><%= category[:title] %>
        <% category[:tags].each do |tag| %>
          <span class="tag <%= tag[:class] %>"><%= tag[:text] %></span>
        <% end %>
      </h2>
      <p class="sub"><%= category[:subtitle] %></p>
      <div class="grid">
        <% category[:images].each do |image| %>
        <div class="card">
          <div class="imgwrap">
            <% if image[:thumbnail] %>
              <img src="<%= image[:thumbnail] %>" alt="<%= image[:alt] %>" loading="lazy">
            <% else %>
              <div style="color:#999"><%= image[:no_thumbnail_text] %></div>
            <% end %>
          </div>
          <div class="meta">
            <div class="name"><%= image[:name] %></div>
            <div class="dims"><%= image[:dimensions] %></div>
            <% if image[:prompt] %>
              <div class="prompt"><%= image[:prompt] %></div>
            <% end %>
          </div>
        </div>
        <% end %>
      </div>
    </section>
    <% end %>
  </main>
</body>
</html>
  HTML

  ERB.new(template).result(binding)
end

# Hauptprogramm
def main(output_file = nil)
  data = KontaktbogenData.new

  # Seerosen-Kategorie
  data.add_category(
    "cat-seerose",
    "Seerosen (Pixabay/Unsplash)",
    [{class: "a", text: "AUSWAHL nötig"}, {class: "", text: "5 Bilder"}],
    "Kandidaten für 3D-Textur / Alpha",
    [
      {
        thumbnail: "thumbs/thumb_water_lily_01_pixabay_1510707_original.webp",
        alt: "water_lily_01_pixabay_1510707_original.jpg",
        name: "water_lily_01_pixabay_1510707_original.jpg",
        dimensions: "5184×3456 px · 1253 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_candidate-10-pixabay-4602155-wide-real-pond-lily-pads.webp",
        alt: "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg",
        name: "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg",
        dimensions: "1280×960 px · 570 KB · <code>pending-approval</code>"
      },
      {
        thumbnail: "thumbs/thumb_candidate-11-pixabay-5904414-giant-water-lily-3d-depth.webp",
        alt: "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg",
        name: "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg",
        dimensions: "1280×951 px · 495 KB · <code>pending-approval</code>"
      },
      {
        thumbnail: "thumbs/thumb_candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.webp",
        alt: "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg",
        name: "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg",
        dimensions: "2400×1600 px · 425 KB · <code>pending-approval</code>"
      },
      {
        thumbnail: "thumbs/thumb_candidate-09-pixabay-6403860-red-water-lily-water-closeup.webp",
        alt: "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg",
        name: "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg",
        dimensions: "1280×853 px · 248 KB · <code>pending-approval</code>"
      }
    ]
  )

  # WaveSpeed 4K Hero-Kategorie
  data.add_category(
    "cat-wavespeed_hero",
    "WaveSpeed 4K Hero",
    [{class: "p", text: "PFLICHT-Kandidat"}, {class: "", text: "2 Bilder"}],
    "Bereits generierter Hero-Hintergrund",
    [
      {
        thumbnail: "thumbs/thumb_hero-meadow.webp",
        alt: "hero-meadow.png",
        name: "hero-meadow.png",
        dimensions: "5504×3072 px · 18908 KB · <code>media</code>",
        prompt: "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..."
      },
      {
        thumbnail: "thumbs/thumb_hero-meadow.webp",
        alt: "hero-meadow.webp",
        name: "hero-meadow.webp",
        dimensions: "5504×3072 px · 836 KB · <code>media</code>",
        prompt: "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g..."
      }
    ]
  )

  # WaveSpeed 4K Glaskugel-Kategorie
  data.add_category(
    "cat-wavespeed_orb",
    "WaveSpeed 4K Glaskugel",
    [{class: "p", text: "PFLICHT-Kandidat"}, {class: "", text: "2 Bilder"}],
    "Referenz-Glaskugel für 3D-Material",
    [
      {
        thumbnail: "thumbs/thumb_glass-orb.webp",
        alt: "glass-orb.png",
        name: "glass-orb.png",
        dimensions: "4096×4096 px · 18805 KB · <code>media</code>",
        prompt: "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..."
      },
      {
        thumbnail: "thumbs/thumb_glass-orb.webp",
        alt: "glass-orb.webp",
        name: "glass-orb.webp",
        dimensions: "4096×4096 px · 730 KB · <code>media</code>",
        prompt: "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h..."
      }
    ]
  )

  # WaveSpeed 4K Sektionen-Kategorie
  data.add_category(
    "cat-wavespeed_projects",
    "WaveSpeed 4K Sektionen",
    [{class: "", text: "Vorhanden"}, {class: "", text: "6 Bilder"}],
    "Section-Backgrounds (Claude/Perplexity)",
    [
      {
        thumbnail: "thumbs/thumb_perplexity-projects.webp",
        alt: "perplexity-projects.png",
        name: "perplexity-projects.png",
        dimensions: "4800×3584 px · 21947 KB · <code>media</code>",
        prompt: "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..."
      },
      {
        thumbnail: "thumbs/thumb_claude-projects.webp",
        alt: "claude-projects.png",
        name: "claude-projects.png",
        dimensions: "4800×3584 px · 20711 KB · <code>media</code>",
        prompt: "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..."
      },
      {
        thumbnail: "thumbs/thumb_og-projects.webp",
        alt: "og-projects.png",
        name: "og-projects.png",
        dimensions: "5504×3072 px · 18199 KB · <code>media</code>",
        prompt: "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..."
      },
      {
        thumbnail: "thumbs/thumb_perplexity-projects.webp",
        alt: "perplexity-projects.webp",
        name: "perplexity-projects.webp",
        dimensions: "4800×3584 px · 1805 KB · <code>media</code>",
        prompt: "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac..."
      },
      {
        thumbnail: "thumbs/thumb_claude-projects.webp",
        alt: "claude-projects.webp",
        name: "claude-projects.webp",
        dimensions: "4800×3584 px · 1114 KB · <code>media</code>",
        prompt: "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ..."
      },
      {
        thumbnail: "thumbs/thumb_og-projects.webp",
        alt: "og-projects.webp",
        name: "og-projects.webp",
        dimensions: "5504×3072 px · 819 KB · <code>media</code>",
        prompt: "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet..."
      }
    ]
  )

  # WaveSpeed 4K Zusatz-Kategorie
  data.add_category(
    "cat-wavespeed_section",
    "WaveSpeed 4K Zusatz",
    [{class: "", text: "Vorhanden"}, {class: "", text: "4 Bilder"}],
    "CTA / Feature-Spotlight",
    [
      {
        thumbnail: "thumbs/thumb_feature-spotlight.webp",
        alt: "feature-spotlight.png",
        name: "feature-spotlight.png",
        dimensions: "4800×3584 px · 18688 KB · <code>media</code>",
        prompt: "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..."
      },
      {
        thumbnail: "thumbs/thumb_cta-background.webp",
        alt: "cta-background.png",
        name: "cta-background.png",
        dimensions: "5504×3072 px · 15543 KB · <code>media</code>",
        prompt: "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..."
      },
      {
        thumbnail: "thumbs/thumb_feature-spotlight.webp",
        alt: "feature-spotlight.webp",
        name: "feature-spotlight.webp",
        dimensions: "4800×3584 px · 1315 KB · <code>media</code>",
        prompt: "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n..."
      },
      {
        thumbnail: "thumbs/thumb_cta-background.webp",
        alt: "cta-background.webp",
        name: "cta-background.webp",
        dimensions: "5504×3072 px · 730 KB · <code>media</code>",
        prompt: "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h..."
      }
    ]
  )

  # Studio-Varianten Glaskugel-Kategorie
  data.add_category(
    "cat-studio_variant",
    "Studio-Varianten Glaskugel",
    [{class: "", text: "Referenz"}, {class: "", text: "8 Bilder"}],
    "Beleuchtungsstudien für Glas",
    [
      {
        thumbnail: "thumbs/thumb_var6_flat_lay.webp",
        alt: "var6_flat_lay.png",
        name: "var6_flat_lay.png",
        dimensions: "1672×941 px · 3173 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_var8_natural_light_outdoor.webp",
        alt: "var8_natural_light_outdoor.png",
        name: "var8_natural_light_outdoor.png",
        dimensions: "1672×941 px · 2481 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_var5_closeup_detail.webp",
        alt: "var5_closeup_detail.png",
        name: "var5_closeup_detail.png",
        dimensions: "1672×941 px · 1863 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_var4_dramatic_lighting.webp",
        alt: "var4_dramatic_lighting.png",
        name: "var4_dramatic_lighting.png",
        dimensions: "1672×941 px · 1573 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_var2_studio_white2.webp",
        alt: "var2_studio_white2.png",
        name: "var2_studio_white2.png",
        dimensions: "1672×941 px · 1285 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_var1_studio_white.webp",
        alt: "var1_studio_white.png",
        name: "var1_studio_white.png",
        dimensions: "1672×941 px · 1259 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_var8_natural_light_outdoor.webp",
        alt: "var8_natural_light_outdoor.jpg",
        name: "var8_natural_light_outdoor.jpg",
        dimensions: "1672×941 px · 800 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      },
      {
        thumbnail: "thumbs/thumb_var4_dramatic_lighting.webp",
        alt: "var4_dramatic_lighting.jpg",
        name: "var4_dramatic_lighting.jpg",
        dimensions: "1672×941 px · 386 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      }
    ]
  )

  # Glasobjekt-Referenz-Kategorie
  data.add_category(
    "cat-glasobjekt",
    "Glasobjekt-Referenz",
    [{class: "", text: "Referenz"}, {class: "", text: "2 Bilder"}],
    "Materialstudie Glas",
    [
      {
        thumbnail: "thumbs/thumb_element_01_glass_bowl.webp",
        alt: "element_01_glass_bowl.png",
        name: "element_01_glass_bowl.png",
        dimensions: "1024×1024 px · 1485 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_element_01_glass_bowl.webp",
        alt: "element_01_glass_bowl.jpg",
        name: "element_01_glass_bowl.jpg",
        dimensions: "1024×1024 px · 126 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      }
    ]
  )

  # Perlen/Beads-Kategorie
  data.add_category(
    "cat-perle",
    "Perlen/Beads",
    [{class: "", text: "Referenz"}, {class: "", text: "4 Bilder"}],
    "Materialstudie klein/rund",
    [
      {
        thumbnail: "thumbs/thumb_element_02_beads_group.webp",
        alt: "element_02_beads_group.png",
        name: "element_02_beads_group.png",
        dimensions: "1024×1024 px · 1751 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_element_03_single_bead.webp",
        alt: "element_03_single_bead.png",
        name: "element_03_single_bead.png",
        dimensions: "1024×1024 px · 1473 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_element_02_beads_group.webp",
        alt: "element_02_beads_group.jpg",
        name: "element_02_beads_group.jpg",
        dimensions: "1024×1024 px · 284 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      },
      {
        thumbnail: "thumbs/thumb_element_03_single_bead.webp",
        alt: "element_03_single_bead.jpg",
        name: "element_03_single_bead.jpg",
        dimensions: "1024×1024 px · 127 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      }
    ]
  )

  # Pfingstrosen-Kompositionen-Kategorie
  data.add_category(
    "cat-peonie_ref",
    "Pfingstrosen-Kompositionen",
    [{class: "", text: "Referenz"}, {class: "", text: "4 Bilder"}],
    "Referenz-Look; nicht direkt nutzbar",
    [
      {
        thumbnail: "thumbs/thumb_comp_02_peonies_warm.webp",
        alt: "comp_02_peonies_warm.png",
        name: "comp_02_peonies_warm.png",
        dimensions: "1024×1536 px · 2500 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_comp_01_peonies_dark.webp",
        alt: "comp_01_peonies_dark.png",
        name: "comp_01_peonies_dark.png",
        dimensions: "1024×1535 px · 2124 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_comp_02_peonies_warm.webp",
        alt: "comp_02_peonies_warm.jpg",
        name: "comp_02_peonies_warm.jpg",
        dimensions: "1024×1536 px · 761 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      },
      {
        thumbnail: "thumbs/thumb_comp_01_peonies_dark.webp",
        alt: "comp_01_peonies_dark.jpg",
        name: "comp_01_peonies_dark.jpg",
        dimensions: "1024×1535 px · 642 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      }
    ]
  )

  # Feder-Kategorie
  data.add_category(
    "cat-feder",
    "Feder",
    [{class: "", text: "Referenz"}, {class: "", text: "1 Bilder"}],
    "Referenz Element",
    [
      {
        thumbnail: "thumbs/thumb_element_04_feather.webp",
        alt: "element_04_feather.png",
        name: "element_04_feather.png",
        dimensions: "1024×1536 px · 2384 KB · <code>examples</code>"
      }
    ]
  )

  # Unsplash Referenzen-Kategorie
  data.add_category(
    "cat-ref_unsplash",
    "Unsplash Referenzen",
    [{class: "", text: "Referenz"}, {class: "", text: "3 Bilder"}],
    "Ästhetik-Referenz",
    [
      {
        thumbnail: "thumbs/thumb_katya-azimova-j945b6ttc7s-unsplash.webp",
        alt: "katya-azimova-j945b6ttc7s-unsplash.jpg",
        name: "katya-azimova-j945b6ttc7s-unsplash.jpg",
        dimensions: "4659×6989 px · 8535 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_anita-austvika-GnO2S8c7slQ-unsplash.webp",
        alt: "anita-austvika-GnO2S8c7slQ-unsplash.jpg",
        name: "anita-austvika-GnO2S8c7slQ-unsplash.jpg",
        dimensions: "4912×7360 px · 7049 KB · <code>examples</code>"
      },
      {
        thumbnail: "thumbs/thumb_salvus-CiH1lH1u4dc-unsplash.webp",
        alt: "salvus-CiH1lH1u4dc-unsplash.jpg",
        name: "salvus-CiH1lH1u4dc-unsplash.jpg",
        dimensions: "3840×2160 px · 530 KB · <code>examples</code>"
      }
    ]
  )

  # Sonstiges-Kategorie
  data.add_category(
    "cat-sonstiges",
    "Sonstiges",
    [{class: "", text: ""}, {class: "", text: "1 Bilder"}],
    "",
    [
      {
        thumbnail: "thumbs/thumb_candidate-08-pixabay-1510707-original.webp",
        alt: "candidate-08-pixabay-1510707-original.jpg",
        name: "candidate-08-pixabay-1510707-original.jpg",
        dimensions: "5184×3456 px · 1253 KB · <code>pending-approval</code>"
      }
    ]
  )

  # Weltkugel-Frames-Kategorie
  data.add_category(
    "cat-globe_frame",
    "Weltkugel-Frames",
    [{class: "", text: "Vorhanden (Frames)"}, {class: "", text: "9 Bilder"}],
    "Bereits verwendet in globe-hero",
    [
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "frame-02.png",
        dimensions: "?×? px · 98 KB · <code>media</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "frame-01.png",
        dimensions: "?×? px · 92 KB · <code>media</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "frame-04.png",
        dimensions: "?×? px · 86 KB · <code>media</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "frame-05.png",
        dimensions: "?×? px · 73 KB · <code>media</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "frame-03.png",
        dimensions: "?×? px · 71 KB · <code>media</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "frame-06.png",
        dimensions: "?×? px · 37 KB · <code>media</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "frame-09.png",
        dimensions: "?×? px · 37 KB · <code>media</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "frame-08.png",
        dimensions: "?×? px · 29 KB · <code>media</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "frame-07.png",
        dimensions: "?×? px · 27 KB · <code>media</code>"
      }
    ]
  )

  # Screenshots-Kategorie
  data.add_category(
    "cat-screenshot",
    "Screenshots",
    [{class: "", text: "Referenz"}, {class: "", text: "4 Bilder"}],
    "Referenz aus Anhang",
    [
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "image-3.jpg",
        dimensions: "?×? px · 121 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "image-4.jpg",
        dimensions: "?×? px · 118 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "image-2.jpg",
        dimensions: "?×? px · 109 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      },
      {
        no_thumbnail_text: "kein Thumbnail",
        name: "image.jpg",
        dimensions: "?×? px · 104 KB · <code>7634afec188f40caa502423fce3ef2ea</code>"
      }
    ]
  )

  html_content = generate_html(data)

  if output_file
    File.write(output_file, html_content)
    puts "HTML file generated: #{output_file}"
  else
    puts html_content
  end
end

# Skriptausführung
if __FILE__ == $0
  output_file = ARGV[0]
  main(output_file)
end
