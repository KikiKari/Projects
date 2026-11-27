// abstraction-provenance: {"artifact_sha256": "f02b48fa8102d0cc7d1ca16e6e2d191cf2bfa688abb5687e4f53d11616a7bbd6", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "go"}
// kontaktbogen.html — portiert nach go
// Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"fmt"
	"html/template"
	"os"
)

type Tag struct {
	Class string
	Text  string
}

type Image struct {
	Src       string
	Alt       string
	Name      string
	Dimensions string
	Size      string
	Code      string
	Prompt    string
}

type Section struct {
	ID          string
	Title       string
	Tags        []Tag
	Description string
	Images      []Image
}

type PageData struct {
	Title       string
	Description string
	Sections    []Section
}

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Usage: go run main.go <output-file>")
		os.Exit(1)
	}

	filename := os.Args[1]
	
	data := PageData{
		Title: "Kontaktbogen — Project-Landingpage Bildbestand",
		Description: "Alle vorhandenen HighRes-Bilder aus deiner Design-Referenz, dem laufenden Codex-Repo und den Anhängen. Kategorisiert nach Verwendungszweck. Bitte markiere pro Kategorie welche Assets in die finale Umsetzung sollen und wo du Erweiterung wünschst.",
		Sections: []Section{
			{
				ID: "cat-seerose",
				Title: "Seerosen (Pixabay/Unsplash)",
				Tags: []Tag{
					{Class: "a", Text: "AUSWAHL nötig"},
					{Class: "", Text: "5 Bilder"},
				},
				Description: "Kandidaten für 3D-Textur / Alpha",
				Images: []Image{
					{
						Src: "thumbs/thumb_water_lily_01_pixabay_1510707_original.webp",
						Alt: "water_lily_01_pixabay_1510707_original.jpg",
						Name: "water_lily_01_pixabay_1510707_original.jpg",
						Dimensions: "5184×3456 px",
						Size: "1253 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_candidate-10-pixabay-4602155-wide-real-pond-lily-pads.webp",
						Alt: "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg",
						Name: "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg",
						Dimensions: "1280×960 px",
						Size: "570 KB",
						Code: "pending-approval",
					},
					{
						Src: "thumbs/thumb_candidate-11-pixabay-5904414-giant-water-lily-3d-depth.webp",
						Alt: "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg",
						Name: "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg",
						Dimensions: "1280×951 px",
						Size: "495 KB",
						Code: "pending-approval",
					},
					{
						Src: "thumbs/thumb_candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.webp",
						Alt: "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg",
						Name: "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg",
						Dimensions: "2400×1600 px",
						Size: "425 KB",
						Code: "pending-approval",
					},
					{
						Src: "thumbs/thumb_candidate-09-pixabay-6403860-red-water-lily-water-closeup.webp",
						Alt: "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg",
						Name: "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg",
						Dimensions: "1280×853 px",
						Size: "248 KB",
						Code: "pending-approval",
					},
				},
			},
			{
				ID: "cat-wavespeed_hero",
				Title: "WaveSpeed 4K Hero",
				Tags: []Tag{
					{Class: "p", Text: "PFLICHT-Kandidat"},
					{Class: "", Text: "2 Bilder"},
				},
				Description: "Bereits generierter Hero-Hintergrund",
				Images: []Image{
					{
						Src: "thumbs/thumb_hero-meadow.webp",
						Alt: "hero-meadow.png",
						Name: "hero-meadow.png",
						Dimensions: "5504×3072 px",
						Size: "18908 KB",
						Code: "media",
						Prompt: "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g...",
					},
					{
						Src: "thumbs/thumb_hero-meadow.webp",
						Alt: "hero-meadow.webp",
						Name: "hero-meadow.webp",
						Dimensions: "5504×3072 px",
						Size: "836 KB",
						Code: "media",
						Prompt: "Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g...",
					},
				},
			},
			{
				ID: "cat-wavespeed_orb",
				Title: "WaveSpeed 4K Glaskugel",
				Tags: []Tag{
					{Class: "p", Text: "PFLICHT-Kandidat"},
					{Class: "", Text: "2 Bilder"},
				},
				Description: "Referenz-Glaskugel für 3D-Material",
				Images: []Image{
					{
						Src: "thumbs/thumb_glass-orb.webp",
						Alt: "glass-orb.png",
						Name: "glass-orb.png",
						Dimensions: "4096×4096 px",
						Size: "18805 KB",
						Code: "media",
						Prompt: "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h...",
					},
					{
						Src: "thumbs/thumb_glass-orb.webp",
						Alt: "glass-orb.webp",
						Name: "glass-orb.webp",
						Dimensions: "4096×4096 px",
						Size: "730 KB",
						Code: "media",
						Prompt: "Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h...",
					},
				},
			},
			{
				ID: "cat-wavespeed_projects",
				Title: "WaveSpeed 4K Sektionen",
				Tags: []Tag{
					{Class: "", Text: "Vorhanden"},
					{Class: "", Text: "6 Bilder"},
				},
				Description: "Section-Backgrounds (Claude/Perplexity)",
				Images: []Image{
					{
						Src: "thumbs/thumb_perplexity-projects.webp",
						Alt: "perplexity-projects.png",
						Name: "perplexity-projects.png",
						Dimensions: "4800×3584 px",
						Size: "21947 KB",
						Code: "media",
						Prompt: "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac...",
					},
					{
						Src: "thumbs/thumb_claude-projects.webp",
						Alt: "claude-projects.png",
						Name: "claude-projects.png",
						Dimensions: "4800×3584 px",
						Size: "20711 KB",
						Code: "media",
						Prompt: "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ...",
					},
					{
						Src: "thumbs/thumb_og-projects.webp",
						Alt: "og-projects.png",
						Name: "og-projects.png",
						Dimensions: "5504×3072 px",
						Size: "18199 KB",
						Code: "media",
						Prompt: "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet...",
					},
					{
						Src: "thumbs/thumb_perplexity-projects.webp",
						Alt: "perplexity-projects.webp",
						Name: "perplexity-projects.webp",
						Dimensions: "4800×3584 px",
						Size: "1805 KB",
						Code: "media",
						Prompt: "Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac...",
					},
					{
						Src: "thumbs/thumb_claude-projects.webp",
						Alt: "claude-projects.webp",
						Name: "claude-projects.webp",
						Dimensions: "4800×3584 px",
						Size: "1114 KB",
						Code: "media",
						Prompt: "Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ...",
					},
					{
						Src: "thumbs/thumb_og-projects.webp",
						Alt: "og-projects.webp",
						Name: "og-projects.webp",
						Dimensions: "5504×3072 px",
						Size: "819 KB",
						Code: "media",
						Prompt: "Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet...",
					},
				},
			},
			{
				ID: "cat-wavespeed_section",
				Title: "WaveSpeed 4K Zusatz",
				Tags: []Tag{
					{Class: "", Text: "Vorhanden"},
					{Class: "", Text: "4 Bilder"},
				},
				Description: "CTA / Feature-Spotlight",
				Images: []Image{
					{
						Src: "thumbs/thumb_feature-spotlight.webp",
						Alt: "feature-spotlight.png",
						Name: "feature-spotlight.png",
						Dimensions: "4800×3584 px",
						Size: "18688 KB",
						Code: "media",
						Prompt: "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n...",
					},
					{
						Src: "thumbs/thumb_cta-background.webp",
						Alt: "cta-background.png",
						Name: "cta-background.png",
						Dimensions: "5504×3072 px",
						Size: "15543 KB",
						Code: "media",
						Prompt: "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h...",
					},
					{
						Src: "thumbs/thumb_feature-spotlight.webp",
						Alt: "feature-spotlight.webp",
						Name: "feature-spotlight.webp",
						Dimensions: "4800×3584 px",
						Size: "1315 KB",
						Code: "media",
						Prompt: "Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n...",
					},
					{
						Src: "thumbs/thumb_cta-background.webp",
						Alt: "cta-background.webp",
						Name: "cta-background.webp",
						Dimensions: "5504×3072 px",
						Size: "730 KB",
						Code: "media",
						Prompt: "Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h...",
					},
				},
			},
			{
				ID: "cat-studio_variant",
				Title: "Studio-Varianten Glaskugel",
				Tags: []Tag{
					{Class: "", Text: "Referenz"},
					{Class: "", Text: "8 Bilder"},
				},
				Description: "Beleuchtungsstudien für Glas",
				Images: []Image{
					{
						Src: "thumbs/thumb_var6_flat_lay.webp",
						Alt: "var6_flat_lay.png",
						Name: "var6_flat_lay.png",
						Dimensions: "1672×941 px",
						Size: "3173 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_var8_natural_light_outdoor.webp",
						Alt: "var8_natural_light_outdoor.png",
						Name: "var8_natural_light_outdoor.png",
						Dimensions: "1672×941 px",
						Size: "2481 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_var5_closeup_detail.webp",
						Alt: "var5_closeup_detail.png",
						Name: "var5_closeup_detail.png",
						Dimensions: "1672×941 px",
						Size: "1863 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_var4_dramatic_lighting.webp",
						Alt: "var4_dramatic_lighting.png",
						Name: "var4_dramatic_lighting.png",
						Dimensions: "1672×941 px",
						Size: "1573 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_var2_studio_white2.webp",
						Alt: "var2_studio_white2.png",
						Name: "var2_studio_white2.png",
						Dimensions: "1672×941 px",
						Size: "1285 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_var1_studio_white.webp",
						Alt: "var1_studio_white.png",
						Name: "var1_studio_white.png",
						Dimensions: "1672×941 px",
						Size: "1259 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_var8_natural_light_outdoor.webp",
						Alt: "var8_natural_light_outdoor.jpg",
						Name: "var8_natural_light_outdoor.jpg",
						Dimensions: "1672×941 px",
						Size: "800 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
					{
						Src: "thumbs/thumb_var4_dramatic_lighting.webp",
						Alt: "var4_dramatic_lighting.jpg",
						Name: "var4_dramatic_lighting.jpg",
						Dimensions: "1672×941 px",
						Size: "386 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
				},
			},
			{
				ID: "cat-glasobjekt",
				Title: "Glasobjekt-Referenz",
				Tags: []Tag{
					{Class: "", Text: "Referenz"},
					{Class: "", Text: "2 Bilder"},
				},
				Description: "Materialstudie Glas",
				Images: []Image{
					{
						Src: "thumbs/thumb_element_01_glass_bowl.webp",
						Alt: "element_01_glass_bowl.png",
						Name: "element_01_glass_bowl.png",
						Dimensions: "1024×1024 px",
						Size: "1485 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_element_01_glass_bowl.webp",
						Alt: "element_01_glass_bowl.jpg",
						Name: "element_01_glass_bowl.jpg",
						Dimensions: "1024×1024 px",
						Size: "126 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
				},
			},
			{
				ID: "cat-perle",
				Title: "Perlen/Beads",
				Tags: []Tag{
					{Class: "", Text: "Referenz"},
					{Class: "", Text: "4 Bilder"},
				},
				Description: "Materialstudie klein/rund",
				Images: []Image{
					{
						Src: "thumbs/thumb_element_02_beads_group.webp",
						Alt: "element_02_beads_group.png",
						Name: "element_02_beads_group.png",
						Dimensions: "1024×1024 px",
						Size: "1751 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_element_03_single_bead.webp",
						Alt: "element_03_single_bead.png",
						Name: "element_03_single_bead.png",
						Dimensions: "1024×1024 px",
						Size: "1473 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_element_02_beads_group.webp",
						Alt: "element_02_beads_group.jpg",
						Name: "element_02_beads_group.jpg",
						Dimensions: "1024×1024 px",
						Size: "284 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
					{
						Src: "thumbs/thumb_element_03_single_bead.webp",
						Alt: "element_03_single_bead.jpg",
						Name: "element_03_single_bead.jpg",
						Dimensions: "1024×1024 px",
						Size: "127 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
				},
			},
			{
				ID: "cat-peonie_ref",
				Title: "Pfingstrosen-Kompositionen",
				Tags: []Tag{
					{Class: "", Text: "Referenz"},
					{Class: "", Text: "4 Bilder"},
				},
				Description: "Referenz-Look; nicht direkt nutzbar",
				Images: []Image{
					{
						Src: "thumbs/thumb_comp_02_peonies_warm.webp",
						Alt: "comp_02_peonies_warm.png",
						Name: "comp_02_peonies_warm.png",
						Dimensions: "1024×1536 px",
						Size: "2500 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_comp_01_peonies_dark.webp",
						Alt: "comp_01_peonies_dark.png",
						Name: "comp_01_peonies_dark.png",
						Dimensions: "1024×1535 px",
						Size: "2124 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_comp_02_peonies_warm.webp",
						Alt: "comp_02_peonies_warm.jpg",
						Name: "comp_02_peonies_warm.jpg",
						Dimensions: "1024×1536 px",
						Size: "761 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
					{
						Src: "thumbs/thumb_comp_01_peonies_dark.webp",
						Alt: "comp_01_peonies_dark.jpg",
						Name: "comp_01_peonies_dark.jpg",
						Dimensions: "1024×1535 px",
						Size: "642 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
				},
			},
			{
				ID: "cat-feder",
				Title: "Feder",
				Tags: []Tag{
					{Class: "", Text: "Referenz"},
					{Class: "", Text: "1 Bilder"},
				},
				Description: "Referenz Element",
				Images: []Image{
					{
						Src: "thumbs/thumb_element_04_feather.webp",
						Alt: "element_04_feather.png",
						Name: "element_04_feather.png",
						Dimensions: "1024×1536 px",
						Size: "2384 KB",
						Code: "examples",
					},
				},
			},
			{
				ID: "cat-ref_unsplash",
				Title: "Unsplash Referenzen",
				Tags: []Tag{
					{Class: "", Text: "Referenz"},
					{Class: "", Text: "3 Bilder"},
				},
				Description: "Ästhetik-Referenz",
				Images: []Image{
					{
						Src: "thumbs/thumb_katya-azimova-j945b6ttc7s-unsplash.webp",
						Alt: "katya-azimova-j945b6ttc7s-unsplash.jpg",
						Name: "katya-azimova-j945b6ttc7s-unsplash.jpg",
						Dimensions: "4659×6989 px",
						Size: "8535 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_anita-austvika-GnO2S8c7slQ-unsplash.webp",
						Alt: "anita-austvika-GnO2S8c7slQ-unsplash.jpg",
						Name: "anita-austvika-GnO2S8c7slQ-unsplash.jpg",
						Dimensions: "4912×7360 px",
						Size: "7049 KB",
						Code: "examples",
					},
					{
						Src: "thumbs/thumb_salvus-CiH1lH1u4dc-unsplash.webp",
						Alt: "salvus-CiH1lH1u4dc-unsplash.jpg",
						Name: "salvus-CiH1lH1u4dc-unsplash.jpg",
						Dimensions: "3840×2160 px",
						Size: "530 KB",
						Code: "examples",
					},
				},
			},
			{
				ID: "cat-sonstiges",
				Title: "Sonstiges",
				Tags: []Tag{
					{Class: "", Text: ""},
					{Class: "", Text: "1 Bilder"},
				},
				Description: "",
				Images: []Image{
					{
						Src: "thumbs/thumb_candidate-08-pixabay-1510707-original.webp",
						Alt: "candidate-08-pixabay-1510707-original.jpg",
						Name: "candidate-08-pixabay-1510707-original.jpg",
						Dimensions: "5184×3456 px",
						Size: "1253 KB",
						Code: "pending-approval",
					},
				},
			},
			{
				ID: "cat-globe_frame",
				Title: "Weltkugel-Frames",
				Tags: []Tag{
					{Class: "", Text: "Vorhanden (Frames)"},
					{Class: "", Text: "9 Bilder"},
				},
				Description: "Bereits verwendet in globe-hero",
				Images: []Image{
					{
						Src: "",
						Alt: "",
						Name: "frame-02.png",
						Dimensions: "?×? px",
						Size: "98 KB",
						Code: "media",
					},
					{
						Src: "",
						Alt: "",
						Name: "frame-01.png",
						Dimensions: "?×? px",
						Size: "92 KB",
						Code: "media",
					},
					{
						Src: "",
						Alt: "",
						Name: "frame-04.png",
						Dimensions: "?×? px",
						Size: "86 KB",
						Code: "media",
					},
					{
						Src: "",
						Alt: "",
						Name: "frame-05.png",
						Dimensions: "?×? px",
						Size: "73 KB",
						Code: "media",
					},
					{
						Src: "",
						Alt: "",
						Name: "frame-03.png",
						Dimensions: "?×? px",
						Size: "71 KB",
						Code: "media",
					},
					{
						Src: "",
						Alt: "",
						Name: "frame-06.png",
						Dimensions: "?×? px",
						Size: "37 KB",
						Code: "media",
					},
					{
						Src: "",
						Alt: "",
						Name: "frame-09.png",
						Dimensions: "?×? px",
						Size: "37 KB",
						Code: "media",
					},
					{
						Src: "",
						Alt: "",
						Name: "frame-08.png",
						Dimensions: "?×? px",
						Size: "29 KB",
						Code: "media",
					},
					{
						Src: "",
						Alt: "",
						Name: "frame-07.png",
						Dimensions: "?×? px",
						Size: "27 KB",
						Code: "media",
					},
				},
			},
			{
				ID: "cat-screenshot",
				Title: "Screenshots",
				Tags: []Tag{
					{Class: "", Text: "Referenz"},
					{Class: "", Text: "4 Bilder"},
				},
				Description: "Referenz aus Anhang",
				Images: []Image{
					{
						Src: "",
						Alt: "",
						Name: "image-3.jpg",
						Dimensions: "?×? px",
						Size: "121 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
					{
						Src: "",
						Alt: "",
						Name: "image-4.jpg",
						Dimensions: "?×? px",
						Size: "118 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
					{
						Src: "",
						Alt: "",
						Name: "image-2.jpg",
						Dimensions: "?×? px",
						Size: "109 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
					{
						Src: "",
						Alt: "",
						Name: "image.jpg",
						Dimensions: "?×? px",
						Size: "104 KB",
						Code: "7634afec188f40caa502423fce3ef2ea",
					},
				},
			},
		},
	}

	tmpl := `<!DOCTYPE html>
<html lang="de"><head><meta charset="utf-8"><title>{{.Title}}</title>
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
  <h1>{{.Title}}</h1>
  <p>{{.Description}}</p>
  <div class="legend">
    <span class="pill pflicht">PFLICHT — muss ins finale Design</span>
    <span class="pill auswahl">AUSWAHL nötig — mehrere Kandidaten</span>
    <span class="pill">Referenz — nur Ästhetik, nicht direkt verwendet</span>
    <span class="pill">Vorhanden — schon im Repo eingebaut</span>
  </div>
</header>
<main>
{{range .Sections}}
<section id="{{.ID}}"><h2>{{.Title}} {{range .Tags}}<span class="tag{{if .Class}} {{.Class}}{{end}}">{{.Text}}</span> {{end}}</h2><p class="sub">{{.Description}}</p><div class="grid">
      {{range .Images}}
      <div class="card">
        <div class="imgwrap">{{if .Src}}<img src="{{.Src}}" alt="{{.Alt}}" loading="lazy">{{else}}<div style="color:#999">kein Thumbnail</div>{{end}}</div>
        <div class="meta">
          <div class="name">{{.Name}}</div>
          <div class="dims">{{.Dimensions}} · {{.Size}} · <code>{{.Code}}</code></div>
          {{if .Prompt}}<div class="prompt">{{.Prompt}}</div>{{end}}
        </div>
      </div>
      {{end}}
</div></section>
{{end}}
</main></body></html>`

	t, err := template.New("kontaktbogen").Parse(tmpl)
	if err != nil {
		panic(err)
	}

	file, err := os.Create(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	err = t.Execute(file, data)
	if err != nil {
		panic(err)
	}
}
