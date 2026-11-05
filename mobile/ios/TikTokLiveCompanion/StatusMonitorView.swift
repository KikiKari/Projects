import SwiftUI
import UIKit

@MainActor
struct StatusMonitorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = StatusMonitorModel()
    @State private var settings = false
    @State private var grid = false
    @State private var message: String?
    @State private var expanded: Set<Int> = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { if grid { grid = false } else { dismiss() } } label: { Image(systemName: "arrow.left") }.accessibilityLabel(grid ? "Zurück zur Monitorliste" : "Monitor schließen")
                Spacer()
                if !grid {
                    Button { settings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Einstellungen")
                    Button { grid = true } label: { Image(systemName: "rectangle.grid.2x2") }.accessibilityLabel("Übersicht öffnen")
                }
                Button { Task { await model.checkAll() } } label: { Image(systemName: "checkmark.circle") }.accessibilityLabel("Alle prüfen")
            }.padding()
            if grid {
                GeometryReader { geometry in
                    let slots = monitorGridSlots(model.config, model.rows)
                    let columns = model.config.gridNine ? 3 : 2
                    let rows = model.config.gridNine ? 3 : 2
                    ScrollView(.vertical) { LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columns), spacing: 4) {
                        ForEach(slots, id: \.self) { index in
                            MonitorGridTile(entry: model.rows[index], refresh: { Task { await model.check(index) } }, playbackChanged: { model.setPlaying(index, $0) })
                                .frame(height: max(100, (geometry.size.height - CGFloat(rows - 1) * 4) / CGFloat(rows)))
                        }
                    } }
                }.background(Color.black)
            } else {
                List {
                    ForEach(model.rows.indices, id: \.self) { index in
                        let row = model.rows[index]
                        VStack(alignment: .leading) { HStack {
                            Circle().fill(statusColor(row.status)).frame(width: 9, height: 9).accessibilityLabel(statusText(row.status))
                            VStack(alignment: .leading) { Text("\(index + 1). @\(row.handle.isEmpty ? "–" : row.handle)"); Text("\(statusText(row.status)) · \(row.sources.count) Links").font(.caption) }
                            Spacer()
                            Button { Task { await model.check(index) } } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Stream erneut prüfen").disabled(row.handle.isEmpty)
                            Button { if model.config.showLinks { if expanded.contains(index) { expanded.remove(index) } else { expanded.insert(index) } } else { copy(row.sources) } } label: { Image(systemName: model.config.showLinks ? "list.bullet" : "doc.on.doc") }.accessibilityLabel(model.config.showLinks ? "Links anzeigen" : "Links kopieren").disabled(row.sources.isEmpty)
                        }
                        if expanded.contains(index) && model.config.showLinks {
                            ForEach(row.sources, id: \.self) { source in HStack { Text(source.absoluteString).font(.caption).lineLimit(2); Spacer(); Button { copy([source]) } label: { Image(systemName: "doc.on.doc") }.accessibilityLabel("Link kopieren") } }
                        } }
                    }
                }
            }
            if let message { Text(message).font(.caption) }
        }
        .sheet(isPresented: $settings) { MonitorSettingsView(config: model.config, message: message) { value in
            do { try model.update(value); message = nil; settings = false }
            catch { message = "Ungültige oder doppelte Handles, Zuordnung oder Einstellungen." }
        } }
        .task(id: scenePhase == .active ? model.config : nil) {
            guard scenePhase == .active, model.config.enabled else { return }
            model.reloadBackgroundStatuses()
            while !Task.isCancelled {
                await model.checkAll(force: false)
                do { try await Task.sleep(nanoseconds: UInt64(model.config.intervalMinutes) * 60_000_000_000) }
                catch { return }
            }
        }
    }
    private func copy(_ sources: [URL]) { UIPasteboard.general.string = sources.map(\.absoluteString).joined(separator: "\n") }
    private func statusText(_ status: MonitorStatus) -> String {
        switch status { case .unknown: return "unbekannt"; case .checking: return "prüft"; case .online: return "online"; case .offline: return "offline"; case .error: return "Fehler" }
    }
    private func statusColor(_ status: MonitorStatus) -> Color {
        switch status { case .online: return .green; case .offline: return .red; case .error: return .orange; default: return .gray }
    }
}

private struct MonitorSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: MonitorConfiguration
    let message: String?
    let save: (MonitorConfiguration) -> Void
    init(config: MonitorConfiguration, message: String?, save: @escaping (MonitorConfiguration) -> Void) { _draft = State(initialValue: config); self.message = message; self.save = save }
    var body: some View {
        NavigationView { Form {
            if let message { Text(message).foregroundColor(.red) }
            ForEach(0..<MonitorConfiguration.slotCount, id: \.self) { index in
                TextField("Handle \(index + 1)", text: $draft.handles[index]).textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            Toggle("3×3 statt 2×2", isOn: $draft.gridNine)
            Toggle("Automatisch prüfen", isOn: $draft.enabled)
            Toggle("Online-Streams in Übersicht zuerst", isOn: $draft.autoSort)
            Toggle("Reihenfolge der Übersicht umkehren", isOn: $draft.reverse)
            Toggle("Links anzeigen statt direkt kopieren", isOn: $draft.showLinks)
            Toggle("Online-Streams mit Links nicht erneut prüfen", isOn: $draft.skipOnline)
            Stepper("Intervall: \(draft.intervalMinutes) Minuten", value: $draft.intervalMinutes, in: 1...60)
            Stepper("Maximale Links: \(draft.maxLinks)", value: $draft.maxLinks, in: 5...30)
            ForEach(0..<4, id: \.self) { tile in
                Picker("Kachel \(tile + 1)", selection: $draft.selectedSlots[tile]) {
                    ForEach(0..<MonitorConfiguration.slotCount, id: \.self) { slot in Text("Platz \(slot + 1)").tag(slot) }
                }
            }
        }.navigationTitle("Monitor-Einstellungen").toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Speichern") { draft.handles = draft.handles.map(MonitorConfiguration.normalize); save(draft) } }
        } }.navigationViewStyle(.stack)
    }
}

private struct MonitorGridTile: View {
    let entry: MonitorEntry
    let refresh: () -> Void
    let playbackChanged: (Bool) -> Void
    @State private var muted = true
    @State private var index = 0
    @State private var generation = 0
    @State private var failed = false
    @State private var playing = false
    var body: some View {
        VStack(spacing: 2) {
            Text("@\(entry.handle.isEmpty ? "–" : entry.handle)").foregroundColor(.white).lineLimit(1)
            if entry.sources.indices.contains(index) && !failed {
                let activeIndex = index
                let activeGeneration = generation
                VlcVideoSurface(url: entry.sources[index], enabled: false, strength: 30, muted: muted, playbackState: { state in
                    guard index == activeIndex, generation == activeGeneration else { return }
                    if state == 1 { playing = true; playbackChanged(true) }
                    if state == 2 { playbackChanged(false); advance() }
                }) { _, _, _, _, error in if error != nil && index == activeIndex && generation == activeGeneration { advance() } }
                .id("\(entry.handle)-\(index)-\(generation)")
                .task(id: "\(entry.handle)-\(index)-\(generation)") {
                    playing = false
                    try? await Task.sleep(nanoseconds: 15_000_000_000)
                    if !Task.isCancelled && !playing && index == activeIndex && generation == activeGeneration { advance() }
                }
            } else { Spacer(); Text(failed ? "Keine Quelle abspielbar" : "Kein Videolink").foregroundColor(.white).font(.caption); Spacer() }
            HStack {
                Button { muted.toggle() } label: { Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill") }.accessibilityLabel(muted ? "Ton einschalten" : "Stummschalten")
                Button { if entry.sources.isEmpty { refresh() } else { index = nextMonitorSource(index: min(index, entry.sources.count - 1), count: entry.sources.count, manual: true) ?? 0; generation += 1; failed = false } } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Stream neu starten oder nächste Quelle prüfen")
            }.foregroundColor(.white)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(white: 0.15))
        .onAppear { if !entry.sources.isEmpty { BackgroundAudioController.shared.activatePlayback() } }
        .onChange(of: entry.sources) { sources in if !sources.isEmpty { BackgroundAudioController.shared.activatePlayback() }; playbackChanged(false); index = 0; generation += 1; failed = false; playing = false }
        .onDisappear { playbackChanged(false) }
    }
    private func advance() {
        guard !failed else { return }
        playing = false
        guard entry.sources.indices.contains(index) else { index = 0; failed = false; return }
        if let next = nextMonitorSource(index: index, count: entry.sources.count, manual: false) { index = next } else { failed = true }
    }
}
