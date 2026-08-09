#!/usr/bin/env pwsh
# sidepanel.html — portiert nach powershell
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/sidepanel.html
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates an HTML file named sidepanel.html with a complex UI structure.
.DESCRIPTION
    This PowerShell script creates the complete HTML structure for a TikTok LIVE Companion
    side panel interface. It builds the document programmatically using PowerShell's
    XML handling capabilities and outputs it to a file specified by the -OutputPath parameter.
.PARAMETER OutputPath
    The path where the generated HTML file will be saved.
.EXAMPLE
    .\Generate-SidePanel.ps1 -OutputPath "C:\temp\sidepanel.html"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Create the HTML document structure
$html = New-Object System.Xml.XmlDocument

# Create doctype (PowerShell doesn't directly support this, so we'll add it manually later)
# Add root html element with language attribute
$htmlElement = $html.CreateElement("html")
$htmlElement.SetAttribute("lang", "de")
$html.AppendChild($htmlElement) | Out-Null

# Create head section
$head = $html.CreateElement("head")
$htmlElement.AppendChild($head) | Out-Null

$metaCharset = $html.CreateElement("meta")
$metaCharset.SetAttribute("charset", "utf-8")
$head.AppendChild($metaCharset) | Out-Null

$metaViewport = $html.CreateElement("meta")
$metaViewport.SetAttribute("name", "viewport")
$metaViewport.SetAttribute("content", "width=device-width, initial-scale=1")
$head.AppendChild($metaViewport) | Out-Null

$title = $html.CreateElement("title")
$title.InnerText = "TikTok LIVE Companion"
$head.AppendChild($title) | Out-Null

$link = $html.CreateElement("link")
$link.SetAttribute("rel", "stylesheet")
$link.SetAttribute("href", "sidepanel.css")
$head.AppendChild($link) | Out-Null

# Create body section
$body = $html.CreateElement("body")
$htmlElement.AppendChild($body) | Out-Null

# Header section
$header = $html.CreateElement("header")
$body.AppendChild($header) | Out-Null

$headerP = $html.CreateElement("p")
$headerP.SetAttribute("id", "page-title")
$headerP.SetAttribute("class", "muted")
$headerP.InnerText = "Kein TikTok-Tab ausgewählt"
$header.AppendChild($headerP) | Out-Null

# Main content
$main = $html.CreateElement("main")
$body.AppendChild($main) | Out-Null

# Chat section
$chatSection = $html.CreateElement("section")
$chatSection.SetAttribute("aria-labelledby", "chat-heading")
$main.AppendChild($chatSection) | Out-Null

$chatDiv = $html.CreateElement("div")
$chatDiv.SetAttribute("class", "section-title")
$chatSection.AppendChild($chatDiv) | Out-Null

$chatH2 = $html.CreateElement("h2")
$chatH2.SetAttribute("id", "chat-heading")
$chatH2.InnerText = "Chatzeilen"
$chatDiv.AppendChild($chatH2) | Out-Null

$titleActions = $html.CreateElement("div")
$titleActions.SetAttribute("class", "title-actions")
$chatDiv.AppendChild($titleActions) | Out-Null

$chatLed = $html.CreateElement("span")
$chatLed.SetAttribute("id", "chat-led")
$chatLed.SetAttribute("class", "status-led off")
$chatLed.SetAttribute("role", "status")
$chatLed.SetAttribute("aria-label", "Chat inaktiv")
$chatLed.SetAttribute("title", "Chat inaktiv")
$titleActions.AppendChild($chatLed) | Out-Null

$chatCount = $html.CreateElement("button")
$chatCount.SetAttribute("id", "chat-count")
$chatCount.SetAttribute("class", "count count-button")
$chatCount.SetAttribute("type", "button")
$chatCount.SetAttribute("aria-haspopup", "dialog")
$chatCount.SetAttribute("title", "Gesammelte Chatzeilen öffnen")
$chatCount.InnerText = "0"
$titleActions.AppendChild($chatCount) | Out-Null

$refreshChat = $html.CreateElement("button")
$refreshChat.SetAttribute("id", "refresh-chat")
$refreshChat.SetAttribute("class", "secondary compact")
$refreshChat.SetAttribute("title", "Chatanzeige leeren")
$refreshChat.InnerText = "Refresh"
$titleActions.AppendChild($refreshChat) | Out-Null

$toggleSpeech = $html.CreateElement("button")
$toggleSpeech.SetAttribute("id", "toggle-speech")
$toggleSpeech.SetAttribute("class", "secondary compact")
$toggleSpeech.SetAttribute("aria-pressed", "false")
$toggleSpeech.InnerText = "Vorlesen an"
$titleActions.AppendChild($toggleSpeech) | Out-Null

$speechLed = $html.CreateElement("span")
$speechLed.SetAttribute("id", "speech-led")
$speechLed.SetAttribute("class", "status-led off")
$speechLed.SetAttribute("role", "status")
$speechLed.SetAttribute("aria-label", "Vorlesen inaktiv")
$speechLed.SetAttribute("title", "Vorlesen inaktiv")
$titleActions.AppendChild($speechLed) | Out-Null

$chatList = $html.CreateElement("div")
$chatList.SetAttribute("id", "chat-list")
$chatList.SetAttribute("class", "chat-list empty")
$chatList.SetAttribute("role", "log")
$chatList.SetAttribute("aria-live", "polite")
$chatList.SetAttribute("aria-relevant", "additions")
$chatList.SetAttribute("aria-label", "Die letzten fünf bereinigten Chatnachrichten")
$chatList.InnerText = "Noch keine Chatnachrichten erkannt."
$chatSection.AppendChild($chatList) | Out-Null

$speechStatus = $html.CreateElement("p")
$speechStatus.SetAttribute("id", "speech-status")
$speechStatus.SetAttribute("role", "status")
$speechStatus.SetAttribute("class", "inline-status")
$speechStatus.InnerText = "Vorlesen ist ausgeschaltet."
$chatSection.AppendChild($speechStatus) | Out-Null

$controlLabel1 = $html.CreateElement("div")
$controlLabel1.SetAttribute("class", "control-label")
$chatSection.AppendChild($controlLabel1) | Out-Null

$labelForVolume = $html.CreateElement("label")
$labelForVolume.SetAttribute("for", "speech-volume")
$labelForVolume.InnerText = "Vorleselautstärke"
$controlLabel1.AppendChild($labelForVolume) | Out-Null

$outputVolume = $html.CreateElement("output")
$outputVolume.SetAttribute("id", "speech-volume-output")
$outputVolume.SetAttribute("for", "speech-volume")
$outputVolume.InnerText = "100%"
$controlLabel1.AppendChild($outputVolume) | Out-Null

$inputVolume = $html.CreateElement("input")
$inputVolume.SetAttribute("id", "speech-volume")
$inputVolume.SetAttribute("type", "range")
$inputVolume.SetAttribute("min", "0")
$inputVolume.SetAttribute("max", "100")
$inputVolume.SetAttribute("step", "5")
$inputVolume.SetAttribute("value", "50")
$chatSection.AppendChild($inputVolume) | Out-Null

$speechSettings = $html.CreateElement("div")
$speechSettings.SetAttribute("class", "settings-grid speech-settings")
$chatSection.AppendChild($speechSettings) | Out-Null

$languageLabel = $html.CreateElement("label")
$speechSettings.AppendChild($languageLabel) | Out-Null

$langSpan = $html.CreateElement("span")
$langSpan.InnerText = "Sprache"
$languageLabel.AppendChild($langSpan) | Out-Null

$langSelect = $html.CreateElement("select")
$langSelect.SetAttribute("id", "speech-language")
$languageLabel.AppendChild($langSelect) | Out-Null

$langOptions = @(
    @{value="auto"; text="Auto"},
    @{value="de-DE"; text="Deutsch"},
    @{value="en-US"; text="Englisch"},
    @{value="ru-RU"; text="Russisch"},
    @{value="uk-UA"; text="Ukrainisch"},
    @{value="bg-BG"; text="Bulgarisch"},
    @{value="sr-RS"; text="Serbisch"},
    @{value="kk-KZ"; text="Kasachisch"},
    @{value="zh-CN"; text="Chinesisch"},
    @{value="ja-JP"; text="Japanisch"},
    @{value="ko-KR"; text="Koreanisch"},
    @{value="ar-JO"; text="Arabisch"},
    @{value="fa-IR"; text="Persisch"},
    @{value="ur-PK"; text="Urdu"},
    @{value="hi-IN"; text="Hindi"},
    @{value="ne-NP"; text="Nepali"},
    @{value="ml-IN"; text="Malayalam"}
)

foreach ($option in $langOptions) {
    $opt = $html.CreateElement("option")
    $opt.SetAttribute("value", $option.value)
    $opt.InnerText = $option.text
    $langSelect.AppendChild($opt) | Out-Null
}

$voiceLabel = $html.CreateElement("label")
$speechSettings.AppendChild($voiceLabel) | Out-Null

$voiceSpan = $html.CreateElement("span")
$voiceSpan.InnerText = "Stimme"
$voiceLabel.AppendChild($voiceSpan) | Out-Null

$voiceSelect = $html.CreateElement("select")
$voiceSelect.SetAttribute("id", "speech-voice")
$voiceLabel.AppendChild($voiceSelect) | Out-Null

$voiceOption = $html.CreateElement("option")
$voiceOption.SetAttribute("value", "")
$voiceOption.InnerText = "Standard"
$voiceSelect.AppendChild($voiceOption) | Out-Null

$auddTokenLabel = $html.CreateElement("label")
$auddTokenLabel.SetAttribute("id", "audd-token-setting")
$speechSettings.AppendChild($auddTokenLabel) | Out-Null

$auddTokenSpan = $html.CreateElement("span")
$auddTokenSpan.SetAttribute("id", "audd-token-label")
$auddTokenSpan.InnerXml = 'AudD API-Token (optional - <a href="https://audd.io/" target="_blank" rel="noopener noreferrer">https://AudD.io</a> Trial/Paid )'
$auddTokenLabel.AppendChild($auddTokenSpan) | Out-Null

$auddTokenInput = $html.CreateElement("input")
$auddTokenInput.SetAttribute("id", "audd-token")
$auddTokenInput.SetAttribute("type", "password")
$auddTokenInput.SetAttribute("autocomplete", "off")
$auddTokenInput.SetAttribute("spellcheck", "false")
$auddTokenLabel.AppendChild($auddTokenInput) | Out-Null

$pairingCodeLabel = $html.CreateElement("label")
$pairingCodeLabel.SetAttribute("id", "pairing-code-setting")
$speechSettings.AppendChild($pairingCodeLabel) | Out-Null

$pairingCodeSpan = $html.CreateElement("span")
$pairingCodeSpan.InnerText = "Pairing-Code"
$pairingCodeLabel.AppendChild($pairingCodeSpan) | Out-Null

$pairingCodeInput = $html.CreateElement("input")
$pairingCodeInput.SetAttribute("id", "pairing-code")
$pairingCodeInput.SetAttribute("type", "password")
$pairingCodeInput.SetAttribute("autocomplete", "off")
$pairingCodeInput.SetAttribute("spellcheck", "false")
$pairingCodeLabel.AppendChild($pairingCodeInput) | Out-Null

$buttonRow1 = $html.CreateElement("div")
$buttonRow1.SetAttribute("class", "button-row")
$chatSection.AppendChild($buttonRow1) | Out-Null

$serviceAction = $html.CreateElement("button")
$serviceAction.SetAttribute("id", "service-action")
$serviceAction.SetAttribute("class", "secondary")
$serviceAction.InnerText = "Sprachdienst installieren"
$buttonRow1.AppendChild($serviceAction) | Out-Null

$sherpaAction = $html.CreateElement("button")
$sherpaAction.SetAttribute("id", "sherpa-action")
$sherpaAction.SetAttribute("class", "secondary")
$sherpaAction.InnerText = "Sherpa installieren"
$buttonRow1.AppendChild($sherpaAction) | Out-Null

$serviceStatus = $html.CreateElement("p")
$serviceStatus.SetAttribute("id", "service-status")
$serviceStatus.SetAttribute("class", "inline-status")
$serviceStatus.InnerText = "Lokaler Sprachdienst noch nicht geprüft."
$chatSection.AppendChild($serviceStatus) | Out-Null

$serviceSetup = $html.CreateElement("div")
$serviceSetup.SetAttribute("id", "service-setup")
$serviceSetup.SetAttribute("class", "inline-status")
$serviceSetup.SetAttribute("hidden", "")
$chatSection.AppendChild($serviceSetup) | Out-Null

$copyServiceSetup = $html.CreateElement("button")
$copyServiceSetup.SetAttribute("id", "copy-service-setup")
$copyServiceSetup.SetAttribute("class", "secondary compact")
$copyServiceSetup.InnerText = "Installation abschließen!"
$serviceSetup.AppendChild($copyServiceSetup) | Out-Null

$optionRow1 = $html.CreateElement("label")
$optionRow1.SetAttribute("class", "option-row")
$chatSection.AppendChild($optionRow1) | Out-Null

$speakNames = $html.CreateElement("input")
$speakNames.SetAttribute("id", "speak-names")
$speakNames.SetAttribute("type", "checkbox")
$speakNames.SetAttribute("checked", "")
$optionRow1.AppendChild($speakNames) | Out-Null

$speakNamesText = $html.CreateTextNode(" Chatnamen sprechen")
$optionRow1.AppendChild($speakNamesText) | Out-Null

$optionRow2 = $html.CreateElement("label")
$optionRow2.SetAttribute("class", "option-row")
$chatSection.AppendChild($optionRow2) | Out-Null

$shortenNames = $html.CreateElement("input")
$shortenNames.SetAttribute("id", "shorten-names")
$shortenNames.SetAttribute("type", "checkbox")
$optionRow2.AppendChild($shortenNames) | Out-Null

$shortenNamesText = $html.CreateTextNode(" Chatnamen kürzen")
$optionRow2.AppendChild($shortenNamesText) | Out-Null

$optionRow3 = $html.CreateElement("label")
$optionRow3.SetAttribute("class", "option-row")
$chatSection.AppendChild($optionRow3) | Out-Null

$gameMode = $html.CreateElement("input")
$gameMode.SetAttribute("id", "game-mode")
$gameMode.SetAttribute("type", "checkbox")
$optionRow3.AppendChild($gameMode) | Out-Null

$gameModeText = $html.CreateTextNode(" Game-Mode")
$optionRow3.AppendChild($gameModeText) | Out-Null

$optionRow4 = $html.CreateElement("label")
$optionRow4.SetAttribute("class", "option-row auto-chat-refresh")
$chatSection.AppendChild($optionRow4) | Out-Null

$autoChatRefresh = $html.CreateElement("input")
$autoChatRefresh.SetAttribute("id", "auto-chat-refresh")
$autoChatRefresh.SetAttribute("type", "checkbox")
$optionRow4.AppendChild($autoChatRefresh) | Out-Null

$autoChatRefreshText = $html.CreateTextNode(" Auto-Chat Refresh ")
$optionRow4.AppendChild($autoChatRefreshText) | Out-Null

$autoChatRefreshMinutes = $html.CreateElement("input")
$autoChatRefreshMinutes.SetAttribute("id", "auto-chat-refresh-minutes")
$autoChatRefreshMinutes.SetAttribute("type", "number")
$autoChatRefreshMinutes.SetAttribute("min", "1")
$autoChatRefreshMinutes.SetAttribute("max", "60")
$autoChatRefreshMinutes.SetAttribute("step", "1")
$autoChatRefreshMinutes.SetAttribute("value", "5")
$autoChatRefreshMinutes.SetAttribute("inputmode", "numeric")
$autoChatRefreshMinutes.SetAttribute("aria-label", "Auto-Chat-Refresh in Minuten")
$optionRow4.AppendChild($autoChatRefreshMinutes) | Out-Null

$autoChatRefreshMinSpan = $html.CreateElement("span")
$autoChatRefreshMinSpan.InnerText = "min."
$optionRow4.AppendChild($autoChatRefreshMinSpan) | Out-Null

$optionRow5 = $html.CreateElement("label")
$optionRow5.SetAttribute("class", "option-row")
$chatSection.AppendChild($optionRow5) | Out-Null

$keepSpeechActive = $html.CreateElement("input")
$keepSpeechActive.SetAttribute("id", "keep-speech-active")
$keepSpeechActive.SetAttribute("type", "checkbox")
$optionRow5.AppendChild($keepSpeechActive) | Out-Null

$keepSpeechActiveText = $html.CreateTextNode(" Permanent aktiv")
$optionRow5.AppendChild($keepSpeechActiveText) | Out-Null

# Top Chatters section
$topChattersSection = $html.CreateElement("section")
$topChattersSection.SetAttribute("aria-labelledby", "top-chatters-heading")
$main.AppendChild($topChattersSection) | Out-Null

$topChattersDiv = $html.CreateElement("div")
$topChattersDiv.SetAttribute("class", "section-title")
$topChattersSection.AppendChild($topChattersDiv) | Out-Null

$topChattersH2 = $html.CreateElement("h2")
$topChattersH2.SetAttribute("id", "top-chatters-heading")
$topChattersH2.InnerText = "Top-Chatter"
$topChattersDiv.AppendChild($topChattersH2) | Out-Null

$openAudience = $html.CreateElement("button")
$openAudience.SetAttribute("id", "open-audience")
$openAudience.SetAttribute("class", "secondary compact")
$openAudience.InnerText = "Zuschauer*innen"
$topChattersDiv.AppendChild($openAudience) | Out-Null

$teamTagStatus = $html.CreateElement("p")
$teamTagStatus.SetAttribute("id", "team-tag-status")
$teamTagStatus.SetAttribute("class", "inline-status")
$teamTagStatus.InnerText = "Teamkürzel: noch nicht erkannt."
$topChattersSection.AppendChild($teamTagStatus) | Out-Null

$topChatters = $html.CreateElement("div")
$topChatters.SetAttribute("id", "top-chatters")
$topChatters.SetAttribute("class", "top-chatters empty")
$topChatters.InnerText = "Noch keine Personen im Chat beobachtet."
$topChattersSection.AppendChild($topChatters) | Out-Null

$topChattersActions = $html.CreateElement("div")
$topChattersActions.SetAttribute("id", "top-chatters-actions")
$topChattersActions.SetAttribute("class", "top-chatters-actions")
$topChattersActions.SetAttribute("hidden", "")
$topChattersSection.AppendChild($topChattersActions) | Out-Null

$topChattersReset = $html.CreateElement("button")
$topChattersReset.SetAttribute("id", "top-chatters-reset")
$topChattersReset.SetAttribute("class", "top-chatter-link")
$topChattersReset.SetAttribute("type", "button")
$topChattersReset.SetAttribute("hidden", "")
$topChattersReset.InnerText = "Reset"
$topChattersActions.AppendChild($topChattersReset) | Out-Null

$topChattersMore = $html.CreateElement("button")
$topChattersMore.SetAttribute("id", "top-chatters-more")
$topChattersMore.SetAttribute("class", "top-chatter-link")
$topChattersMore.SetAttribute("type", "button")
$topChattersMore.InnerText = "mehr…"
$topChattersActions.AppendChild($topChattersMore) | Out-Null

# Page Info section
$pageInfoSection = $html.CreateElement("section")
$pageInfoSection.SetAttribute("id", "page-info-section")
$pageInfoSection.SetAttribute("aria-labelledby", "page-info-heading")
$main.AppendChild($pageInfoSection) | Out-Null

$pageInfoDiv = $html.CreateElement("div")
$pageInfoDiv.SetAttribute("class", "section-title")
$pageInfoSection.AppendChild($pageInfoDiv) | Out-Null

$pageInfoH2 = $html.CreateElement("h2")
$pageInfoH2.SetAttribute("id", "page-info-heading")
$pageInfoH2.InnerText = "Seiteninformationen"
$pageInfoDiv.AppendChild($pageInfoH2) | Out-Null

$pageInfoActions = $html.CreateElement("div")
$pageInfoActions.SetAttribute("class", "title-actions")
$pageInfoDiv.AppendChild($pageInfoActions) | Out-Null

$pageInfoSource = $html.CreateElement("span")
$pageInfoSource.SetAttribute("id", "page-info-source")
$pageInfoSource.SetAttribute("class", "live-indicator")
$pageInfoSource.InnerText = "Metadaten"
$pageInfoActions.AppendChild($pageInfoSource) | Out-Null

$refreshPageInfo = $html.CreateElement("button")
$refreshPageInfo.SetAttribute("id", "refresh-page-info")
$refreshPageInfo.SetAttribute("class", "secondary compact")
$refreshPageInfo.InnerText = "Refresh"
$pageInfoActions.AppendChild($refreshPageInfo) | Out-Null

$forcePageInfo = $html.CreateElement("button")
$forcePageInfo.SetAttribute("id", "force-page-info")
$forcePageInfo.SetAttribute("class", "secondary compact danger-outline")
$forcePageInfo.InnerText = "Force"
$pageInfoActions.AppendChild($forcePageInfo) | Out-Null

$profileInfo = $html.CreateElement("div")
$profileInfo.SetAttribute("id", "profile-info")
$profileInfo.SetAttribute("class", "profile-info")
$profileInfo.SetAttribute("hidden", "")
$pageInfoSection.AppendChild($profileInfo) | Out-Null

$summaryInfo = $html.CreateElement("div")
$summaryInfo.SetAttribute("id", "summary-info")
$summaryInfo.SetAttribute("class", "summary-info")
$pageInfoSection.AppendChild($summaryInfo) | Out-Null

# Stats section
$statsSection = $html.CreateElement("section")
$statsSection.SetAttribute("aria-labelledby", "stats-heading")
$main.AppendChild($statsSection) | Out-Null

$statsDiv = $html.CreateElement("div")
$statsDiv.SetAttribute("class", "section-title")
$statsSection.AppendChild($statsDiv) | Out-Null

$statsH2 = $html.CreateElement("h2")
$statsH2.SetAttribute("id", "stats-heading")
$statsH2.InnerText = "LIVE-Informationen"
$statsDiv.AppendChild($statsH2) | Out-Null

$statsLive = $html.CreateElement("span")
$statsLive.SetAttribute("id", "stats-live")
$statsLive.SetAttribute("class", "live-indicator")
$statsLive.InnerText = "warte"
$statsDiv.AppendChild($statsLive) | Out-Null

$liveStats = $html.CreateElement("div")
$liveStats.SetAttribute("id", "live-stats")
$liveStats.SetAttribute("class", "status-grid stats-grid")
$statsSection.AppendChild($liveStats) | Out-Null

$statsStatus = $html.CreateElement("p")
$statsStatus.SetAttribute("id", "stats-status")
$statsStatus.SetAttribute("class", "inline-status")
$statsSection.AppendChild($statsStatus) | Out-Null

# Hook section
$hookSection = $html.CreateElement("section")
$hookSection.SetAttribute("aria-labelledby", "hook-heading")
$main.AppendChild($hookSection) | Out-Null

$hookDiv = $html.CreateElement("div")
$hookDiv.SetAttribute("class", "section-title")
$hookSection.AppendChild($hookDiv) | Out-Null

$hookH2 = $html.CreateElement("h2")
$hookH2.SetAttribute("id", "hook-heading")
$hookH2.InnerText = "WebSocket-Hook"
$hookDiv.AppendChild($hookH2) | Out-Null

$hookLed = $html.CreateElement("span")
$hookLed.SetAttribute("id", "hook-led")
$hookLed.SetAttribute("class", "status-led off")
$hookLed.SetAttribute("role", "status")
$hookLed.SetAttribute("aria-label", "Hook inaktiv")
$hookLed.SetAttribute("title", "Hook inaktiv")
$hookDiv.AppendChild($hookLed) | Out-Null

$hookButtonRow = $html.CreateElement("div")
$hookButtonRow.SetAttribute("class", "button-row")
$hookSection.AppendChild($hookButtonRow) | Out-Null

$enableHook = $html.CreateElement("button")
$enableHook.SetAttribute("id", "enable-hook")
$enableHook.SetAttribute("class", "primary")
$enableHook.InnerText = "Hook setzen"
$hookButtonRow.AppendChild($enableHook) | Out-Null

$disableHook = $html.CreateElement("button")
$disableHook.SetAttribute("id", "disable-hook")
$disableHook.SetAttribute("class", "secondary")
$disableHook.InnerText = "Hook deaktivieren"
$hookButtonRow.AppendChild($disableHook) | Out-Null

$resetTab = $html.CreateElement("button")
$resetTab.SetAttribute("id", "reset-tab")
$resetTab.SetAttribute("class", "secondary danger-outline")
$resetTab.InnerText = "Refresh"
$hookButtonRow.AppendChild($resetTab) | Out-Null

$openEmbedLive = $html.CreateElement("button")
$openEmbedLive.SetAttribute("id", "open-embed-live")
$openEmbedLive.SetAttribute("class", "secondary")
$openEmbedLive.InnerText = "Embed"
$hookButtonRow.AppendChild($openEmbedLive) | Out-Null

$openNormalLive = $html.CreateElement("button")
$openNormalLive.SetAttribute("id", "open-normal-live")
$openNormalLive.SetAttribute("class", "secondary")
$openNormalLive.InnerText = "Normal"
$hookButtonRow.AppendChild($openNormalLive) | Out-Null

$playerVlcFrame = $html.CreateElement("button")
$playerVlcFrame.SetAttribute("id", "player-vlc-frame")
$playerVlcFrame.SetAttribute("class", "secondary compact")
$playerVlcFrame.InnerText = "VLC Ersatz"
$hookButtonRow.AppendChild($playerVlcFrame) | Out-Null

$hookStatus = $html.CreateElement("p")
$hookStatus.SetAttribute("id", "hook-status")
$hookStatus.SetAttribute("class", "inline-status")
$hookSection.AppendChild($hookStatus) | Out-Null

$hookOptionRow1 = $html.CreateElement("label")
$hookOptionRow1.SetAttribute("class", "option-row")
$hookSection.AppendChild($hookOptionRow1) | Out-Null

$hookAutostart = $html.CreateElement("input")
$hookAutostart.SetAttribute("id", "hook-autostart")
$hookAutostart.SetAttribute("type", "checkbox")
$hookOptionRow1.AppendChild($hookAutostart) | Out-Null

$hookAutostartText = $html.CreateTextNode(" Permanent Hook")
$hookOptionRow1.AppendChild($hookAutostartText) | Out-Null

$hookOptionRow2 = $html.CreateElement("label")
$hookOptionRow2.SetAttribute("class", "option-row")
$hookSection.AppendChild($hookOptionRow2) | Out-Null

$quickRecover = $html.CreateElement("input")
$quickRecover.SetAttribute("id", "quick-recover")
$quickRecover.SetAttribute("type", "checkbox")
$hookOptionRow2.AppendChild($quickRecover) | Out-Null

$quickRecoverText = $html.CreateTextNode(" Auto-Reconnect")
$hookOptionRow2.AppendChild($quickRecoverText) | Out-Null

# Caption section
$captionSection = $html.CreateElement("section")
$captionSection.SetAttribute("aria-labelledby", "caption-heading")
$main.AppendChild($captionSection) | Out-Null

$captionDiv = $html.CreateElement("div")
$captionDiv.SetAttribute("class", "section-title")
$captionSection.AppendChild($captionDiv) | Out-Null

$captionH2 = $html.CreateElement("h2")
$captionH2.SetAttribute("id", "caption-heading")
$captionH2.InnerText = "Untertitel"
$captionDiv.AppendChild($captionH2) | Out-Null

$scan = $html.CreateElement("button")
$scan.SetAttribute("id", "scan")
$scan.SetAttribute("class", "secondary")
$scan.InnerText = "Seite prüfen"
$captionDiv.AppendChild($scan) | Out-Null

$captionStatus = $html.CreateElement("div")
$captionStatus.SetAttribute("id", "caption-status")
$captionStatus.SetAttribute("class", "status-grid")
$captionSection.AppendChild($captionStatus) | Out-Null

$enableCaptions = $html.CreateElement("button")
$enableCaptions.SetAttribute("id", "enable-captions")
$enableCaptions.SetAttribute("class", "primary")
$enableCaptions.InnerText = "Untertitel aktivieren"
$captionSection.AppendChild($enableCaptions) | Out-Null

$captionActionStatus = $html.CreateElement("p")
$captionActionStatus.SetAttribute("id", "caption-action-status")
$captionActionStatus.SetAttribute("role", "status")
$captionActionStatus.SetAttribute("class", "inline-status action-status")
$captionSection.AppendChild($captionActionStatus) | Out-Null

# Player section
$playerSection = $html.CreateElement("section")
$playerSection.SetAttribute("aria-labelledby", "player-heading")
$main.AppendChild($playerSection) | Out-Null

$playerDiv = $html.CreateElement("div")
$playerDiv.SetAttribute("class", "section-title")
$playerSection.AppendChild($playerDiv) | Out-Null

$playerH2 = $html.CreateElement("h2")
$playerH2.SetAttribute("id", "player-heading")
$playerH2.InnerText = "Playersteuerung"
$playerDiv.AppendChild($playerH2) | Out-Null

$playerTime = $html.CreateElement("span")
$playerTime.SetAttribute("id", "player-time")
$playerTime.SetAttribute("class", "player-time")
$playerTime.InnerText = "–"
$playerDiv.AppendChild($playerTime) | Out-Null

$playerControls = $html.CreateElement("div")
$playerControls.SetAttribute("class", "player-controls")
$playerControls.SetAttribute("role", "group")
$playerControls.SetAttribute("aria-label", "TikTok-Player steuern")
$playerSection.AppendChild($playerControls) | Out-Null

$playerPlay = $html.CreateElement("button")
$playerPlay.SetAttribute("id", "player-play")
$playerPlay.SetAttribute("class", "secondary compact")
$playerPlay.InnerText = "Pause"
$playerControls.AppendChild($playerPlay) | Out-Null

$playerReplay = $html.CreateElement("button")
$playerReplay.SetAttribute("id", "player-replay")
$playerReplay.SetAttribute("class", "secondary compact")
$playerReplay.InnerText = "Neu laden"
$playerControls.AppendChild($playerReplay) | Out-Null

$playerMute = $html.CreateElement("button")
$playerMute.SetAttribute("id", "player-mute")
$playerMute.SetAttribute("class", "secondary compact")
$playerMute.InnerText = "Stumm"
$playerControls.AppendChild($playerMute) | Out-Null

$playerPip = $html.CreateElement("button")
$playerPip.SetAttribute("id", "player-pip")
$playerPip.SetAttribute("class", "secondary compact")
$playerPip.InnerText = "Bild-in-Bild"
$playerControls.AppendChild($playerPip) | Out-Null

$playerFullscreen = $html.CreateElement("button")
$playerFullscreen.SetAttribute("id", "player-fullscreen")
$playerFullscreen.SetAttribute("class", "secondary compact")
$playerFullscreen.InnerText = "Vollbild"
$playerControls.AppendChild($playerFullscreen) | Out-Null

$playerReport = $html.CreateElement("button")
$playerReport.SetAttribute("id", "player-report")
$playerReport.SetAttribute("class", "secondary compact danger-outline")
$playerReport.InnerText = "Melden öffnen"
$playerControls.AppendChild($playerReport) | Out-Null

$audioControls = $html.CreateElement("div")
$audioControls.SetAttribute("class", "audio-controls")
$playerSection.AppendChild($audioControls) | Out-Null

$controlLabel2 = $html.CreateElement("div")
$controlLabel2.SetAttribute("class", "control-label")
$audioControls.AppendChild($controlLabel2) | Out-Null

$labelForPlayerVolume = $html.CreateElement("label")
$labelForPlayerVolume.SetAttribute("for", "player-volume")
$labelForPlayerVolume.InnerText = "Lautstärke"
$controlLabel2.AppendChild($labelForPlayerVolume) | Out-Null

$outputPlayerVolume = $html.CreateElement("output")
$outputPlayerVolume.SetAttribute("id", "player-volume-output")
$outputPlayerVolume.SetAttribute("for", "player-volume")
$outputPlayerVolume.InnerText = "–"
$controlLabel2.AppendChild($outputPlayerVolume) | Out-Null

$inputPlayerVolume = $html.CreateElement("input")
$inputPlayerVolume.SetAttribute("id", "player-volume")
$inputPlayerVolume.SetAttribute("type", "range")
$inputPlayerVolume.SetAttribute("min", "0")
$inputPlayerVolume.SetAttribute("max", "100")
$inputPlayerVolume.SetAttribute("step", "1")
$inputPlayerVolume.SetAttribute("value", "100")
$audioControls.AppendChild($inputPlayerVolume) | Out-Null

$audioMeterRow = $html.CreateElement("div")
$audioMeterRow.SetAttribute("class", "audio-meter-row")
$audioControls.AppendChild($audioMeterRow) | Out-Null

$audioMeterSpan = $html.CreateElement("span")
$audioMeterSpan.InnerText = "Spitzenpegel"
$audioMeterRow.AppendChild($audioMeterSpan) | Out-Null

$playerPeak = $html.CreateElement("strong")
$playerPeak.SetAttribute("id", "player-peak")
$playerPeak.InnerText = "–"
$audioMeterRow.AppendChild($playerPeak) | Out-Null

$limiterOptionRow = $html.CreateElement("label")
$limiterOptionRow.SetAttribute("class", "option-row")
$audioControls.AppendChild($limiterOptionRow) | Out-Null

$limiterEnabled = $html.CreateElement("input")
$limiterEnabled.SetAttribute("id", "limiter-enabled")
$limiterEnabled.SetAttribute("type", "checkbox")
$limiterOptionRow.AppendChild($limiterEnabled) | Out-Null

$limiterEnabledText = $html.CreateTextNode(" Pegelschutz aktivieren")
$limiterOptionRow.AppendChild($limiterEnabledText) | Out-Null

$controlLabel3 = $html.CreateElement("div")
$controlLabel3.SetAttribute("class", "control-label")
$audioControls.AppendChild($controlLabel3) | Out-Null

$labelForLimiterStrength = $html.CreateElement("label")
$labelForLimiterStrength.SetAttribute("for", "limiter-strength")
$labelForLimiterStrength.InnerText = "Schutzstärke"
$controlLabel3.AppendChild($labelForLimiterStrength) | Out-Null

$outputLimiterStrength = $html.CreateElement("output")
$outputLimiterStrength.SetAttribute("id", "limiter-strength-output")
$outputLimiterStrength.SetAttribute("for", "limiter-strength")
$outputLimiterStrength.InnerText = "30"
$controlLabel3.AppendChild($outputLimiterStrength) | Out-Null

$inputLimiterStrength = $html.CreateElement("input")
$inputLimiterStrength.SetAttribute("id", "limiter-strength")
$inputLimiterStrength.SetAttribute("type", "range")
$inputLimiterStrength.SetAttribute("min", "0")
$inputLimiterStrength.SetAttribute("max", "100")
$inputLimiterStrength.SetAttribute("step", "1")
$inputLimiterStrength.SetAttribute("value", "30")
$audioControls.AppendChild($inputLimiterStrength) | Out-Null

$multiGuestStatus = $html.CreateElement("p")
$multiGuestStatus.SetAttribute("id", "multi-guest-status")
$multiGuestStatus.SetAttribute("class", "inline-status")
$multiGuestStatus.InnerText = "Verbundene Streams: noch nicht erkannt."
$playerSection.AppendChild($multiGuestStatus) | Out-Null

$playerStatus
