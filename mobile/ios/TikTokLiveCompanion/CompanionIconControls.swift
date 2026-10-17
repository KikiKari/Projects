import SwiftUI
import UIKit

private struct CompanionIconStyleKey: EnvironmentKey { static let defaultValue = "plastisch" }
extension EnvironmentValues {
    var companionIconStyle: String { get { self[CompanionIconStyleKey.self] } set { self[CompanionIconStyleKey.self] = newValue } }
}
struct CompanionControlIcon: View {
    @Environment(\.companionIconStyle) private var style
    let component: String
    var body: some View {
        let selected = ["plastisch", "glass", "linear"].contains(style) ? style : "plastisch"
        if let path = Bundle.main.path(forResource: component, ofType: "png", inDirectory: "icons/" + selected), let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image).resizable().scaledToFit().frame(width: 32, height: 32).accessibilityHidden(true)
        }
    }
}
struct CompanionIconLabel: View {
    let label: String
    let component: String
    var body: some View { ZStack { CompanionControlIcon(component: component) }.frame(minWidth: 44, minHeight: 44).accessibilityElement(children: .ignore).accessibilityLabel(label).help(label) }
}
struct CompanionIconToggleStyle: ToggleStyle {
    var hideLabel = false
    var hint = ""
    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        let control = Button { configuration.isOn.toggle() } label: {
            HStack { if !hideLabel { configuration.label; Spacer() }; CompanionControlIcon(component: configuration.isOn ? "on" : "off").frame(width: 48, height: 48) }
        }.buttonStyle(.plain).accessibilityElement(children: .combine).accessibilityValue(configuration.isOn ? "On" : "Off").help(hint.isEmpty ? (configuration.isOn ? "On" : "Off") : "\(hint): \(configuration.isOn ? "On" : "Off")")
        if hideLabel { control.accessibilityLabel(hint) } else { control }
    }
}
