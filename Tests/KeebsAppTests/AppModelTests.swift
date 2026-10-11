#if os(macOS)
import XCTest
import KeebsCore
@testable import KeebsApp

@MainActor
private final class RecordingAudio: KeyboardAudioOutput {
    var onReady: ((String?) -> Void)?
    let configurationSource: AnyObject = NSObject()
    var applied: [SoundSettings] = []
    var selectedID: String?
    var starts = 0
    var suspensions = 0
    func apply(_ settings: SoundSettings) { applied.append(settings) }
    func prepare(_ item: KeebsCore.LibraryItem) { selectedID = item.id; onReady?(nil) }
    func start() throws { starts += 1 }
    func play(key: PhysicalKey, phase: KeyPhase) throws {}
    func silence() {}
    func suspend() { suspensions += 1 }
}

final class AppModelTests: XCTestCase {
    func testRapidSliderChangesApplyOnceAndPersist() async throws {
        try await MainActor.run {
            let suite = "KeebsTests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let audio = RecordingAudio()
            let model = AppModel(defaults: defaults, audio: audio, monitorInput: false)
            var expectedUpdates = audio.applied.count
            let fields: [WritableKeyPath<SoundSettings, Double>] = [\.volume, \.width, \.room, \.resonance]
            for field in fields {
                let binding = model.mixBinding(field)
                for step in 0...250 {
                    let value = Double(step) / 250
                    if model.settings[keyPath: field] != value { expectedUpdates += 1 }
                    binding.wrappedValue = value
                    XCTAssertEqual(model.settings[keyPath: field], value)
                    XCTAssertEqual(audio.applied.count, expectedUpdates, "A slider write must not recursively apply settings")
                }
            }
            let stored = try JSONDecoder().decode(SoundSettings.self, from: XCTUnwrap(defaults.data(forKey: "soundSettings")))
            XCTAssertEqual(stored, model.settings)
            let relaunched = AppModel(defaults: defaults, audio: RecordingAudio(), monitorInput: false)
            XCTAssertEqual(relaunched.settings, model.settings)
        }
    }

    func testMenuAndDesktopBindingsStayInSyncAndClampInvalidValues() async throws {
        try await MainActor.run {
            let suite = "KeebsTests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let model = AppModel(defaults: defaults, audio: RecordingAudio(), monitorInput: false)
            let desktopVolume = model.mixBinding(\.volume)
            let menuVolume = model.mixBinding(\.volume)
            menuVolume.wrappedValue = 0.27
            XCTAssertEqual(desktopVolume.wrappedValue, 0.27)
            desktopVolume.wrappedValue = 0.81
            XCTAssertEqual(menuVolume.wrappedValue, 0.81)
            menuVolume.wrappedValue = .nan
            XCTAssertEqual(desktopVolume.wrappedValue, 0.55)
            model.mixBinding(\.width).wrappedValue = -4
            model.mixBinding(\.room).wrappedValue = 9
            model.mixBinding(\.resonance).wrappedValue = .infinity
            XCTAssertEqual(model.settings.width, 0)
            XCTAssertEqual(model.settings.room, 1)
            XCTAssertEqual(model.settings.resonance, 0.4)
            model.mixBinding(\.variation).wrappedValue = false
            model.mixBinding(\.releases).wrappedValue = false
            XCTAssertFalse(model.settings.variation)
            XCTAssertFalse(model.settings.releases)
            model.resetMix()
            XCTAssertEqual(model.settings, SoundSettings())
        }
    }

    func testMenuPauseAndProfileCyclingWorkWithoutDesktopWindow() async throws {
        try await MainActor.run {
            let suite = "KeebsTests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let audio = RecordingAudio()
            let model = AppModel(defaults: defaults, audio: audio, monitorInput: false)
            model.heldKeys.insert(0)
            let previousSuspensions = audio.suspensions
            model.enabled = false
            XCTAssertTrue(model.heldKeys.isEmpty)
            XCTAssertGreaterThan(audio.suspensions, previousSuspensions)
            model.stepProfile(-1)
            XCTAssertEqual(model.selectedID, KeebsCore.LibraryItem.all.last?.id)
            XCTAssertEqual(audio.selectedID, model.selectedID)
            model.stepProfile(1)
            XCTAssertEqual(model.selectedID, KeebsCore.LibraryItem.all.first?.id)
            model.enabled = true
            XCTAssertGreaterThan(audio.starts, 0)
            XCTAssertTrue(defaults.bool(forKey: "enabled"))
        }
    }
}
#endif
