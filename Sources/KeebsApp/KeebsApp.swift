#if os(macOS)
import SwiftUI
import AppKit
import Carbon
import KeebsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let updater = AppUpdater()
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Also covers running the executable directly, outside Launch Services.
        NSApp.setActivationPolicy(.accessory)
    }
    func applicationDidFinishLaunching(_ notification: Notification) { updater.start() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

@main
@MainActor
struct KeebsApplication: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = AppModel()
    @StateObject private var studio = StudioWindowController()
    var body: some Scene {
        MenuBarExtra("Keebs", systemImage: model.enabled ? "keyboard" : "keyboard.badge.ellipsis") {
            MenuPanel(openStudio: { studio.show(model: model, updater: delegate.updater) })
                .environmentObject(model).environmentObject(delegate.updater).preferredColorScheme(.dark)
        }.menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                UpdateMenuItems(updater: delegate.updater)
                Divider()
                Toggle("Keyboard sounds", isOn: $model.enabled)
                    .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }
    }
}

@MainActor
struct MenuPanel: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var updater: AppUpdater
    var openStudio: () -> Void = {}
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("keebs", systemImage: "keyboard").font(.title2.bold())
                Spacer()
                Text(model.enabled ? "ON" : "PAUSED").font(.caption2.bold()).foregroundStyle(model.enabled ? Palette.sage : Palette.muted)
            }
            Button { model.enabled.toggle() } label: {
                Label(model.enabled ? "Pause sounds" : "Resume sounds", systemImage: model.enabled ? "pause.circle.fill" : "play.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(Palette.background)
                    .background(Palette.sage, in: RoundedRectangle(cornerRadius: 7))
            }.buttonStyle(.plain)
            Text(model.enabled ? model.status : "Sounds paused").font(.caption).foregroundStyle(.secondary)
            Divider()
            Picker("Switch profile", selection: $model.selectedID) {
                ForEach(LibraryItem.all) { item in
                    Text("\(model.favorites.contains(item.id) ? "♥ " : "")\(item.name)").tag(item.id)
                }
            }.pickerStyle(.menu)
            HStack {
                Button { model.stepProfile(-1) } label: { Image(systemName: "chevron.left") }.help("Previous switch").accessibilityLabel("Previous switch")
                Button { model.preview() } label: { Label(model.loading ? "Loading…" : "Listen", systemImage: "play.fill") }.disabled(model.loading)
                Button { model.stepProfile(1) } label: { Image(systemName: "chevron.right") }.help("Next switch").accessibilityLabel("Next switch")
                Spacer()
                Button { model.toggleFavorite(model.selectedID) } label: {
                    Image(systemName: model.favorites.contains(model.selectedID) ? "heart.fill" : "heart")
                }.help("Favorite this switch").accessibilityLabel("Favorite this switch")
            }
            Divider()
            quickSlider("Volume", icon: "speaker.wave.2", value: model.mixBinding(\.volume))
            quickSlider("Stereo width", icon: "arrow.left.and.right", value: model.mixBinding(\.width))
            quickSlider("Room", icon: "square.dashed", value: model.mixBinding(\.room))
            quickSlider("Desk resonance", icon: "waveform.path", value: model.mixBinding(\.resonance))
            Toggle("Natural variation", isOn: model.mixBinding(\.variation)).toggleStyle(.switch).controlSize(.mini)
            Toggle("Key release", isOn: model.mixBinding(\.releases)).toggleStyle(.switch).controlSize(.mini)
            if model.needsPermission {
                Button("Enable keyboard access") { model.requestPermission() }
            }
            Divider()
            Button("Check for Updates…") { updater.checkForUpdates() }
                .disabled(!updater.canCheckForUpdates)
            HStack {
                Button("Open studio", action: openStudio)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding(20).frame(width: 350)
        .tint(Palette.sage)
    }

    private func quickSlider(_ title: String, icon: String, value: Binding<Double>) -> some View {
        VStack(spacing: 4) {
            HStack {
                Label(title, systemImage: icon).font(.caption)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%").font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.sage)
            }
            Slider(value: value, in: 0...1).controlSize(.small).accessibilityLabel(title)
        }
    }
}

@MainActor
private struct UpdateMenuItems: View {
    @ObservedObject var updater: AppUpdater
    var body: some View {
        Button("Check for Updates…") { updater.checkForUpdates() }
            .disabled(!updater.canCheckForUpdates)
    }
}
#else
import Foundation
@main
enum KeebsUnsupported {
    static func main() { print("Keebs is a native macOS 14+ app. Core tests can run on Linux with swift test.") }
}
#endif
