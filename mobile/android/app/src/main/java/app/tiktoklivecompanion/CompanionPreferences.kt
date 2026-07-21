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
    val limiterEnabled: Flow<Boolean> = context.companionDataStore.data.map { values -> values[limiterEnabledKey] ?: false }
    val limiterThreshold: Flow<Int> = context.companionDataStore.data.map { values -> (values[limiterThresholdKey] ?: -6).coerceIn(-30, -1) }

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
}
