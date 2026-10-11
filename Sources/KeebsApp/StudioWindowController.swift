#if os(macOS)
import AppKit
import SwiftUI

/// The menu bar owns the app lifetime; the studio is created only on request.
@MainActor
final class StudioWindowController: ObservableObject {
    private(set) var window: NSWindow?

    func show(model: AppModel, updater: AppUpdater) {
        if window == nil {
            let content = LibraryView()
                .environmentObject(model).environmentObject(updater)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1040, minHeight: 720)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1240, height: 820),
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            window.title = "Keebs"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(Palette.background)
            window.contentMinSize = NSSize(width: 1040, height: 720)
            // Retain the same studio, model, and mix when the close button is used.
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: content)
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
