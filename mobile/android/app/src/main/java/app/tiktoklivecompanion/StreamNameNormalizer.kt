package app.tiktoklivecompanion

/** Normalisiert eine Streamnamen-Eingabe (mit oder ohne führendes "@") zu einer TikTok-LIVE-URL. */
object StreamNameNormalizer {
    private val allowed = Regex("^[a-z0-9._]{2,24}$")

    /** Liefert den bereinigten Nutzernamen ohne "@" oder null bei ungültiger Eingabe. */
    fun normalize(input: String): String? {
        val name = input.trim().removePrefix("@").lowercase()
        return name.takeIf { allowed.matches(it) }
    }

    /** Liefert die vollständige LIVE-URL oder null bei ungültiger Eingabe. */
    fun liveUrl(input: String): String? = normalize(input)?.let { "https://www.tiktok.com/@$it/live" }
}
