#if os(macOS)
import XCTest
import AppKit
import KeebsCore
@testable import KeebsApp

@MainActor
private final class LifecycleAudio: KeyboardAudioOutput {
    var onReady: ((String?) -> Void)?
    let configurationSource: AnyObject = NSObject()
    var played = 0
    var suspensions = 0
    func apply(_ settings: SoundSettings) {}
    func prepare(_ item: KeebsApp.LibraryItem) { onReady?(nil) }
    func start() throws {}
    func play(key: PhysicalKey, phase: KeyPhase) throws { played += 1 }
    func silence() {}
    func suspend() { suspensions += 1 }
}

final class AppLifecycleTests: XCTestCase {
    func testStudioClosesAndReopensWhileAudioKeepsRunningWithoutDockPresence() async throws {
        try await MainActor.run {
            let app = NSApplication.shared
            let originalPolicy = app.activationPolicy()
            defer { app.setActivationPolicy(originalPolicy) }
            let delegate = AppDelegate()
            delegate.applicationWillFinishLaunching(Notification(name: NSApplication.willFinishLaunchingNotification))
            XCTAssertEqual(app.activationPolicy(), .accessory)
            XCTAssertFalse(delegate.applicationShouldTerminateAfterLastWindowClosed(app))

            let suite = "KeebsLifecycle.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let audio = LifecycleAudio()
            let model = AppModel(defaults: defaults, audio: audio, monitorInput: false)
            let studio = StudioWindowController()
            XCTAssertNil(studio.window, "Launching must not create the studio")

            studio.show(model: model, updater: delegate.updater)
            let window = try XCTUnwrap(studio.window)
            defer { window.close() }
            XCTAssertTrue(window.isVisible)
            XCTAssertEqual(app.activationPolicy(), .accessory)
            let suspensions = audio.suspensions
            window.performClose(nil)
            XCTAssertFalse(window.isVisible)
            XCTAssertTrue(model.enabled)
            XCTAssertEqual(audio.suspensions, suspensions)
            model.handle(12, .down, false)
            model.handle(12, .up, false)
            XCTAssertEqual(audio.played, 2, "Physical keys must still reach audio after closing the studio")

            studio.show(model: model, updater: delegate.updater)
            XCTAssertTrue(studio.window === window, "Reopening must reuse the studio and its settings")
            XCTAssertTrue(window.isVisible)
            XCTAssertEqual(app.activationPolicy(), .accessory)
        }
    }
}
#endif
