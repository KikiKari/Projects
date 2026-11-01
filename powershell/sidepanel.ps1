#!/usr/bin/env pwsh
# sidepanel.html — portiert nach powershell
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
# Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates an HTML document similar to sidepanel.html and writes it to a file.
.DESCRIPTION
    This script creates the HTML structure programmatically using PowerShell's XML capabilities,
    then outputs it to a specified file or standard output.
.PARAMETER OutputPath
    Optional path to write the generated HTML file. If not provided, outputs to stdout.
#>

param(
    [string]$OutputPath
)

# Create the HTML document structure
$html = New-Object System.Xml.XmlDocument

# Create DOCTYPE declaration manually since XmlDocument doesn't support it directly
$docType = $html.CreateDocumentType("html", "", "", "")
$html.AppendChild($docType) > $null

# Root html element with language attribute
$htmlElement = $html.CreateElement("html")
$htmlElement.SetAttribute("lang", "de")
$html.AppendChild($htmlElement) > $null

# Head section
$head = $html.CreateElement("head")
$htmlElement.AppendChild($head) > $null

$metaCharset = $html.CreateElement("meta")
$metaCharset.SetAttribute("charset", "utf-8")
$head.AppendChild($metaCharset) > $null

$metaViewport = $html.CreateElement("meta")
$metaViewport.SetAttribute("name", "viewport")
$metaViewport.SetAttribute("content", "width=device-width, initial-scale=1")
$head.AppendChild($metaViewport) > $null

$title = $html.CreateElement("title")
$title.InnerText = "TikTok LIVE Companion"
$head.AppendChild($title) > $null

$link1 = $html.CreateElement("link")
$link1.SetAttribute("rel", "stylesheet")
$link1.SetAttribute("href", "sidepanel.css")
$head.AppendChild($link1) > $null

$link2 = $html.CreateElement("link")
$link2.SetAttribute("rel", "stylesheet")
$link2.SetAttribute("href", "icon-controls.css")
$head.AppendChild($link2) > $null

$link3 = $html.CreateElement("link")
$link3.SetAttribute("rel", "stylesheet")
$link3.SetAttribute("href", "status-overview-panel.css")
$head.AppendChild($link3) > $null

# Body section
$body = $html.CreateElement("body")
$htmlElement.AppendChild($body) > $null

$pTitle = $html.CreateElement("p")
$pTitle.SetAttribute("id", "page-title")
$pTitle.SetAttribute("hidden", "")
$body.AppendChild($pTitle) > $null

$main = $html.CreateElement("main")
$body.AppendChild($main) > $null

# Chat Section
$sectionChat = $html.CreateElement("section")
$sectionChat.SetAttribute("aria-labelledby", "chat-heading")
$main.AppendChild($sectionChat) > $null

$divSectionTitleChat = $html.CreateElement("div")
$divSectionTitleChat.SetAttribute("class", "section-title")
$sectionChat.AppendChild($divSectionTitleChat) > $null

$h2ChatHeading = $html.CreateElement("h2")
$h2ChatHeading.SetAttribute("id", "chat-heading")
$h2ChatHeading.InnerText = "Chat"
$divSectionTitleChat.AppendChild($h2ChatHeading) > $null

$divTitleActionsChat = $html.CreateElement("div")
$divTitleActionsChat.SetAttribute("class", "title-actions")
$divSectionTitleChat.AppendChild($divTitleActionsChat) > $null

$spanChatLed = $html.CreateElement("span")
$spanChatLed.SetAttribute("id", "chat-led")
$spanChatLed.SetAttribute("class", "status-led off")
$spanChatLed.SetAttribute("role", "status")
$spanChatLed.SetAttribute("aria-label", "Chat inaktiv")
$spanChatLed.SetAttribute("title", "Chat inaktiv")
$divTitleActionsChat.AppendChild($spanChatLed) > $null

$buttonChatCount = $html.CreateElement("button")
$buttonChatCount.SetAttribute("id", "chat-count")
$buttonChatCount.SetAttribute("class", "count count-button")
$buttonChatCount.SetAttribute("type", "button")
$buttonChatCount.SetAttribute("aria-haspopup", "dialog")
$buttonChatCount.SetAttribute("title", "Gesammelte Chatzeilen öffnen")
$buttonChatCount.InnerText = "0"
$divTitleActionsChat.AppendChild($buttonChatCount) > $null

$buttonRefreshChat = $html.CreateElement("button")
$buttonRefreshChat.SetAttribute("id", "refresh-chat")
$buttonRefreshChat.SetAttribute("class", "secondary compact")
$buttonRefreshChat.SetAttribute("title", "Chatanzeige leeren")
$buttonRefreshChat.InnerText = "Reset"
$divTitleActionsChat.AppendChild($buttonRefreshChat) > $null

$buttonToggleSpeech = $html.CreateElement("button")
$buttonToggleSpeech.SetAttribute("id", "toggle-speech")
$buttonToggleSpeech.SetAttribute("class", "secondary compact")
$buttonToggleSpeech.SetAttribute("aria-pressed", "false")
$buttonToggleSpeech.SetAttribute("aria-label", "Vorlesen")
$buttonToggleSpeech.InnerText = "On"
$divTitleActionsChat.AppendChild($buttonToggleSpeech) > $null

$spanSpeechLed = $html.CreateElement("span")
$spanSpeechLed.SetAttribute("id", "speech-led")
$spanSpeechLed.SetAttribute("class", "status-led off")
$spanSpeechLed.SetAttribute("role", "status")
$spanSpeechLed.SetAttribute("aria-label", "Vorlesen inaktiv")
$spanSpeechLed.SetAttribute("title", "Vorlesen inaktiv")
$divTitleActionsChat.AppendChild($spanSpeechLed) > $null

$divChatList = $html.CreateElement("div")
$divChatList.SetAttribute("id", "chat-list")
$divChatList.SetAttribute("class", "chat-list empty")
$divChatList.SetAttribute("role", "log")
$divChatList.SetAttribute("aria-live", "polite")
$divChatList.SetAttribute("aria-relevant", "additions")
$divChatList.SetAttribute("aria-label", "Die letzten fünf bereinigten Chatnachrichten")
$divChatList.InnerText = "Noch keine Chatnachrichten erkannt."
$sectionChat.AppendChild($divChatList) > $null

$pSpeechStatus = $html.CreateElement("p")
$pSpeechStatus.SetAttribute("id", "speech-status")
$pSpeechStatus.SetAttribute("role", "status")
$pSpeechStatus.SetAttribute("class", "inline-status")
$pSpeechStatus.InnerText = "Vorlesen ist ausgeschaltet."
$sectionChat.AppendChild($pSpeechStatus) > $null

$divControlLabelVolume = $html.CreateElement("div")
$divControlLabelVolume.SetAttribute("class", "control-label")
$sectionChat.AppendChild($divControlLabelVolume) > $null

$labelSpeechVolume = $html.CreateElement("label")
$labelSpeechVolume.SetAttribute("for", "speech-volume")
$labelSpeechVolume.InnerText = "Vorleselautstärke"
$divControlLabelVolume.AppendChild($labelSpeechVolume) > $null

$outputSpeechVolume = $html.CreateElement("output")
$outputSpeechVolume.SetAttribute("id", "speech-volume-output")
$outputSpeechVolume.SetAttribute("for", "speech-volume")
$outputSpeechVolume.InnerText = "100%"
$divControlLabelVolume.AppendChild($outputSpeechVolume) > $null

$inputSpeechVolume = $html.CreateElement("input")
$inputSpeechVolume.SetAttribute("id", "speech-volume")
$inputSpeechVolume.SetAttribute("type", "range")
$inputSpeechVolume.SetAttribute("min", "0")
$inputSpeechVolume.SetAttribute("max", "100")
$inputSpeechVolume.SetAttribute("step", "5")
$inputSpeechVolume.SetAttribute("value", "50")
$sectionChat.AppendChild($inputSpeechVolume) > $null

$divButtonRowChat = $html.CreateElement("div")
$divButtonRowChat.SetAttribute("class", "button-row")
$sectionChat.AppendChild($divButtonRowChat) > $null

$buttonServiceAction = $html.CreateElement("button")
$buttonServiceAction.SetAttribute("id", "service-action")
$buttonServiceAction.SetAttribute("class", "secondary")
$buttonServiceAction.InnerText = "Sprachdienst"
$divButtonRowChat.AppendChild($buttonServiceAction) > $null

$buttonSherpaAction = $html.CreateElement("button")
$buttonSherpaAction.SetAttribute("id", "sherpa-action")
$buttonSherpaAction.SetAttribute("class", "secondary")
$buttonSherpaAction.InnerText = "Sherpa"
$divButtonRowChat.AppendChild($buttonSherpaAction) > $null

$buttonOpenSpeechSettings = $html.CreateElement("button")
$buttonOpenSpeechSettings.SetAttribute("id", "open-speech-settings")
$buttonOpenSpeechSettings.SetAttribute("class", "secondary compact settings-button")
$buttonOpenSpeechSettings.SetAttribute("type", "button")
$buttonOpenSpeechSettings.SetAttribute("aria-label", "Erweiterte Einstellungen öffnen")
$buttonOpenSpeechSettings.SetAttribute("aria-haspopup", "dialog")
$buttonOpenSpeechSettings.SetAttribute("title", "Einstellungen")
$divButtonRowChat.AppendChild($buttonOpenSpeechSettings) > $null

$pServiceStatus = $html.CreateElement("p")
$pServiceStatus.SetAttribute("id", "service-status")
$pServiceStatus.SetAttribute("class", "inline-status")
$pServiceStatus.InnerText = "Lokaler Sprachdienst noch nicht geprüft."
$sectionChat.AppendChild($pServiceStatus) > $null

$divServiceSetup = $html.CreateElement("div")
$divServiceSetup.SetAttribute("id", "service-setup")
$divServiceSetup.SetAttribute("class", "inline-status")
$divServiceSetup.SetAttribute("hidden", "")
$sectionChat.AppendChild($divServiceSetup) > $null

$buttonCopyServiceSetup = $html.CreateElement("button")
$buttonCopyServiceSetup.SetAttribute("id", "copy-service-setup")
$buttonCopyServiceSetup.SetAttribute("class", "secondary compact")
$buttonCopyServiceSetup.InnerText = "Installation abschließen!"
$divServiceSetup.AppendChild($buttonCopyServiceSetup) > $null

# Stats Section
$sectionStats = $html.CreateElement("section")
$sectionStats.SetAttribute("aria-labelledby", "stats-heading")
$main.AppendChild($sectionStats) > $null

$divSectionTitleStats = $html.CreateElement("div")
$divSectionTitleStats.SetAttribute("class", "section-title")
$sectionStats.AppendChild($divSectionTitleStats) > $null

$h2StatsHeading = $html.CreateElement("h2")
$h2StatsHeading.SetAttribute("id", "stats-heading")
$h2StatsHeading.InnerText = "LIVE-Information"
$divSectionTitleStats.AppendChild($h2StatsHeading) > $null

$spanStatsLive = $html.CreateElement("span")
$spanStatsLive.SetAttribute("id", "stats-live")
$spanStatsLive.SetAttribute("class", "live-indicator")
$spanStatsLive.InnerText = "warte"
$divSectionTitleStats.AppendChild($spanStatsLive) > $null

$divLiveStats = $html.CreateElement("div")
$divLiveStats.SetAttribute("id", "live-stats")
$divLiveStats.SetAttribute("class", "status-grid stats-grid")
$sectionStats.AppendChild($divLiveStats) > $null

$pStatsStatus = $html.CreateElement("p")
$pStatsStatus.SetAttribute("id", "stats-status")
$pStatsStatus.SetAttribute("class", "inline-status")
$sectionStats.AppendChild($pStatsStatus) > $null

# Page Info Section
$sectionPageInfo = $html.CreateElement("section")
$sectionPageInfo.SetAttribute("id", "page-info-section")
$sectionPageInfo.SetAttribute("aria-labelledby", "page-info-heading")
$main.AppendChild($sectionPageInfo) > $null

$divSectionTitlePageInfo = $html.CreateElement("div")
$divSectionTitlePageInfo.SetAttribute("class", "section-title")
$sectionPageInfo.AppendChild($divSectionTitlePageInfo) > $null

$h2PageInfoHeading = $html.CreateElement("h2")
$h2PageInfoHeading.SetAttribute("id", "page-info-heading")
$h2PageInfoHeading.InnerText = "PROFIL-Information"
$divSectionTitlePageInfo.AppendChild($h2PageInfoHeading) > $null

$divTitleActionsPageInfo = $html.CreateElement("div")
$divTitleActionsPageInfo.SetAttribute("class", "title-actions")
$divSectionTitlePageInfo.AppendChild($divTitleActionsPageInfo) > $null

$spanPageInfoSource = $html.CreateElement("span")
$spanPageInfoSource.SetAttribute("id", "page-info-source")
$spanPageInfoSource.SetAttribute("class", "live-indicator")
$spanPageInfoSource.InnerText = "Metadaten"
$divTitleActionsPageInfo.AppendChild($spanPageInfoSource) > $null

$buttonRefreshPageInfo = $html.CreateElement("button")
$buttonRefreshPageInfo.SetAttribute("id", "refresh-page-info")
$buttonRefreshPageInfo.SetAttribute("class", "secondary compact")
$buttonRefreshPageInfo.SetAttribute("title", "Refresh")
$buttonRefreshPageInfo.InnerText = "Refresh"
$divTitleActionsPageInfo.AppendChild($buttonRefreshPageInfo) > $null

$buttonForcePageInfo = $html.CreateElement("button")
$buttonForcePageInfo.SetAttribute("id", "force-page-info")
$buttonForcePageInfo.SetAttribute("class", "secondary compact danger-outline")
$buttonForcePageInfo.InnerText = "Force"
$divTitleActionsPageInfo.AppendChild($buttonForcePageInfo) > $null

$divProfileInfo = $html.CreateElement("div")
$divProfileInfo.SetAttribute("id", "profile-info")
$divProfileInfo.SetAttribute("class", "profile-info")
$divProfileInfo.SetAttribute("hidden", "")
$sectionPageInfo.AppendChild($divProfileInfo) > $null

$divSummaryInfo = $html.CreateElement("div")
$divSummaryInfo.SetAttribute("id", "summary-info")
$divSummaryInfo.SetAttribute("class", "summary-info")
$sectionPageInfo.AppendChild($divSummaryInfo) > $null

# Hook Section
$sectionHook = $html.CreateElement("section")
$sectionHook.SetAttribute("aria-labelledby", "hook-heading")
$main.AppendChild($sectionHook) > $null

$divSectionTitleHook = $html.CreateElement("div")
$divSectionTitleHook.SetAttribute("class", "section-title header-controls")
$sectionHook.AppendChild($divSectionTitleHook) > $null

$h2HookHeading = $html.CreateElement("h2")
$h2HookHeading.SetAttribute("id", "hook-heading")
$h2HookHeading.InnerText = "Connection"
$divSectionTitleHook.AppendChild($h2HookHeading) > $null

$divTitleActionsHook = $html.CreateElement("div")
$divTitleActionsHook.SetAttribute("class", "title-actions")
$divSectionTitleHook.AppendChild($divTitleActionsHook) > $null

$buttonResetTab = $html.CreateElement("button")
$buttonResetTab.SetAttribute("id", "reset-tab")
$buttonResetTab.SetAttribute("class", "secondary compact danger-outline")
$buttonResetTab.SetAttribute("title", "Reset")
$buttonResetTab.InnerText = "Reset"
$divTitleActionsHook.AppendChild($buttonResetTab) > $null

$inputHookAutostart = $html.CreateElement("input")
$inputHookAutostart.SetAttribute("id", "hook-autostart")
$inputHookAutostart.SetAttribute("type", "checkbox")
$inputHookAutostart.SetAttribute("aria-label", "Hook dauerhaft")
$inputHookAutostart.SetAttribute("title", "Hook dauerhaft: Off")
$divTitleActionsHook.AppendChild($inputHookAutostart) > $null

$spanHookStatusLed = $html.CreateElement("span")
$spanHookStatusLed.SetAttribute("class", "status-led off")
$spanHookStatusLed.SetAttribute("data-switch-status", "hook-autostart")
$spanHookStatusLed.SetAttribute("role", "status")
$divTitleActionsHook.AppendChild($spanHookStatusLed) > $null

$divButtonRowHook = $html.CreateElement("div")
$divButtonRowHook.SetAttribute("class", "button-row")
$sectionHook.AppendChild($divButtonRowHook) > $null

$buttonToggleHook = $html.CreateElement("button")
$buttonToggleHook.SetAttribute("id", "toggle-hook")
$buttonToggleHook.SetAttribute("class", "primary")
$buttonToggleHook.SetAttribute("aria-label", "Connection")
$buttonToggleHook.SetAttribute("aria-pressed", "false")
$buttonToggleHook.InnerText = "On"
$divButtonRowHook.AppendChild($buttonToggleHook) > $null

$buttonOpenConnectionSettings = $html.CreateElement("button")
$buttonOpenConnectionSettings.SetAttribute("id", "open-connection-settings")
$buttonOpenConnectionSettings.SetAttribute("class", "secondary compact settings-button")
$buttonOpenConnectionSettings.SetAttribute("type", "button")
$buttonOpenConnectionSettings.SetAttribute("aria-label", "Connection-Einstellungen öffnen")
$buttonOpenConnectionSettings.SetAttribute("aria-haspopup", "dialog")
$divButtonRowHook.AppendChild($buttonOpenConnectionSettings) > $null

$buttonOpenEmbedLive = $html.CreateElement("button")
$buttonOpenEmbedLive.SetAttribute("id", "open-embed-live")
$buttonOpenEmbedLive.SetAttribute("class", "secondary")
$buttonOpenEmbedLive.InnerText = "Embed"
$divButtonRowHook.AppendChild($buttonOpenEmbedLive) > $null

$buttonOpenNormalLive = $html.CreateElement("button")
$buttonOpenNormalLive.SetAttribute("id", "open-normal-live")
$buttonOpenNormalLive.SetAttribute("class", "secondary")
$buttonOpenNormalLive.InnerText = "Browser"
$divButtonRowHook.AppendChild($buttonOpenNormalLive) > $null

$buttonPlayerVlcFrame = $html.CreateElement("button")
$buttonPlayerVlcFrame.SetAttribute("id", "player-vlc-frame")
$buttonPlayerVlcFrame.SetAttribute("class", "secondary compact")
$buttonPlayerVlcFrame.InnerText = "Player"
$divButtonRowHook.AppendChild($buttonPlayerVlcFrame) > $null

$divConnectionStatus = $html.CreateElement("div")
$divConnectionStatus.SetAttribute("class", "connection-status")
$sectionHook.AppendChild($divConnectionStatus) > $null

$spanHookLed = $html.CreateElement("span")
$spanHookLed.SetAttribute("id", "hook-led")
$spanHookLed.SetAttribute("class", "status-led off")
$spanHookLed.SetAttribute("role", "status")
$spanHookLed.SetAttribute("aria-label", "Hook inaktiv")
$spanHookLed.SetAttribute("title", "Hook inaktiv")
$divConnectionStatus.AppendChild($spanHookLed) > $null

$pHookStatus = $html.CreateElement("p")
$pHookStatus.SetAttribute("id", "hook-status")
$pHookStatus.SetAttribute("class", "inline-status")
$divConnectionStatus.AppendChild($pHookStatus) > $null

$pEmbedStartupStatus = $html.CreateElement("p")
$pEmbedStartupStatus.SetAttribute("id", "embed-startup-status")
$pEmbedStartupStatus.SetAttribute("class", "inline-status")
$pEmbedStartupStatus.SetAttribute("role", "status")
$pEmbedStartupStatus.SetAttribute("aria-live", "polite")
$pEmbedStartupStatus.SetAttribute("hidden", "")
$sectionHook.AppendChild($pEmbedStartupStatus) > $null

$buttonCancelEmbedStartup = $html.CreateElement("button")
$buttonCancelEmbedStartup.SetAttribute("id", "cancel-embed-startup")
$buttonCancelEmbedStartup.SetAttribute("class", "secondary")
$buttonCancelEmbedStartup.SetAttribute("hidden", "")
$buttonCancelEmbedStartup.InnerText = "Embed-Start abbrechen"
$sectionHook.AppendChild($buttonCancelEmbedStartup) > $null

$pHookReconnectStatus = $html.CreateElement("p")
$pHookReconnectStatus.SetAttribute("id", "hook-reconnect-status")
$pHookReconnectStatus.SetAttribute("class", "inline-status")
$pHookReconnectStatus.SetAttribute("role", "status")
$pHookReconnectStatus.InnerText = "Hook-Reconnect: aus"
$sectionHook.AppendChild($pHookReconnectStatus) > $null

$pPlayerRecoveryStatus = $html.CreateElement("p")
$pPlayerRecoveryStatus.SetAttribute("id", "player-recovery-status")
$pPlayerRecoveryStatus.SetAttribute("class", "inline-status")
$pPlayerRecoveryStatus.SetAttribute("role", "status")
$pPlayerRecoveryStatus.InnerText = "Player-Recovery: aus"
$sectionHook.AppendChild($pPlayerRecoveryStatus) > $null

# Player Section
$sectionPlayer = $html.CreateElement("section")
$sectionPlayer.SetAttribute("aria-labelledby", "player-heading")
$main.AppendChild($sectionPlayer) > $null

$divSectionTitlePlayer = $html.CreateElement("div")
$divSectionTitlePlayer.SetAttribute("class", "section-title header-controls")
$sectionPlayer.AppendChild($divSectionTitlePlayer) > $null

$h2PlayerHeading = $html.CreateElement("h2")
$h2PlayerHeading.SetAttribute("id", "player-heading")
$h2PlayerHeading.InnerText = "Player"
$divSectionTitlePlayer.AppendChild($h2PlayerHeading) > $null

$divTitleActionsPlayer = $html.CreateElement("div")
$divTitleActionsPlayer.SetAttribute("class", "title-actions")
$divSectionTitlePlayer.AppendChild($divTitleActionsPlayer) > $null

$buttonPlayerReplay = $html.CreateElement("button")
$buttonPlayerReplay.SetAttribute("id", "player-replay")
$buttonPlayerReplay.SetAttribute("class", "secondary compact")
$buttonPlayerReplay.SetAttribute("title", "Neu laden")
$buttonPlayerReplay.InnerText = "Neu laden"
$divTitleActionsPlayer.AppendChild($buttonPlayerReplay) > $null

$inputLimiterEnabled = $html.CreateElement("input")
$inputLimiterEnabled.SetAttribute("id", "limiter-enabled")
$inputLimiterEnabled.SetAttribute("type", "checkbox")
$inputLimiterEnabled.SetAttribute("aria-label", "Pegelschutz")
$inputLimiterEnabled.SetAttribute("title", "Pegelschutz: Off")
$divTitleActionsPlayer.AppendChild($inputLimiterEnabled) > $null

$spanLimiterStatusLed = $html.CreateElement("span")
$spanLimiterStatusLed.SetAttribute("class", "status-led off")
$spanLimiterStatusLed.SetAttribute("data-switch-status", "limiter-enabled")
$spanLimiterStatusLed.SetAttribute("role", "status")
$divTitleActionsPlayer.AppendChild($spanLimiterStatusLed) > $null

$divPlayerControls = $html.CreateElement("div")
$divPlayerControls.SetAttribute("class", "player-controls")
$divPlayerControls.SetAttribute("role", "group")
$divPlayerControls.SetAttribute("aria-label", "TikTok-Player steuern")
$sectionPlayer.AppendChild($divPlayerControls) > $null

$buttonPlayerPlay = $html.CreateElement("button")
$buttonPlayerPlay.SetAttribute("id", "player-play")
$buttonPlayerPlay.SetAttribute("class", "secondary compact")
$buttonPlayerPlay.InnerText = "Play"
$divPlayerControls.AppendChild($buttonPlayerPlay) > $null

$buttonPlayerMute = $html.CreateElement("button")
$buttonPlayerMute.SetAttribute("id", "player-mute")
$buttonPlayerMute.SetAttribute("class", "secondary compact")
$buttonPlayerMute.InnerText = "Mute"
$divPlayerControls.AppendChild($buttonPlayerMute) > $null

$buttonPlayerPip = $html.CreateElement("button")
$buttonPlayerPip.SetAttribute("id", "player-pip")
$buttonPlayerPip.SetAttribute("class", "secondary compact")
$buttonPlayerPip.InnerText = "Bild-in-Bild"
$divPlayerControls.AppendChild($buttonPlayerPip) > $null

$buttonPlayerFullscreen = $html.CreateElement("button")
$buttonPlayerFullscreen.SetAttribute("id", "player-fullscreen")
$buttonPlayerFullscreen.SetAttribute("class", "secondary compact")
$buttonPlayerFullscreen.InnerText = "Vollbild"
$divPlayerControls.AppendChild($buttonPlayerFullscreen) > $null

$buttonPlayerReport = $html.CreateElement("button")
$buttonPlayerReport.SetAttribute("id", "player-report")
$buttonPlayerReport.SetAttribute("class", "secondary compact danger-outline")
$buttonPlayerReport.InnerText = "Meldung"
$divPlayerControls.AppendChild($buttonPlayerReport) > $null

$divAudioControls = $html.CreateElement("div")
$divAudioControls.SetAttribute("class", "audio-controls")
$sectionPlayer.AppendChild($divAudioControls) > $null

$divControlLabelPlayerVolume = $html.CreateElement("div")
$divControlLabelPlayerVolume.SetAttribute("class", "control-label")
$divAudioControls.AppendChild($divControlLabelPlayerVolume) > $null

$labelPlayerVolume = $html.CreateElement("label")
$labelPlayerVolume.SetAttribute("for", "player-volume")
$labelPlayerVolume.InnerText = "Lautstärke"
$divControlLabelPlayerVolume.AppendChild($labelPlayerVolume) > $null

$outputPlayerVolume = $html.CreateElement("output")
$outputPlayerVolume.SetAttribute("id", "player-volume-output")
$outputPlayerVolume.SetAttribute("for", "player-volume")
$outputPlayerVolume.InnerText = "–"
$divControlLabelPlayerVolume.AppendChild($outputPlayerVolume) > $null

$inputPlayerVolume = $html.CreateElement("input")
$inputPlayerVolume.SetAttribute("id", "player-volume")
$inputPlayerVolume.SetAttribute("type", "range")
$inputPlayerVolume.SetAttribute("min", "0")
$inputPlayerVolume.SetAttribute("max", "100")
$inputPlayerVolume.SetAttribute("step", "1")
$inputPlayerVolume.SetAttribute("value", "100")
$divAudioControls.AppendChild($inputPlayerVolume) > $null

$divAudioMeterRow = $html.CreateElement("div")
$divAudioMeterRow.SetAttribute("class", "audio-meter-row")
$divAudioControls.AppendChild($divAudioMeterRow) > $null

$spanAudioMeterLabel = $html.CreateElement("span")
$spanAudioMeterLabel.InnerText = "Spitzenpegel"
$divAudioMeterRow.AppendChild($spanAudioMeterLabel) > $null

$strongPlayerPeak = $html.CreateElement("strong")
$strongPlayerPeak.SetAttribute("id", "player-peak")
$strongPlayerPeak.InnerText = "–"
$divAudioMeterRow.AppendChild($strongPlayerPeak) > $null

$divControlLabelLimiterStrength = $html.CreateElement("div")
$divControlLabelLimiterStrength.SetAttribute("class", "control-label")
$divAudioControls.AppendChild($divControlLabelLimiterStrength) > $null

$labelLimiterStrength = $html.CreateElement("label")
$labelLimiterStrength.SetAttribute("for", "limiter-strength")
$labelLimiterStrength.InnerText = "Schutzstärke"
$divControlLabelLimiterStrength.AppendChild($labelLimiterStrength) > $null

$outputLimiterStrength = $html.CreateElement("output")
$outputLimiterStrength.SetAttribute("id", "limiter-strength-output")
$outputLimiterStrength.SetAttribute("for", "limiter-strength")
$outputLimiterStrength.InnerText = "30"
$divControlLabelLimiterStrength.AppendChild($outputLimiterStrength) > $null

$inputLimiterStrength = $html.CreateElement("input")
$inputLimiterStrength.SetAttribute("id", "limiter-strength")
$inputLimiterStrength.SetAttribute("type", "range")
$inputLimiterStrength.SetAttribute("min", "0")
$inputLimiterStrength.SetAttribute("max", "100")
$inputLimiterStrength.SetAttribute("step", "1")
$inputLimiterStrength.SetAttribute("value", "30")
$divAudioControls.AppendChild($inputLimiterStrength) > $null

$pMultiGuestStatus = $html.CreateElement("p")
$pMultiGuestStatus.SetAttribute("id", "multi-guest-status")
$pMultiGuestStatus.SetAttribute("class", "inline-status")
$pMultiGuestStatus.InnerText = "Verbundene Streams: noch nicht erkannt."
$sectionPlayer.AppendChild($pMultiGuestStatus) > $null

$pPlayerStatus = $html.CreateElement("p")
$pPlayerStatus.SetAttribute("id", "player-status")
$pPlayerStatus.SetAttribute("role", "status")
$pPlayerStatus.SetAttribute("class", "inline-status")
$pPlayerStatus.InnerText = "Warte auf den TikTok-Player."
$sectionPlayer.AppendChild($pPlayerStatus) > $null

$spanPlayerTime = $html.CreateElement("span")
$spanPlayerTime.SetAttribute("id", "player-time")
$spanPlayerTime.SetAttribute("class", "player-time")
$spanPlayerTime.SetAttribute("hidden", "")
$spanPlayerTime.InnerText = "–"
$sectionPlayer.AppendChild($spanPlayerTime) > $null

# Top Chatters Section
$sectionTopChatters = $html.CreateElement("section")
$sectionTopChatters.SetAttribute("aria-labelledby", "top-chatters-heading")
$main.AppendChild($sectionTopChatters) > $null

$divSectionTitleTopChatters = $html.CreateElement("div")
$divSectionTitleTopChatters.SetAttribute("class", "section-title")
$sectionTopChatters.AppendChild($divSectionTitleTopChatters) > $null

$h2TopChattersHeading = $html.CreateElement("h2")
$h2TopChattersHeading.SetAttribute("id", "top-chatters-heading")
$h2TopChattersHeading.InnerText = "Top-Chatter"
$divSectionTitleTopChatters.AppendChild($h2TopChattersHeading) > $null

$buttonOpenAudience = $html.CreateElement("button")
$buttonOpenAudience.SetAttribute("id", "open-audience")
$buttonOpenAudience.SetAttribute("class", "secondary compact")
$buttonOpenAudience.InnerText = "Zuschauer*innen"
$divSectionTitleTopChatters.AppendChild($buttonOpenAudience) > $null

$pTeamTagStatus = $html.CreateElement("p")
$pTeamTagStatus.SetAttribute("id", "team-tag-status")
$pTeamTagStatus.SetAttribute("class", "inline-status")
$pTeamTagStatus.InnerText = "Teamkürzel: noch nicht erkannt."
$sectionTopChatters.AppendChild($pTeamTagStatus) > $null

$divTopChatters = $html.CreateElement("div")
$divTopChatters.SetAttribute("id", "top-chatters")
$divTopChatters.SetAttribute("class", "top-chatters empty")
$divTopChatters.InnerText = "Noch keine Personen im Chat beobachtet."
$sectionTopChatters.AppendChild($divTopChatters) > $null

$divTopChattersActions = $html.CreateElement("div")
$divTopChattersActions.SetAttribute("id", "top-chatters-actions")
$divTopChattersActions.SetAttribute("class", "top-chatters-actions")
$divTopChattersActions.SetAttribute("hidden", "")
$sectionTopChatters.AppendChild($divTopChattersActions) > $null

$buttonTopChattersReset = $html.CreateElement("button")
$buttonTopChattersReset.SetAttribute("id", "top-chatters-reset")
$buttonTopChattersReset.SetAttribute("class", "top-chatter-link")
$buttonTopChattersReset.SetAttribute("type", "button")
$buttonTopChattersReset.SetAttribute("hidden", "")
$buttonTopChattersReset.InnerText = "Reset"
$divTopChattersActions.AppendChild($buttonTopChattersReset) > $null

$buttonTopChattersMore = $html.CreateElement("button")
$buttonTopChattersMore.SetAttribute("id", "top-chatters-more")
$buttonTopChattersMore.SetAttribute("class", "top-chatter-link")
$buttonTopChattersMore.SetAttribute("type", "button")
$buttonTopChattersMore.InnerText = "mehr…"
$divTopChattersActions.AppendChild($buttonTopChattersMore) > $null

# Recommendations Section
$sectionRecommendations = $html.CreateElement("section")
$sectionRecommendations.SetAttribute("id", "recommendations-section")
$sectionRecommendations.SetAttribute("aria-labelledby", "recommendations-heading")
$main.AppendChild($sectionRecommendations) > $null

$divSectionTitleRecommendations = $html.CreateElement("div")
$divSectionTitleRecommendations.SetAttribute("class", "section-title")
$sectionRecommendations.AppendChild($divSectionTitleRecommendations) > $null

$h2RecommendationsHeading = $html.CreateElement("h2")
$h2RecommendationsHeading.SetAttribute("id", "recommendations-heading")
$h2RecommendationsHeading.InnerText = "LIVE-Empfehlungen"
$divSectionTitleRecommendations.AppendChild($h2RecommendationsHeading) > $null

$spanRecommendationStatus = $html.CreateElement("span")
$spanRecommendationStatus.SetAttribute("id", "recommendation-status")
$spanRecommendationStatus.SetAttribute("class", "live-indicator")
$spanRecommendationStatus.InnerText = "bereit"
$divSectionTitleRecommendations.AppendChild($spanRecommendationStatus) > $null

$divRecommendationControls = $html.CreateElement("div")
$divRecommendationControls.SetAttribute("class", "recommendation-controls")
$sectionRecommendations.AppendChild($divRecommendationControls) > $null

$labelRecLimit = $html.CreateElement("label")
$spanRecLimitLabel = $html.CreateElement("span")
$spanRecLimitLabel.InnerText = "Anzahl"
$labelRecLimit.AppendChild($spanRecLimitLabel) > $null

$inputRecLimit = $html.CreateElement("input")
$inputRecLimit.SetAttribute("id", "recommendation-limit")
$inputRecLimit.SetAttribute("type", "number")
$inputRecLimit.SetAttribute("min", "1")
$inputRecLimit.SetAttribute("max", "300")
$inputRecLimit.SetAttribute("step", "1")
$inputRecLimit.SetAttribute("value", "20")
$inputRecLimit.SetAttribute("inputmode", "numeric")
$labelRecLimit.AppendChild($inputRecLimit) > $null
$divRecommendationControls.AppendChild($labelRecLimit) > $null

$labelRecSort = $html.CreateElement("label")
$spanRecSortLabel = $html.CreateElement("span")
$spanRecSortLabel.InnerText = "Sortierung"
$labelRecSort.AppendChild($spanRecSortLabel) > $null

$selectRecSort = $html.CreateElement("select")
$selectRecSort.SetAttribute("id", "recommendation-sort")
$optionTikTok = $html.CreateElement("option")
$optionTikTok.SetAttribute("value", "tiktok")
$optionTikTok.InnerText = "TikTok-Reihenfolge"
$selectRecSort.AppendChild($optionTikTok) > $null

$optionViewers = $html.CreateElement("option")
$optionViewers.SetAttribute("value", "viewers")
$optionViewers.InnerText = "Zuschauer*innen"
$selectRecSort.AppendChild($optionViewers) > $null
$labelRecSort.AppendChild($selectRecSort) > $null
$divRecommendationControls.AppendChild($labelRecSort) > $null

$divButtonRowRec = $html.CreateElement("div")
$divButtonRowRec.SetAttribute("class", "button-row")
$sectionRecommendations.AppendChild($divButtonRowRec) > $null

$buttonScanRec = $html.CreateElement("button")
$buttonScanRec.SetAttribute("id", "scan-recommendations")
$buttonScanRec.SetAttribute("class", "primary")
$buttonScanRec.InnerText = "Empfehlungen scannen"
$divButtonRowRec.AppendChild($buttonScanRec) > $null

$buttonCancelRec = $html.CreateElement("button")
$buttonCancelRec.SetAttribute("id", "cancel-recommendations")
$buttonCancelRec.SetAttribute("class", "secondary")
$buttonCancelRec.SetAttribute("hidden", "")
$buttonCancelRec.InnerText = "Abbrechen"
$divButtonRowRec.AppendChild($buttonCancelRec) > $null

$pRecProgress = $html.CreateElement("p")
$pRecProgress.SetAttribute("id", "recommendation-progress")
$pRecProgress.SetAttribute("class", "inline-status")
$pRecProgress.SetAttribute("aria-live", "polite")
$pRecProgress.InnerText = "Noch kein Scan gestartet."
$sectionRecommendations.AppendChild($pRecProgress) > $null

$divRecList = $html.CreateElement("div")
$divRecList.SetAttribute("id", "recommendation-list")
$divRecList.SetAttribute("class", "recommendation-list empty")
$divRecList.InnerText = "Noch keine Empfehlungen erfasst."
$sectionRecommendations.AppendChild($divRecList) > $null

$divRecActions = $html.CreateElement("div")
$divRecActions.SetAttribute("id", "recommendation-actions")
$divRecActions.SetAttribute("class", "top-chatters-actions")
$divRecActions.SetAttribute("hidden", "")
$sectionRecommendations.AppendChild($divRecActions) > $null

$buttonRecMore = $html
