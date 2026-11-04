package app.tiktoklivecompanion

import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class MonitorProbeTest {
    private fun page(handle: String, status: Int, extra: String = "") = """
        <script id="SIGI_STATE">{"LiveRoom":{"liveRoomUserInfo":{"user":{"uniqueId":"$handle"},"liveRoom":{"status":$status $extra}}}}</script>
    """.trimIndent()

    @Test fun onlineSourcesRemainBoundToTheRequestedHandle() {
        val row = MonitorProbe.parse("alice", page("alice", 2, ",\"url\":\"https://a.tiktokcdn.com/live.m3u8\""))
        assertEquals(MonitorStatus.ONLINE, row.status)
        assertEquals(listOf("https://a.tiktokcdn.com/live.m3u8"), row.sources)
        assertEquals(MonitorStatus.ERROR, MonitorProbe.parse("bob", page("alice", 2)).status)
    }

    @Test fun unknownStatusAndMissingDataAreNotOffline() {
        assertEquals(MonitorStatus.ERROR, MonitorProbe.parse("alice", page("alice", 3)).status)
        assertEquals(MonitorStatus.ERROR, MonitorProbe.parse("alice", "").status)
        assertEquals(MonitorStatus.OFFLINE, MonitorProbe.parse("alice", page("alice", 4)).status)
    }

    @Test fun rejectsOtherHostsAudioAndExpiredLinks() {
        val extra = ",\"urls\":[\"https://tiktokcdn.com.evil.test/live.m3u8\",\"https://a.tiktokcdn.com/audio.mp3\",\"https://a.tiktokcdn.com/live.m3u8?only_audio=1\",\"https://a.tiktokcdn.com/live_audio.m3u8\",\"https://a.tiktokcdn.com/live.flv?expire=1\"]"
        assertEquals(emptyList<String>(), MonitorProbe.parse("alice", page("alice", 2, extra)).sources)
    }

    @Test fun sourceValidityRejectsAnExpiredSessionUrl() {
        assertEquals(false, MonitorProbe.isUsableSource("https://a.tiktokcdn.com/live.flv?expire=1"))
        assertEquals(true, MonitorProbe.isUsableSource("https://a.tiktokcdn.com/live.flv?expire=4102444800"))
    }

    @Test fun extractsSourcesFromNestedStreamData() {
        val embedded = org.json.JSONObject().put("data", org.json.JSONObject().put("hd", org.json.JSONObject()
            .put("main", org.json.JSONObject().put("hls", "https://a.tiktokcdn.com/live.m3u8"))))
        val extra = ",\"stream_data\":" + org.json.JSONObject.quote(embedded.toString())
        assertEquals(listOf("https://a.tiktokcdn.com/live.m3u8"), MonitorProbe.parse("alice", page("alice", 2, extra)).sources)
    }
}
