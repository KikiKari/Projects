package app.tiktoklivecompanion

import android.content.ClipData
import android.content.ClipboardManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.activity.compose.BackHandler
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.currentStateAsState
import androidx.lifecycle.repeatOnLifecycle
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.videolan.libvlc.LibVLC
import org.videolan.libvlc.Media
import org.videolan.libvlc.MediaPlayer
import org.videolan.libvlc.util.VLCVideoLayout
import java.util.concurrent.atomic.AtomicBoolean

/** Runs while the main app is visible and the monitor screen is closed. */
@Composable
internal fun MonitorForeground() {
    val context = LocalContext.current
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    val preferences = remember { MonitorPreferences(context) }
    val probe = remember { MonitorProbe() }
    LaunchedEffect(lifecycle) {
        val initial = preferences.load()
        MonitorWorker.schedule(context, initial)
        lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            while (true) {
                val config = preferences.load()
                if (config.enabled) {
                    for ((index, handle) in config.handles.withIndex()) {
                        if (handle.isNotEmpty()) {
                            val revision = preferences.revision(index)
                            val row = withContext(Dispatchers.IO) { probe.check(handle, config.maxLinks) }
                            preferences.saveStatus(index, row, revision)
                        }
                    }
                }
                delay(config.intervalMinutes * 60_000L)
            }
        }
    }
}

/** Monitor configuration is persisted separately from session-only rows. */
@Composable
internal fun MonitorScreen(close: () -> Unit) {
    val context = LocalContext.current
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    val preferences = remember { MonitorPreferences(context) }
    var config by remember { mutableStateOf(preferences.load()) }
    var rows by remember { mutableStateOf(preferences.loadRows(config)) }
    var gridOpen by remember { mutableStateOf(false) }
    var settings by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }
    val expanded = remember { mutableStateMapOf<Int, Boolean>() }
    val scope = rememberCoroutineScope()
    val probe = remember { MonitorProbe() }
    val checking = remember { mutableStateMapOf<Int, Int>() }
    val playingSlots = remember { mutableStateMapOf<Int, Boolean>() }
    val revisions = remember { IntArray(MonitorConfig.SLOT_COUNT) }
    val lifecycleState by lifecycle.currentStateAsState()
    val currentConfig by rememberUpdatedState(config)
    BackHandler { if (gridOpen) gridOpen = false else close() }
    fun save(next: MonitorConfig) { config = next; preferences.save(next); MonitorWorker.schedule(context, next) }
    fun check(index: Int, force: Boolean = true) {
        val handle = config.handles[index]
        val revision = revisions[index]
        val storedRevision = preferences.revision(index)
        if (handle.isEmpty() || checking[index] == revision) return
        val visibleSlots = if (config.gridNine) (0 until 9).toList() else config.selectedSlots
        if (!force && config.skipOnline && rows[index].status == MonitorStatus.ONLINE && rows[index].sources.any { MonitorProbe.isUsableSource(it) }) return
        if (!force && gridOpen && index in visibleSlots && playingSlots[index] == true && rows[index].sources.any { MonitorProbe.isUsableSource(it) }) return
        checking[index] = revision
        rows = applyMonitorResult(rows, index, rows[index].copy(status = MonitorStatus.CHECKING))
        scope.launch {
            try {
                val result = withContext(Dispatchers.IO) { probe.check(handle, currentConfig.maxLinks) }
                if (revisions[index] == revision && currentConfig.handles[index] == handle) {
                    rows = applyMonitorResult(rows, index, result)
                    preferences.saveStatus(index, result, storedRevision)
                }
            } finally {
                // An older request must not clear a newer request for the same slot.
                if (checking[index] == revision) checking.remove(index)
            }
        }
    }
    fun copy(text: String) {
        if (text.isBlank()) {
            message = "Keine gültigen Links verfügbar. Bitte erneut prüfen."
            return
        }
        (context.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as ClipboardManager)
            .setPrimaryClip(ClipData.newPlainText("LIVE-Links", text))
        message = null
    }
    LaunchedEffect(lifecycle, config.enabled, config.intervalMinutes) {
        MonitorWorker.schedule(context, config)
        lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            val stored = preferences.loadRows(currentConfig)
            rows = rows.mapIndexed { i, row ->
                val saved = stored[i]
                if (row.sources.isEmpty() && (saved.checkedAtMillis ?: 0) > (row.checkedAtMillis ?: 0)) saved else row
            }
            while (config.enabled) {
                for (i in 0 until MonitorConfig.SLOT_COUNT) check(i, force = false)
                delay(config.intervalMinutes * 60_000L)
            }
        }
    }
    if (gridOpen) {
        val selected = if (config.gridNine) (0 until 9).toList() else config.selectedSlots
        val sorted = if (config.autoSort) selected.sortedBy { rows[it].status != MonitorStatus.ONLINE } else selected
        val slots = if (config.reverse) sorted.reversed() else sorted
        val columns = if (config.gridNine) 3 else 2
        Column(Modifier.fillMaxSize().background(Color.Black)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                IconButton(onClick = { gridOpen = false }, modifier = Modifier.semantics { contentDescription = "Zurück zur Monitorliste" }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, tint = Color.White) }
                IconButton(onClick = { for (i in 0 until MonitorConfig.SLOT_COUNT) check(i) }, modifier = Modifier.semantics { contentDescription = "Alle prüfen" }) { CompanionControlIcon("status") }
                IconButton(onClick = close, modifier = Modifier.semantics { contentDescription = "Monitor schließen" }) { Icon(Icons.Default.Close, contentDescription = null, tint = Color.White) }
            }
            slots.chunked(columns).forEach { line ->
                Row(Modifier.fillMaxWidth().weight(1f)) {
                    line.forEach { index ->
                        key(index, rows[index].handle) {
                            MonitorTile(rows[index], Modifier.weight(1f).fillMaxHeight(), lifecycleState.isAtLeast(Lifecycle.State.STARTED), refresh = { check(index) }, onPlaybackChanged = { playingSlots[index] = it })
                        }
                    }
                }
            }
        }
        return
    }
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(12.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            IconButton(onClick = close, modifier = Modifier.semantics { contentDescription = "Monitor schließen" }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null) }
            Row {
                IconButton(onClick = { settings = true }, modifier = Modifier.semantics { contentDescription = "Einstellungen" }) { CompanionControlIcon("settings") }
                IconButton(onClick = { gridOpen = true }, modifier = Modifier.semantics { contentDescription = "Übersicht öffnen" }) { CompanionControlIcon("player") }
                IconButton(onClick = { for (i in 0 until MonitorConfig.SLOT_COUNT) check(i) }, modifier = Modifier.semantics { contentDescription = "Alle prüfen" }) { CompanionControlIcon("status") }
            }
        }
        val orderedRows = rows.indices.toList().let { indices -> if (config.autoSort) indices.sortedBy { rows[it].status != MonitorStatus.ONLINE } else indices }
        orderedRows.forEach { index ->
            val row = rows[index]
            Column {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("● ", color = when (row.status) {
                        MonitorStatus.ONLINE -> Color(0xFF16833B)
                        MonitorStatus.OFFLINE -> Color(0xFFBE2535)
                        MonitorStatus.ERROR -> Color(0xFFAB6200)
                        else -> Color.Gray
                    })
                    val checked = row.checkedAtMillis?.let { "\nGeprüft: ${android.text.format.DateFormat.getTimeFormat(context).format(java.util.Date(it))}" }.orEmpty()
                    Text("${index + 1}. @${row.handle.ifBlank { "–" }} · ${when (row.status) { MonitorStatus.UNKNOWN -> "unbekannt"; MonitorStatus.CHECKING -> "prüft"; MonitorStatus.ONLINE -> "online"; MonitorStatus.OFFLINE -> "offline"; MonitorStatus.ERROR -> "Fehler" }} · ${row.sources.size} Links$checked", Modifier.weight(1f))
                    TextButton(onClick = { check(index) }, modifier = Modifier.semantics { contentDescription = "${row.handle} erneut prüfen" }, enabled = row.handle.isNotBlank()) { Text("↻") }
                    TextButton(onClick = { if (config.showLinks) expanded[index] = expanded[index] != true else copy(row.sources.filter { MonitorProbe.isUsableSource(it) }.joinToString("\n")) }, enabled = row.sources.isNotEmpty()) { Text(if (config.showLinks) "Anzeigen" else "Kopieren") }
                }
                if (expanded[index] == true && row.sources.isNotEmpty()) {
                    TextButton(onClick = { copy(row.sources.filter { MonitorProbe.isUsableSource(it) }.joinToString("\n")) }) { Text("Alle Links dieses Handles kopieren") }
                    row.sources.forEach { source ->
                        Row(Modifier.fillMaxWidth()) {
                            Text("${monitorSourceLabel(source)}\n$source", Modifier.weight(1f), maxLines = 3)
                            TextButton(onClick = { copy(source.takeIf { MonitorProbe.isUsableSource(it) }.orEmpty()) }) { Text("Kopieren") }
                        }
                    }
                }
            }
        }
        message?.let { Text(it, color = MaterialTheme.colorScheme.error) }
    }
    if (settings) {
        var draft by remember { mutableStateOf(config.handles) }
        var interval by remember { mutableStateOf(config.intervalMinutes.toString()) }
        var maxLinks by remember { mutableStateOf(config.maxLinks.toString()) }
        var selected by remember { mutableStateOf(config.selectedSlots) }
        var nine by remember { mutableStateOf(config.gridNine) }
        var enabled by remember { mutableStateOf(config.enabled) }
        var showLinks by remember { mutableStateOf(config.showLinks) }
        var autoSort by remember { mutableStateOf(config.autoSort) }
        var skipOnline by remember { mutableStateOf(config.skipOnline) }
        var reverse by remember { mutableStateOf(config.reverse) }
        AlertDialog(onDismissRequest = { settings = false }, title = { Text("Monitor-Einstellungen") }, text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                message?.let { Text(it, color = MaterialTheme.colorScheme.error) }
                draft.forEachIndexed { index, value ->
                    OutlinedTextField(value = value, onValueChange = { input -> draft = draft.toMutableList().apply { this[index] = input } }, label = { Text("Handle ${index + 1}") }, singleLine = true)
                }
                Row { Checkbox(checked = nine, onCheckedChange = { nine = it }); Text("3×3 statt 2×2") }
                Row { Checkbox(checked = enabled, onCheckedChange = { enabled = it }); Text("Automatisch prüfen") }
                Row { Checkbox(checked = showLinks, onCheckedChange = { showLinks = it }); Text("Links anzeigen statt direkt kopieren") }
                Row { Checkbox(checked = autoSort, onCheckedChange = { autoSort = it }); Text("Online-Streams zuerst anzeigen") }
                Row { Checkbox(checked = skipOnline, onCheckedChange = { skipOnline = it }); Text("Online-Streams mit gültigen Links nicht automatisch erneut prüfen") }
                Row { Checkbox(checked = reverse, onCheckedChange = { reverse = it }); Text("Reihenfolge der Übersicht umkehren") }
                OutlinedTextField(value = interval, onValueChange = { interval = it }, label = { Text("Intervall in Minuten (1–60)") }, singleLine = true)
                OutlinedTextField(value = maxLinks, onValueChange = { maxLinks = it }, label = { Text("Linkobergrenze (5–30)") }, singleLine = true)
                Text("2×2-Zuordnung: Tippen wechselt den jeweiligen Platz")
                selected.forEachIndexed { tile, slot ->
                    TextButton(onClick = {
                        val next = (1..9).map { (slot + it) % 9 }.first { it !in selected }
                        selected = selected.toMutableList().apply { this[tile] = next }
                    }) { Text("Kachel ${tile + 1}: Platz ${slot + 1}") }
                }
            }
        }, confirmButton = { TextButton(onClick = {
            val next = runCatching { MonitorConfig(handles = draft.map(MonitorConfig::normalizeHandle), selectedSlots = selected, gridNine = nine, intervalMinutes = interval.toInt(), enabled = enabled, maxLinks = maxLinks.toInt(), showLinks = showLinks, autoSort = autoSort, skipOnline = skipOnline, reverse = reverse) }
            next.onSuccess { value ->
                rows = rows.mapIndexed { i, row -> if (row.handle == value.handles[i]) row else { revisions[i]++; MonitorRow(value.handles[i]) } }
                save(value); message = null; settings = false
            }.onFailure { message = "Ungültige oder doppelte Handles, Zuordnung oder Intervall." }
        }) { Text("Speichern") } }, dismissButton = { TextButton(onClick = { settings = false }) { Text("Abbrechen") } })
    }
}

@Composable
private fun MonitorTile(row: MonitorRow, modifier: Modifier, active: Boolean, refresh: () -> Unit, onPlaybackChanged: (Boolean) -> Unit) {
    var muted by remember(row.handle) { mutableStateOf(true) }
    var audioError by remember(row.handle, row.sources) { mutableStateOf<String?>(null) }
    var sourceIndex by remember(row.handle, row.sources) { mutableIntStateOf(0) }
    var generation by remember(row.handle) { mutableIntStateOf(0) }
    var failed by remember(row.handle, row.sources, generation) { mutableStateOf(false) }
    var playing by remember(row.handle, row.sources, sourceIndex, generation, active) { mutableStateOf(false) }
    val currentSource = sourceIndex
    val advance = {
        if (sourceIndex == currentSource && !failed) {
            val next = nextMonitorSource(sourceIndex, row.sources.size, manual = false)
            if (next == null) failed = true else sourceIndex = next
        }
    }
    LaunchedEffect(row.handle, row.sources, sourceIndex, generation, active) {
        if (active && row.sources.getOrNull(sourceIndex) != null) {
            delay(15_000)
            if (!playing) advance()
        }
    }
    Column(modifier.padding(3.dp).background(Color.DarkGray)) {
        Text("@${row.handle.ifBlank { "–" }}", color = Color.White, maxLines = 1)
        Box(Modifier.weight(1f).fillMaxWidth()) {
            val source = row.sources.getOrNull(sourceIndex)
            if (source != null && !failed && active) {
                key(source, generation) {
                    MonitorVlcSurface(source, Modifier.fillMaxSize(), muted, onPlaying = { playing = true; onPlaybackChanged(true) }, onStop = { onPlaybackChanged(false) }, onError = { onPlaybackChanged(false); advance() }, onAudioError = { audioError = it })
                }
            } else Text(if (failed) "Keine Quelle abspielbar" else "Kein Videolink", color = Color.White)
        }
        audioError?.let { Text(it, color = Color.White, maxLines = 2) }
        Row {
            IconButton(onClick = { muted = !muted }, enabled = row.sources.isNotEmpty(), modifier = Modifier.semantics { contentDescription = if (muted) "Ton für ${row.handle} einschalten" else "Ton für ${row.handle} stummschalten" }) {
                CompanionControlIcon(if (muted) "mute" else "unmute")
            }
            IconButton(modifier = Modifier.semantics { contentDescription = "Stream ${row.handle} neu starten oder nächste Quelle prüfen" }, onClick = {
                if (row.sources.none { MonitorProbe.isUsableSource(it) }) refresh()
                else { sourceIndex = nextMonitorSource(sourceIndex, row.sources.size, manual = true) ?: 0; generation++ }
            }) { CompanionControlIcon("reset") }
        }
    }
}

@Composable
private fun MonitorVlcSurface(url: String, modifier: Modifier, muted: Boolean, onPlaying: () -> Unit, onStop: () -> Unit, onError: () -> Unit, onAudioError: (String?) -> Unit) {
    val context = LocalContext.current
    val callback by rememberUpdatedState(onError)
    val playingCallback by rememberUpdatedState(onPlaying)
    val stopCallback by rememberUpdatedState(onStop)
    val mutedState by rememberUpdatedState(muted)
    val audioErrorCallback by rememberUpdatedState(onAudioError)
    val view = remember { VLCVideoLayout(context) }
    val lib = remember { LibVLC(context, arrayListOf("--network-caching=1500")) }
    val player = remember { MediaPlayer(lib) }
    val audio = remember(player) { mutableStateOf<NativeVlcAudio?>(null) }
    val handler = remember { Handler(Looper.getMainLooper()) }
    AndroidView(factory = { view }, modifier = modifier)
    LaunchedEffect(player, muted) {
        audio.value?.setMuted(muted)
        player.volume = if (muted) 0 else 100
    }
    DisposableEffect(player, url) {
        val closed = AtomicBoolean(false)
        val ended = AtomicBoolean(false)
        player.setEventListener { event ->
            when (event.type) {
                MediaPlayer.Event.Playing -> handler.post {
                    if (!closed.get() && !ended.get()) {
                        player.volume = if (mutedState) 0 else 100
                        playingCallback()
                    }
                }
                MediaPlayer.Event.EncounteredError, MediaPlayer.Event.EndReached -> {
                    if (ended.compareAndSet(false, true)) handler.post { if (!closed.get()) callback() }
                }
                else -> Unit
            }
        }
        player.attachViews(view, null, false, false)
        try {
            audio.value = NativeVlcAudio { _, _, _, _, error -> if (error != null) audioErrorCallback(error) }
            audio.value!!.install(player)
            audio.value!!.setMuted(muted)
            audioErrorCallback(null)
        } catch (error: Throwable) {
            audio.value?.beginStop()
            audio.value?.releaseAfterPlayerStopped()
            audio.value = null
            audioErrorCallback("Audioausgabe nicht verfügbar")
        }
        player.volume = if (muted) 0 else 100
        val media = Media(lib, Uri.parse(url))
        try { media.setHWDecoderEnabled(true, false); player.media = media; player.play() } finally { media.release() }
        onDispose { closed.set(true); stopCallback(); player.setEventListener(null); audio.value?.beginStop(); player.stop(); audio.value?.releaseAfterPlayerStopped(); audio.value = null; player.detachViews(); player.release(); lib.release() }
    }
}
