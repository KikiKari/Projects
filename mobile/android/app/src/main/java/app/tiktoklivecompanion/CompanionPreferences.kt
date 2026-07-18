package app.tiktoklivecompanion

import android.content.Context
import androidx.datastore.preferences.core.edit
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

    suspend fun setSource(source: RecognitionSource) {
        context.companionDataStore.edit { values -> values[sourceKey] = source.name }
    }

    suspend fun setMutedAuthors(authors: Set<String>) {
        context.companionDataStore.edit { values -> values[mutedAuthorsKey] = authors }
    }
}
