package app.tiktoklivecompanion

import org.junit.Assert.assertEquals
import org.junit.Test

private class FakeEngine : RecognitionEngine {
    override var onResult: ((RecognitionResult) -> Unit)? = null
    override var onError: ((String) -> Unit)? = null
    var microphoneStarts = 0; var streamStarts = 0
    override fun recognizeMicrophone() { microphoneStarts++ }
    override fun startPcmStream(sampleRate: Int) { streamStarts++ }
    override fun appendPcm16(bytes: ByteArray, sampleRate: Int) {}
    override fun finishPcmStream() {}
    override fun cancel() {}
}

class CompanionViewModelTest {
    private fun envelope(type: String, payload: Map<String, Any?>) = BridgeEnvelope(1, type, "", 1, "2026-07-21T12:00:00Z", payload)

    @Test fun recognitionStartsOnlyAfterExplicitAction() {
        val engine = FakeEngine(); val model = CompanionViewModel(engine)
        assertEquals(0, engine.microphoneStarts)
        model.recognize(); assertEquals(1, engine.microphoneStarts)
        model.selectSource(RecognitionSource.WEBVIEW); model.recognize(); assertEquals(1, engine.streamStarts)
    }

    @Test fun chatEventsFillChatAndTopChatters() {
        val model = CompanionViewModel(FakeEngine())
        repeat(3) { model.handle(envelope("chat", mapOf("nickname" to "Anna", "content" to "hi $it"))) }
        model.handle(envelope("chat", mapOf("nickname" to "Ben", "content" to "hallo")))
        assertEquals(4, model.state.value.chats.size)
        assertEquals(listOf("Anna", "Ben"), model.state.value.topChatters.map { it.author })
        assertEquals(6, model.state.value.topChatters.first().words)
        model.muteAuthor("Anna")
        assertEquals(listOf("Ben"), model.state.value.topChatters.map { it.author })
    }

    @Test fun chatIsCappedAndSpeechQueueKeepsOnlyFiveNewMessages() {
        val model = CompanionViewModel(FakeEngine())
        model.setTtsEnabled(true)
        repeat(60) { model.handle(envelope("chat", mapOf("nickname" to "A-very-long-chat-name-$it", "content" to "hello $it", "language" to "en"))) }
        assertEquals(50, model.state.value.chatEntries.size)
        assertEquals(5, model.state.value.speechQueue.size)
        assertEquals("en-US", model.state.value.speechQueue.last().languageTag)
        assertEquals(true, model.state.value.speechQueue.last().text.startsWith("A-very-long-chat-name"))
    }

    @Test fun manualSpeechHonorsNameAndLanguageSettings() {
        val model = CompanionViewModel(FakeEngine())
        model.setTtsSpeakNames(false)
        model.setTtsLanguage(TtsLanguage.GERMAN)
        model.requestSpeak(ChatLine("Anna", "danke", "en"))
        assertEquals("danke", model.state.value.speechQueue.single().text)
        assertEquals("de-DE", model.state.value.speechQueue.single().languageTag)
    }

    @Test fun inspectionFillsPageInfo() {
        val model = CompanionViewModel(FakeEngine())
        model.handle(envelope("inspection", mapOf("title" to "Stream", "url" to "https://www.tiktok.com/@x/live", "creatorHandle" to "@x", "signature" to "Bio", "followerText" to "12K", "verified" to true, "videoPresent" to true, "captionsControlPresent" to false)))
        val info = model.state.value.pageInfo
        assertEquals("Stream", info["Titel"])
        assertEquals("https://www.tiktok.com/@x/live", info["URL"])
        assertEquals("ja", info["Video vorhanden"])
        assertEquals("nein", info["Untertitel-Steuerung"])
        assertEquals("@x", info["Handle"])
        assertEquals("Bio", info["Bio"])
        assertEquals("12K", info["Follower"])
        assertEquals("ja", info["Verifiziert"])
    }

    @Test fun liveStatsMapToGermanLabelsAndCountFollows() {
        val model = CompanionViewModel(FakeEngine())
        model.handle(envelope("live-stats", mapOf("viewerCount" to 42, "likeCount" to 7)))
        model.handle(envelope("live-stats", mapOf("kind" to "follow")))
        model.handle(envelope("live-stats", mapOf("kind" to "follow")))
        val values = model.state.value.liveValues
        assertEquals("42", values["Zuschauer*innen"])
        assertEquals("7", values["Likes"])
        assertEquals("2", values["Follows seit Hook"])
    }

    @Test fun participantsAreBoundedAndRankByMessagesWordsThenName() {
        val model = CompanionViewModel(FakeEngine())
        repeat(5_001) { model.handle(envelope("chat", mapOf("nickname" to "user$it", "content" to "one two"))) }
        model.handle(envelope("chat", mapOf("nickname" to "user2", "content" to "one two three")))
        model.handle(envelope("chat", mapOf("nickname" to "user1", "content" to "one")))
        assertEquals(5_000, model.state.value.participants.size)
        assertEquals("user2", model.state.value.topChatters.first().author)
    }

    @Test fun cumulativeLiveValuesNeverDecrease() {
        val model = CompanionViewModel(FakeEngine())
        model.handle(envelope("live-stats", mapOf("likeCount" to 100, "viewerCount" to 42)))
        model.handle(envelope("live-stats", mapOf("likeCount" to 80, "viewerCount" to 30)))
        assertEquals("100", model.state.value.liveValues["Likes"])
        assertEquals("30", model.state.value.liveValues["Zuschauer*innen"])
    }

    @Test fun limiterSettingsAreClampedAndSentToBridge() {
        val model = CompanionViewModel(FakeEngine())
        val sent = mutableListOf<Pair<String, Map<String, Any>>>()
        model.sendCommand = { command, payload -> sent += command to payload }
        model.setLimiterEnabled(true)
        model.setLimiterThreshold(-99)
        assertEquals(-30, model.state.value.limiterThreshold)
        model.setLimiterThreshold(5)
        assertEquals(-1, model.state.value.limiterThreshold)
        assertEquals(3, sent.count { it.first == "set-limiter" })
        model.handle(envelope("bridge-ready", emptyMap()))
        assertEquals(4, sent.count { it.first == "set-limiter" })
        assertEquals(true, sent.last().second["enabled"])
    }

    @Test fun failedForceReturnSurfacesError() {
        val model = CompanionViewModel(FakeEngine())
        model.handle(envelope("force-return", mapOf("ok" to false, "reason" to "max-attempts")))
        assertEquals(true, model.state.value.error?.contains("Force"))
        model.handle(envelope("force-return", mapOf("ok" to true)))
    }

    @Test fun forceFailureRecoversOnceToValidatedLiveUrl() {
        val model = CompanionViewModel(FakeEngine())
        val loaded = mutableListOf<String>()
        val sent = mutableListOf<String>()
        model.loadUrl = { loaded += it }
        model.sendCommand = { command, _ -> sent += command }
        model.setStreamName("creator")
        model.startForce()
        assertEquals(listOf("force-profile"), sent)
        model.handle(envelope("force-return", mapOf("ok" to false)))
        assertEquals(listOf("https://www.tiktok.com/@creator/live"), loaded)
        assertEquals(false, model.state.value.forceInProgress)
    }

    @Test fun hookAvailabilityStaysOnceAnyFrameReportsIt() {
        val model = CompanionViewModel(FakeEngine())
        model.handle(envelope("capability", mapOf("feature" to "websocket-hook", "available" to true)))
        model.handle(envelope("capability", mapOf("feature" to "websocket-hook", "available" to false)))
        assertEquals(true, model.state.value.hookAvailable)
    }
}
