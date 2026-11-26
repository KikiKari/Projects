// abstraction-provenance: {"artifact_sha256": "adebe73f11a273fe4473c53e3bd04cea3d5840879cd076723bd99f6266d335e9", "source_sha256": "58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3", "target_language": "fsharp"}
// index.html — portiert nach fsharp
// Quelle: html, Projects@Telegram-Monitor:public/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

// Program.fs
open System
open System.IO
open System.Text

type HtmlElement =
    | Doctype of string
    | HtmlTag of string * Map<string, string> * HtmlElement list
    | Text of string
    | RawText of string

module HtmlBuilder =
    let inline (!+) (s: string) = Text s
    let inline (!*) (s: string) = RawText s
    
    let attr key value = (key, value)
    let attrs xs = Map xs
    
    let tag name attrs children = HtmlTag(name, attrs, children)
    
    let html = tag "html"
    let head = tag "head"
    let meta = tag "meta"
    let title = tag "title"
    let style = tag "style"
    let body = tag "body"
    let div = tag "div"
    let header = tag "header"
    let h1 = tag "h1"
    let h2 = tag "h2"
    let h3 = tag "h3"
    let p = tag "p"
    let span = tag "span"
    let a = tag "a"
    let link = tag "link"
    let script = tag "script"
    let ul = tag "ul"
    let ol = tag "ol"
    let li = tag "li"
    let pre = tag "pre"
    let code = tag "code"
    let table = tag "table"
    let tr = tag "tr"
    let th = tag "th"
    let td = tag "td"

let renderHtml (elements: HtmlElement list) =
    let sb = StringBuilder()
    
    let rec renderElement indent element =
        match element with
        | Doctype dt -> sb.Append("<!DOCTYPE ").Append(dt).AppendLine(">") |> ignore
        | Text t -> sb.Append(t) |> ignore
        | RawText rt -> sb.Append(rt) |> ignore
        | HtmlTag(tagName, attributes, children) ->
            if tagName = "html" then
                sb.Append("<").Append(tagName)
                if not attributes.IsEmpty then
                    for KeyValue(key, value) in attributes do
                        sb.Append(" ").Append(key).Append("=\"").Append(value.Replace("\"", "&quot;")).Append("\"") |> ignore
                sb.AppendLine(">") |> ignore
                for child in children do
                    renderElement (indent + "  ") child
                sb.AppendLine("</" + tagName + ">") |> ignore
            else
                sb.Append(indent).Append("<").Append(tagName)
                if not attributes.IsEmpty then
                    for KeyValue(key, value) in attributes do
                        sb.Append(" ").Append(key).Append("=\"").Append(value.Replace("\"", "&quot;")).Append("\"") |> ignore
                if List.isEmpty children then
                    sb.AppendLine("/>") |> ignore
                else
                    sb.AppendLine(">") |> ignore
                    for child in children do
                        match child with
                        | Text _ | RawText _ ->
                            renderElement "" child
                        | _ ->
                            renderElement (indent + "  ") child
                    sb.Append(indent).AppendLine("</" + tagName + ">") |> ignore
    
    for element in elements do
        renderElement "" element
    
    sb.ToString()

[<EntryPoint>]
let main argv =
    let outputFilePath = 
        if argv.Length > 0 then argv.[0] 
        else "index.html"
        
    let htmlContent = [
        Doctype "html"
        HtmlBuilder.html (HtmlBuilder.attrs [HtmlBuilder.attr "lang" "de"]) [
            HtmlBuilder.head HtmlBuilder.attrs.Empty [
                HtmlBuilder.meta (HtmlBuilder.attrs [HtmlBuilder.attr "charset" "utf-8"]) []
                HtmlBuilder.meta (HtmlBuilder.attrs [HtmlBuilder.attr "name" "viewport"; HtmlBuilder.attr "content" "width=device-width, initial-scale=1"]) []
                HtmlBuilder.title HtmlBuilder.attrs.Empty [!+"Telegram Monitor — lokaler Beobachtungs-Companion"]
                HtmlBuilder.meta (HtmlBuilder.attrs [HtmlBuilder.attr "name" "description"; HtmlBuilder.attr "content" "Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf dem eigenen Rechner und meldet den Livegang. Keine Cloud, keine Anmeldung."]) []
                HtmlBuilder.meta (HtmlBuilder.attrs [HtmlBuilder.attr "name" "theme-color"; HtmlBuilder.attr "content" "#2481cc"]) []
                HtmlBuilder.meta (HtmlBuilder.attrs [HtmlBuilder.attr "property" "og:title"; HtmlBuilder.attr "content" "Telegram Monitor"]) []
                HtmlBuilder.meta (HtmlBuilder.attrs [HtmlBuilder.attr "property" "og:description"; HtmlBuilder.attr "content" "Lokaler Beobachtungs-Companion. Docker, PWA, Meldung beim Livegang."]) []
                HtmlBuilder.meta (HtmlBuilder.attrs [HtmlBuilder.attr "property" "og:type"; HtmlBuilder.attr "content" "website"]) []
                HtmlBuilder.style HtmlBuilder.attrs.Empty [
                    !* @"
  :root{
    --bg:#ffffff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;
    --tg:#2481cc; --tg-soft:#e8f2fb; --tt:#fe2c55;
    --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;
    color-scheme: light;
  }
  @media (prefers-color-scheme: dark){
    :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
           --tg-soft:#132a3d; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:820px;margin:0 auto;padding:0 20px 72px}
  header{padding:64px 0 40px;border-bottom:1px solid var(--line);margin-bottom:8px}
  h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}
  .lede{font-size:18px;color:var(--muted);margin:0 0 22px;max-width:60ch}
  h2{font-size:13px;margin:44px 0 14px;text-transform:uppercase;letter-spacing:.06em;
     color:var(--muted);font-weight:650}
  h3{font-size:17px;margin:26px 0 6px}
  p{margin:0 0 14px;max-width:68ch}
  .badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:22px}
  .badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;
         background:var(--soft);color:var(--muted);border:1px solid var(--line)}
  .badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}
  .cta{display:flex;gap:10px;flex-wrap:wrap}
  .btn{display:inline-block;font-weight:650;font-size:15px;padding:11px 20px;
       border-radius:9px;text-decoration:none;border:1px solid var(--line);
       background:var(--bg);color:var(--text)}
  .btn.primary{background:var(--tg);border-color:var(--tg);color:#fff}
  .btn:hover{border-color:var(--tg)}
  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}
  .card{border:1px solid var(--line);border-radius:12px;padding:16px 18px;background:var(--bg)}
  .card h3{margin-top:0;font-size:15.5px}
  .card p{font-size:14px;color:var(--muted);margin:0}
  ol.steps{list-style:none;counter-reset:s;padding:0;margin:0}
  ol.steps li{counter-increment:s;position:relative;padding:0 0 20px 40px;
              border-left:2px solid var(--line);margin-left:11px}
  ol.steps li:last-child{border-left-color:transparent;padding-bottom:0}
  ol.steps li::before{content:counter(s);position:absolute;left:-13px;top:0;
       width:24px;height:24px;border-radius:50%;background:var(--tg);color:#fff;
       display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700}
  ol.steps b{display:block;margin-bottom:3px}
  ol.steps p{font-size:14.5px;color:var(--muted);margin:0 0 8px}
  code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;
       font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}
  pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;
      padding:13px 15px;overflow-x:auto;margin:0 0 14px}
  pre code{background:none;padding:0;font-size:13.5px;line-height:1.7}
  table{width:100%;border-collapse:collapse;font-size:14.5px;margin:0 0 16px}
  th,td{text-align:left;padding:9px 11px;border-bottom:1px solid var(--line);vertical-align:top}
  th{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.04em;font-weight:650}
  .note{border-left:3px solid var(--warn);background:var(--warn-soft);
        border-radius:0 9px 9px 0;padding:13px 16px;margin:0 0 16px;font-size:14.5px}
  .note b{display:block;margin-bottom:3px}
  a{color:var(--tg)}
  footer{margin-top:52px;padding-top:22px;border-top:1px solid var(--line);
         font-size:13.5px;color:var(--muted)}
"
                ]
            ]
            HtmlBuilder.body HtmlBuilder.attrs.Empty [
                HtmlBuilder.div (HtmlBuilder.attrs [HtmlBuilder.attr "class" "wrap"]) [
                    HtmlBuilder.header HtmlBuilder.attrs.Empty [
                        HtmlBuilder.h1 HtmlBuilder.attrs.Empty [!+"Telegram Monitor"]
                        HtmlBuilder.p (HtmlBuilder.attrs [HtmlBuilder.attr "class" "lede"]) [
                            !+"Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf
     deinem eigenen Rechner und meldet sich, wenn jemand live geht. Keine Cloud,
     kein Konto, keine App-Installation auf dem Telefon nötig."
                        ]
                        HtmlBuilder.div (HtmlBuilder.attrs [HtmlBuilder.attr "class" "badges"]) [
                            HtmlBuilder.span (HtmlBuilder.attrs [HtmlBuilder.attr "class" "badge on"]) [!+"Standardbibliothek"]
                            HtmlBuilder.span (HtmlBuilder.attrs [HtmlBuilder.attr "class" "badge on"]) [!+"Docker"]
                            HtmlBuilder.span (HtmlBuilder.attrs [HtmlBuilder.attr "class" "badge on"]) [!+"installierbar als App"]
                            HtmlBuilder.span (HtmlBuilder.attrs [HtmlBuilder.attr "class" "badge on"]) [!+"Browser-Erweiterung"]
                            HtmlBuilder.span (HtmlBuilder.attrs [HtmlBuilder.attr "class" "badge"]) [!+"Windows · macOS · Linux"]
                        ]
                        HtmlBuilder.div (HtmlBuilder.attrs [HtmlBuilder.attr "class" "cta"]) [
                            HtmlBuilder.a (HtmlBuilder.attrs [HtmlBuilder.attr "class" "btn primary"; HtmlBuilder.attr "href" "https://github.com/KikiKari/Projects/tree/Telegram-Monitor"]) [!+"Quelltext auf GitHub"]
                            HtmlBuilder.a (HtmlBuilder.attrs [HtmlBuilder.attr "class" "btn"; HtmlBuilder.attr "href" "/viewer"]) [!+"Live-Viewer öffnen"]
                        ]
                    ]
                    
                    HtmlBuilder.h2 HtmlBuilder.attrs.Empty [!+"Was es tut"]
                    HtmlBuilder.div (HtmlBuilder.attrs [HtmlBuilder.attr "class" "grid"]) [
                        HtmlBuilder.div (HtmlBuilder.attrs [HtmlBuilder.attr "class" "card"]) [
                            HtmlBuilder.h3 HtmlBuilder.attrs.Empty [!+"Beobachten"]
                            HtmlBuilder.p HtmlBuilder.attrs.Empty [
                                !+"Fragt jeden Kanal im eingestellten Turnus ab und sammelt den Verlauf auf
       der Platte — neueste Beiträge oben, anders als in Telegram selbst."
                            ]
                        ]
                        HtmlBuilder.div (HtmlBuilder.attrs [HtmlBuilder.attr "class" "card"]) [
                            HtmlBuilder.h3 HtmlBuilder.attrs.Empty [!+"Erkennen"]
                            HtmlBuilder.p HtmlBuilder.attrs.Empty [
                                !+"Vergleicht den Zustand mit dem letzten Durchlauf. Gemeldet wird nur ein
       echter Wechsel; ein fehlgeschlagener Abruf gilt nicht als „offline\"."
                            ]
                        ]
                        HtmlBuilder.div (HtmlBuilder.attrs [HtmlBuilder.attr "class" "card"]) [
                            HtmlBuilder.h3 HtmlBuilder.attrs.Empty [!+"Melden"]
                            HtmlBuilder.p HtmlBuilder.attrs.Empty [
                                !+"Drei Wege gleichzeitig: Ereignisprotokoll, Systemmeldung und Webhook.
       Fällt einer aus, steht der Wechsel trotzdem mit Zeitstempel fest."
                            ]
                        ]
                    ]
                    
                    HtmlBuilder.h2 HtmlBuilder.attrs.Empty [!+"Drei Zugänge, ein Monitor"]
                    HtmlBuilder.table HtmlBuilder.attrs.Empty [
                        HtmlBuilder.tr HtmlBuilder.attrs.Empty [
                            HtmlBuilder.th HtmlBuilder.attrs.Empty [!+"Zugang"]
                            HtmlBuilder.th HtmlBuilder.attrs.Empty [!+"wofür"]
                        ]
                        HtmlBuilder.tr HtmlBuilder.attrs.Empty [
                            HtmlBuilder.td HtmlBuilder.attrs.Empty [HtmlBuilder.b HtmlBuilder.attrs.Empty [!+"Installierte App"]]
                            HtmlBuilder.td HtmlBuilder.attrs.Empty [
                                !+"Vollständige Oberfläche mit allen Reitern, eigenes Fenster ohne
          Adressleiste, Symbol im Startmenü"
                            ]
                        ]
                        HtmlBuilder.tr HtmlBuilder.attrs.Empty [
                            HtmlBuilder.td HtmlBuilder.attrs.Empty [HtmlBuilder.b HtmlBuilder.attrs.Empty [!+"Browser-Erweiterung"]]
                            HtmlBuilder.td HtmlBuilder.attrs.Empty [
                                !+"Meldung beim Livegang, ohne dass ein Tab offen sein muss"
                            ]
                        ]
                        HtmlBuilder.tr HtmlBuilder.attrs.Empty [
                            HtmlBuilder.td HtmlBuilder.attrs.Empty [HtmlBuilder.b HtmlBuilder.attrs.Empty [!+"Live-Viewer"]]
                            HtmlBuilder.td HtmlBuilder.attrs.Empty [
                                !+"Bettet den offiziellen Player ein — ohne Anmeldung, ohne Geschenk-
          oder Kauf-Oberfläche. "
                                HtmlBuilder.a (HtmlBuilder.attrs [HtmlBuilder.attr "href" "/viewer"]) [!+"Hier direkt ausprobieren."]
                            ]
                        ]
                    ]
                    
                    HtmlBuilder.h2 HtmlBuilder.attrs.Empty [!+"Einrichten"]
                    HtmlBuilder.ol (HtmlBuilder.attrs [HtmlBuilder.attr "class" "steps"]) [
                        HtmlBuilder.li HtmlBuilder.attrs.Empty [
                            HtmlBuilder.b HtmlBuilder.attrs.Empty [!+"Repository holen"]
                            HtmlBuilder.p HtmlBuilder.attrs.Empty [!+"Branch "; HtmlBuilder.code HtmlBuilder.attrs.Empty [!+"Telegram-Monitor"]; !+" auschecken."]
                            HtmlBuilder.pre HtmlBuilder.attrs.Empty [
                                HtmlBuilder.code HtmlBuilder.attrs.Empty [
                                    !* @"git clone -b Telegram-Monitor https://github.com/KikiKari/Projects.git
cd Projects"
                                ]
                            ]
                        ]
                        HtmlBuilder.li HtmlBuilder.attrs.Empty [
                            HtmlBuilder.b HtmlBuilder.attrs.Empty [!+"Dauerhaft starten"]
                            HtmlBuilder.p HtmlBuilder.attrs.Empty [
                                !+"Bindet an "; HtmlBuilder.code HtmlBuilder.attrs.Empty [!+"127.0.0.1:8765"]; !+", der Verlauf liegt im Volume
       "; HtmlBuilder.code HtmlBuilder.attrs.Empty [!+"monitor-data"]; !+" und überlebt jedes Neubauen. Unter Windows
       genügt ein Doppelklick auf "; HtmlBuilder.code HtmlBuilder.attrs.Empty [!+"Telegram Monitor - Docker.cmd"]; !+"."
                            ]
                            HtmlBuilder.pre HtmlBuilder.attrs.Empty [
                                HtmlBuilder.code HtmlBuilder.attrs.Empty [!+"docker compose up -d --build"]
                            ]
                        ]
                        HtmlBuilder.li HtmlBuilder.attrs.Empty [
                            HtmlBuilder.b HtmlBuilder.attrs.Empty [!+"Ohne Docker"]
                            HtmlBuilder.p HtmlBuilder.attrs.Empty [!+"Der Kern braucht nur die Standardbibliothek — nichts zu installieren."]
                            HtmlBuilder.pre HtmlBuilder.attrs.Empty [
                                HtmlBuilder.code HtmlBuilder.attrs.Empty [!+"python server.py --poll-interval 120"]
                            ]
                        ]
                        HtmlBuilder.li HtmlBuilder.attrs.Empty [
                            HtmlBuilder.b HtmlBuilder.attrs.Empty [!+"Als App einrichten"]
                            HtmlBuilder.p HtmlBuilder.attrs.Empty [
                                !+"In der geöffneten Oberfläche auf "; HtmlBuilder.b HtmlBuilder.attrs.Empty [!+"Als App installieren"]; !+" klicken.
       Danach liegt der Monitor als eigenes Programm im Startmenü."
                            ]
                        ]
                        HtmlBuilder.li HtmlBuilder.attrs.Empty [
                            HtmlBuilder.b HtmlBuilder.attrs.Empty [!+"Aufs Telefon bringen"]
                            HtmlBuilder.p HtmlBuilder.attrs.Empty [
                                !+"Über das eigene VPN freigeben, dann die "; HtmlBuilder.code HtmlBuilder.attrs.Empty [!+"https"]; !+"-Adresse auf
       dem Telefon öffnen und dort installieren. Eine "; HtmlBuilder.code HtmlBuilder.attrs.Empty [!+".apk"]; !+" gibt es
       nicht und wird auch nicht gebraucht."
                            ]
                            HtmlBuilder.pre HtmlBuilder.attrs.Empty [
                                HtmlBuilder.code HtmlBuilder.attrs.Empty [!+"tailscale serve --bg 8765"]
                            ]
                        ]
                    ]
                    
                    HtmlBuilder.h2 HtmlBuilder.attrs.Empty [!+"Was hier nicht läuft"]
                    HtmlBuilder.div (HtmlBuilder.attrs [HtmlBuilder.attr "class" "note"]) [
                        HtmlBuilder.b HtmlBuilder.attrs.Empty [!+"Diese Seite ist nur die Visitenkarte."]
                        !+" Der Monitor selbst läuft "; HtmlBuilder.i HtmlBuilder.attrs.Empty [!+"nicht"]; !+" im Web. Sein Kern ist ein
  Hintergrundprozess, der dauerhaft abfragt und Zustand auf die Platte
  schreibt — beides gibt es in einer serverlosen Umgebung nicht. Ausgeliefert
  werden hier nur diese Seite und der Viewer, der ohnehin ohne Server
  auskommt. Beobachtet wird auf deinem Rechner."
                    ]
                    
                    HtmlBuilder.h2 HtmlBuilder.attrs.Empty [!+"Grenzen"]
                    HtmlBuilder.p HtmlBuilder.attrs.Empty [
                        !+"Gelesen wird ausschließlich, was öffentlich abrufbar ist. Anmeldeschranken
   und Zugriffssperren werden nicht umgangen — wo es offizielle Einbettungen
   gibt, werden die genommen. Private Telegram-Konten liefern nur Name und Bio;
   das ist eine Einschränkung von Telegram, kein Fehler."
                    ]
                    HtmlBuilder.p HtmlBuilder.attrs.Empty [
                        !+"Der Turnus bleibt höflich: ein bis fünf Minuten. Sekundentakt bringt selten
   mehr Information und handelt eine Sperre ein."
                    ]
                    
                    HtmlBuilder.footer HtmlBuilder.attrs.Empty [
                        !+"Läuft lokal, gehört dir. Das wiederverwendbare Muster dahinter steckt im Skill
  "; HtmlBuilder.code HtmlBuilder.attrs.Empty [!+"lokaler-companion"]; !+"."
                    ]
                ]
            ]
        ]
    ]
    
    let renderedHtml = renderHtml htmlContent
    File.WriteAllText(outputFilePath, renderedHtml)
    0
