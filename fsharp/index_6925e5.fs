// abstraction-provenance: {"artifact_sha256": "5a2d0d240f497e4e712dfaa2af68685ef1aca30b4129d0398501f274c3aa05de", "source_sha256": "6925e5ed34d3344b10c23ce3442546a31631cc8434f3b7df4bdc003d32218523", "target_language": "fsharp"}
// index.html — portiert nach fsharp
// Quelle: html, Projects@MCP-Server-Monitor:public/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type HtmlElement =
    | Html of string
    | Head of HtmlElement list
    | Body of HtmlElement list
    | Div of attributes: (string * string) list * children: HtmlElement list
    | Span of attributes: (string * string) list * children: HtmlElement list
    | Header of HtmlElement list
    | H1 of attributes: (string * string) list * children: HtmlElement list
    | H2 of attributes: (string * string) list * children: HtmlElement list
    | H3 of attributes: (string * string) list * children: HtmlElement list
    | P of attributes: (string * string) list * children: HtmlElement list
    | Table of attributes: (string * string) list * children: HtmlElement list
    | Tr of HtmlElement list
    | Th of attributes: (string * string) list * children: HtmlElement list
    | Td of attributes: (string * string) list * children: HtmlElement list
    | Pre of attributes: (string * string) list * children: HtmlElement list
    | Code of attributes: (string * string) list * children: HtmlElement list
    | FieldSet of attributes: (string * string) list * children: HtmlElement list
    | Legend of attributes: (string * string) list * children: HtmlElement list
    | Label of attributes: (string * string) list * children: HtmlElement list
    | Input of attributes: (string * string) list
    | Button of attributes: (string * string) list * children: HtmlElement list
    | Text of string
    | Style of string
    | Script of string

let attr k v = (k, v)
let id x = attr "id" x
let cls x = attr "class" x
let htmlFor x = attr "for" x
let ``type`` x = attr "type" x

let inline text s = Text s

let renderHtml (element: HtmlElement): string =
    let sb = StringBuilder()
    
    let escapeHtml (s: string) =
        s.Replace("&", "&amp;")
         .Replace("<", "&lt;")
         .Replace(">", "&gt;")
         .Replace("\"", "&quot;")
         .Replace("'", "&#x27;")
    
    let rec render (elem: HtmlElement) =
        match elem with
        | Html children ->
            sb.Append("<!DOCTYPE html>") |> ignore
            sb.Append("<html lang=\"de\">") |> ignore
            List.iter render children
            sb.Append("</html>") |> ignore
        | Head children ->
            sb.Append("<head>") |> ignore
            List.iter render children
            sb.Append("</head>") |> ignore
        | Body children ->
            sb.Append("<body>") |> ignore
            List.iter render children
            sb.Append("</body>") |> ignore
        | Div(attrs, children) ->
            sb.Append("<div") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</div>") |> ignore
        | Span(attrs, children) ->
            sb.Append("<span") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</span>") |> ignore
        | Header children ->
            sb.Append("<header>") |> ignore
            List.iter render children
            sb.Append("</header>") |> ignore
        | H1(attrs, children) ->
            sb.Append("<h1") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</h1>") |> ignore
        | H2(attrs, children) ->
            sb.Append("<h2") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</h2>") |> ignore
        | H3(attrs, children) ->
            sb.Append("<h3") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</h3>") |> ignore
        | P(attrs, children) ->
            sb.Append("<p") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</p>") |> ignore
        | Table(attrs, children) ->
            sb.Append("<table") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</table>") |> ignore
        | Tr children ->
            sb.Append("<tr>") |> ignore
            List.iter render children
            sb.Append("</tr>") |> ignore
        | Th(attrs, children) ->
            sb.Append("<th") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</th>") |> ignore
        | Td(attrs, children) ->
            sb.Append("<td") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</td>") |> ignore
        | Pre(attrs, children) ->
            sb.Append("<pre") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</pre>") |> ignore
        | Code(attrs, children) ->
            sb.Append("<code") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</code>") |> ignore
        | FieldSet(attrs, children) ->
            sb.Append("<fieldset") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</fieldset>") |> ignore
        | Legend(attrs, children) ->
            sb.Append("<legend") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</legend>") |> ignore
        | Label(attrs, children) ->
            sb.Append("<label") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</label>") |> ignore
        | Input attrs ->
            sb.Append("<input") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
        | Button(attrs, children) ->
            sb.Append("<button") |> ignore
            attrs |> List.iter (fun (k,v) -> sb.Append(sprintf " %s=\"%s\"" k (escapeHtml v)) |> ignore)
            sb.Append(">") |> ignore
            List.iter render children
            sb.Append("</button>") |> ignore
        | Text s ->
            sb.Append(escapeHtml s) |> ignore
        | Style css ->
            sb.Append("<style>") |> ignore
            sb.Append(css) |> ignore
            sb.Append("</style>") |> ignore
        | Script js ->
            sb.Append("<script>") |> ignore
            sb.Append(js) |> ignore
            sb.Append("</script>") |> ignore
    
    render element
    sb.ToString()

let generateDocument() =
    Html [
        Head [
            Style """
  :root{
    --bg:#fff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;
    --ac:#6d5bd0; --ac-soft:#efecfb;
    --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;
    color-scheme: light;
  }
  @media (prefers-color-scheme: dark){
    :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
           --ac-soft:#1e1a33; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:840px;margin:0 auto;padding:0 20px 72px}
  header{padding:64px 0 36px;border-bottom:1px solid var(--line)}
  h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}
  .lede{font-size:18px;color:var(--muted);margin:0 0 20px;max-width:62ch}
  h2{font-size:13px;margin:48px 0 14px;text-transform:uppercase;letter-spacing:.06em;
     color:var(--muted);font-weight:650}
  h3{font-size:17px;margin:24px 0 6px}
  p{margin:0 0 14px;max-width:70ch}
  .badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:20px}
  .badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;
         background:var(--soft);color:var(--muted);border:1px solid var(--line)}
  .badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}
  table{border-collapse:collapse;width:100%;font-size:14.5px;margin:0 0 14px}
  th,td{text-align:left;padding:9px 10px;border-bottom:1px solid var(--line);vertical-align:top}
  th{font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}
  code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;
       font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}
  pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;
      padding:13px 15px;overflow-x:auto;margin:0 0 14px}
  pre code{background:none;padding:0}
  .card{border:1px solid var(--line);border-radius:12px;padding:18px 20px;background:var(--bg)}
  .note{background:var(--warn-soft);border:1px solid transparent;border-radius:10px;
        padding:14px 16px;margin:0 0 16px;font-size:14.5px}
  .note b{color:var(--warn)}
  fieldset{border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:0 0 14px}
  legend{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);padding:0 6px}
  label.q{display:flex;gap:10px;align-items:flex-start;padding:7px 0;font-size:15px;cursor:pointer}
  label.q input{margin-top:4px;flex:none}
  label.q span small{display:block;color:var(--muted);font-size:13px}
  #ergebnis{margin-top:6px}
  .verdict{border:1px solid var(--line);border-left:4px solid var(--ac);
           border-radius:10px;padding:16px 18px;background:var(--soft)}
  .verdict h3{margin:0 0 6px;font-size:18px}
  .verdict .step{font-weight:650;margin:10px 0 0}
  .verdict .w{margin-top:12px;padding:11px 13px;background:var(--warn-soft);
              border-radius:8px;font-size:14px}
  .probe{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px}
  .probe input{flex:1 1 240px;padding:10px 12px;border:1px solid var(--line);
               border-radius:9px;background:var(--bg);color:var(--text);font-size:15px}
  .btn{font-weight:650;font-size:15px;padding:10px 18px;border-radius:9px;
       border:1px solid var(--ac);background:var(--ac);color:#fff;cursor:pointer}
  .btn.ghost{background:var(--bg);color:var(--text);border-color:var(--line)}
  footer{margin-top:56px;padding-top:22px;border-top:1px solid var(--line);
         color:var(--muted);font-size:14px}
  a{color:var(--ac)}
"""
            Text """<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MCP-Server-Monitor — Zustand feststellen statt raten</title>
<meta name="description" content="Fremde, offizielle MCP-Server finden, ihren Zustand feststellen und einrichten lassen. Fuenf Zustaende, ein naechster Schritt pro Zustand.">
<meta name="theme-color" content="#6d5bd0">
<meta property="og:title" content="MCP-Server-Monitor">
<meta property="og:description" content="Warum fehlen die Tools? Fuenf Zustaende, ein naechster Schritt pro Zustand.">
<meta property="og:type" content="website">"""
        ]
        Body [
            Div [cls "wrap"] [
                Header [] [
                    Div [cls "badges"] [
                        Span [cls "badge on"] [Text "Fuenf Zustaende"]
                        Span [cls "badge"] [Text "Discovery"]
                        Span [cls "badge"] [Text "MSIX-Pfadfalle"]
                        Span [cls "badge"; id "modus"] [Text "statisch"]
                    ]
                    H1 [] [
                        Text "MCP-Server-Monitor"
                    ]
                    P [cls "lede"] [
                        Text "Fast jede Frage nach einem MCP-Server ist in Wahrheit eine Zustandsfrage. Wer den Zustand feststellt, hat die Antwort meist schon."
                    ]
                    P [cls "lede"; attr "style" "font-size:16px"] [
                        Text "Dieses Werkzeug traegt "
                        Text "keine"
                        Text " Server ein und meldet niemanden an. Es diagnostiziert, sucht und bereitet den Klickweg exakt vor. Den Klick macht der Nutzer — das ist geprüfte Grenze, keine Bequemlichkeit."
                    ]
                ]
                
                H2 [] [Text "Zustand bestimmen"]
                Div [cls "card"] [
                    FieldSet [] [
                        Legend [] [Text "Was siehst du?"]
                        Label [cls "q"; htmlFor "q_tools"] [
                            Input [``type`` "checkbox"; id "q_tools"]
                            Span [] [
                                Text "Es gibt Tools mit dem Namensmuster des Servers"
                                Small [] [Text "Das verlaesslichste Signal — Tool-Listen sind scope-gefiltert. Was da ist, ist nutzbar."]
                            ]
                        ]
                        Label [cls "q"; htmlFor "q_haekchen"] [
                            Input [``type`` "checkbox"; id "q_haekchen"]
                            Span [] [
                                Text "Der Konnektor steht in der Liste, mit Haekchen"
                                Small [] [Text "Einstellungen → Anpassen → Konnektoren. Ferne Server haben Typ „Web\"."]
                            ]
                        ]
                        Label [cls "q"; htmlFor "q_auth"] [
                            Input [``type`` "checkbox"; id "q_auth"]
                            Span [] [
                                Text "Es kommt die Meldung „benoetigt Authentifizierung\""
                            ]
                        ]
                        Label [cls "q"; htmlFor "q_plugin"] [
                            Input [``type`` "checkbox"; id "q_plugin"]
                            Span [] [
                                Text "Derselbe Name laeuft auch als "
                                Code [] [Text "plugin:…"]
                                Small [] [Text "Dann sind es zwei verschiedene Server mit getrennter Anmeldung."]
                            ]
                        ]
                        Label [cls "q"; htmlFor "q_angemeldet"] [
                            Input [``type`` "checkbox"; id "q_angemeldet"]
                            Span [] [
                                Text "Es wurde fuer diesen Dienst schon einmal etwas angemeldet"
                            ]
                        ]
                    ]
                    Div [id "ergebnis"] []
                ]
                
                H2 [] [Text "Die fuenf Zustaende"]
                Table [] [
                    Tr [] [
                        Th [] [Text "Zustand"]
                        Th [] [Text "Woran erkennbar"]
                        Th [] [Text "Naechster Schritt"]
                    ]
                    Tr [] [
                        Td [] [Text "1 — Offen"]
                        Td [] [Text "Tools vorhanden, nie etwas angemeldet"]
                        Td [] [Text "Direkt benutzen"]
                    ]
                    Tr [] [
                        Td [] [Text "2 — Verbunden, mit Tools"]
                        Td [] [Text "Konnektor mit Haekchen, Tools vorhanden"]
                        Td [] [Text "Direkt benutzen"]
                    ]
                    Tr [] [
                        Td [] [Text "3 — Verbunden, ohne Tools"]
                        Td [] [Text "Konnektor mit Haekchen, aber keine Tools"]
                        Td [] [Text "Liefert er ueberhaupt Tools? Scope erteilt?"]
                    ]
                    Tr [] [
                        Td [] [Text "4 — Installiert, unangemeldet"]
                        Td [] [Text "gelistet, Tools fehlen, „benoetigt Authentifizierung\""]
                        Td [] [Text "Anmelden — braucht eine interaktive Sitzung"]
                    ]
                    Tr [] [
                        Td [] [Text "5 — Nicht vorhanden"]
                        Td [] [Text "nichts"]
                        Td [] [Text "Suchen, dann eintragen lassen"]
                    ]
                ]
                P [] [
                    Text "Zustand 3 ist der, der als Fehler missverstanden wird. Ein Konnektor kann verbunden sein und trotzdem keine Tools mitbringen, weil er gar keine liefert. Die GitHub-Integration ist so ein Fall: Sie oeffnet Repository-Zugriff, eine Tool-Sammlung ist sie nicht."
                ]
                
                H2 [] [Text "Discovery"]
                Div [cls "note"; id "cors-hinweis"] [
                    Text "Warum hier kein Knopf steht."
                    Text " Diese Seite ruft keine fremden Endpunkte ab. Ein "
                    Code [] [Text "fetch"]
                    Text " aus dem Browser auf "
                    Code [] [Text "mcp.DOMAIN"]
                    Text " scheitert an CORS — eine Seite, die es trotzdem versucht, bleibt leer und sieht dabei kaputt aus. Die echten Proben macht der lokale Companion. Start: "
                    Code [] [Text "python cli.py serve"]
                    Text ", dann diese Seite unter "
                    Code [] [Text "http://127.0.0.1:8787"]
                    Text " oeffnen — der Knopf erscheint dort von selbst."
                ]
                Div [id "probe-ui"; attr "hidden" ""] [
                    Div [cls "probe"] [
                        Input [id "dom"; attr "placeholder" "domain, z. B. linear.app"; attr "autocomplete" "off"]
                        Button [cls "btn"; id "go"] [Text "Pruefen"]
                    ]
                    Div [id "probe-out"] []
                ]
                P [] [
                    Text "Geprueft wird in dieser Reihenfolge:"
                ]
                Table [] [
                    Tr [] [
                        Th [] [Text "#"]
                        Th [] [Text "Pfad"]
                        Th [] [Text "Bedeutung"]
                    ]
                    Tr [] [
                        Td [] [Text "1"]
                        Td [] [
                            Code [] [Text "https://mcp.DOMAIN/"]
                        ]
                        Td [] [Text "Streamable-HTTP-Endpunkt"]
                    ]
                    Tr [] [
                        Td [] [Text "2"]
                        Td [] [
                            Code [] [Text "https://mcp.DOMAIN/mcp"]
                        ]
                        Td [] [Text "haeufige Pfadvariante"]
                    ]
                    Tr [] [
                        Td [] [Text "3"]
                        Td [] [
                            Code [] [Text "https://docs.DOMAIN/mcp"]
                        ]
                        Td [] [Text "dort steht sie bei den meisten Anbietern"]
                    ]
                    Tr [] [
                        Td [] [Text "4"]
                        Td [] [
                            Code [] [Text "/.well-known/oauth-protected-resource"]
                        ]
                        Td [] [Text "existiert sie, gibt es einen OAuth-faehigen Server"]
                    ]
                    Tr [] [
                        Td [] [Text "5"]
                        Td [] [
                            Code [] [Text "/.well-known/oauth-authorization-server"]
                        ]
                        Td [] [Text "dito, mit Revocation-Endpunkt"]
                    ]
                ]
                P [] [
                    Text "Eine leere Antwort auf ein nacktes GET beweist nichts."
                    Text " Streamable-HTTP-Endpunkte antworten darauf oft mit gar nichts, und 400/401/405 sind regulaere Ablehnungen, keine Negativbefunde. Erst wenn auch die Discovery-Pfade fehlen, ist von Abwesenheit auszugehen."
                ]
                
                H2 [] [Text "Eintragen — der reale Weg"]
                P [] [
                    Text "Ferne Server gehoeren unter Konnektoren, nicht unter Erweiterungen."
                    Text " Erweiterungen"
                    Text " liegt im Abschnitt „Desktop-App\" und meint lokale Erweiterungen. "
                    Text "Konnektoren"
                    Text " liegt unter „Anpassen\" und ist der richtige Ort."
                ]
                H3 [] [Text "Weg 1 — Claude-App"]
                P [] [
                    Text "Einstellungen → Anpassen → Konnektoren → „Hinzufuegen\" oben rechts → URL eintragen. Danach fuehrt die Anmeldung durch den Browser."
                ]
                H3 [] [Text "Weg 2 — Claude Code"]
                Pre [] [
                    Code [] [Text "claude mcp add --transport http NAME https://mcp.DOMAIN/"]
                ]
                P [] [
                    Text "Danach "
                    Code [] [Text "/mcp"]
                    Text " aufrufen und im Browser anmelden."
                ]
                H3 [] [Text "Weg 3 — Konfigurationsdatei"]
                Table [] [
                    Tr [] [
                        Th [] [Text "Installationsart"]
                        Th [] [Text "Pfad"]
                    ]
                    Tr [] [
                        Td [] [Text "Standard-Installer"]
                        Td [] [
                            Code [] [Text "%APPDATA%\\Claude\\claude_desktop_config.json"]
                        ]
                    ]
                    Tr [] [
                        Td [] [Text "MSIX (Store, WinGet, Enterprise)"]
                        Td [] [
                            Code [] [Text "%LOCALAPPDATA%\\Packages\\Claude_pzs8sxrjxfjjc\\LocalCache\\Roaming\\Claude\\claude_desktop_config.json"]
                        ]
                    ]
                ]
                Div [cls "note"] [
                    Text "Die Falle."
                    Text " Bei MSIX oeffnet „Edit Config\" im Entwickler-Menue die "
                    Text "erste"
                    Text " Datei, gelesen wird die "
                    Text "zweite"
                    Text ". Wer dort eintraegt, wartet vergeblich. Und die App liest die Datei nur beim Start — nach dem Aendern vollstaendig beenden und neu oeffnen."
                ]
                P [] [
                    Text "Welche Datei bei dir wirkt, sagt "
                    Code [] [Text "python cli.py config"]
                    Text "."
                ]
                
                H2 [] [Text "Fehlerbilder"]
                Table [] [
                    Tr [] [
                        Th [] [Text "Bild"]
                        Th [] [Text "Wahrscheinliche Ursache"]
                    ]
                    Tr [] [
                        Td [] [Text "Verbunden, aber keine Tools"]
                        Td [] [Text "Konnektor liefert keine Tools, oder Scope fehlt"]
                    ]
                    Tr [] [
                        Td [] [Text "Name doppelt: verbunden "
                        Text "und"
                        Text " „benoetigt Auth\""]
                        Td [] [Text "Konnektor und Plugin-Server verwechselt"]
                    ]
                    Tr [] [
                        Td [] [
                            Code [] [Text "invalid_scope"]
                        ]
                        Td [] [Text "Mehr angefragt, als der Client registriert hat"]
                    ]
                    Tr [] [
                        Td [] [Text "Haengt dauerhaft in „connecting\""]
                        Td [] [Text "Endpunkt falsch, Netz blockiert, oder Server unten"]
                    ]
                    Tr [] [
                        Td [] [Text "401 nach Wochen problemlosen Betriebs"]
                        Td [] [Text "Refresh-Token abgelaufen oder widerrufen — neu anmelden"]
                    ]
                    Tr [] [
                        Td [] [Text "Manuell eingetragener Server bleibt stumm"]
                        Td [] [Text "MSIX-Pfadfalle, oder App nicht neu gestartet"]
                    ]
                    Tr [] [
                        Td [] [Text "Tools nach Update verschwunden"]
                        Td [] [Text "Server neu verbunden, Scopes neu erteilen"]
                    ]
                ]
                
                H2 [] [Text "Betriebsgrenzen"]
                P [] [
                    Text "Ferne Server sind bequem, aber nicht kostenlos: kein Binaer-Upload (die meisten nehmen nur URLs), ein Roundtrip pro Aufruf, und jeder Aufruf verbraucht echtes Kontingent beim Anbieter — genau wie ein direkter API-Aufruf. Daraus die Regel: "
                    Text "Fuer Einzelfragen der MCP-Server. Ab mehreren Aufrufen, bei Dateien oder in Skripten die Direkt-API."
                ]
                
                Footer [] [
                    Text "MCP-Server-Monitor — Branch "
                    Code [] [Text "MCP-Server-Monitor"]
                    Text " in "
                    Text "KikiKari/Projects"
                    Text ". Statisch ausgeliefert aus "
                    Code [] [Text "public/"]
                    Text ", kein Build, keine Zaehlpixel."
                ]
            ]
            
            Script """
(function(){
  "use strict";
  var Z = {
    offen:      ["1 — Offen","Direkt benutzen."],
    mitTools:   ["2 — Verbunden, mit Tools","Direkt benutzen."],
    ohneTools:  ["3 — Verbunden, ohne Tools","Pruefen, ob der Konnektor ueberhaupt Tools liefert; danach die erteilten Scopes. Die Tool-Liste ist scope-gefiltert — ein fehlendes Tool heisst fast immer fehlender Scope, nicht fehlende Funktion."],
    unauth:     ["4 — Installiert, unangemeldet","Anmelden. Das braucht eine interaktive Sitzung — in einer nicht-interaktiven Sitzung startet kein OAuth-Flow."],
    absent:     ["5 — Nicht vorhanden","Discovery laufen lassen (Connector-Registry, dann die fuenf Pfade unten), danach unter Anpassen → Konnektoren eintragen."]
  };
  var W_PLUGIN = "Der Name laeuft auch als <code>plugin:…</code> — das ist ein zweiter, separat anzumeldender Server. Konnektoren haengen am Konto, Plugins bringen eigene MCP-Server mit. Wer das nicht trennt, meldet sich an und sucht den Fehler an der falschen Stelle.";
  var W_Z3 = "Zustand 3 wird oft als Fehler missverstanden. Lies die Beschreibung des Konnektors im Dialog, bevor du einen Fehler vermutest.";

  var ids = ["q_tools","q_haekchen","q_auth","q_plugin","q_angemeldet"];
  var el = {}; ids.forEach(function(i){ el[i] = document.getElementById(i); });
  var out = document.getElementById("ergebnis");

  function bestimme(){
    var t=el.q_tools.checked, h=el.q_haekchen.checked, a=el.q_auth.checked,
        pl=el.q_plugin.checked, an=el.q_angemeldet.checked;
    var key, warn=[];
    if (pl) warn.push(W_PLUGIN);
    if (t)        key = (h||an) ? "mitTools" : "offen";
    else if (a)   key = "unauth";
    else if (h)   { key = "ohneTools"; warn.push(W_Z3); }
    else          key = "absent";
    var z = Z[key];
    out.innerHTML = '<div class="verdict"><h3>' + z[0] + '</h3>' +
      '<p class="step">Naechster Schritt</p><p>' + z[1] + '</p>' +
      warn.map(function(w){ return '<div class="w">' + w + '</div>'; }).join("") +
      '</div>';
  }
  ids.forEach(function(i){ el[i].addEventListener("change", bestimme); });
  bestimme();

  // Der Live-Probe-Knopf erscheint nur beim lokalen Companion. Im Browser auf
  // einer fremden Herkunft scheitert der Abruf an CORS — dann lieber gar nicht
  // anbieten, als leer laufen lassen.
  var lokal = ["127.0.0.1","localhost","[::1]"].indexOf(location.hostname) !== -1;
  if (lokal){
    document.getElementById("modus").textContent = "lokal — Proben aktiv";
    document.getElementById("modus").className = "badge on";
    document.getElementById("probe-ui").hidden = false;
    document.getElementById("cors-hinweis").hidden = true;
    var po = document.getElementById("probe-out");
    document.getElementById("go").addEventListener("click", function(){
      var d = document.getElementById("dom").value.trim();
      if (!d) return;
      po.innerHTML = "<p>pruefe " + d + " …</p>";
      fetch("/api/probe?domain=" + encodeURIComponent(d))
        .then(function(r){ return r.json(); })
        .then(function(r){
          var rows = r.proben.map(function(p){
            return "<tr><td><code>" + (p.status || "ERR") + "</code></td><td>" + p.art +
                   "</td><td style='word-break:break-all'>" + p.url + "</td></tr>";
          }).join("");
          po.innerHTML = '<div class="verdict"><h3>' + r.urteil + "</h3><p>" + r.deutung +
                         "</p><table><tr><th>HTTP</th><th>Art</th><th>URL</th></tr>" +
                         rows + "</table></div>";
        })
        .catch(function(e){ po.innerHTML = "<p>Fehlgeschlagen: " + e + "</p>"; });
    });
    document.getElementById("dom").addEventListener("keydown", function(e){
      if (e.key === "Enter") document.getElementById("go").click();
    });
  }
})();
"""
        ]
    ]

[<EntryPoint>]
let main argv =
    let outputPath = 
        if argv.Length > 0 then argv.[0]
        else "index.html"
    
    let htmlContent = generateDocument() |> renderHtml
    File.WriteAllText(outputPath, htmlContent)
    printfn "HTML file generated at %s" outputPath
    0
