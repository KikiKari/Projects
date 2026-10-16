package app.tiktoklivecompanion

import kotlinx.coroutines.CancellationException
import java.net.URI

/** Only probes are retried. A POST is sent once to the selected service. */
internal object CompanionEndpoint {
    const val local = "http://127.0.0.1:43117"

    fun normalize(value: String): String {
        val text = value.trim().trimEnd('/')
        val address = if ("://" in text) text else "https://$text"
        val uri = try { URI(address) } catch (error: Exception) {
            throw IllegalArgumentException("Alternative Companion-Adresse ist ungültig; Host und optional Port angeben.", error)
        }
        require(uri.host != null && uri.userInfo == null && uri.rawQuery == null && uri.rawFragment == null &&
            (uri.rawPath.isNullOrEmpty()) && (uri.port == -1 || uri.port in 1..65535)) {
            "Alternative Companion-Adresse ist ungültig; Host und optional Port angeben."
        }
        val loopback = uri.host.lowercase() in setOf("localhost", "127.0.0.1", "[::1]", "::1")
        require(uri.scheme == "https" || (uri.scheme == "http" && loopback)) {
            "Lokaler Dienst nicht erreichbar. Die alternative Adresse benötigt HTTPS mit gültigem Zertifikat."
        }
        return address
    }

    suspend fun select(configured: String, probe: suspend (String) -> Unit): String {
        val candidates = listOf(local, "http://localhost:43117")
        for (candidate in candidates) {
            try { probe(candidate); return candidate }
            catch (error: CancellationException) { throw error }
            catch (_: Exception) { /* Try the other loopback address before the configured service. */ }
        }
        require(configured.isNotBlank()) {
            "Kein lokaler Companion-Dienst auf diesem Gerät erreichbar. Alternative Dienstadresse und Kopplungscode eintragen; Systemstimmen bleiben verfügbar."
        }
        val alternative = normalize(configured)
        try { probe(alternative) }
        catch (error: CancellationException) { throw error }
        catch (error: Exception) {
            throw IllegalStateException("Lokaler und alternativer Companion-Dienst nicht erreichbar: ${error.message}", error)
        }
        return alternative
    }
}
