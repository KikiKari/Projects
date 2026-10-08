package app.tiktoklivecompanion

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.companionDataStore by preferencesDataStore(name = "companion_settings")

class CompanionPreferences(private val context: Context) {
    private val sourceKey = stringPreferencesKey("recognition_source")
    private val mutedAuthorsKey = stringSetPreferencesKey("muted_authors")
    val source: Flow<RecognitionSource> = context.companionDataStore.data.map { values ->
        runCatching { RecognitionSource.valueOf(values[sourceKey] ?: "MICROPHONE") }.getOrDefault(RecognitionSource.MICROPHONE)
    }
    val mutedAuthors: Flow<Set<String>> = context.companionDataStore.data.map { values -> values[mutedAuthorsKey] ?: emptySet() }
    private val limiterEnabledKey = booleanPreferencesKey("limiter_enabled")
    private val limiterThresholdKey = intPreferencesKey("limiter_threshold")
    private val limiterStrengthKey = intPreferencesKey("limiter_strength")
    private val ttsEnabledKey = booleanPreferencesKey("tts_enabled")
    private val ttsVolumeKey = intPreferencesKey("tts_volume_percent")
    private val ttsLanguageKey = stringPreferencesKey("tts_language")
    private val ttsSpeakNamesKey = booleanPreferencesKey("tts_speak_names")
    private val ttsShortenNamesKey = booleanPreferencesKey("tts_shorten_names")
    private val autoReconnectKey = booleanPreferencesKey("auto_reconnect")
    private val autoReconnectDelayKey = intPreferencesKey("auto_reconnect_delay_seconds")
    private val hookEnabledKey = booleanPreferencesKey("hook_reconnect_enabled")
    private val hookDelayKey = intPreferencesKey("hook_reconnect_delay_seconds")
    val hookEnabled: Flow<Boolean> = context.companionDataStore.data.map { it[hookEnabledKey] ?: false }
    val hookDelay: Flow<Int> = context.companionDataStore.data.map { (it[hookDelayKey] ?: 3).coerceIn(1, 59) }
    suspend fun setHookEnabled(value: Boolean) { context.companionDataStore.edit { it[hookEnabledKey] = value } }
    suspend fun setHookDelay(value: Int) { context.companionDataStore.edit { it[hookDelayKey] = value.coerceIn(1, 59) } }
    private val auddTokenKey = stringPreferencesKey("audd_token")
    private val pairingCodeKey = stringPreferencesKey("pairing_code")
    private val universalApiKey = stringPreferencesKey("universal_caption_api_key")
    private val filterExternalSpeechTriggersKey = booleanPreferencesKey("filterExternalSpeechTriggers")
    val filterExternalSpeechTriggers: Flow<Boolean> = context.companionDataStore.data.map { it[filterExternalSpeechTriggersKey] ?: false }
    suspend fun setFilterExternalSpeechTriggers(enabled: Boolean) { context.companionDataStore.edit { it[filterExternalSpeechTriggersKey] = enabled } }
    private val gameModeKey = booleanPreferencesKey("game_mode")
    private val ttsVoiceKey = stringPreferencesKey("tts_voice")
    val limiterEnabled: Flow<Boolean> = context.companionDataStore.data.map { values -> values[limiterEnabledKey] ?: false }
    val limiterThreshold: Flow<Int> = context.companionDataStore.data.map { values -> (values[limiterThresholdKey] ?: -6).coerceIn(-30, -1) }
    val limiterStrength: Flow<Int> = context.companionDataStore.data.map { values ->
        (values[limiterStrengthKey] ?: (((-(values[limiterThresholdKey] ?: -6) - 4) * 100) / 26)).coerceIn(0, 100)
    }
    val ttsEnabled: Flow<Boolean> = context.companionDataStore.data.map { it[ttsEnabledKey] ?: false }
    val ttsVolume: Flow<Int> = context.companionDataStore.data.map { (it[ttsVolumeKey] ?: 100).coerceIn(0, 100) }
    val ttsLanguage: Flow<TtsLanguage> = context.companionDataStore.data.map { values -> runCatching { TtsLanguage.valueOf(values[ttsLanguageKey] ?: "AUTO") }.getOrDefault(TtsLanguage.AUTO) }
    val ttsSpeakNames: Flow<Boolean> = context.companionDataStore.data.map { it[ttsSpeakNamesKey] ?: true }
    val ttsShortenNames: Flow<Boolean> = context.companionDataStore.data.map { it[ttsShortenNamesKey] ?: true }
    val autoReconnect: Flow<Boolean> = context.companionDataStore.data.map { it[autoReconnectKey] ?: false }
    val autoReconnectDelay: Flow<Int> = context.companionDataStore.data.map { (it[autoReconnectDelayKey] ?: 3).coerceIn(1, 59) }
    val auddToken: Flow<String> = context.companionDataStore.data.map { it[auddTokenKey] ?: "" }
    val pairingCode: Flow<String> = context.companionDataStore.data.map { it[pairingCodeKey] ?: "" }
    val universalCaptionApiKey: Flow<String> = context.companionDataStore.data.map { it[universalApiKey] ?: "" }
    val gameMode: Flow<Boolean> = context.companionDataStore.data.map { it[gameModeKey] ?: true }
    val ttsVoice: Flow<String> = context.companionDataStore.data.map { it[ttsVoiceKey] ?: "Systemstandard" }

    suspend fun setSource(source: RecognitionSource) {
        context.companionDataStore.edit { values -> values[sourceKey] = source.name }
    }

    suspend fun setMutedAuthors(authors: Set<String>) {
        context.companionDataStore.edit { values -> values[mutedAuthorsKey] = authors }
    }

    suspend fun setLimiterEnabled(enabled: Boolean) {
        context.companionDataStore.edit { values -> values[limiterEnabledKey] = enabled }
    }

    suspend fun setLimiterThreshold(threshold: Int) {
        context.companionDataStore.edit { values ->
            val safe = threshold.coerceIn(-30, -1)
            values[limiterThresholdKey] = safe
            values[limiterStrengthKey] = (((-safe - 4) * 100) / 26).coerceIn(0, 100)
        }
    }
    suspend fun setLimiter(enabled: Boolean, strength: Int) {
        context.companionDataStore.edit { values ->
            val safe = strength.coerceIn(0, 100)
            values[limiterEnabledKey] = enabled
            values[limiterStrengthKey] = safe
            values[limiterThresholdKey] = -4 - safe * 26 / 100
        }
    }

    suspend fun setTtsEnabled(enabled: Boolean) { context.companionDataStore.edit { it[ttsEnabledKey] = enabled } }
    suspend fun setTtsVolume(volume: Int) { context.companionDataStore.edit { it[ttsVolumeKey] = volume.coerceIn(0, 100) } }
    suspend fun setTtsLanguage(language: TtsLanguage) { context.companionDataStore.edit { it[ttsLanguageKey] = language.name } }
    suspend fun setTtsSpeakNames(enabled: Boolean) { context.companionDataStore.edit { it[ttsSpeakNamesKey] = enabled } }
    suspend fun setTtsShortenNames(enabled: Boolean) { context.companionDataStore.edit { it[ttsShortenNamesKey] = enabled } }
    suspend fun setAutoReconnect(enabled: Boolean) { context.companionDataStore.edit { it[autoReconnectKey] = enabled } }
    suspend fun setAutoReconnectDelay(seconds: Int) { context.companionDataStore.edit { it[autoReconnectDelayKey] = seconds.coerceIn(1, 59) } }
    suspend fun setAuddToken(value: String) { context.companionDataStore.edit { it[auddTokenKey] = value.take(4096) } }
    suspend fun setPairingCode(value: String) { context.companionDataStore.edit { it[pairingCodeKey] = value.take(512) } }
    suspend fun setUniversalCaptionApiKey(value: String) { context.companionDataStore.edit { it[universalApiKey] = value.take(4096) } }
    suspend fun setGameMode(enabled: Boolean) { context.companionDataStore.edit { it[gameModeKey] = enabled } }
    suspend fun setTtsVoice(value: String) { context.companionDataStore.edit { it[ttsVoiceKey] = value.take(160) } }
}
