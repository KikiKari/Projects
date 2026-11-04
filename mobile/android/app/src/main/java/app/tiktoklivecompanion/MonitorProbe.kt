package app.tiktoklivecompanion

import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import java.net.URI
import java.util.concurrent.TimeUnit

/** Reads public LIVE metadata without cookies; media URLs are returned only to the caller. */
internal class MonitorProbe(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS).readTimeout(15, TimeUnit.SECONDS)
        .followRedirects(true).build(),
) {
    fun check(handle: String, maxLinks: Int = 5): MonitorRow {
        require(handle.isNotEmpty() && MonitorConfig.normalizeHandle(handle) == handle)
        require(maxLinks in 5..30)
        MonitorConfig(handles = listOf(handle) + List(MonitorConfig.SLOT_COUNT - 1) { "" })
        return try {
            val request = Request.Builder().url("https://www.tiktok.com/@$handle/live")
                .header("User-Agent", BROWSER_USER_AGENT)
                .header("Cache-Control", "no-cache").build()
            client.newCall(request).execute().use { response ->
                check(response.isSuccessful) { "HTTP ${response.code}" }
                val body = requireNotNull(response.body)
                val source = body.source()
                source.request(MAX_HTML_BYTES + 1)
                check(source.buffer.size <= MAX_HTML_BYTES) { "Response too large" }
                parse(handle, source.readUtf8()).let { it.copy(sources = it.sources.take(maxLinks)) }
            }
        } catch (_: Exception) {
            MonitorRow(handle, MonitorStatus.ERROR, checkedAtMillis = System.currentTimeMillis())
        }
    }

    companion object {
        private const val MAX_HTML_BYTES = 2L * 1024 * 1024
        private const val BROWSER_USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
        private val script = Regex("<script\\b[^>]*\\bid=[\"']SIGI_STATE[\"'][^>]*>([\\s\\S]*?)</script>", RegexOption.IGNORE_CASE)
        private val embeddedUrl = Regex("https://[^\\s\"'<>\\\\]+", RegexOption.IGNORE_CASE)
        private val audioMarker = Regex("(?:^|[_-])audio(?:[_-]|\\.|$)", RegexOption.IGNORE_CASE)
        private val domains = listOf("tiktokcdn.com", "tiktokcdn-eu.com", "tiktokcdn-us.com", "tiktokcdn-in.com", "ttlivecdn.com")

        fun parse(handle: String, html: String): MonitorRow {
            val now = System.currentTimeMillis()
            return try {
                val data = JSONObject(requireNotNull(script.find(html)?.groupValues?.get(1)))
                val info = data.getJSONObject("LiveRoom").getJSONObject("liveRoomUserInfo")
                require(MonitorConfig.normalizeHandle(info.getJSONObject("user").getString("uniqueId")) == handle)
                val room = info.getJSONObject("liveRoom")
                when (room.optInt("status", -1)) {
                    4 -> MonitorRow(handle, MonitorStatus.OFFLINE, checkedAtMillis = now)
                    2 -> MonitorRow(handle, MonitorStatus.ONLINE, extractSources(room), now)
                    else -> MonitorRow(handle, MonitorStatus.ERROR, checkedAtMillis = now)
                }
            } catch (_: Exception) {
                MonitorRow(handle, MonitorStatus.ERROR, checkedAtMillis = now)
            }
        }

        private fun extractSources(room: JSONObject): List<String> {
            val found = linkedSetOf<String>()
            var visited = 0
            fun visit(value: Any?, depth: Int) {
                if (depth > 20 || visited++ >= 50000 || found.size >= 30) return
                when (value) {
                    is JSONObject -> {
                        val keys = value.keys()
                        while (keys.hasNext() && visited < 50000 && found.size < 30) visit(value.opt(keys.next()), depth + 1)
                    }
                    is JSONArray -> for (i in 0 until minOf(value.length(), 50000 - visited)) visit(value.opt(i), depth + 1)
                    is String -> {
                        if (isUsableSource(value)) found.add(value)
                        else if (value.length <= 512 * 1024 && (value.startsWith("{") || value.startsWith("["))) {
                            runCatching { if (value.startsWith("{")) visit(JSONObject(value), depth + 1) else visit(JSONArray(value), depth + 1) }
                        } else if (value.length <= 512 * 1024) {
                            embeddedUrl.findAll(value).forEach { match ->
                                val candidate = match.value.trimEnd(')', ',', ';', ']', '}')
                                if (found.size < 30 && isUsableSource(candidate)) found.add(candidate)
                            }
                        }
                    }
                }
            }
            visit(room, 0)
            return found.toList()
        }

        internal fun isUsableSource(value: String): Boolean {
            return try {
                val uri = URI(value)
                val host = uri.host?.lowercase() ?: return false
                val query = uri.rawQuery?.split('&').orEmpty()
                val expires = query.firstOrNull { it.startsWith("expire=") }?.substringAfter('=')?.toLongOrNull()
                val mediaPath = "${uri.rawPath.orEmpty()}?${uri.rawQuery.orEmpty()}"
                uri.scheme == "https" && uri.userInfo == null && domains.any { host == it || host.endsWith(".$it") } &&
                    (uri.path.orEmpty().contains(".flv", true) || uri.path.orEmpty().contains(".m3u8", true)) &&
                    query.none { it.equals("only_audio=1", ignoreCase = true) } &&
                    !audioMarker.containsMatchIn(mediaPath) &&
                    (expires == null || expires > System.currentTimeMillis() / 1000)
            } catch (_: Exception) { false }
        }
    }
}
