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
    private val ttsEnabledKey = booleanPreferencesKey("tts_enabled")
    private val ttsVolumeKey = intPreferencesKey("tts_volume_percent")
    private val ttsLanguageKey = stringPreferencesKey("tts_language")
    private val ttsSpeakNamesKey = booleanPreferencesKey("tts_speak_names")
    private val ttsShortenNamesKey = booleanPreferencesKey("tts_shorten_names")
    val limiterEnabled: Flow<Boolean> = context.companionDataStore.data.map { values -> values[limiterEnabledKey] ?: false }
    val limiterThreshold: Flow<Int> = context.companionDataStore.data.map { values -> (values[limiterThresholdKey] ?: -6).coerceIn(-30, -1) }
    val ttsEnabled: Flow<Boolean> = context.companionDataStore.data.map { it[ttsEnabledKey] ?: false }
    val ttsVolume: Flow<Int> = context.companionDataStore.data.map { (it[ttsVolumeKey] ?: 100).coerceIn(0, 100) }
    val ttsLanguage: Flow<TtsLanguage> = context.companionDataStore.data.map { values -> runCatching { TtsLanguage.valueOf(values[ttsLanguageKey] ?: "AUTO") }.getOrDefault(TtsLanguage.AUTO) }
    val ttsSpeakNames: Flow<Boolean> = context.companionDataStore.data.map { it[ttsSpeakNamesKey] ?: true }
    val ttsShortenNames: Flow<Boolean> = context.companionDataStore.data.map { it[ttsShortenNamesKey] ?: true }

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
        context.companionDataStore.edit { values -> values[limiterThresholdKey] = threshold.coerceIn(-30, -1) }
    }

    suspend fun setTtsEnabled(enabled: Boolean) { context.companionDataStore.edit { it[ttsEnabledKey] = enabled } }
    suspend fun setTtsVolume(volume: Int) { context.companionDataStore.edit { it[ttsVolumeKey] = volume.coerceIn(0, 100) } }
    suspend fun setTtsLanguage(language: TtsLanguage) { context.companionDataStore.edit { it[ttsLanguageKey] = language.name } }
    suspend fun setTtsSpeakNames(enabled: Boolean) { context.companionDataStore.edit { it[ttsSpeakNamesKey] = enabled } }
    suspend fun setTtsShortenNames(enabled: Boolean) { context.companionDataStore.edit { it[ttsShortenNamesKey] = enabled } }
}
