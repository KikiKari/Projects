// abstraction-provenance: {"artifact_sha256": "cce6535254b80dfe6fc2a7b47aac27ebcb351bef4eb8ebb2fa6be68e90f2e2fb", "source_sha256": "6f0520ae03891dc25c6d08a38907c3c9c1c5f8bb7d8a33172bd65cf6a1d074d9", "target_language": "fsharp"}
// sidepanel.html — portiert nach fsharp
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/sidepanel.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

// F#-Programm zur Erzeugung der sidepanel.html-Struktur

open System
open System.IO
open System.Text

type HtmlElement = {
    Tag: string
    Attributes: Map<string, string>
    Children: HtmlNode list
}

and HtmlNode =
    | Element of HtmlElement
    | Text of string

let createElement tag attributes children =
    Element { Tag = tag; Attributes = Map.ofList attributes; Children = children }

let text s = Text s

let html head body =
    createElement "html" ["lang", "de"] [
        head
        body
    ]

let head' =
    createElement "head" [] [
        createElement "meta" ["charset", "utf-8"] []
        createElement "meta" ["name", "viewport"; "content", "width=device-width, initial-scale=1"] []
        createElement "title" [] [text "TikTok LIVE Companion"]
        createElement "link" ["rel", "stylesheet"; "href", "sidepanel.css"] []
    ]

let header' =
    createElement "header" [] [
        createElement "p" ["id", "page-title"; "class", "muted"] [text "Kein TikTok-Tab ausgewählt"]
    ]

let chatSection =
    createElement "section" ["aria-labelledby", "chat-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "chat-heading"] [text "Chat"]
            createElement "div" ["class", "title-actions"] [
                createElement "span" ["id", "chat-led"; "class", "status-led off"; "role", "status"; "aria-label", "Chat inaktiv"; "title", "Chat inaktiv"] []
                createElement "button" ["id", "chat-count"; "class", "count count-button"; "type", "button"; "aria-haspopup", "dialog"; "title", "Gesammelte Chatzeilen öffnen"] [text "0"]
                createElement "button" ["id", "refresh-chat"; "class", "secondary compact"; "title", "Chatanzeige leeren"] [text "Refresh"]
                createElement "button" ["id", "toggle-speech"; "class", "secondary compact"; "aria-pressed", "false"; "aria-label", "Vorlesen"] [text "On"]
                createElement "span" ["id", "speech-led"; "class", "status-led off"; "role", "status"; "aria-label", "Vorlesen inaktiv"; "title", "Vorlesen inaktiv"] []
            ]
        ]
        createElement "div" ["id", "chat-list"; "class", "chat-list empty"; "role", "log"; "aria-live", "polite"; "aria-relevant", "additions"; "aria-label", "Die letzten fünf bereinigten Chatnachrichten"] [text "Noch keine Chatnachrichten erkannt."]
        createElement "p" ["id", "speech-status"; "role", "status"; "class", "inline-status"] [text "Vorlesen ist ausgeschaltet."]
        createElement "div" ["class", "control-label"] [
            createElement "label" ["for", "speech-volume"] [text "Vorleselautstärke"]
            createElement "output" ["id", "speech-volume-output"; "for", "speech-volume"] [text "100%"]
        ]
        createElement "input" ["id", "speech-volume"; "type", "range"; "min", "0"; "max", "100"; "step", "5"; "value", "50"] []
        createElement "div" ["class", "button-row"] [
            createElement "button" ["id", "service-action"; "class", "secondary"] [text "Sprachdienst"]
            createElement "button" ["id", "sherpa-action"; "class", "secondary"] [text "Sherpa"]
            createElement "button" ["id", "open-speech-settings"; "class", "secondary compact settings-button"; "type", "button"; "aria-label", "Erweiterte Einstellungen öffnen"; "aria-haspopup", "dialog"; "title", "Einstellungen"] [text "⚙"]
        ]
        createElement "p" ["id", "service-status"; "class", "inline-status"] [text "Lokaler Sprachdienst noch nicht geprüft."]
        createElement "div" ["id", "service-setup"; "class", "inline-status"; "hidden", ""] [
            createElement "button" ["id", "copy-service-setup"; "class", "secondary compact"] [text "Installation abschließen!"]
        ]
        createElement "label" ["class", "option-row"] [
            createElement "input" ["id", "keep-speech-active"; "type", "checkbox"] []
            text " Permanent aktiv"
        ]
    ]

let topChattersSection =
    createElement "section" ["aria-labelledby", "top-chatters-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "top-chatters-heading"] [text "Top-Chatter"]
            createElement "button" ["id", "open-audience"; "class", "secondary compact"] [text "Zuschauer*innen"]
        ]
        createElement "p" ["id", "team-tag-status"; "class", "inline-status"] [text "Teamkürzel: noch nicht erkannt."]
        createElement "div" ["id", "top-chatters"; "class", "top-chatters empty"] [text "Noch keine Personen im Chat beobachtet."]
        createElement "div" ["id", "top-chatters-actions"; "class", "top-chatters-actions"; "hidden", ""] [
            createElement "button" ["id", "top-chatters-reset"; "class", "top-chatter-link"; "type", "button"; "hidden", ""] [text "Reset"]
            createElement "button" ["id", "top-chatters-more"; "class", "top-chatter-link"; "type", "button"] [text "mehr…"]
        ]
    ]

let pageInfoSection =
    createElement "section" ["id", "page-info-section"; "aria-labelledby", "page-info-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "page-info-heading"] [text "PROFIL-Information"]
            createElement "div" ["class", "title-actions"] [
                createElement "span" ["id", "page-info-source"; "class", "live-indicator"] [text "Metadaten"]
                createElement "button" ["id", "refresh-page-info"; "class", "secondary compact"] [text "Refresh"]
                createElement "button" ["id", "force-page-info"; "class", "secondary compact danger-outline"] [text "Force"]
            ]
        ]
        createElement "div" ["id", "profile-info"; "class", "profile-info"; "hidden", ""] []
        createElement "div" ["id", "summary-info"; "class", "summary-info"] []
    ]

let statsSection =
    createElement "section" ["aria-labelledby", "stats-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "stats-heading"] [text "LIVE-Information"]
            createElement "span" ["id", "stats-live"; "class", "live-indicator"] [text "warte"]
        ]
        createElement "div" ["id", "live-stats"; "class", "status-grid stats-grid"] []
        createElement "p" ["id", "stats-status"; "class", "inline-status"] []
    ]

let hookSection =
    createElement "section" ["aria-labelledby", "hook-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "hook-heading"] [text "Connection"]
            createElement "span" ["id", "hook-led"; "class", "status-led off"; "role", "status"; "aria-label", "Hook inaktiv"; "title", "Hook inaktiv"] []
        ]
        createElement "div" ["class", "button-row"] [
            createElement "button" ["id", "toggle-hook"; "class", "primary"; "aria-label", "Connection"; "aria-pressed", "false"] [text "On"]
            createElement "button" ["id", "reset-tab"; "class", "secondary danger-outline"] [text "Refresh"]
            createElement "button" ["id", "open-embed-live"; "class", "secondary"] [text "Embed"]
            createElement "button" ["id", "open-normal-live"; "class", "secondary"] [text "Browser"]
            createElement "button" ["id", "player-vlc-frame"; "class", "secondary compact"] [text "Player"]
            createElement "button" ["id", "open-connection-settings"; "class", "secondary compact settings-button"; "type", "button"; "aria-label", "Connection-Einstellungen öffnen"; "aria-haspopup", "dialog"] [text "⚙"]
        ]
        createElement "p" ["id", "hook-status"; "class", "inline-status"] []
        createElement "p" ["id", "embed-startup-status"; "class", "inline-status"; "role", "status"; "aria-live", "polite"; "hidden", ""] []
        createElement "button" ["id", "cancel-embed-startup"; "class", "secondary"; "hidden", ""] [text "Embed-Start abbrechen"]
        createElement "label" ["class", "option-row"] [
            createElement "input" ["id", "hook-autostart"; "type", "checkbox"] []
            text " Permanent Hook"
        ]
        createElement "p" ["id", "hook-reconnect-status"; "class", "inline-status"; "role", "status"] [text "Hook-Reconnect: aus"]
        createElement "p" ["id", "player-recovery-status"; "class", "inline-status"; "role", "status"] [text "Player-Recovery: aus"]
    ]

let recommendationsSection =
    createElement "section" ["id", "recommendations-section"; "aria-labelledby", "recommendations-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "recommendations-heading"] [text "LIVE-Empfehlungen"]
            createElement "span" ["id", "recommendation-status"; "class", "live-indicator"] [text "bereit"]
        ]
        createElement "div" ["class", "recommendation-controls"] [
            createElement "label" [] [
                createElement "span" [] [text "Anzahl"]
                createElement "input" ["id", "recommendation-limit"; "type", "number"; "min", "1"; "max", "50"; "step", "1"; "value", "20"; "inputmode", "numeric"] []
            ]
            createElement "label" [] [
                createElement "span" [] [text "Sortierung"]
                createElement "select" ["id", "recommendation-sort"] [
                    createElement "option" ["value", "tiktok"] [text "TikTok-Reihenfolge"]
                    createElement "option" ["value", "viewers"] [text "Zuschauer*innen"]
                ]
            ]
        ]
        createElement "div" ["class", "button-row"] [
            createElement "button" ["id", "scan-recommendations"; "class", "primary"] [text "Empfehlungen scannen"]
            createElement "button" ["id", "cancel-recommendations"; "class", "secondary"; "hidden", ""] [text "Abbrechen"]
        ]
        createElement "p" ["id", "recommendation-progress"; "class", "inline-status"; "aria-live", "polite"] [text "Noch kein Scan gestartet."]
        createElement "div" ["id", "recommendation-list"; "class", "recommendation-list empty"] [text "Noch keine Empfehlungen erfasst."]
        createElement "div" ["id", "recommendation-actions"; "class", "top-chatters-actions"; "hidden", ""] [
            createElement "button" ["id", "recommendation-more"; "class", "top-chatter-link"; "type", "button"] [text "mehr…"]
        ]
    ]

let captionSection =
    createElement "section" ["aria-labelledby", "caption-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "caption-heading"] [text "Titel"]
            createElement "button" ["id", "scan"; "class", "secondary"] [text "Seite prüfen"]
        ]
        createElement "div" ["id", "caption-status"; "class", "status-grid"] []
        createElement "button" ["id", "enable-captions"; "class", "primary"] [text "Untertitel aktivieren"]
        createElement "p" ["id", "caption-action-status"; "role", "status"; "class", "inline-status action-status"] []
    ]

let playerSection =
    createElement "section" ["aria-labelledby", "player-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "player-heading"] [text "Player"]
            createElement "span" ["id", "player-time"; "class", "player-time"] [text "–"]
        ]
        createElement "div" ["class", "player-controls"; "role", "group"; "aria-label", "TikTok-Player steuern"] [
            createElement "button" ["id", "player-play"; "class", "secondary compact"] [text "Pause"]
            createElement "button" ["id", "player-replay"; "class", "secondary compact"] [text "Neu laden"]
            createElement "button" ["id", "player-mute"; "class", "secondary compact"] [text "Stumm"]
            createElement "button" ["id", "player-pip"; "class", "secondary compact"] [text "Bild-in-Bild"]
            createElement "button" ["id", "player-fullscreen"; "class", "secondary compact"] [text "Vollbild"]
            createElement "button" ["id", "player-report"; "class", "secondary compact danger-outline"] [text "Melden öffnen"]
        ]
        createElement "div" ["class", "audio-controls"] [
            createElement "div" ["class", "control-label"] [
                createElement "label" ["for", "player-volume"] [text "Lautstärke"]
                createElement "output" ["id", "player-volume-output"; "for", "player-volume"] [text "–"]
            ]
            createElement "input" ["id", "player-volume"; "type", "range"; "min", "0"; "max", "100"; "step", "1"; "value", "100"] []
            createElement "div" ["class", "audio-meter-row"] [
                createElement "span" [] [text "Spitzenpegel"]
                createElement "strong" ["id", "player-peak"] [text "–"]
            ]
            createElement "label" ["class", "option-row"] [
                createElement "input" ["id", "limiter-enabled"; "type", "checkbox"] []
                text " Pegelschutz aktivieren"
            ]
            createElement "div" ["class", "control-label"] [
                createElement "label" ["for", "limiter-strength"] [text "Schutzstärke"]
                createElement "output" ["id", "limiter-strength-output"; "for", "limiter-strength"] [text "30"]
            ]
            createElement "input" ["id", "limiter-strength"; "type", "range"; "min", "0"; "max", "100"; "step", "1"; "value", "30"] []
        ]
        createElement "p" ["id", "multi-guest-status"; "class", "inline-status"] [text "Verbundene Streams: noch nicht erkannt."]
        createElement "p" ["id", "player-status"; "role", "status"; "class", "inline-status"] [text "Warte auf den TikTok-Player."]
    ]

let songSection =
    createElement "section" ["aria-labelledby", "song-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "song-heading"] [text "Songs"]
            createElement "span" ["id", "song-led"; "class", "status-led off"; "role", "status"; "aria-label", "Songerkennung inaktiv"] []
        ]
        createElement "label" ["class", "option-row"] [
            createElement "input" ["id", "song-enabled"; "type", "checkbox"] []
            text " Songerkennung aktivieren"
        ]
        createElement "button" ["id", "recognize-song"; "class", "primary"; "disabled", ""] [text "Jetzt erkennen"]
        createElement "p" ["id", "song-status"; "class", "inline-status"] []
        createElement "div" ["id", "song-result"; "class", "song-result"; "hidden", ""] []
    ]

let linksSection =
    createElement "section" ["aria-labelledby", "links-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "links-heading"] [text "HAR-Logs"]
            createElement "span" ["id", "media-count"; "class", "count"] [text "0"]
        ]
        createElement "div" ["id", "media-list"; "class", "list empty"] [text "Noch keine FLV-/HLS-Links erkannt."]
        createElement "p" ["class", "hint"] [text "Extern gestarteter VLC liegt außerhalb des Companion-Pegelschutzes."]
    ]

let logSection =
    createElement "section" ["aria-labelledby", "log-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "log-heading"] [text "LIVE-Logs"]
            createElement "span" ["id", "caption-count"; "class", "count"] [text "0"]
        ]
        createElement "div" ["class", "button-row"] [
            createElement "button" ["id", "export-log"; "class", "secondary"] [text "JSON-L-Export"]
            createElement "button" ["id", "export-caption-raw"; "class", "secondary"] [text "RAW-JSON-Export"]
            createElement "button" ["id", "clear"; "class", "ghost"] [text "Anzeige leeren"]
        ]
        createElement "div" ["id", "caption-list"; "class", "list empty"] [text "Noch keine CaptionMessages empfangen."]
    ]

let debugSection =
    createElement "section" ["aria-labelledby", "debug-heading"] [
        createElement "div" ["class", "section-title"] [
            createElement "h2" ["id", "debug-heading"] [text "Debugmodus"]
            createElement "span" ["id", "debug-count"; "class", "count"] [text "0"]
        ]
        createElement "label" ["class", "option-row"] [
            createElement "input" ["id", "debug-enabled"; "type", "checkbox"] []
            text " Diagnoseereignisse für diesen Tab protokollieren"
        ]
        createElement "div" ["class", "button-row"] [
            createElement "button" ["id", "export-debug"; "class", "secondary"] [text "Debug exportieren"]
            createElement "button" ["id", "clear-debug"; "class", "ghost"] [text "Debug leeren"]
        ]
        createElement "p" ["class", "muted small"] []
    ]

let audienceModal =
    createElement "div" ["id", "audience-modal"; "class", "modal-backdrop"; "hidden", ""] [
        createElement "section" ["class", "modal"; "role", "dialog"; "aria-modal", "true"; "aria-labelledby", "audience-heading"] [
            createElement "div" ["class", "section-title"] [
                createElement "h2" ["id", "audience-heading"] [text "Im Chat beobachtete Personen"]
                createElement "button" ["id", "close-audience"; "class", "secondary compact"; "aria-label", "Übersicht schließen"] [text "Schließen"]
            ]
            createElement "p" ["id", "audience-limit"; "class", "inline-status"] []
            createElement "div" ["id", "audience-list"; "class", "audience-list"] []
        ]
    ]

let speechSettingsModal =
    createElement "div" ["id", "speech-settings-modal"; "class", "modal-backdrop"; "hidden", ""] [
        createElement "section" ["class", "modal"; "role", "dialog"; "aria-modal", "true"; "aria-labelledby", "speech-settings-heading"] [
            createElement "div" ["class", "section-title"] [
                createElement "h2" ["id", "speech-settings-heading"] [text "Erweiterte Einstellungen"]
                createElement "button" ["id", "close-speech-settings"; "class", "secondary compact"; "aria-label", "Einstellungen schließen"] [text "Schließen"]
            ]
            createElement "div" ["class", "settings-grid speech-integration-settings"] [
                createElement "label" [] [
                    createElement "span" [] [text "Sprache"]
                    createElement "select" ["id", "speech-language"] [
                        createElement "option" ["value", "auto"] [text "Auto"]
                        createElement "option" ["value", "de-DE"] [text "Deutsch"]
                        createElement "option" ["value", "en-US"] [text "Englisch"]
                        createElement "option" ["value", "ru-RU"] [text "Russisch"]
                        createElement "option" ["value", "uk-UA"] [text "Ukrainisch"]
                        createElement "option" ["value", "bg-BG"] [text "Bulgarisch"]
                        createElement "option" ["value", "sr-RS"] [text "Serbisch"]
                        createElement "option" ["value", "kk-KZ"] [text "Kasachisch"]
                        createElement "option" ["value", "zh-CN"] [text "Chinesisch"]
                        createElement "option" ["value", "ja-JP"] [text "Japanisch"]
                        createElement "option" ["value", "ko-KR"] [text "Koreanisch"]
                        createElement "option" ["value", "ar-JO"] [text "Arabisch"]
                        createElement "option" ["value", "fa-IR"] [text "Persisch"]
                        createElement "option" ["value", "ur-PK"] [text "Urdu"]
                        createElement "option" ["value", "hi-IN"] [text "Hindi"]
                        createElement "option" ["value", "ne-NP"] [text "Nepali"]
                        createElement "option" ["value", "ml-IN"] [text "Malayalam"]
                    ]
                ]
                createElement "label" [] [
                    createElement "span" [] [text "Stimme"]
                    createElement "select" ["id", "speech-voice"] [
                        createElement "option" ["value", ""] [text "Standard"]
                    ]
                ]
                createElement "label" ["id", "audd-token-setting"] [
                    createElement "span" ["id", "audd-token-label"] [
                        text "AudD API-Token (optional - "
                        createElement "a" ["href", "https://audd.io/"; "target", "_blank"; "rel", "noopener noreferrer"] [text "https://AudD.io"]
                        text " Trial/Paid)"
                    ]
                    createElement "input" ["id", "audd-token"; "type", "password"; "autocomplete", "off"; "spellcheck", "false"] []
                ]
                createElement "label" ["id", "pairing-code-setting"] [
                    createElement "span" [] [text "Pairing-Code"]
                    createElement "input" ["id", "pairing-code"; "type", "password"; "autocomplete", "off"; "spellcheck", "false"] []
                ]
                createElement "label" [] [
                    createElement "span" [] [text "Universal API-Key"]
                    createElement "input" ["id", "universal-caption-api-key"; "type", "password"; "autocomplete", "off"; "spellcheck", "false"] []
                ]
            ]
            createElement "label" ["class", "option-row"] [
                createElement "input" ["id", "speak-names"; "type", "checkbox"; "checked", ""] []
                text " Chatnamen sprechen"
            ]
            createElement "label" ["class", "option-row"] [
                createElement "input" ["id", "shorten-names"; "type", "checkbox"] []
                text " Chatnamen kürzen"
            ]
            createElement "label" ["class", "option-row auto-chat-refresh"] [
                createElement "input" ["id", "auto-chat-refresh"; "type", "checkbox"] []
                text " Auto-Chat Refresh "
                createElement "input" ["id", "auto-chat-refresh-minutes"; "type", "number"; "min", "1"; "max", "60"; "step", "1"; "value", "5"; "inputmode", "numeric"; "aria-label", "Auto-Chat-Refresh in Minuten"] []
                createElement "span" [] [text "min."]
            ]
            createElement "label" ["class", "option-row"] [
                createElement "input" ["id", "game-mode"; "type", "checkbox"] []
                text " Game-Mode"
            ]
            createElement "label" ["class", "option-row"] [
                createElement "input" ["id", "filter-external-speech-triggers"; "type", "checkbox"] []
                text " Trigger externer Sprachdienste filtern"
            ]
        ]
    ]

let chatHistoryModal =
    createElement "div" ["id", "chat-history-modal"; "class", "modal-backdrop"; "hidden", ""] [
        createElement "section" ["class", "modal"; "role", "dialog"; "aria-modal", "true"; "aria-labelledby", "chat-history-heading"] [
            createElement "div" ["class", "section-title"] [
                createElement "h2" ["id", "chat-history-heading"] [text "Gesammelte Chatnachrichten"]
                createElement "button" ["id", "close-chat-history"; "class", "secondary compact"; "aria-label", "Chatzeilen schließen"] [text "Schließen"]
            ]
            createElement "p" ["id", "chat-history-limit"; "class", "inline-status"] []
            createElement "div" ["id", "chat-history-list"; "class", "chat-history-list"] []
        ]
    ]

let recommendationModal =
    createElement "div" ["id", "recommendation-modal"; "class", "modal-backdrop"; "hidden", ""] [
        createElement "section" ["class", "modal"; "role", "dialog"; "aria-modal", "true"; "aria-labelledby", "recommendation-modal-heading"] [
            createElement "div" ["class", "section-title"] [
                createElement "h2" ["id", "recommendation-modal-heading"] [text "Gescannte LIVE-Empfehlungen"]
                createElement "button" ["id", "close-recommendations"; "class", "secondary compact"; "aria-label", "Empfehlungen schließen"] [text "Schließen"]
            ]
            createElement "div" ["id", "recommendation-modal-list"; "class", "recommendation-list"] []
        ]
    ]

let notice =
    createElement "p" ["id", "notice"; "role", "alert"; "class", "notice"] []

let connectionSettingsModal =
    createElement "div" ["id", "connection-settings-modal"; "class", "modal-backdrop"; "hidden", ""] [
        createElement "section" ["class", "modal"; "role", "dialog"; "aria-modal", "true"; "aria-labelledby", "connection-settings-heading"] [
            createElement "div" ["class", "section-title"] [
                createElement "h2" ["id", "connection-settings-heading"] [text "Connection-Einstellungen"]
                createElement "button" ["id", "close-connection-settings"; "class", "secondary compact"] [text "Schließen"]
            ]
            createElement "label" ["class", "option-row quick-recover-setting"] [
                createElement "input" ["id", "hook-reconnect"; "type", "checkbox"] []
                text " Hook-Reconnect "
                createElement "input" ["id", "hook-reconnect-seconds"; "type", "number"; "min", "1"; "max", "59"; "step", "1"; "value", "3"; "inputmode", "numeric"; "aria-label", "Hook-Reconnect-Wartezeit in Sekunden"]
                createElement "span" [] [text "Sek."]
            ]
            createElement "label" ["class", "option-row quick-recover-setting"] [
                createElement "input" ["id", "quick-recover"; "type", "checkbox"] []
                text " Player-Recovery "
                createElement "input" ["id", "quick-recover-seconds"; "type", "number"; "min", "1"; "max", "59"; "step", "1"; "value", "3"; "inputmode", "numeric"; "aria-label", "Player-Recovery-Bestätigungszeit in Sekunden"]
                createElement "span" [] [text "Sek."]
            ]
        ]
    ]

let scripts =
    createElement "body" [] [
        header'
        createElement "main" [] [
            chatSection
            topChattersSection
            pageInfoSection
            statsSection
            hookSection
            recommendationsSection
            captionSection
            playerSection
            songSection
            linksSection
            logSection
            debugSection
            audienceModal
            speechSettingsModal
            chatHistoryModal
            recommendationModal
            notice
        ]
        connectionSettingsModal
        createElement "script" ["src", "content-core.js"] []
        createElement "script" ["src", "sidepanel.js"] []
    ]

let doc =
    createElement "!doctype" ["html", ""] [] :: [html head' scripts]

let rec renderHtmlNode (node: HtmlNode) : string =
    match node with
    | Text s -> s
    | Element e ->
        let attrs = 
            e.Attributes
            |> Map.toList
            |> List.map (fun (k, v) -> sprintf "%s=\"%s\"" k v)
            |> String.concat " "
            |> fun s -> if s = "" then "" else " " + s
        
        let children = 
            e.Children
            |> List.map renderHtmlNode
            |> String.concat ""
        
        if e.Tag = "!doctype" then
            sprintf "<!doctype %s>" (Map.find "html" e.Attributes)
        elif List.isEmpty e.Children then
            sprintf "<%s%s>" e.Tag attrs
        else
            sprintf "<%s%s>%s</%s>" e.Tag attrs children

let renderDocument (nodes: HtmlNode list) : string =
    nodes
    |> List.map renderHtmlNode
    |> String.concat "\n"

[<EntryPoint>]
let main argv =
    let outputPath = 
        if argv.Length > 0 then argv.[0]
        else "sidepanel.html"
    
    let content = renderDocument doc
    File.WriteAllText(outputPath, content, Encoding.UTF8)
    printfn "HTML file generated at: %s" outputPath
    0
