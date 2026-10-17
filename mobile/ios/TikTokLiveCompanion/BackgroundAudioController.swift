import AVFoundation
import UIKit

/// Aktiviert die systemweite Playback-Audiositzung erst nach dem expliziten Öffnen eines Streams.
final class BackgroundAudioController {
    static let shared = BackgroundAudioController()
    private(set) var playbackRequested = false

    private var observers: [NSObjectProtocol] = []
    private init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notification in
            guard let value = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: value) == .ended else { return }
            self?.restoreIfNeeded()
        })
        for name in [AVAudioSession.mediaServicesWereResetNotification, UIApplication.didBecomeActiveNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.restoreIfNeeded() })
        }
    }

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
