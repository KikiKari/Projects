import AVFoundation

/// Aktiviert die systemweite Playback-Audiositzung erst nach dem expliziten Öffnen eines Streams.
final class BackgroundAudioController {
    static let shared = BackgroundAudioController()
    private(set) var playbackRequested = false

    private init() {}

    func activatePlayback() {
        playbackRequested = true
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            // Der sichtbare WebView-Player bleibt nutzbar; der Fehler wird beim nächsten Aktivierungsversuch erneut geprüft.
        }
    }

    func restoreIfNeeded() {
        if playbackRequested { activatePlayback() }
    }
}
