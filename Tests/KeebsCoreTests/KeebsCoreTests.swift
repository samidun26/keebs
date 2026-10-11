import XCTest
@testable import KeebsCore
#if os(macOS)
import AVFoundation
#endif

final class KeebsCoreTests: XCTestCase {
    func testEverySoundIsFiniteBoundedAndFadesToSilence() {
        for profile in SwitchProfile.library {
            for group in KeyGroup.allCases {
                for phase in KeyPhase.allCases {
                    let samples = SoundRenderer.render(profile: profile, group: group, phase: phase, variant: 0)
                    XCTAssertFalse(samples.isEmpty)
                    XCTAssertTrue(samples.allSatisfy { $0.isFinite && abs($0) <= 1 })
                    XCTAssertEqual(samples.last!, 0, accuracy: 0.00001)
                    XCTAssertGreaterThan(samples.map { abs($0) }.max()!, 0.01)
                }
            }
        }
    }
    func testReleaseIsQuieterAndProfilesAreDistinct() {
        var fingerprints: Set<Int> = []
        for profile in SwitchProfile.library {
            let down = SoundRenderer.render(profile: profile, group: .regular, phase: .down, variant: 2)
            let up = SoundRenderer.render(profile: profile, group: .regular, phase: .up, variant: 2)
            let energy: ([Float]) -> Double = { $0.reduce(0) { $0 + Double($1 * $1) } }
            XCTAssertLessThan(energy(up), energy(down))
            fingerprints.insert(Int(energy(down) * 10_000))
        }
        XCTAssertEqual(fingerprints.count, SwitchProfile.library.count)
        XCTAssertEqual(Set(SwitchProfile.library.map(\.id)).count, SwitchProfile.library.count)
    }
    func testHeldKeysDoNotRepeatAndResetDoesNotEmitReleases() {
        var tracker = KeyTracker()
        XCTAssertTrue(tracker.accept(code: 0, phase: .down))
        XCTAssertFalse(tracker.accept(code: 0, phase: .down, isRepeat: true))
        XCTAssertFalse(tracker.accept(code: 0, phase: .down))
        XCTAssertTrue(tracker.accept(code: 0, phase: .up))
        XCTAssertFalse(tracker.accept(code: 0, phase: .up))
        XCTAssertTrue(tracker.accept(code: 49, phase: .down))
        tracker.reset()
        XCTAssertFalse(tracker.accept(code: 49, phase: .up))
        XCTAssertFalse(tracker.accept(code: 49, phase: .down, isRepeat: true))
    }
    func testPhysicalPlacementAndSpecialKeys() {
        XCTAssertLessThan(PhysicalKey(code: 0).pan, 0)
        XCTAssertGreaterThan(PhysicalKey(code: 37).pan, 0)
        XCTAssertEqual(PhysicalKey(code: 49).pan, 0)
        XCTAssertEqual(PhysicalKey(code: 49).group, .space)
        XCTAssertEqual(PhysicalKey(code: 36).group, .enter)
        XCTAssertEqual(PhysicalKey(code: 51).group, .delete)
        XCTAssertEqual(PhysicalKey(code: 255).pan, 0)
    }
    func testCorruptSettingsAreClamped() {
        var settings = SoundSettings()
        settings.volume = .nan
        settings.room = 999
        settings.width = -2
        settings.resonance = .infinity
        settings.sanitize()
        XCTAssertEqual(settings.volume, 0.55)
        XCTAssertEqual(settings.room, 1)
        XCTAssertEqual(settings.width, 0)
        XCTAssertEqual(settings.resonance, 0.4)
    }

    #if os(macOS)
    func testEveryBundledRecordingDecodesWithAppleAudioFrameworks() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/KeebsApp/Resources/Recordings")
        let enumerator = try XCTUnwrap(FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil))
        let urls = enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "mp3" }
        XCTAssertEqual(urls.count, 150)
        for url in urls {
            let audio = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
            XCTAssertGreaterThan(audio.length, 0, url.path)
            XCTAssertLessThan(Double(audio.length) / audio.processingFormat.sampleRate, 2, url.path)
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: audio.processingFormat, frameCapacity: AVAudioFrameCount(audio.length)))
            try audio.read(into: buffer)
            XCTAssertGreaterThan(buffer.frameLength, 0, url.path)
            XCTAssertNotNil(buffer.floatChannelData, url.path)
        }
    }
    #endif
}
