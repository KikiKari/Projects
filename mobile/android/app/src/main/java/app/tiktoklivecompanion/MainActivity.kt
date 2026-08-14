package app.tiktoklivecompanion

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager
import android.speech.tts.TextToSpeech
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import java.util.Locale
import android.os.Bundle

private val Accent = Color(0xFFFF1C50)

internal fun mobileVideoHeightDp(screenHeightDp: Int, landscape: Boolean): Int =
    if (!landscape) screenHeightDp / 2 else (screenHeightDp - 160 - 96).coerceIn(0, 220)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val engine = remember { createRecognitionEngine(applicationContext) }
            val model: CompanionViewModel = viewModel(factory = simpleViewModelFactory { CompanionViewModel(engine, CompanionPreferences(applicationContext)) })
            DisposableEffect(model) {
                model.backgroundPlaybackChanged = { enabled ->
                    val intent = Intent(applicationContext, BackgroundPlaybackService::class.java).setAction(if (enabled) BackgroundPlaybackService.ACTION_START else BackgroundPlaybackService.ACTION_STOP)
                    if (enabled) ContextCompat.startForegroundService(applicationContext, intent) else applicationContext.startService(intent)
                }
                BackgroundPlaybackService.commandSink = { command -> model.sendCommand?.invoke(command, emptyMap()) }
                onDispose {
                    model.backgroundPlaybackChanged = null
                    BackgroundPlaybackService.commandSink = null
                }
            }
            MaterialTheme(colorScheme = lightColorScheme(primary = Accent, secondary = Accent)) { CompanionApp(model) }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable private fun CompanionApp(model: CompanionViewModel) {
    val state by model.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val tts = remember { TextToSpeech(context) { } }
    DisposableEffect(tts) { onDispose { tts.shutdown() } }
    val nextSpeech = state.speechQueue.firstOrNull()
    LaunchedEffect(nextSpeech?.id) {
        nextSpeech?.let { request ->
            request.languageTag?.let { tts.language = Locale.forLanguageTag(it) }
            val params = Bundle().apply { putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, state.ttsVolume / 100f) }
            tts.speak(request.text, TextToSpeech.QUEUE_ADD, params, "tlc-chat-${request.id}")
            model.consumeSpeech(request.id)
        }
    }
    val micPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { allowed -> if (allowed) model.recognize() else model.reportError("Mikrofonzugriff wurde abgelehnt") }
    BackHandler(enabled = state.videoExpanded) { model.toggleVideoExpanded() }
    val configuration = LocalConfiguration.current
    val landscape = configuration.screenWidthDp > configuration.screenHeightDp
    val compactLandscape = landscape && configuration.screenHeightDp < 352
    // Querformat: Video kleiner halten, damit Inhalt unter dem Menüband sichtbar und scrollbar bleibt (0PE-56).
    val videoHeight = mobileVideoHeightDp(configuration.screenHeightDp, landscape).dp
    Scaffold(topBar = { if (!state.videoExpanded) TopAppBar(title = { Row(verticalAlignment = Alignment.CenterVertically) { Icon(Icons.Default.GraphicEq, null, tint = Color.White, modifier = Modifier.background(Accent, RoundedCornerShape(8.dp)).padding(7.dp)); Spacer(Modifier.width(10.dp)); Text("TikTok LIVE Companion", fontWeight = FontWeight.Bold) } }, actions = { Icon(Icons.Default.Circle, null, tint = Accent, modifier = Modifier.size(9.dp)); Text(" LIVE", fontSize = 12.sp); Spacer(Modifier.width(14.dp)) }) }) { insets ->
        Column(Modifier.padding(insets).fillMaxSize().then(if (compactLandscape && !state.videoExpanded) Modifier.verticalScroll(rememberScrollState()) else Modifier)) {
            if (!state.videoExpanded) StreamNameField(state, model)
            val playerModifier = if (state.videoExpanded) Modifier.fillMaxSize() else Modifier.fillMaxWidth().height(videoHeight)
            Box(playerModifier) {
                CompanionWebView(model, Modifier.fillMaxSize().alpha(if (state.vlcReplacementUrl == null) 1f else 0f), onTap = model::expandVideo)
                state.vlcReplacementUrl?.let { VlcVideoSurface(it, Modifier.fillMaxSize()) }
            }
            if (!state.videoExpanded) {
                PrimaryTabRow(selectedTabIndex = state.tab.ordinal) { CompanionTab.entries.forEach { tab -> Tab(selected = state.tab == tab, onClick = { model.selectTab(tab) }, text = { Text(tab.label) }) } }
                val tabModifier = if (compactLandscape) Modifier.fillMaxWidth().heightIn(min = 96.dp).padding(16.dp) else Modifier.fillMaxWidth().weight(1f).verticalScroll(rememberScrollState()).padding(16.dp)
                Box(tabModifier) {
                    when (state.tab) {
                        CompanionTab.SONG -> SongTab(state, model) {
                            if (state.source == RecognitionSource.MICROPHONE && ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) micPermission.launch(Manifest.permission.RECORD_AUDIO) else model.recognize()
                        }
                        CompanionTab.CHAT -> ChatTab(state, model)
                        CompanionTab.LIVE -> LiveTab(state, model)
                        CompanionTab.PLAYER -> PlayerTab(state, model)
                        CompanionTab.MORE -> MoreTab(state, model)
                    }
                }
            }
        }
    }
    state.error?.let { AlertDialog(onDismissRequest = model::clearError, confirmButton = { TextButton(onClick = model::clearError) { Text("OK") } }, title = { Text("Hinweis") }, text = { Text(it) }) }
}

@Composable private fun StreamNameField(state: CompanionUiState, model: CompanionViewModel) {
    OutlinedTextField(
        value = state.streamName,
        onValueChange = model::setStreamName,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 6.dp).semantics { contentDescription = "Streamname, mit oder ohne At-Zeichen" },
        singleLine = true,
        label = { Text("Streamname (@creator oder creator)") },
        placeholder = { Text("@creator") },
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Go),
        keyboardActions = KeyboardActions(onGo = { model.openStream() }),
        trailingIcon = { IconButton(onClick = model::openStream, enabled = state.streamName.isNotBlank()) { Icon(Icons.Default.PlayArrow, "Stream öffnen") } }
    )
}

@Composable private fun SongTab(state: CompanionUiState, model: CompanionViewModel, recognize: () -> Unit) {
    val context = LocalContext.current
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text("Songerkennung", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Button(onClick = recognize, shape = CircleShape, modifier = Modifier.align(Alignment.CenterHorizontally).size(116.dp).semantics { contentDescription = "Jetzt erkennen; höchstens zwölf Sekunden" }) { Column(horizontalAlignment = Alignment.CenterHorizontally) { Icon(Icons.Default.Search, null, modifier = Modifier.size(34.dp)); Text("Jetzt erkennen", fontWeight = FontWeight.Bold) } }
        SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) { RecognitionSource.entries.forEachIndexed { index, source -> SegmentedButton(selected = state.source == source, onClick = { model.selectSource(source) }, shape = SegmentedButtonDefaults.itemShape(index, RecognitionSource.entries.size)) { Text(source.label, maxLines = 1) } } }
        Row(verticalAlignment = Alignment.CenterVertically) { Icon(Icons.Default.Circle, null, tint = Color(0xFF009B5A), modifier = Modifier.size(10.dp)); Spacer(Modifier.width(8.dp)); Text(state.recognitionStatus, style = MaterialTheme.typography.bodySmall) }
        state.result?.takeIf { it.matched }?.let { result -> ElevatedCard(Modifier.fillMaxWidth()) { Column(Modifier.padding(16.dp)) { Text(result.title, fontWeight = FontWeight.Bold); Text(result.artist, color = Color.Gray); result.songUrl?.let { url -> TextButton(onClick = { BridgeValidator.safeHttpsUrl(url)?.let { safe -> context.startActivity(Intent(Intent.ACTION_VIEW, safe)) } }) { Text("Song öffnen") } } } } }
    }
}

@Composable private fun CapabilityRows(state: CompanionUiState) { ElevatedCard(Modifier.fillMaxWidth()) { Capability("WebSocket-Hook", state.hookAvailable); HorizontalDivider(); Capability("Untertitel", state.captionsAvailable); HorizontalDivider(); Capability("Verbindung", state.connected) } }
@Composable private fun Capability(label: String, available: Boolean) { Row(Modifier.fillMaxWidth().heightIn(min = 46.dp).padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) { Text(label); Spacer(Modifier.weight(1f)); Icon(Icons.Default.Circle, null, tint = if (available) Color(0xFF009B5A) else Color(0xFFD82035), modifier = Modifier.size(11.dp)) } }
@Composable private fun ChatTab(state: CompanionUiState, model: CompanionViewModel) {
    var settingsOpen by remember { mutableStateOf(false) }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("Chat", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        ElevatedCard(Modifier.fillMaxWidth()) { Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) { Text("Neue Nachrichten automatisch vorlesen", Modifier.weight(1f)); Switch(state.ttsEnabled, model::setTtsEnabled) }
            Text("Lautstärke ${state.ttsVolume} %", style = MaterialTheme.typography.labelMedium)
            Slider(state.ttsVolume.toFloat(), { model.setTtsVolume(it.toInt()) }, valueRange = 0f..100f)
            OutlinedButton(onClick = { settingsOpen = true }, modifier = Modifier.fillMaxWidth()) { Icon(Icons.Default.Settings, null); Spacer(Modifier.width(8.dp)); Text("Sprach- und Chat-Einstellungen") }
        } }
        Text("Letzte Chatnachrichten", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        if (state.chatEntries.isEmpty()) Text("Noch keine öffentlichen Chatzeilen empfangen.", color = Color.Gray)
        state.chatEntries.takeLast(5).forEach { line -> ElevatedCard(Modifier.fillMaxWidth()) { Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) { Text(line.visibleText, Modifier.weight(1f)); IconButton(onClick = { model.requestSpeak(line) }) { Icon(Icons.Default.VolumeUp, "Vorlesen") } } } }
        Text("Top-Chatter", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        if (state.topChatters.isEmpty()) Text("Noch keine Personen im Chat beobachtet.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        if (state.topChatters.isNotEmpty()) TextButton(onClick = model::resetTopChatters) { Text("Top-Chatter zurücksetzen") }
        state.topChatters.take(20).forEach { chatter -> ElevatedCard(Modifier.fillMaxWidth()) { Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) { Text(chatter.author); Spacer(Modifier.weight(1f)); Text("${chatter.messages} N · ${chatter.words} W", fontWeight = FontWeight.Bold); IconButton(onClick = { model.muteAuthor(chatter.author) }) { Icon(Icons.Default.VolumeOff, "Stummschalten") } } } }
    }
    if (settingsOpen) SpeechSettingsDialog(state, model) { settingsOpen = false }
}
@Composable private fun SpeechSettingsDialog(state: CompanionUiState, model: CompanionViewModel, close: () -> Unit) {
    AlertDialog(onDismissRequest = close, confirmButton = { TextButton(onClick = close) { Text("Schließen") } }, title = { Text("Sprach- und Chat-Einstellungen") }, text = {
        Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(state.auddToken, model::setAuddToken, label = { Text("AudD API-Token") }, singleLine = true, visualTransformation = PasswordVisualTransformation())
            OutlinedTextField(state.pairingCode, model::setPairingCode, label = { Text("Pairing-Code") }, singleLine = true, visualTransformation = PasswordVisualTransformation())
            OutlinedTextField(state.universalCaptionApiKey, model::setUniversalCaptionApiKey, label = { Text("Universal API-Key für Untertitel") }, singleLine = true, visualTransformation = PasswordVisualTransformation())
            Text("Sprache", style = MaterialTheme.typography.labelMedium)
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) { TtsLanguage.entries.forEachIndexed { index, language -> SegmentedButton(state.ttsLanguage == language, { model.setTtsLanguage(language) }, SegmentedButtonDefaults.itemShape(index, TtsLanguage.entries.size)) { Text(language.label) } } }
            OutlinedTextField(state.ttsVoice, model::setTtsVoice, label = { Text("Stimme") }, singleLine = true)
            Row(verticalAlignment = Alignment.CenterVertically) { Text("Chatnamen sprechen", Modifier.weight(1f)); Switch(state.ttsSpeakNames, model::setTtsSpeakNames) }
            Row(verticalAlignment = Alignment.CenterVertically) { Text("Chatnamen kürzen", Modifier.weight(1f)); Switch(state.ttsShortenNames, model::setTtsShortenNames) }
            Row(verticalAlignment = Alignment.CenterVertically) { Text("Game-Mode", Modifier.weight(1f)); Switch(state.gameModeEnabled, model::setGameMode) }
        }
    })
}
@Composable private fun LiveTab(state: CompanionUiState, model: CompanionViewModel) {
    val context = LocalContext.current
    var recommendationLimit by remember(state.recommendationLimit) { mutableStateOf(state.recommendationLimit.toString()) }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("LIVE-Informationen", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        CapabilityRows(state)
        if (state.liveValues.isEmpty()) Text("Der WebSocket-Hook liefert die Werte nach dem Laden des Streams.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        state.liveValues.toSortedMap().forEach { (key, value) -> ElevatedCard(Modifier.fillMaxWidth()) { Row(Modifier.padding(14.dp)) { Text(key); Spacer(Modifier.weight(1f)); Text(value, fontWeight = FontWeight.Bold) } } }
        Text("Personen stummschalten", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        val activeAuthors = state.chatEntries.map { it.author }.filter { it.isNotBlank() }.distinct().takeLast(20)
        if (activeAuthors.isEmpty()) Text("Noch keine Personen aus dem LIVE-Chat verfügbar.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        activeAuthors.forEach { author -> ElevatedCard(Modifier.fillMaxWidth()) { Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) { Text(author, Modifier.weight(1f)); TextButton(onClick = { model.muteAuthor(author) }) { Icon(Icons.Default.VolumeOff, null); Spacer(Modifier.width(6.dp)); Text("Stumm") } } } }
        Text("Seiteninformationen", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        if (state.pageInfo.isEmpty()) Text("Noch keine Seitenprüfung ausgeführt · „Seite prüfen“ im Tab Mehr.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        state.pageInfo.forEach { (key, value) -> ElevatedCard(Modifier.fillMaxWidth()) { Column(Modifier.padding(14.dp)) { Text(key, style = MaterialTheme.typography.labelMedium, color = Color.Gray); Text(value, fontWeight = FontWeight.Bold) } } }
        Text("LIVE-Empfehlungen", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(recommendationLimit, { recommendationLimit = it.filter(Char::isDigit).take(2) }, label = { Text("Anzahl 1–50") }, enabled = state.recommendationStatus != "running", modifier = Modifier.width(130.dp), singleLine = true)
            if (state.recommendationStatus == "running") OutlinedButton(model::cancelRecommendationScan) { Text("Abbrechen") }
            else Button(onClick = { model.startRecommendationScan(recommendationLimit.toIntOrNull() ?: 20) }) { Text("Scannen") }
        }
        Text("Status: ${state.recommendationStatus} · ${state.recommendationScanned} geprüft · ${state.recommendationItems.size} gefunden", style = MaterialTheme.typography.bodySmall)
        state.recommendationItems.take(50).forEach { item -> ElevatedCard(Modifier.fillMaxWidth()) { Column(Modifier.padding(12.dp)) { Text("@${item.handle}", fontWeight = FontWeight.Bold); Text(item.displayName); Text(item.viewerLabel.ifBlank { item.viewerCount?.toString() ?: "–" }); if (item.title.isNotBlank()) Text(item.title, style = MaterialTheme.typography.bodySmall); TextButton(onClick = { BridgeValidator.safeHttpsUrl(item.url)?.let { context.startActivity(Intent(Intent.ACTION_VIEW, it)) } }) { Text("Stream öffnen") } } } }
    }
}
@Composable private fun PlayerTab(state: CompanionUiState, model: CompanionViewModel) {
    val context = LocalContext.current
    fun copyMedia(label: String, value: String) {
        val clipboard = context.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
        clipboard.setPrimaryClip(android.content.ClipData.newPlainText(label, value))
    }
    fun openExternalVlc() {
        val url = model.bestVlcMediaUrl() ?: return model.reportError("Keine Media-URL verfügbar")
        val vlcIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).setPackage("org.videolan.vlc")
        if (vlcIntent.resolveActivity(context.packageManager) != null) {
            context.startActivity(vlcIntent)
        } else {
            val store = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=org.videolan.vlc"))
            runCatching { context.startActivity(store) }.getOrElse {
                context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=org.videolan.vlc")))
            }
        }
    }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("Player", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        listOf("play" to "Play", "pause" to "Pause", "mute" to "Stumm").chunked(3).forEach { row -> Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) { row.forEach { (command, label) -> OutlinedButton(onClick = { model.sendCommand?.invoke(command, emptyMap()) }, modifier = Modifier.weight(1f)) { Text(label) } } } }
        if (state.playerMuted != false || state.audibleStartBlocked) Button(onClick = model::enableStreamSound, modifier = Modifier.fillMaxWidth()) { Text("Ton aktivieren") }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            // Vollbild nativ: Bridge-„fullscreen" greift im mobilen WebView nicht (0PE-54); PiP ist Nicht-Ziel.
            OutlinedButton(onClick = model::toggleVideoExpanded, modifier = Modifier.weight(1f)) { Text("Vollbild") }
            OutlinedButton(onClick = { model.sendCommand?.invoke("reload-player", emptyMap()) }, modifier = Modifier.weight(1f)) { Text("Neu laden") }
        }
        OutlinedButton(onClick = model::toggleVlcReplacement, enabled = state.mediaUrls.isNotEmpty(), modifier = Modifier.fillMaxWidth()) { Text("VLC Ersatz") }
        OutlinedButton(onClick = ::openExternalVlc, enabled = state.mediaUrls.isNotEmpty(), modifier = Modifier.fillMaxWidth()) { Text("VLC Player") }
        Text("Pegelschutz", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Row(verticalAlignment = Alignment.CenterVertically) { Text("Digitalen Pegelschutz aktivieren", Modifier.weight(1f)); Switch(checked = state.limiterEnabled, onCheckedChange = model::setLimiterEnabled) }
        Row(verticalAlignment = Alignment.CenterVertically) { Text("Grenzwert"); Spacer(Modifier.weight(1f)); Text("${state.limiterThreshold} dBFS", fontWeight = FontWeight.Bold) }
        Slider(value = state.limiterThreshold.toFloat(), onValueChange = { model.setLimiterThreshold(it.toInt()) }, valueRange = -30f..-1f, steps = 28, enabled = state.limiterEnabled)
        Text("dBFS ist ein digitaler Signalpegel, kein am Ohr messbarer dB-SPL-Wert. Der Schutz komprimiert Spitzen oberhalb des Grenzwerts lokal im WebView.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        Text("Media-/VLC-URLs", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        if (state.mediaUrls.isEmpty()) Text("Noch keine direkte Media-URL erkannt. Sie erscheint, sobald TikTok den Player lädt.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        state.mediaUrls.forEach { media -> ElevatedCard(Modifier.fillMaxWidth()) { Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) { Column(Modifier.weight(1f)) { Text(media.kind, style = MaterialTheme.typography.labelMedium, color = Color.Gray); Text(media.url, maxLines = 2) }; TextButton(onClick = { copyMedia("TikTok LIVE Media-URL", media.url) }) { Text("Kopieren") } } } }
        if (state.mediaUrls.isNotEmpty()) OutlinedButton(onClick = { copyMedia("TikTok LIVE Media-URLs", state.mediaUrls.joinToString("\n") { it.url }) }, modifier = Modifier.fillMaxWidth()) { Text("Alle kopieren") }
    }
}
@Composable private fun MoreTab(state: CompanionUiState, model: CompanionViewModel) {
    val context = LocalContext.current
    var reconnectDelay by remember(state.autoReconnectDelaySeconds) { mutableStateOf(state.autoReconnectDelaySeconds.toString()) }
    var pendingCaptionExport by remember { mutableStateOf("") }
    val exportCaption = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/json")) { uri ->
        if (uri != null) context.contentResolver.openOutputStream(uri)?.use { it.write(pendingCaptionExport.toByteArray(Charsets.UTF_8)) }
    }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("Mehr", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Row(verticalAlignment = Alignment.CenterVertically) { Text("Auto-Reconnect", Modifier.weight(1f)); OutlinedTextField(reconnectDelay, { value -> reconnectDelay = value.filter(Char::isDigit).take(2); value.toIntOrNull()?.let(model::setAutoReconnectDelay) }, label = { Text("Sek.") }, singleLine = true, modifier = Modifier.width(88.dp)); Switch(state.autoReconnectEnabled, model::setAutoReconnect) }
        listOf("inspect" to "Seite prüfen", "captions" to "Untertitel aktivieren", "refresh" to "Refresh", "open-report" to "Melden öffnen").forEach { (command, label) -> OutlinedButton(onClick = { model.sendCommand?.invoke(command, emptyMap()) }, modifier = Modifier.fillMaxWidth()) { Text(label) } }
        OutlinedButton(onClick = model::startForce, enabled = !state.forceInProgress, modifier = Modifier.fillMaxWidth()) { Text(if (state.forceInProgress) "Force läuft …" else "Force") }
        state.forceRecoveryUrl?.let { OutlinedButton(onClick = { model.recoverForce() }, modifier = Modifier.fillMaxWidth()) { Text("Manuell zum LIVE-Stream zurück") } }
        Text("Debugmodus", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Row(verticalAlignment = Alignment.CenterVertically) { Text("Validierte Diagnoseereignisse protokollieren", Modifier.weight(1f)); Switch(state.debugEnabled, model::setDebugEnabled) }
        Text("${state.debugEvents.size} vollständige Rohereignisse", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        state.debugEvents.forEach { Text(it, style = MaterialTheme.typography.bodySmall) }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = { val clipboard = context.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager; val vlcInstalled = runCatching { context.packageManager.getPackageInfo("org.videolan.vlc", 0) }.isSuccess; clipboard.setPrimaryClip(android.content.ClipData.newPlainText("TikTok LIVE Companion Debug", model.debugReport(vlcInstalled))) }, enabled = state.debugEvents.isNotEmpty(), modifier = Modifier.weight(1f)) { Text("Debug kopieren") }
            OutlinedButton(onClick = model::clearDebugEvents, enabled = state.debugEvents.isNotEmpty(), modifier = Modifier.weight(1f)) { Text("Leeren") }
        }
        Text("Caption-Protokoll", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Text("${state.captionRecords.size} RAW-Untertitelereignisse", style = MaterialTheme.typography.bodySmall)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = { pendingCaptionExport = model.captionJsonLines(); exportCaption.launch("tiktok-live-captions.jsonl") }, enabled = state.captionRecords.isNotEmpty(), modifier = Modifier.weight(1f)) { Text("JSON-L-Export") }
            OutlinedButton(onClick = { pendingCaptionExport = model.captionRawJson(); exportCaption.launch("tiktok-live-caption-raw.json") }, enabled = state.captionRecords.isNotEmpty(), modifier = Modifier.weight(1f)) { Text("RAW-JSON-Export") }
        }
        TextButton(onClick = model::clearCaptions, enabled = state.captionRecords.isNotEmpty()) { Text("Caption-Protokoll leeren") }
        Text("Nicht verfügbare WebView-Funktionen werden als Status angezeigt. Eine Meldung wird nie automatisch ausgefüllt oder abgesendet.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
    }
}

inline fun <reified T : androidx.lifecycle.ViewModel> simpleViewModelFactory(crossinline create: () -> T) = object : androidx.lifecycle.ViewModelProvider.Factory { override fun <R : androidx.lifecycle.ViewModel> create(modelClass: Class<R>): R = create() as R }
