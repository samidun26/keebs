#if os(macOS)
import XCTest
import AppKit
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import KeebsCore
@testable import KeebsApp

/// An opt-in export harness for the actual app views, not a visual regression test.
final class DocumentationCaptureTests: XCTestCase {
    func testExportDocumentationVisuals() async throws {
        guard let directory = ProcessInfo.processInfo.environment["KEEBS_DOCS_OUTPUT"] else {
            throw XCTSkip("Set KEEBS_DOCS_OUTPUT to export documentation visuals.")
        }
        try await DocumentationCapture.export(to: URL(fileURLWithPath: directory, isDirectory: true))
    }
}

@MainActor
private final class DocumentationAudio: KeyboardAudioOutput {
    var onReady: ((String?) -> Void)?
    let configurationSource: AnyObject = NSObject()
    func apply(_ settings: SoundSettings) {}
    func prepare(_ item: KeebsApp.LibraryItem) { onReady?(nil) }
    func start() throws {}
    func play(key: PhysicalKey, phase: KeyPhase) throws {}
    func silence() {}
    func suspend() {}
}

@MainActor
private enum DocumentationCapture {
    static func export(to directory: URL) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let suite = "KeebsDocumentation.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = AppModel(defaults: defaults, audio: DocumentationAudio(), monitorInput: false)
        let updater = AppUpdater()
        model.status = "Preview mode"
        model.favorites = ["cream-travel", "holy-pandas", "ink"]
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        var frames: [CGImage] = []
        for id in ["cream-travel", "mxblue-travel", "holy-pandas"] {
            model.selectedID = id
            let content = LibraryView().environmentObject(model).environmentObject(updater)
                .preferredColorScheme(.dark)
            let image = try await capture(content, size: NSSize(width: 1240, height: 820))
            if frames.isEmpty { try writePNG(image, to: directory.appendingPathComponent("studio.png")) }
            frames.append(image)
        }
        model.selectedID = "holy-pandas"
        let menu = MenuPanel().environmentObject(model).environmentObject(updater)
            .preferredColorScheme(.dark).background(Palette.background)
        let menuHeight = ceil(NSHostingView(rootView: menu).fittingSize.height)
        try writePNG(try await capture(menu, size: NSSize(width: 350, height: menuHeight)),
                     to: directory.appendingPathComponent("menu-bar.png"))
        let preview = directory.appendingPathComponent("preview.gif")
        let gif = try XCTUnwrap(CGImageDestinationCreateWithURL(preview as CFURL, UTType.gif.identifier as CFString, frames.count, nil))
        CGImageDestinationSetProperties(gif, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for frame in frames {
            CGImageDestinationAddImage(gif, frame, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1.8]] as CFDictionary)
        }
        XCTAssertTrue(CGImageDestinationFinalize(gif))
    }

    private static func capture<Content: View>(_ content: Content, size: NSSize) async throws -> CGImage {
        let window = CaptureWindow(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(calibratedRed: 23/255, green: 25/255, blue: 27/255, alpha: 1)
        let host = NSHostingView(rootView: content.frame(width: size.width, height: size.height))
        host.frame = NSRect(origin: .zero, size: size)
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        defer { window.close() }
        // Allow native text fields, sliders, fonts, and layout to finish drawing.
        try await Task.sleep(for: .milliseconds(500))
        host.layoutSubtreeIfNeeded()
        host.displayIfNeeded()
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        return try XCTUnwrap(bitmap.cgImage)
    }

    private static func writePNG(_ image: CGImage, to url: URL) throws {
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }
}

@MainActor
private final class CaptureWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
#endif
