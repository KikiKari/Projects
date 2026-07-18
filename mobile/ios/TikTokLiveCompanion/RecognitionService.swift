import AVFoundation
import Foundation
import ShazamKit

protocol RecognitionService: AnyObject {
    var onResult: ((RecognitionResult) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    func startMicrophone()
    func startPCMStream(source: RecognitionSource, sampleRate: Double)
    func appendPCM16(_ data: Data, sampleRate: Double)
    func finishPCMStream()
    func cancel()
}

final class ShazamRecognitionService: NSObject, RecognitionService, SHSessionDelegate {
    var onResult: ((RecognitionResult) -> Void)?
    var onError: ((String) -> Void)?
    private var session: SHSession?
    private var audioEngine: AVAudioEngine?
    private var source: RecognitionSource = .microphone
    private var stopTask: Task<Void, Never>?

    func startMicrophone() {
        cancel()
        source = .microphone
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            guard let self else { return }
            guard allowed else { return self.onError?("Mikrofonzugriff wurde abgelehnt") }
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .measurement)
                try audioSession.setActive(true)
                let engine = AVAudioEngine()
                let input = engine.inputNode
                let format = input.outputFormat(forBus: 0)
                let shazam = SHSession()
                shazam.delegate = self
                input.installTap(onBus: 0, bufferSize: 2_048, format: format) { buffer, time in shazam.matchStreamingBuffer(buffer, at: time) }
                try engine.start()
                self.session = shazam
                self.audioEngine = engine
                self.stopTask = Task { try? await Task.sleep(nanoseconds: 12_000_000_000); self.cancel() }
            } catch { self.onError?("Mikrofon konnte nicht gestartet werden: \(error.localizedDescription)") }
        }
    }

    func startPCMStream(source: RecognitionSource, sampleRate: Double) {
        cancel()
        self.source = source
        let shazam = SHSession()
        shazam.delegate = self
        session = shazam
    }

    func appendPCM16(_ data: Data, sampleRate: Double) {
        guard let session,
              let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: sampleRate, channels: 1, interleaved: true),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(data.count / 2)) else { return }
        buffer.frameLength = buffer.frameCapacity
        guard let channel = buffer.int16ChannelData?[0] else { return }
        data.copyBytes(to: UnsafeMutableRawBufferPointer(start: channel, count: data.count))
        session.matchStreamingBuffer(buffer, at: nil)
    }

    func finishPCMStream() { cancelAudioOnly() }
    func cancel() { stopTask?.cancel(); stopTask = nil; cancelAudioOnly(); session = nil }
    private func cancelAudioOnly() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let item = match.mediaItems.first else { return }
        let result = RecognitionResult(matched: true, title: item.title ?? "", artist: item.artist ?? "", album: nil, artworkURL: item.artworkURL, songURL: item.webURL, matchOffset: item.matchOffset, source: source)
        onResult?(result)
        cancel()
    }

    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        if let error { onError?("ShazamKit: \(error.localizedDescription)") }
        else { onResult?(RecognitionResult(matched: false, title: "", artist: "", album: nil, artworkURL: nil, songURL: nil, matchOffset: nil, source: source)) }
        cancel()
    }
}
