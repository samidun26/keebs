#if os(macOS)
import SwiftUI
import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

@main
@MainActor
struct KeebsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = AppModel()
    var body: some Scene {
        Window("Keebs", id: "library") {
            LibraryView().environmentObject(model)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1040, minHeight: 720)
        }
        .defaultSize(width: 1240, height: 820)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Toggle("Keyboard sounds", isOn: $model.enabled)
                    .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }
        MenuBarExtra("Keebs", systemImage: model.enabled ? "keyboard" : "keyboard.badge.ellipsis") {
            MenuPanel().environmentObject(model).preferredColorScheme(.dark)
        }.menuBarExtraStyle(.window)
    }
}

@MainActor
struct MenuPanel: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openWindow) var openWindow
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Text("keebs").font(.title2.bold()); Spacer(); Toggle("Sound", isOn: $model.enabled).labelsHidden() }
            Text(model.selected.name).font(.headline)
            Text(model.enabled ? model.status : "Sounds paused").font(.caption).foregroundStyle(.secondary)
            Slider(value: $model.settings.volume, in: 0...1) { Text("Volume") }
            Picker("Switch profile", selection: $model.selectedID) {
                ForEach(LibraryItem.all) { Text($0.name).tag($0.id) }
            }
            HStack {
                Button("Open Keebs") { openWindow(id: "library"); NSApp.activate(ignoringOtherApps: true) }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding(20).frame(width: 310)
        .tint(Palette.sage)
    }
}
#else
import Foundation
@main
enum KeebsUnsupported {
    static func main() { print("Keebs is a native macOS 14+ app. Core tests can run on Linux with swift test.") }
}
#endif
