// abstraction-provenance: {"artifact_sha256": "924848eaa4e305c7d7236669913fd15fad70532628f7f682342493168ae0a336", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "fsharp"}
// kontaktbogen.html — portiert nach fsharp
// Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Xml.Linq

type TagType = 
    | Pflicht
    | Auswahl
    | Referenz
    | Vorhanden
    | None

type ImageAsset = {
    Src: string
    Alt: string
    Name: string
    Dimensions: string
    Size: string
    Path: string
    Prompt: string option
}

type Category = {
    Id: string
    Title: string
    Subtitle: string
    Tag: TagType
    Count: int
    Images: ImageAsset list
}

let createDocument() =
    let html = XElement(XName.Get "html", XAttribute(XName.Get "lang", "de"))
    let head = XElement(XName.Get "head")
    let meta = XElement(XName.Get "meta", XAttribute(XName.Get "charset", "utf-8"))
    let title = XElement(XName.Get "title", "Kontaktbogen — Project-Landingpage Assets")
    
    head.Add(meta)
    head.Add(title)
    
    // Add styles
    let style = XElement(XName.Get "style", """
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
""")
    
    head.Add(style)
    html.Add(head)
    html

let addHeader(doc: XElement) =
    let body = XElement(XName.Get "body")
    
    let header = XElement(XName.Get "header")
    
    let h1 = XElement(XName.Get "h1", "Kontaktbogen — Project-Landingpage Bildbestand")
    header.Add(h1)
    
    let p = XElement(XName.Get "p", "Alle vorhandenen HighRes-Bilder aus deiner Design-Referenz, dem laufenden Codex-Repo und den Anhängen. Kategorisiert nach Verwendungszweck. Bitte markiere pro Kategorie welche Assets in die finale Umsetzung sollen und wo du Erweiterung wünschst.")
    header.Add(p)
    
    let legend = XElement(XName.Get "div", XAttribute(XName.Get "class", "legend"))
    
    let pill1 = XElement(XName.Get "span", XAttribute(XName.Get "class", "pill pflicht"), "PFLICHT — muss ins finale Design")
    legend.Add(pill1)
    
    let pill2 = XElement(XName.Get "span", XAttribute(XName.Get "class", "pill auswahl"), "AUSWAHL nötig — mehrere Kandidaten")
    legend.Add(pill2)
    
    let pill3 = XElement(XName.Get "span", XAttribute(XName.Get "class", "pill"), "Referenz — nur Ästhetik, nicht direkt verwendet")
    legend.Add(pill3)
    
    let pill4 = XElement(XName.Get "span", XAttribute(XName.Get "class", "pill"), "Vorhanden — schon im Repo eingebaut")
    legend.Add(pill4)
    
    header.Add(legend)
    body.Add(header)
    doc.Add(body)
    body

let tagToString tag =
    match tag with
    | Pflicht -> "PFLICHT"
    | Auswahl -> "AUSWAHL nötig"
    | Referenz -> "Referenz"
    | Vorhanden -> "Vorhanden"
    | None -> ""

let tagToClass tag =
    match tag with
    | Pflicht -> "p"
    | Auswahl -> "a"
    | _ -> ""

let createTagElement tag count =
    let tags = XElement(XName.Get "span", XAttribute(XName.Get "class", "tag"), sprintf "%d Bilder" count)
    if tag <> None then
        let tagElement = XElement(XName.Get "span", XAttribute(XName.Get "class", sprintf "tag %s" (tagToClass tag)), tagToString tag)
        [tagElement; tags]
    else
        [tags]

let createImageCard (image: ImageAsset) =
    let card = XElement(XName.Get "div", XAttribute(XName.Get "class", "card"))
    
    let imgWrap = XElement(XName.Get "div", XAttribute(XName.Get "class", "imgwrap"))
    if image.Src = "" then
        imgWrap.Add(XElement(XName.Get "div", XAttribute(XName.Get "style", "color:#999"), "kein Thumbnail"))
    else
        let img = XElement(XName.Get "img", 
                           XAttribute(XName.Get "src", image.Src),
                           XAttribute(XName.Get "alt", image.Alt),
                           XAttribute(XName.Get "loading", "lazy"))
        imgWrap.Add(img)
    card.Add(imgWrap)
    
    let meta = XElement(XName.Get "div", XAttribute(XName.Get "class", "meta"))
    
    let name = XElement(XName.Get "div", XAttribute(XName.Get "class", "name"), image.Name)
    meta.Add(name)
    
    let dims = XElement(XName.Get "div", XAttribute(XName.Get "class", "dims"), image.Dimensions)
    meta.Add(dims)
    
    match image.Prompt with
    | Some prompt ->
        let promptDiv = XElement(XName.Get "div", XAttribute(XName.Get "class", "prompt"), prompt)
        meta.Add(promptDiv)
    | None -> ()
    
    card.Add(meta)
    card

let createCategorySection (category: Category) =
    let section = XElement(XName.Get "section", XAttribute(XName.Get "id", category.Id))
    
    let h2 = XElement(XName.Get "h2", category.Title)
    
    let tags = createTagElement category.Tag category.Count
    for tag in tags do
        h2.Add(tag)
    
    section.Add(h2)
    
    let sub = XElement(XName.Get "p", XAttribute(XName.Get "class", "sub"), category.Subtitle)
    section.Add(sub)
    
    let grid = XElement(XName.Get "div", XAttribute(XName.Get "class", "grid"))
    
    for image in category.Images do
        grid.Add(createImageCard image)
    
    section.Add(grid)
    section

let categories = [
    { Id = "cat-seerose"; Title = "Seerosen (Pixabay/Unsplash)"; Subtitle = "Kandidaten für 3D-Textur / Alpha"; Tag = Auswahl; Count = 5;
      Images = [
        { Src = "thumbs/thumb_water_lily_01_pixabay_1510707_original.webp"; Alt = "water_lily_01_pixabay_1510707_original.jpg"; Name = "water_lily_01_pixabay_1510707_original.jpg"; Dimensions = "5184×3456 px"; Size = "1253 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_candidate-10-pixabay-4602155-wide-real-pond-lily-pads.webp"; Alt = "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg"; Name = "candidate-10-pixabay-4602155-wide-real-pond-lily-pads.jpg"; Dimensions = "1280×960 px"; Size = "570 KB"; Path = "pending-approval"; Prompt = None }
        { Src = "thumbs/thumb_candidate-11-pixabay-5904414-giant-water-lily-3d-depth.webp"; Alt = "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg"; Name = "candidate-11-pixabay-5904414-giant-water-lily-3d-depth.jpg"; Dimensions = "1280×951 px"; Size = "495 KB"; Path = "pending-approval"; Prompt = None }
        { Src = "thumbs/thumb_candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.webp"; Alt = "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg"; Name = "candidate-12-unsplash-Z9h4Fl6iCuU-pond-lily-pads.jpg"; Dimensions = "2400×1600 px"; Size = "425 KB"; Path = "pending-approval"; Prompt = None }
        { Src = "thumbs/thumb_candidate-09-pixabay-6403860-red-water-lily-water-closeup.webp"; Alt = "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg"; Name = "candidate-09-pixabay-6403860-red-water-lily-water-closeup.jpg"; Dimensions = "1280×853 px"; Size = "248 KB"; Path = "pending-approval"; Prompt = None }
      ] }
      
    { Id = "cat-wavespeed_hero"; Title = "WaveSpeed 4K Hero"; Subtitle = "Bereits generierter Hero-Hintergrund"; Tag = Pflicht; Count = 2;
      Images = [
        { Src = "thumbs/thumb_hero-meadow.webp"; Alt = "hero-meadow.png"; Name = "hero-meadow.png"; Dimensions = "5504×3072 px"; Size = "18908 KB"; Path = "media";
          Prompt = Some("Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g...") }
        { Src = "thumbs/thumb_hero-meadow.webp"; Alt = "hero-meadow.webp"; Name = "hero-meadow.webp"; Dimensions = "5504×3072 px"; Size = "836 KB"; Path = "media";
          Prompt = Some("Preserve the dense botanical meadow composition and teal, moss, cream and restrained amber palette. Create an elegant cinematic 4K landing-page background with realistic flowers, g...") }
      ] }
      
    { Id = "cat-wavespeed_orb"; Title = "WaveSpeed 4K Glaskugel"; Subtitle = "Referenz-Glaskugel für 3D-Material"; Tag = Pflicht; Count = 2;
      Images = [
        { Src = "thumbs/thumb_glass-orb.webp"; Alt = "glass-orb.png"; Name = "glass-orb.png"; Dimensions = "4096×4096 px"; Size = "18805 KB"; Path = "media";
          Prompt = Some("Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h...") }
        { Src = "thumbs/thumb_glass-orb.webp"; Alt = "glass-orb.webp"; Name = "glass-orb.webp"; Dimensions = "4096×4096 px"; Size = "730 KB"; Path = "media";
          Prompt = Some("Preserve the transparent glass sphere as the single subject. Refine it into a premium luminous crystal orb in a botanical meadow, soft white and pale teal refractions, restrained h...") }
      ] }
      
    { Id = "cat-wavespeed_projects"; Title = "WaveSpeed 4K Sektionen"; Subtitle = "Section-Backgrounds (Claude/Perplexity)"; Tag = Vorhanden; Count = 6;
      Images = [
        { Src = "thumbs/thumb_perplexity-projects.webp"; Alt = "perplexity-projects.png"; Name = "perplexity-projects.png"; Dimensions = "4800×3584 px"; Size = "21947 KB"; Path = "media";
          Prompt = Some("Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac...") }
        { Src = "thumbs/thumb_claude-projects.webp"; Alt = "claude-projects.png"; Name = "claude-projects.png"; Dimensions = "4800×3584 px"; Size = "20711 KB"; Path = "media";
          Prompt = Some("Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ...") }
        { Src = "thumbs/thumb_og-projects.webp"; Alt = "og-projects.png"; Name = "og-projects.png"; Dimensions = "5504×3072 px"; Size = "18199 KB"; Path = "media";
          Prompt = Some("Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet...") }
        { Src = "thumbs/thumb_perplexity-projects.webp"; Alt = "perplexity-projects.webp"; Name = "perplexity-projects.webp"; Dimensions = "4800×3584 px"; Size = "1805 KB"; Path = "media";
          Prompt = Some("Create an abstract premium visual for research, weather and computer-vision projects. Fine observation grids, atmospheric map contours, optical glass details, teal and pale blue ac...") }
        { Src = "thumbs/thumb_claude-projects.webp"; Alt = "claude-projects.webp"; Name = "claude-projects.webp"; Dimensions = "4800×3584 px"; Size = "1114 KB"; Path = "media";
          Prompt = Some("Create an abstract premium visual for a family of automation, security and publishing tools. Layered paper-like systems, fine technical lines, small warm copper accents, botanical ...") }
        { Src = "thumbs/thumb_og-projects.webp"; Alt = "og-projects.webp"; Name = "og-projects.webp"; Dimensions = "5504×3072 px"; Size = "819 KB"; Path = "media";
          Prompt = Some("Create a strong social preview image: luminous glass orb floating above a cinematic botanical meadow, quiet technical linework inside the sphere, ivory, moss, teal and copper palet...") }
      ] }
      
    { Id = "cat-wavespeed_section"; Title = "WaveSpeed 4K Zusatz"; Subtitle = "CTA / Feature-Spotlight"; Tag = Vorhanden; Count = 4;
      Images = [
        { Src = "thumbs/thumb_feature-spotlight.webp"; Alt = "feature-spotlight.png"; Name = "feature-spotlight.png"; Dimensions = "4800×3584 px"; Size = "18688 KB"; Path = "media";
          Prompt = Some("Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n...") }
        { Src = "thumbs/thumb_cta-background.webp"; Alt = "cta-background.png"; Name = "cta-background.png"; Dimensions = "5504×3072 px"; Size = "15543 KB"; Path = "media";
          Prompt = Some("Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h...") }
        { Src = "thumbs/thumb_feature-spotlight.webp"; Alt = "feature-spotlight.webp"; Name = "feature-spotlight.webp"; Dimensions = "4800×3584 px"; Size = "1315 KB"; Path = "media";
          Prompt = Some("Combine the botanical meadow and glass sphere into a polished editorial technology image. The glass orb reveals subtle scientific line patterns and biodiversity details, balanced n...") }
        { Src = "thumbs/thumb_cta-background.webp"; Alt = "cta-background.webp"; Name = "cta-background.webp"; Dimensions = "5504×3072 px"; Size = "730 KB"; Path = "media";
          Prompt = Some("Transform the botanical meadow into a very light, spacious call-to-action background. Soft radial teal, amber and copper blooms around empty central space, subtle organic detail, h...") }
      ] }
      
    { Id = "cat-studio_variant"; Title = "Studio-Varianten Glaskugel"; Subtitle = "Beleuchtungsstudien für Glas"; Tag = Referenz; Count = 8;
      Images = [
        { Src = "thumbs/thumb_var6_flat_lay.webp"; Alt = "var6_flat_lay.png"; Name = "var6_flat_lay.png"; Dimensions = "1672×941 px"; Size = "3173 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_var8_natural_light_outdoor.webp"; Alt = "var8_natural_light_outdoor.png"; Name = "var8_natural_light_outdoor.png"; Dimensions = "1672×941 px"; Size = "2481 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_var5_closeup_detail.webp"; Alt = "var5_closeup_detail.png"; Name = "var5_closeup_detail.png"; Dimensions = "1672×941 px"; Size = "1863 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_var4_dramatic_lighting.webp"; Alt = "var4_dramatic_lighting.png"; Name = "var4_dramatic_lighting.png"; Dimensions = "1672×941 px"; Size = "1573 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_var2_studio_white2.webp"; Alt = "var2_studio_white2.png"; Name = "var2_studio_white2.png"; Dimensions = "1672×941 px"; Size = "1285 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_var1_studio_white.webp"; Alt = "var1_studio_white.png"; Name = "var1_studio_white.png"; Dimensions = "1672×941 px"; Size = "1259 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_var8_natural_light_outdoor.webp"; Alt = "var8_natural_light_outdoor.jpg"; Name = "var8_natural_light_outdoor.jpg"; Dimensions = "1672×941 px"; Size = "800 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
        { Src = "thumbs/thumb_var4_dramatic_lighting.webp"; Alt = "var4_dramatic_lighting.jpg"; Name = "var4_dramatic_lighting.jpg"; Dimensions = "1672×941 px"; Size = "386 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
      ] }
      
    { Id = "cat-glasobjekt"; Title = "Glasobjekt-Referenz"; Subtitle = "Materialstudie Glas"; Tag = Referenz; Count = 2;
      Images = [
        { Src = "thumbs/thumb_element_01_glass_bowl.webp"; Alt = "element_01_glass_bowl.png"; Name = "element_01_glass_bowl.png"; Dimensions = "1024×1024 px"; Size = "1485 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_element_01_glass_bowl.webp"; Alt = "element_01_glass_bowl.jpg"; Name = "element_01_glass_bowl.jpg"; Dimensions = "1024×1024 px"; Size = "126 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
      ] }
      
    { Id = "cat-perle"; Title = "Perlen/Beads"; Subtitle = "Materialstudie klein/rund"; Tag = Referenz; Count = 4;
      Images = [
        { Src = "thumbs/thumb_element_02_beads_group.webp"; Alt = "element_02_beads_group.png"; Name = "element_02_beads_group.png"; Dimensions = "1024×1024 px"; Size = "1751 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_element_03_single_bead.webp"; Alt = "element_03_single_bead.png"; Name = "element_03_single_bead.png"; Dimensions = "1024×1024 px"; Size = "1473 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_element_02_beads_group.webp"; Alt = "element_02_beads_group.jpg"; Name = "element_02_beads_group.jpg"; Dimensions = "1024×1024 px"; Size = "284 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
        { Src = "thumbs/thumb_element_03_single_bead.webp"; Alt = "element_03_single_bead.jpg"; Name = "element_03_single_bead.jpg"; Dimensions = "1024×1024 px"; Size = "127 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
      ] }
      
    { Id = "cat-peonie_ref"; Title = "Pfingstrosen-Kompositionen"; Subtitle = "Referenz-Look; nicht direkt nutzbar"; Tag = Referenz; Count = 4;
      Images = [
        { Src = "thumbs/thumb_comp_02_peonies_warm.webp"; Alt = "comp_02_peonies_warm.png"; Name = "comp_02_peonies_warm.png"; Dimensions = "1024×1536 px"; Size = "2500 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_comp_01_peonies_dark.webp"; Alt = "comp_01_peonies_dark.png"; Name = "comp_01_peonies_dark.png"; Dimensions = "1024×1535 px"; Size = "2124 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_comp_02_peonies_warm.webp"; Alt = "comp_02_peonies_warm.jpg"; Name = "comp_02_peonies_warm.jpg"; Dimensions = "1024×1536 px"; Size = "761 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
        { Src = "thumbs/thumb_comp_01_peonies_dark.webp"; Alt = "comp_01_peonies_dark.jpg"; Name = "comp_01_peonies_dark.jpg"; Dimensions = "1024×1535 px"; Size = "642 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
      ] }
      
    { Id = "cat-feder"; Title = "Feder"; Subtitle = "Referenz Element"; Tag = Referenz; Count = 1;
      Images = [
        { Src = "thumbs/thumb_element_04_feather.webp"; Alt = "element_04_feather.png"; Name = "element_04_feather.png"; Dimensions = "1024×1536 px"; Size = "2384 KB"; Path = "examples"; Prompt = None }
      ] }
      
    { Id = "cat-ref_unsplash"; Title = "Unsplash Referenzen"; Subtitle = "Ästhetik-Referenz"; Tag = Referenz; Count = 3;
      Images = [
        { Src = "thumbs/thumb_katya-azimova-j945b6ttc7s-unsplash.webp"; Alt = "katya-azimova-j945b6ttc7s-unsplash.jpg"; Name = "katya-azimova-j945b6ttc7s-unsplash.jpg"; Dimensions = "4659×6989 px"; Size = "8535 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_anita-austvika-GnO2S8c7slQ-unsplash.webp"; Alt = "anita-austvika-GnO2S8c7slQ-unsplash.jpg"; Name = "anita-austvika-GnO2S8c7slQ-unsplash.jpg"; Dimensions = "4912×7360 px"; Size = "7049 KB"; Path = "examples"; Prompt = None }
        { Src = "thumbs/thumb_salvus-CiH1lH1u4dc-unsplash.webp"; Alt = "salvus-CiH1lH1u4dc-unsplash.jpg"; Name = "salvus-CiH1lH1u4dc-unsplash.jpg"; Dimensions = "3840×2160 px"; Size = "530 KB"; Path = "examples"; Prompt = None }
      ] }
      
    { Id = "cat-sonstiges"; Title = "Sonstiges"; Subtitle = ""; Tag = None; Count = 1;
      Images = [
        { Src = "thumbs/thumb_candidate-08-pixabay-1510707-original.webp"; Alt = "candidate-08-pixabay-1510707-original.jpg"; Name = "candidate-08-pixabay-1510707-original.jpg"; Dimensions = "5184×3456 px"; Size = "1253 KB"; Path = "pending-approval"; Prompt = None }
      ] }
      
    { Id = "cat-globe_frame"; Title = "Weltkugel-Frames"; Subtitle = "Bereits verwendet in globe-hero"; Tag = Vorhanden; Count = 9;
      Images = [
        { Src = ""; Alt = ""; Name = "frame-02.png"; Dimensions = "?×? px"; Size = "98 KB"; Path = "media"; Prompt = None }
        { Src = ""; Alt = ""; Name = "frame-01.png"; Dimensions = "?×? px"; Size = "92 KB"; Path = "media"; Prompt = None }
        { Src = ""; Alt = ""; Name = "frame-04.png"; Dimensions = "?×? px"; Size = "86 KB"; Path = "media"; Prompt = None }
        { Src = ""; Alt = ""; Name = "frame-05.png"; Dimensions = "?×? px"; Size = "73 KB"; Path = "media"; Prompt = None }
        { Src = ""; Alt = ""; Name = "frame-03.png"; Dimensions = "?×? px"; Size = "71 KB"; Path = "media"; Prompt = None }
        { Src = ""; Alt = ""; Name = "frame-06.png"; Dimensions = "?×? px"; Size = "37 KB"; Path = "media"; Prompt = None }
        { Src = ""; Alt = ""; Name = "frame-09.png"; Dimensions = "?×? px"; Size = "37 KB"; Path = "media"; Prompt = None }
        { Src = ""; Alt = ""; Name = "frame-08.png"; Dimensions = "?×? px"; Size = "29 KB"; Path = "media"; Prompt = None }
        { Src = ""; Alt = ""; Name = "frame-07.png"; Dimensions = "?×? px"; Size = "27 KB"; Path = "media"; Prompt = None }
      ] }
      
    { Id = "cat-screenshot"; Title = "Screenshots"; Subtitle = "Referenz aus Anhang"; Tag = Referenz; Count = 4;
      Images = [
        { Src = ""; Alt = ""; Name = "image-3.jpg"; Dimensions = "?×? px"; Size = "121 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
        { Src = ""; Alt = ""; Name = "image-4.jpg"; Dimensions = "?×? px"; Size = "118 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
        { Src = ""; Alt = ""; Name = "image-2.jpg"; Dimensions = "?×? px"; Size = "109 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
        { Src = ""; Alt = ""; Name = "image.jpg"; Dimensions = "?×? px"; Size = "104 KB"; Path = "7634afec188f40caa502423fce3ef2ea"; Prompt = None }
      ] }
]

let generateHtml outputFile =
    let doc = createDocument()
    let body = doc.Element(XName.Get "body")
    
    let header = XElement(XName.Get "header")
    
    let h1 = XElement(XName.Get "h1", "Kontaktbogen — Project-Landingpage Bildbestand")
    header.Add(h1)
    
    let p = XElement(XName.Get "p", "Alle vorhandenen HighRes-Bilder aus deiner Design-Referenz, dem laufenden Codex-Repo und den Anhängen. Kategorisiert nach Verwendungszweck. Bitte markiere pro Kategorie welche Assets in die finale Umsetzung sollen und wo du Erweiterung wünschst.")
    header.Add(p)
    
    let legend = XElement(XName.Get "div", XAttribute(XName.Get "class", "legend"))
    
    let pill1 = XElement(XName.Get "span", XAttribute(XName.Get "class", "pill pflicht"), "PFLICHT — muss ins finale Design")
    legend.Add(pill1)
    
    let pill2 = XElement(XName.Get "span", XAttribute(XName.Get "class", "pill auswahl"), "AUSWAHL nötig — mehrere Kandidaten")
    legend.Add(pill2)
    
    let pill3 = XElement(XName.Get "span", XAttribute(XName.Get "class", "pill"), "Referenz — nur Ästhetik, nicht direkt verwendet")
    legend.Add(pill3)
    
    let pill4 = XElement(XName.Get "span", XAttribute(XName.Get "class", "pill"), "Vorhanden — schon im Repo eingebaut")
    legend.Add(pill4)
    
    header.Add(legend)
    body.Add(header)
    
    let main = XElement(XName.Get "main", XAttribute(XName.Get "class", "main"))
    
    for category in categories do
        main.Add(createCategorySection category)
    
    body.Add(main)
    
    use writer = new StreamWriter(outputFile)
    doc.Save(writer)
    printfn "HTML file generated: %s" outputFile

[<EntryPoint>]
let main argv =
    let outputFile = if argv.Length > 0 then argv.[0] else "kontaktbogen.html"
    generateHtml outputFile
    0
