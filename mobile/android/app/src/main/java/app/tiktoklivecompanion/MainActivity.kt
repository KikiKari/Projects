package app.tiktoklivecompanion

import android.Manifest
import android.content.Intent
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
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
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

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val engine = remember { createRecognitionEngine(applicationContext) }
            val model: CompanionViewModel = viewModel(factory = simpleViewModelFactory { CompanionViewModel(engine, CompanionPreferences(applicationContext)) })
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
    // Querformat: Video kleiner halten, damit Inhalt unter dem Menüband sichtbar und scrollbar bleibt (0PE-56).
    val videoHeight = if (landscape) minOf(configuration.screenHeightDp * 0.35f, 220f).dp else (configuration.screenHeightDp * 0.5f).dp
    Scaffold(topBar = { if (!state.videoExpanded) TopAppBar(title = { Row(verticalAlignment = Alignment.CenterVertically) { Icon(Icons.Default.GraphicEq, null, tint = Color.White, modifier = Modifier.background(Accent, RoundedCornerShape(8.dp)).padding(7.dp)); Spacer(Modifier.width(10.dp)); Text("TikTok LIVE Companion", fontWeight = FontWeight.Bold) } }, actions = { Icon(Icons.Default.Circle, null, tint = Accent, modifier = Modifier.size(9.dp)); Text(" LIVE", fontSize = 12.sp); Spacer(Modifier.width(14.dp)) }) }) { insets ->
        Column(Modifier.padding(insets).fillMaxSize()) {
            if (!state.videoExpanded) StreamNameField(state, model)
            CompanionWebView(model, if (state.videoExpanded) Modifier.fillMaxSize() else Modifier.fillMaxWidth().height(videoHeight), onTap = model::toggleVideoExpanded)
            if (!state.videoExpanded) {
                PrimaryTabRow(selectedTabIndex = state.tab.ordinal) { CompanionTab.entries.forEach { tab -> Tab(selected = state.tab == tab, onClick = { model.selectTab(tab) }, text = { Text(tab.label) }) } }
                Box(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                    when (state.tab) {
                        CompanionTab.SONG -> SongTab(state, model) {
                            if (state.source == RecognitionSource.MICROPHONE && ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) micPermission.launch(Manifest.permission.RECORD_AUDIO) else model.recognize()
                        }
                        CompanionTab.CHAT -> ChatTab(state, model)
                        CompanionTab.LIVE -> LiveTab(state)
                        CompanionTab.PLAYER -> PlayerTab(state, model)
                        CompanionTab.MORE -> MoreTab(model)
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
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("Chat", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        ElevatedCard(Modifier.fillMaxWidth()) { Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) { Text("Neue Nachrichten automatisch vorlesen", Modifier.weight(1f)); Switch(state.ttsEnabled, model::setTtsEnabled) }
            Text("Lautstärke ${state.ttsVolume} %", style = MaterialTheme.typography.labelMedium)
            Slider(state.ttsVolume.toFloat(), { model.setTtsVolume(it.toInt()) }, valueRange = 0f..100f)
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) { TtsLanguage.entries.forEachIndexed { index, language -> SegmentedButton(state.ttsLanguage == language, { model.setTtsLanguage(language) }, SegmentedButtonDefaults.itemShape(index, TtsLanguage.entries.size)) { Text(language.label) } } }
            Row(verticalAlignment = Alignment.CenterVertically) { Text("Chatnamen vorlesen", Modifier.weight(1f)); Switch(state.ttsSpeakNames, model::setTtsSpeakNames) }
            Row(verticalAlignment = Alignment.CenterVertically) { Text("Lange Namen kürzen", Modifier.weight(1f)); Switch(state.ttsShortenNames, model::setTtsShortenNames) }
        } }
        if (state.chatEntries.isEmpty()) Text("Noch keine öffentlichen Chatzeilen empfangen.", color = Color.Gray)
        state.chatEntries.forEach { line -> ElevatedCard(Modifier.fillMaxWidth()) { Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) { Text(line.visibleText, Modifier.weight(1f)); IconButton(onClick = { model.requestSpeak(line) }) { Icon(Icons.Default.VolumeUp, "Vorlesen") }; line.author.takeIf { it.isNotBlank() }?.let { author -> IconButton(onClick = { model.muteAuthor(author) }) { Icon(Icons.Default.VolumeOff, "Autor dauerhaft stummschalten") } } } } }
    }
}
@Composable private fun LiveTab(state: CompanionUiState) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("LIVE-Informationen", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        CapabilityRows(state)
        if (state.liveValues.isEmpty()) Text("Der WebSocket-Hook liefert die Werte nach dem Laden des Streams.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        state.liveValues.toSortedMap().forEach { (key, value) -> ElevatedCard(Modifier.fillMaxWidth()) { Row(Modifier.padding(14.dp)) { Text(key); Spacer(Modifier.weight(1f)); Text(value, fontWeight = FontWeight.Bold) } } }
        Text("Top-Chatter", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        if (state.topChatters.isEmpty()) Text("Noch keine Personen im Chat beobachtet.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        state.topChatters.forEach { (author, count) -> ElevatedCard(Modifier.fillMaxWidth()) { Row(Modifier.padding(14.dp)) { Text(author); Spacer(Modifier.weight(1f)); Text("$count", fontWeight = FontWeight.Bold) } } }
        Text("Seiteninformationen", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        if (state.pageInfo.isEmpty()) Text("Noch keine Seitenprüfung ausgeführt · „Seite prüfen“ im Tab Mehr.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        state.pageInfo.forEach { (key, value) -> ElevatedCard(Modifier.fillMaxWidth()) { Column(Modifier.padding(14.dp)) { Text(key, style = MaterialTheme.typography.labelMedium, color = Color.Gray); Text(value, fontWeight = FontWeight.Bold) } } }
    }
}
@Composable private fun PlayerTab(state: CompanionUiState, model: CompanionViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("Player", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        listOf("play" to "Play", "pause" to "Pause", "mute" to "Stumm").chunked(3).forEach { row -> Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) { row.forEach { (command, label) -> OutlinedButton(onClick = { model.sendCommand?.invoke(command, emptyMap()) }, modifier = Modifier.weight(1f)) { Text(label) } } } }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            // Vollbild nativ: Bridge-„fullscreen" greift im mobilen WebView nicht (0PE-54); PiP ist Nicht-Ziel.
            OutlinedButton(onClick = model::toggleVideoExpanded, modifier = Modifier.weight(1f)) { Text("Vollbild") }
            OutlinedButton(onClick = { model.sendCommand?.invoke("reload-player", emptyMap()) }, modifier = Modifier.weight(1f)) { Text("Neu laden") }
        }
        Text("Pegelschutz", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Row(verticalAlignment = Alignment.CenterVertically) { Text("Digitalen Pegelschutz aktivieren", Modifier.weight(1f)); Switch(checked = state.limiterEnabled, onCheckedChange = model::setLimiterEnabled) }
        Row(verticalAlignment = Alignment.CenterVertically) { Text("Grenzwert"); Spacer(Modifier.weight(1f)); Text("${state.limiterThreshold} dBFS", fontWeight = FontWeight.Bold) }
        Slider(value = state.limiterThreshold.toFloat(), onValueChange = { model.setLimiterThreshold(it.toInt()) }, valueRange = -30f..-1f, steps = 28, enabled = state.limiterEnabled)
        Text("dBFS ist ein digitaler Signalpegel, kein am Ohr messbarer dB-SPL-Wert. Der Schutz komprimiert Spitzen oberhalb des Grenzwerts lokal im WebView.", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
    }
}
@Composable private fun MoreTab(model: CompanionViewModel) { Column(verticalArrangement = Arrangement.spacedBy(10.dp)) { Text("Mehr", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold); listOf("inspect" to "Seite prüfen", "captions" to "Untertitel aktivieren", "refresh" to "Refresh", "force-profile" to "Force", "open-report" to "Melden öffnen").forEach { (command, label) -> OutlinedButton(onClick = { model.sendCommand?.invoke(command, emptyMap()) }, modifier = Modifier.fillMaxWidth()) { Text(label) } }; Text("Nicht verfügbare WebView-Funktionen werden als Status angezeigt. Eine Meldung wird nie automatisch ausgefüllt oder abgesendet.", style = MaterialTheme.typography.bodySmall, color = Color.Gray) } }

inline fun <reified T : androidx.lifecycle.ViewModel> simpleViewModelFactory(crossinline create: () -> T) = object : androidx.lifecycle.ViewModelProvider.Factory { override fun <R : androidx.lifecycle.ViewModel> create(modelClass: Class<R>): R = create() as R }
