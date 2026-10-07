import SwiftUI
import UIKit
#if canImport(MobileVLCKit)
import MobileVLCKit
#endif

struct VlcVideoSurface: UIViewRepresentable {
    let url: URL

    final class Coordinator {
#if canImport(MobileVLCKit)
        let player = VLCMediaPlayer()
#endif
        var currentURL: URL?

        deinit {
#if canImport(MobileVLCKit)
            player.stop()
#endif
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
#if canImport(MobileVLCKit)
        context.coordinator.player.drawable = view
#endif
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard context.coordinator.currentURL != url else { return }
        context.coordinator.currentURL = url
#if canImport(MobileVLCKit)
        context.coordinator.player.stop()
        context.coordinator.player.media = VLCMedia(url: url)
        context.coordinator.player.play()
#endif
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
#if canImport(MobileVLCKit)
        coordinator.player.stop()
        coordinator.player.drawable = nil
#endif
    }
}
