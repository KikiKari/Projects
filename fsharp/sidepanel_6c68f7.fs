// abstraction-provenance: {"artifact_sha256": "017921ce35832f00ae60cc8061d8b7e90e6618c85379ba19b3b8f1fca7812729", "source_sha256": "6c68f7375733776fa70f0fd1e48fe739ffdf7c38b6444a8ef7c36fd50e4d08e9", "target_language": "fsharp"}
// sidepanel.html — portiert nach fsharp
// Quelle: html, Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

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

module Html =
    let createElement tag attributes children =
        Element { Tag = tag; Attributes = Map.ofList attributes; Children = children }

    let text s = Text s

    let render (node: HtmlNode) : string =
        let sb = StringBuilder()
        
        let rec renderNode indent node =
            match node with
            | Text t -> 
                if not (String.IsNullOrWhiteSpace t) then
                    sb.Append(indent) |> ignore
                    sb.Append(t) |> ignore
                    sb.AppendLine() |> ignore
            | Element e ->
                sb.Append(indent) |> ignore
                sb.Append("<") |> ignore
                sb.Append(e.Tag) |> ignore
                
                e.Attributes
                |> Map.iter (fun key value ->
                    sb.Append(" ") |> ignore
                    sb.Append(key) |> ignore
                    sb.Append("=\"") |> ignore
                    sb.Append(value) |> ignore
                    sb.Append("\"") |> ignore)
                
                if e.Children.IsEmpty then
                    sb.Append(" />") |> ignore
                    sb.AppendLine() |> ignore
                else
                    sb.Append(">") |> ignore
                    sb.AppendLine() |> ignore
                    
                    e.Children |> List.iter (renderNode (indent + "  "))
                    
                    sb.Append(indent) |> ignore
                    sb.Append("</") |> ignore
                    sb.Append(e.Tag) |> ignore
                    sb.Append(">") |> ignore
                    sb.AppendLine() |> ignore
        
        sb.Append("<!DOCTYPE html>") |> ignore
        sb.AppendLine() |> ignore
        renderNode "" node
        sb.ToString()

let createDocument children =
    Html.createElement "html" [("lang", "de")] [
        Html.createElement "head" [] [
            Html.text "\n  "
            Html.createElement "meta" [("charset", "utf-8")] []
            Html.text "\n  "
            Html.createElement "meta" [("name", "viewport"); ("content", "width=device-width, initial-scale=1")] []
            Html.text "\n  "
            Html.createElement "title" [] [Html.text "TikTok LIVE Companion"]
            Html.text "\n  "
            Html.createElement "link" [("rel", "stylesheet"); ("href", "sidepanel.css")] []
            Html.text "\n  "
            Html.createElement "link" [("rel", "stylesheet"); ("href", "icon-controls.css")] []
            Html.text "\n"
        ]
        Html.createElement "body" [] children
    ]

let createHeader () =
    Html.createElement "header" [] [
        Html.createElement "p" [("id", "page-title"); ("class", "muted")] [Html.text "Kein TikTok-Tab ausgewählt"]
    ]

let createChatSection () =
    Html.createElement "section" [("aria-labelledby", "chat-heading")] [
        Html.createElement "div" [("class", "section-title")] [
            Html.createElement "h2" [("id", "chat-heading")] [Html.text "Chat"]
            Html.createElement "div" [("class", "title-actions")] [
                Html.createElement "span" [("id", "chat-led"); ("class", "status-led off"); ("role", "status"); ("aria-label", "Chat inaktiv"); ("title", "Chat inaktiv")] []
                Html.createElement "button" [("id", "chat-count"); ("class", "count count-button"); ("type", "button"); ("aria-haspopup", "dialog"); ("title", "Gesammelte Chatzeilen öffnen")] [Html.text "0"]
                Html.createElement "button" [("id", "refresh-chat"); ("class", "secondary compact"); ("title", "Chatanzeige leeren")] [Html.text "Reset"]
                Html.createElement "button" [("id", "toggle-speech"); ("class", "secondary compact"); ("aria-pressed", "false"); ("aria-label", "Vorlesen")] [Html.text "On"]
                Html.createElement "span" [("id", "speech-led"); ("class", "status-led off"); ("role", "status"); ("aria-label", "Vorlesen inaktiv"); ("title", "Vorlesen inaktiv")] []
            ]
        ]
        Html.createElement "div" [("id", "chat-list"); ("class", "chat-list empty"); ("role", "log"); ("aria-live", "polite"); ("aria-relevant", "additions"); ("aria-label", "Die letzten fünf bereinigten Chatnachrichten")] [Html.text "Noch keine Chatnachrichten erkannt."]
        Html.createElement "p" [("id", "speech-status"); ("role", "status"); ("class", "inline-status")] [Html.text "Vorlesen ist ausgeschaltet."]
        Html.createElement "div" [("class", "control-label")] [
            Html.createElement "label" [("for", "speech-volume")] [Html.text "Vorleselautstärke"]
            Html.createElement "output" [("id", "speech-volume-output"); ("for", "speech-volume")] [Html.text "100%"]
        ]
        Html.createElement "input" [("id", "speech-volume"); ("type", "range"); ("min", "0"); ("max", "100"); ("step", "5"); ("value", "50")] []
        Html.createElement "div" [("class", "button-row")] [
            Html.createElement "button" [("id", "service-action"); ("class", "secondary")] [Html.text "Sprachdienst"]
            Html.createElement "button" [("id", "sherpa-action"); ("class", "secondary")] [Html.text "Sherpa"]
            Html.createElement "button" [("id", "open-speech-settings"); ("class", "secondary compact settings-button"); ("type", "button"); ("aria-label", "Erweiterte Einstellungen öffnen"); ("aria-haspopup", "dialog"); ("title", "Einstellungen")] []
        ]
        Html.createElement "p" [("id", "service-status"); ("class", "inline-status")] [Html.text "Lokaler Sprachdienst noch nicht geprüft."]
        Html.createElement "div" [("id", "service-setup"); ("class", "inline-status"); ("hidden", "")] [
            Html.createElement "button" [("id", "copy-service-setup"); ("class", "secondary compact")] [Html.text "Installation abschließen!"]
        ]
    ]

let createStatsSection () =
    Html.createElement "section" [("aria-labelledby", "stats-heading")] [
        Html.createElement "div" [("class", "section-title")] [
            Html.createElement "h2" [("id", "stats-heading")] [Html.text "LIVE-Information"]
            Html.createElement "span" [("id", "stats-live"); ("class", "live-indicator")] [Html.text "warte"]
        ]
        Html.createElement "div" [("id", "live-stats"); ("class", "status-grid stats-grid")] []
        Html.createElement "p" [("id", "stats-status"); ("class", "inline-status")] []
    ]

let createPageInfoSection () =
    Html.createElement "section" [("id", "page-info-section"); ("aria-labelledby", "page-info-heading")] [
        Html.createElement "div" [("class", "section-title")] [
            Html.createElement "h2" [("id", "page-info-heading")] [Html.text "PROFIL-Information"]
            Html.createElement "div" [("class", "title-actions")] [
                Html.createElement "span" [("id", "page-info-source"); ("class", "live-indicator")] [Html.text "Metadaten"]
                Html.createElement "button" [("id", "refresh-page-info"); ("class", "secondary compact"); ("title", "Refresh")] [Html.text "Refresh"]
                Html.createElement "button" [("id", "force-page-info"); ("class", "secondary compact danger-outline")] [Html.text "Force"]
            ]
        ]
        Html.createElement "div" [("id", "profile-info"); ("class", "profile-info"); ("hidden", "")] []
        Html.createElement "div" [("id", "summary-info"); ("class", "summary-info")] []
    ]

let createHookSection () =
    Html.createElement "section" [("aria-labelledby", "hook-heading")] [
        Html.createElement "div" [("class", "section-title header-controls")] [
            Html.createElement "h2" [("id", "hook-heading")] [Html.text "Connection"]
            Html.createElement "div" [("class", "title-actions")] [
                Html.createElement "button" [("id", "reset-tab"); ("class", "secondary compact danger-outline"); ("title", "Reset")] [Html.text "Reset"]
                Html.createElement "input" [("id", "hook-autostart"); ("type", "checkbox"); ("aria-label", "Hook dauerhaft"); ("title", "Hook dauerhaft: Off")] []
                Html.createElement "span" [("class", "status-led off"); ("data-switch-status", "hook-autostart"); ("role", "status")] []
            ]
        ]
        Html.createElement "div" [("class", "button-row")] [
            Html.createElement "button" [("id", "toggle-hook"); ("class", "primary"); ("aria-label", "Connection"); ("aria-pressed", "false")] [Html.text "On"]
            Html.createElement "button" [("id", "open-connection-settings"); ("class", "secondary compact settings-button"); ("type", "button"); ("aria-label", "Connection-Einstellungen öffnen"); ("aria-haspopup", "dialog")] []
            Html.createElement "button" [("id", "open-embed-live"); ("class", "secondary")] [Html.text "Embed"]
            Html.createElement "button" [("id", "open-normal-live"); ("class", "secondary")] [Html.text "Browser"]
            Html.createElement "button" [("id", "player-vlc-frame"); ("class", "secondary compact")] [Html.text "Player"]
        ]
        Html.createElement "div" [("class", "connection-status")] [
            Html.createElement "span" [("id", "hook-led"); ("class", "status-led off"); ("role", "status"); ("aria-label", "Hook inaktiv"); ("title", "Hook inaktiv")] []
            Html.createElement "p" [("id", "hook-status"); ("class", "inline-status")] []
        ]
        Html.createElement "p" [("id", "embed-startup-status"); ("class", "inline-status"); ("role", "status"); ("aria-live", "polite"); ("hidden", "")] []
        Html.createElement "button" [("id", "cancel-embed-startup"); ("class", "secondary"); ("hidden", "")] [Html.text "Embed-Start abbrechen"]
        Html.createElement "p" [("id", "hook-reconnect-status"); ("class", "inline-status"); ("role", "status")] [Html.text "Hook-Reconnect: aus"]
        Html.createElement "p" [("id", "player-recovery-status"); ("class", "inline-status"); ("role", "status")] [Html.text "Player-Recovery: aus"]
    ]

let createPlayerSection () =
    Html.createElement "section" [("aria-labelledby", "player-heading")] [
        Html.createElement "div" [("class", "section-title header-controls")] [
            Html.createElement "h2" [("id", "player-heading")] [Html.text "Player"]
            Html.createElement "div" [("class", "title-actions")] [
                Html.createElement "button" [("id", "player-replay"); ("class", "secondary compact"); ("title", "Neu laden")] [Html.text "Neu laden"]
                Html.createElement "input" [("id", "limiter-enabled"); ("type", "checkbox"); ("aria-label", "Pegelschutz"); ("title", "Pegelschutz: Off")] []
                Html.createElement "span" [("class", "status-led off"); ("data-switch-status", "limiter-enabled"); ("role", "status")] []
            ]
        ]
        Html.createElement "div" [("class", "player-controls"); ("role", "group"); ("aria-label", "TikTok-Player steuern")] [
            Html.createElement "button" [("id", "player-play"); ("class", "secondary compact")] [Html.text "Play"]
            Html.createElement "button" [("id", "player-mute"); ("class", "secondary compact")] [Html.text "Mute"]
            Html.createElement "button" [("id", "player-pip"); ("class", "secondary compact")] [Html.text "Bild-in-Bild"]
            Html.createElement "button" [("id", "player-fullscreen"); ("class", "secondary compact")] [Html.text "Vollbild"]
            Html.createElement "button" [("id", "player-report"); ("class", "secondary compact danger-outline")] [Html.text "Meldung"]
        ]
        Html.createElement "div" [("class", "audio-controls")] [
            Html.createElement "div" [("class", "control-label")] [
                Html.createElement "label" [("for", "player-volume")] [Html.text "Lautstärke"]
                Html.createElement "output" [("id", "player-volume-output"); ("for", "player-volume")] [Html.text "–"]
            ]
            Html.createElement "input" [("id", "player-volume"); ("type", "range"); ("min", "0"); ("max", "100"); ("step", "1"); ("value", "100")] []
            Html.createElement "div" [("class", "audio-meter-row")] [
                Html.createElement "span" [] [Html.text "Spitzenpegel"]
                Html.createElement "strong" [("id", "player-peak")] [Html.text "–"]
            ]
            Html.createElement "div" [("class", "control-label")] [
                Html.createElement "label" [("for", "limiter-strength")] [Html.text "Schutzstärke"]
                Html.createElement "output" [("id", "limiter-strength-output"); ("for", "limiter-strength")] [Html.text "30"]
            ]
            Html.createElement "input" [("id", "limiter-strength"); ("type", "range"); ("min", "0"); ("max", "100"); ("step", "1"); ("value", "30")] []
        ]
        Html.createElement "p" [("id", "multi-guest-status"); ("class", "inline-status")] [Html.text "Verbundene Streams: noch nicht erkannt."]
        Html.createElement "p" [("id", "player-status"); ("role", "status"); ("class", "inline-status")] [Html.text "Warte auf den TikTok-Player."]
        Html.createElement "span" [("id", "player-time"); ("class", "player-time"); ("hidden", "")] [Html.text "–"]
    ]

let createTopChattersSection () =
    Html.createElement "section" [("aria-labelledby", "top-chatters-heading")] [
        Html.createElement "div" [("class", "section-title")] [
            Html.createElement "h2" [("id", "top-chatters-heading")] [Html.text "Top-Chatter"]
            Html.createElement "button" [("id", "open-audience"); ("class", "secondary compact")] [Html.text "Zuschauer*innen"]
        ]
        Html.createElement "p" [("id", "team-tag-status"); ("class", "inline-status")] [Html.text "Teamkürzel: noch nicht erkannt."]
        Html.createElement "div" [("id", "top-chatters"); ("class", "top-chatters empty")] [Html.text "Noch keine Personen im Chat beobachtet."]
        Html.createElement "div" [("id", "top-chatters-actions"); ("class", "top-chatters-actions"); ("hidden", "")] [
            Html.createElement "button" [("id", "top-chatters-reset"); ("class", "top-chatter-link"); ("type", "button"); ("hidden", "")] [Html.text "Reset"]
            Html.createElement "button" [("id", "top-chatters-more"); ("class", "top-chatter-link"); ("type", "button")] [Html.text "mehr…"]
        ]
    ]

let createRecommendationsSection () =
    Html.createElement "section" [("id", "recommendations-section"); ("aria-labelledby", "recommendations-heading")] [
        Html.createElement "div" [("class", "section-title")] [
            Html.createElement "h2" [("id", "recommendations-heading")] [Html.text "LIVE-Empfehlungen"]
            Html.createElement "span" [("id", "recommendation-status"); ("class", "live-indicator")] [Html.text "bereit"]
        ]
        Html.createElement "div" [("class", "recommendation-controls")] [
            Html.createElement "label" [] [
                Html.createElement "span" [] [Html.text "Anzahl"]
                Html.createElement "input" [("id", "recommendation-limit"); ("type", "number"); ("min", "1"); ("max", "300"); ("step", "1"); ("value", "20"); ("inputmode", "numeric")] []
            ]
            Html.createElement "label" [] [
                Html.createElement "span" [] [Html.text "Sortierung"]
                Html.createElement "select" [("id", "recommendation-sort")] [
                    Html.createElement "option" [("value", "tiktok")] [Html.text "TikTok-Reihenfolge"]
                    Html.createElement "option" [("value", "viewers")] [Html.text "Zuschauer*innen"]
                ]
            ]
        ]
        Html.createElement "div" [("class", "button-row")] [
            Html.createElement "button" [("id", "scan-recommendations"); ("class", "primary")] [Html.text "Empfehlungen scannen"]
            Html.createElement "button" [("id", "cancel-recommendations"); ("class", "secondary"); ("hidden", "")] [Html.text "Abbrechen"]
        ]
        Html.createElement "p" [("id", "recommendation-progress"); ("class", "inline-status"); ("aria-live", "polite")] [Html.text "Noch kein Scan gestartet."]
        Html.createElement "div" [("id", "recommendation-list"); ("class", "recommendation-list empty")] [Html.text "Noch keine Empfehlungen erfasst."]
        Html.createElement "div" [("id", "recommendation-actions"); ("class", "top-chatters-actions"); ("hidden", "")] [
            Html.createElement "button" [("id", "recommendation-more"); ("class", "top-chatter-link"); ("type", "button")] [Html.text "mehr…"]
        ]
    ]

let createCaptionSection () =
    Html.createElement "section" [("aria-labelledby", "caption-heading")] [
        Html.createElement "div" [("class", "section-title")] [
            Html.createElement "h2" [("id", "caption-heading")] [Html.text "Titel"]
            Html.createElement "button" [("id", "scan"); ("class", "secondary")] [Html.text "Status"]
        ]
        Html.createElement "div" [("id", "caption-status"); ("class", "status-grid")] []
        Html.createElement "button" [("id", "enable-captions"); ("class", "primary")] [Html.text "Untertitel"]
        Html.createElement "p" [("id", "caption-action-status"); ("role", "status"); ("class", "inline-status action-status")] []
    ]

let createSongSection () =
    Html.createElement "section" [("aria-labelledby", "song-heading")] [
        Html.createElement "div" [("class", "section-title header-controls")] [
            Html.createElement "h2" [("id", "song-heading")] [Html.text "Songs"]
            Html.createElement "div" [("class", "title-actions")] [
                Html.createElement "input" [("id", "song-enabled"); ("type", "checkbox"); ("aria-label", "Songerkennung"); ("title", "Songerkennung: Off")] []
                Html.createElement "span" [("id", "song-led"); ("class", "status-led off"); ("data-switch-status", "song-enabled"); ("role", "status"); ("aria-label", "Songerkennung inaktiv")] []
            ]
        ]
        Html.createElement "button" [("id", "recognize-song"); ("class", "primary"); ("disabled", "")] [Html.text "Jetzt erkennen"]
        Html.createElement "p" [("id", "song-status"); ("class", "inline-status")] []
        Html.createElement "div" [("id", "song-result"); ("class", "song-result"); ("hidden", "")] []
    ]

let createLinksSection () =
    Html.createElement "section" [("aria-labelledby", "links-heading")] [
        Html.createElement "div" [("class", "section-title")] [
            Html.createElement "h2" [("id", "links-heading")] [Html.text "HAR-Logs"]
            Html.createElement "span" [("id", "media-count"); ("class", "count")] [Html.text "0"]
        ]
        Html.createElement "div" [("id", "media-list"); ("class", "list empty")] [Html.text "Noch keine FLV-/HLS-Links erkannt."]
    ]

let createLogSection () =
    Html.createElement "section" [("aria-labelledby", "log-heading")] [
        Html.createElement "div" [("class", "section-title header-controls")] [
            Html.createElement "h2" [("id", "log-heading")] [Html.text "LIVE-Logs"]
            Html.createElement "div" [("class", "title-actions")] [
                Html.createElement "span" [("class", "status-led off"); ("data-counter-status", "caption-count"); ("role", "status")] []
                Html.createElement "span" [("id", "caption-count"); ("class", "count")] [Html.text "0"]
                Html.createElement "button" [("id", "clear"); ("class", "ghost compact"); ("title", "Reset")] [Html.text "Reset"]
                Html.createElement "input" [("id", "live-logs-enabled"); ("type", "checkbox"); ("aria-label", "LIVE-Logs"); ("title", "LIVE-Logs: Off")] []
                Html.createElement "span" [("class", "status-led off"); ("data-switch-status", "live-logs-enabled"); ("role", "status"); ("aria-label", "LIVE-Logs: deaktiviert")] []
            ]
        ]
        Html.createElement "div" [("class", "button-row")] [
            Html.createElement "button" [("id", "export-log"); ("class", "secondary")] [Html.text "JSON-L-Export"]
            Html.createElement "button" [("id", "export-caption-raw"); ("class", "secondary")] [Html.text "RAW-JSON-Export"]
        ]
        Html.createElement "div" [("id", "caption-list"); ("class", "list empty")] [Html.text "Noch keine CaptionMessages empfangen."]
    ]

let createDebugSection () =
    Html.createElement "section" [("aria-labelledby", "debug-heading")] [
        Html.createElement "div" [("class", "section-title header-controls")] [
            Html.createElement "h2" [("id", "debug-heading")] [Html.text "Debugmodus"]
            Html.createElement "div" [("class", "title-actions")] [
                Html.createElement "span" [("class", "status-led off"); ("data-counter-status", "debug-count"); ("role", "status")] []
                Html.createElement "span" [("id", "debug-count"); ("class", "count")] [Html.text "0"]
                Html.createElement "button" [("id", "clear-debug"); ("class", "ghost compact"); ("title", "Reset")] [Html.text "Reset"]
                Html.createElement "input" [("id", "debug-enabled"); ("type", "checkbox"); ("aria-label", "Diagnoseereignisse für diesen Tab protokollieren"); ("title", "Diagnoseereignisse für diesen Tab protokollieren: Off")] []
                Html.createElement "span" [("class", "status-led off"); ("data-switch-status", "debug-enabled"); ("role", "status")] []
            ]
        ]
        Html.createElement "div" [("class", "button-row")] [
            Html.createElement "button" [("id", "export-debug"); ("class", "secondary")] [Html.text "Debug exportieren"]
        ]
        Html.createElement "p" [("class", "muted small")] []
    ]

let createModals () =
    [
        Html.createElement "div" [("id", "audience-modal"); ("class", "modal-backdrop"); ("hidden", "")] [
            Html.createElement "section" [("class", "modal"); ("role", "dialog"); ("aria-modal", "true"); ("aria-labelledby", "audience-heading")] [
                Html.createElement "div" [("class", "section-title")] [
                    Html.createElement "h2" [("id", "audience-heading")] [Html.text "Im Chat beobachtete Personen"]
                    Html.createElement "button" [("id", "close-audience"); ("class", "secondary compact"); ("aria-label", "Übersicht schließen")] [Html.text "Schließen"]
                ]
                Html.createElement "p" [("id", "audience-limit"); ("class", "inline-status")] []
                Html.createElement "div" [("id", "audience-list"); ("class", "audience-list")] []
            ]
        ]
        
        Html.createElement "div" [("id", "speech-settings-modal"); ("class", "modal-backdrop"); ("hidden", "")] [
            Html.createElement "section" [("class", "modal"); ("role", "dialog"); ("aria-modal", "true"); ("aria-labelledby", "speech-settings-heading")] [
                Html.createElement "div" [("class", "section-title")] [
                    Html.createElement "h2" [("id", "speech-settings-heading")] [Html.text "Erweiterte Einstellungen"]
                    Html.createElement "button" [("id", "close-speech-settings"); ("class", "secondary compact"); ("aria-label", "Einstellungen schließen")] [Html.text "Schließen"]
                ]
                Html.createElement "div" [("class", "settings-grid speech-integration-settings")] [
                    Html.createElement "label" [("class", "icon-style-setting")] [
                        Html.createElement "span" [] [Html.text "Icon-Stil"]
                        Html.createElement "select" [("id", "icon-style")] [
                            Html.createElement "option" [("value", "plastisch")] [Html.text "3D / Plastisch"]
                            Html.createElement "option" [("value", "glass")] [Html.text "Glass / Realistisch"]
                            Html.createElement "option" [("value", "linear")] [Html.text "Minimal / Linear"]
                        ]
                    ]
                    Html.createElement "label" [] [
                        Html.createElement "span" [] [Html.text "Sprache"]
                        Html.createElement "select" [("id", "speech-language")] [
                            Html.createElement "option" [("value", "auto")] [Html.text "Auto"]
                            Html.createElement "option" [("value", "de-DE")] [Html.text "Deutsch"]
                            Html.createElement "option" [("value", "en-US")] [Html.text "Englisch"]
                            Html.createElement "option" [("value", "ru-RU")] [Html.text "Russisch"]
                            Html.createElement "option" [("value", "uk-UA")] [Html.text "Ukrainisch"]
                            Html.createElement "option" [("value", "bg-BG")] [Html.text "Bulgarisch"]
                            Html.createElement "option" [("value", "sr-RS")] [Html.text "Serbisch"]
                            Html.createElement "option" [("value", "kk-KZ")] [Html.text "Kasachisch"]
                            Html.createElement "option" [("value", "zh-CN")] [Html.text "Chinesisch"]
                            Html.createElement "option" [("value", "ja-JP")] [Html.text "Japanisch"]
                            Html.createElement "option" [("value", "ko-KR")] [Html.text "Koreanisch"]
                            Html.createElement "option" [("value", "ar-JO")] [Html.text "Arabisch"]
                            Html.createElement "option" [("value", "fa-IR")] [Html.text "Persisch"]
                            Html.createElement "option" [("value", "ur-PK")] [Html.text "Urdu"]
                            Html.createElement "option" [("value", "hi-IN")] [Html.text "Hindi"]
                            Html.createElement "option" [("value", "ne-NP")] [Html.text "Nepali"]
                            Html.createElement "option" [("value", "ml-IN")] [Html.text "Malayalam"]
                        ]
                    ]
                    Html.createElement "label" [] [
                        Html.createElement "span" [] [Html.text "Stimme"]
                        Html.createElement "select" [("id", "speech-voice")] [
                            Html.createElement "option" [("value", "")] [Html.text "Standard"]
                        ]
                    ]
                    Html.createElement "label" [("id", "audd-token-setting")] [
                        Html.createElement "span" [("id", "audd-token-label")] [
                            Html.text "AudD API-Token (optional - "
                            Html.createElement "a" [("href", "https://audd.io/"); ("target", "_blank"); ("rel", "noopener noreferrer")] [Html.text "https://AudD.io"]
                            Html.text " Trial/Paid)"
                        ]
                        Html.createElement "input" [("id", "audd-token"); ("type", "password"); ("autocomplete", "off"); ("spellcheck", "false")] []
                    ]
                    Html.createElement "label" [("id", "pairing-code-setting")] [
                        Html.createElement "span" [] [Html.text "Pairing-Code"]
                        Html.createElement "input" [("id", "pairing-code"); ("type", "password"); ("autocomplete", "off"); ("spellcheck", "false")] []
                    ]
                    Html.createElement "label" [] [
                        Html.createElement "span" [] [Html.text "Universal API-Key"]
                        Html.createElement "input" [("id", "universal-caption-api-key"); ("type", "password"); ("autocomplete", "off"); ("spellcheck", "false")] []
                    ]
                ]
                Html.createElement "label" [("class", "option-row")] [
                    Html.createElement "input" [("id", "speak-names"); ("type", "checkbox"); ("checked", "")] []
                    Html.text " Chatnamen sprechen"
                ]
                Html.createElement "label" [("class", "option-row")] [
                    Html.createElement "input" [("id", "shorten-names"); ("type", "checkbox")] []
                    Html.text " Chatnamen kürzen"
                ]
                Html.createElement "label" [("class", "option-row auto-chat-refresh")] [
                    Html.createElement "input" [("id", "auto-chat-refresh"); ("type", "checkbox")] []
                    Html.text " Auto-Chat Refresh "
                    Html.createElement "input" [("id", "auto-chat-refresh-minutes"); ("type", "number"); ("min", "1"); ("max", "60"); ("step", "1"); ("value", "5"); ("inputmode", "numeric"); ("aria-label", "Auto-Chat-Refresh in Minuten")] []
                    Html.createElement "span" [] [Html.text "min."]
                ]
                Html.createElement "label" [("class", "option-row")] [
                    Html.createElement "input" [("id", "game-mode"); ("type", "checkbox")] []
                    Html.text " Game-Mode (Spam-, Emoji, usw. Chatfilter)"
                ]
                Html.createElement "div" [("class", "option-row external-speech-trigger-row")] [
                    Html.createElement "label" [] [
                        Html.createElement "input" [("id", "filter-external-speech-triggers"); ("type", "checkbox")] []
                        Html.text " Trigger filtern (ext. Sprachdienste)"
                    ]
                    Html.createElement "input" [("id", "external-speech-trigger-characters"); ("type", "text"); ("value", "."); ("maxlength", "10"); ("aria-label", "Triggerzeichen, maximal fünf Sonderzeichen"); ("autocomplete", "off"); ("spellcheck", "false")] []
                ]
                Html.createElement "label" [("class", "option-row")] [
                    Html.createElement "input" [("id", "keep-speech-active"); ("type", "checkbox"); ("aria-label", "Vorlesen dauerhaft"); ("title", "Vorlesen dauerhaft: Off")] []
                    Html.text " Vorlesen dauerhaft"
                ]
            ]
        ]
        
        Html.createElement "div" [("id", "chat-history-modal"); ("class", "modal-backdrop"); ("hidden", "")] [
            Html.createElement "section" [("class", "modal"); ("role", "dialog"); ("aria-modal", "true"); ("aria-labelledby", "chat-history-heading")] [
                Html.createElement "div" [("class", "section-title")] [
                    Html.createElement "h2" [("id", "chat-history-heading")] [Html.text "Gesammelte Chatnachrichten"]
                    Html.createElement "button" [("id", "close-chat-history"); ("class", "secondary compact"); ("aria-label", "Chatzeilen schließen")] [Html.text "Schließen"]
                ]
                Html.createElement "p" [("id", "chat-history-limit"); ("class", "inline-status")] []
                Html.createElement "div" [("id", "chat-history-list"); ("class", "chat-history-list")] []
            ]
        ]
        
        Html.createElement "div" [("id", "recommendation-modal"); ("class", "modal-backdrop"); ("hidden", "")] [
            Html.createElement "section" [("class", "modal"); ("role", "dialog"); ("aria-modal", "true"); ("aria-labelledby", "recommendation-modal-heading")] [
                Html.createElement "div" [("class", "section-title")] [
                    Html.createElement "h2" [("id", "recommendation-modal-heading")] [Html.text "Gescannte LIVE-Empfehlungen"]
                    Html.createElement "button" [("id", "close-recommendations"); ("class", "secondary compact"); ("aria-label", "Empfehlungen schließen")] [Html.text "Schließen"]
                ]
                Html.createElement "div" [("id", "recommendation-modal-list"); ("class", "recommendation-list")] []
            ]
        ]
        
        Html.createElement "p" [("id", "notice"); ("role", "alert"); ("class", "notice")] []
    ]

let createConnectionSettingsModal () =
    Html.createElement "div" [("id", "connection-settings-modal"); ("class", "modal-backdrop"); ("hidden", "")] [
        Html.createElement "section" [("class", "modal"); ("role", "dialog"); ("aria-modal", "true"); ("aria-labelledby", "connection-settings-heading")] [
            Html.createElement "div" [("class", "section-title")] [
                Html.createElement "h2" [("id", "connection-settings-heading")] [Html.text "Connection-Einstellungen"]
                Html.createElement "button" [("id", "close-connection-settings"); ("class", "secondary compact")] [Html.text "Schließen"]
            ]
            Html.createElement "label" [("class", "option-row quick-recover-setting")] [
                Html.createElement "input" [("id", "hook-reconnect"); ("type", "checkbox")] []
                Html.text " Hook-Reconnect "
                Html.createElement "input" [("id", "hook-reconnect-seconds"); ("type", "number"); ("min", "1"); ("max", "59"); ("step", "1"); ("value", "3"); ("inputmode", "numeric"); ("aria-label", "Hook-Reconnect-Wartezeit in Sekunden")] []
                Html.createElement "span" [] [Html.text "Sek."]
            ]
            Html.createElement "label" [("class", "option-row quick-recover-setting")] [
                Html.createElement "input" [("id", "quick-recover"); ("type", "checkbox")] []
                Html.text " Player-Recovery "
                Html.createElement "input" [("id", "quick-recover-seconds"); ("type", "number"); ("min", "1"); ("max", "59"); ("step", "1"); ("value", "3"); ("inputmode", "numeric"); ("aria-label", "Player-Recovery-Bestätigungszeit in Sekunden")] []
                Html.createElement "span" [] [Html.text "Sek."]
            ]
        ]
    ]

let createScripts () =
    [
        Html.createElement "script" [("src", "content-core.js")] []
        Html.createElement "script" [("src", "sidepanel.js")] []
        Html.createElement "script" [("src", "icon-controls.js")] []
    ]

let generateSidePanel () =
    createDocument [
        createHeader ()
        Html.createElement "main" [] [
            createChatSection ()
            createStatsSection ()
            createPageInfoSection ()
            createHookSection ()
            createPlayerSection ()
            createTopChattersSection ()
            createRecommendationsSection ()
            createCaptionSection ()
            createSongSection ()
            createLinksSection ()
            createLogSection ()
            createDebugSection ()
        ] @ createModals() @ [createConnectionSettingsModal()] @ createScripts()
    ]

[<EntryPoint>]
let main argv =
    try
        let outputPath = 
            if argv.Length > 0 then argv.[0] 
            else "sidepanel-generated.html"
            
        let document = generateSidePanel()
        let htmlContent = Html.render document
        
        File.WriteAllText(outputPath, htmlContent, Encoding.UTF8)
        printfn "HTML file generated successfully at %s" outputPath
        0
    with
    | ex ->
        eprintfn "Error generating HTML file: %s" ex.Message
        1
