import SwiftUI
import UIKit
import MobileVLCKit

struct VlcVideoSurface: UIViewRepresentable {
    let url: URL
    let enabled: Bool
    let strength: Int
    let report: (Bool, Double, Double, Double, String?) -> Void

    final class Coordinator {
        // The adapter owns VLCMediaPlayer and waits for its asynchronous stop.
        var output: TLCNativeVlcAudio?
        var currentURL: URL?
        var generation = 0
        var enabled = false
        var strength = 30
        var report: ((Bool, Double, Double, Double, String?) -> Void)?
        func stop() {
            generation += 1; currentURL = nil
            output?.stop(completion: {})
            output = nil
        }
        deinit { output?.stop(completion: {}) }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UIView {
        let view = UIView(); view.backgroundColor = .black; return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator
        coordinator.report = report; coordinator.enabled = enabled; coordinator.strength = strength
        coordinator.output?.setProtection(enabled: enabled, strength: strength)
        guard coordinator.currentURL != url else { return }
        coordinator.generation += 1
        let generation = coordinator.generation
        coordinator.currentURL = url
        let start = { [weak coordinator, weak uiView] in
            guard let coordinator, let uiView, coordinator.generation == generation else { return }
            let output = TLCNativeVlcAudio(report: { [weak coordinator] active, input, result, reduction, error in
                guard let coordinator, coordinator.generation == generation else { return }
                coordinator.report?(active, input, result, reduction, error)
            })
            guard let output else {
                coordinator.report?(false, -100, -100, 0, "Native Audioausgabe nicht verfügbar")
                return
            }
            coordinator.output = output
            output.setProtection(enabled: coordinator.enabled, strength: coordinator.strength)
            output.play(url: url, drawable: uiView)
        }
        if let previous = coordinator.output {
            coordinator.output = nil
            previous.stop(completion: start)
        } else { start() }
    }
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) { coordinator.stop() }
}
