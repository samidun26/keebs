#if os(macOS)
import XCTest
import AVFoundation
import KeebsCore
@testable import KeebsApp

final class AudioEngineTests: XCTestCase {
    func testRealGraphStartsAndRendersRecordedKeysAfterMixChanges() async throws {
        let ready = expectation(description: "Recorded profile loaded")
        let audio = try await MainActor.run {
            let audio = KeyboardAudio()
            let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2))
            // Uses the same graph as the app, without depending on CI's sound device.
            try audio.engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 1024)
            audio.onReady = { error in XCTAssertNil(error); ready.fulfill() }
            audio.prepare(LibraryItem.all[0])
            return audio
        }
        await fulfillment(of: [ready], timeout: 10)
        try await MainActor.run {
            for step in 0...100 {
                var settings = SoundSettings()
                settings.volume = Double(step) / 100
                settings.room = 1 - settings.volume
                settings.resonance = settings.volume
                settings.width = settings.volume
                audio.apply(settings)
            }
            var settings = SoundSettings()
            settings.width = 1
            settings.room = 0
            audio.apply(settings)
            try audio.play(key: PhysicalKey(code: 50), phase: .down)
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: audio.engine.manualRenderingFormat, frameCapacity: 1024))
            var leftEnergy = 0.0
            var rightEnergy = 0.0
            for _ in 0..<16 {
                let status = try audio.engine.renderOffline(1024, to: buffer)
                if status == .cannotDoInCurrentContext { continue }
                XCTAssertEqual(status, .success)
                let channels = try XCTUnwrap(buffer.floatChannelData)
                for frame in 0..<Int(buffer.frameLength) {
                    let left = channels[0][frame]
                    let right = channels[1][frame]
                    XCTAssertTrue(left.isFinite && right.isFinite)
                    leftEnergy += Double(left * left)
                    rightEnergy += Double(right * right)
                }
            }
            XCTAssertGreaterThan(leftEnergy, 0.0001, "The actual playback graph must produce audio")
            XCTAssertGreaterThan(leftEnergy, rightEnergy, "A leftmost physical key should pan left")
            audio.suspend()
            try audio.start()
            XCTAssertTrue(audio.engine.isRunning)
            audio.suspend()
        }
    }
}
#endif
