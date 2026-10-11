#if os(macOS)
import AVFoundation
import AudioToolbox
import KeebsCore

private struct BufferKey: Hashable {
    let group: Int
    let phase: Int
    let variant: Int
}

@MainActor
protocol KeyboardAudioOutput: AnyObject {
    var onReady: ((String?) -> Void)? { get set }
    var configurationSource: AnyObject { get }
    func apply(_ settings: SoundSettings)
    func prepare(_ item: LibraryItem)
    func start() throws
    func play(key: PhysicalKey, phase: KeyPhase) throws
    func silence()
    func suspend()
}

@MainActor
final class KeyboardAudio: KeyboardAudioOutput {
    let engine = AVAudioEngine()
    var configurationSource: AnyObject { engine }
    private let mix = AVAudioMixerNode()
    private let room = AVAudioUnitReverb()
    private let desk = AVAudioUnitEQ(numberOfBands: 1)
    private let limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_PeakLimiter,
        componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0))
    private var voices: [AVAudioPlayerNode] = []
    private var buffers: [BufferKey: AVAudioPCMBuffer] = [:]
    private var cursor = 0
    private var generation = 0
    private var settings = SoundSettings()
    var onReady: ((String?) -> Void)?
    private let format = AVAudioFormat(standardFormatWithSampleRate: SoundRenderer.sampleRate, channels: 1)!

    init() {
        engine.attach(mix)
        engine.attach(room)
        engine.attach(desk)
        engine.attach(limiter)
        // Stereo graph after the mono voices preserves each player's pan.
        let stereo = AVAudioFormat(standardFormatWithSampleRate: SoundRenderer.sampleRate, channels: 2)!
        for _ in 0..<32 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mix, format: format)
            voices.append(player)
        }
        engine.connect(mix, to: desk, format: stereo)
        engine.connect(desk, to: room, format: stereo)
        engine.connect(room, to: limiter, format: stereo)
        engine.connect(limiter, to: engine.mainMixerNode, format: stereo)
        room.loadFactoryPreset(.smallRoom)
        desk.bands[0].filterType = .parametric
        desk.bands[0].frequency = 180
        desk.bands[0].bandwidth = 1.3
        desk.bands[0].bypass = false
        apply(settings)
    }

    func apply(_ value: SoundSettings) {
        settings = value
        mix.outputVolume = Float(value.volume) * 0.65
        room.wetDryMix = Float(value.room * 40)
        desk.bands[0].gain = Float(value.resonance * 10 - 3)
    }

    func prepare(_ item: LibraryItem) {
        generation += 1
        let token = generation
        silence()
        buffers.removeAll()
        // Decode and synthesize away from the event callback and UI thread.
        Task {
            do {
                let samples = try await Task.detached(priority: .userInitiated) {
                    try Self.makeSamples(item)
                }.value
                guard token == generation else { return }
                for (key, data) in samples {
                    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(data.count)),
                          let channel = buffer.floatChannelData?[0] else { throw AudioError.invalidRecording }
                    buffer.frameLength = AVAudioFrameCount(data.count)
                    data.withUnsafeBufferPointer { source in
                        channel.update(from: source.baseAddress!, count: data.count)
                    }
                    buffers[key] = buffer
                }
                try start()
                onReady?(nil)
            } catch {
                guard token == generation else { return }
                onReady?(error.localizedDescription)
            }
        }
    }

    func start() throws {
        if !engine.isRunning { engine.prepare(); try engine.start() }
    }

    func play(key: PhysicalKey, phase: KeyPhase) throws {
        guard phase == .down || settings.releases else { return }
        let variant = settings.variation ? Int.random(in: 0..<5) : 2
        guard let buffer = buffers[BufferKey(group: key.group.rawValue, phase: phase.rawValue, variant: variant)] else { return }
        try start()
        let voice = voices[cursor]
        cursor = (cursor + 1) % voices.count
        voice.stop()
        voice.pan = key.pan * Float(settings.width)
        voice.scheduleBuffer(buffer)
        voice.play()
    }

    func silence() { voices.forEach { $0.stop() } }
    func suspend() { silence(); engine.pause() }

    nonisolated private static func makeSamples(_ item: LibraryItem) throws -> [BufferKey: [Float]] {
        var result: [BufferKey: [Float]] = [:]
        var decoded: [URL: [Float]] = [:]
        for group in KeyGroup.allCases {
            for phase in KeyPhase.allCases {
                for variant in 0..<5 {
                    let key = BufferKey(group: group.rawValue, phase: phase.rawValue, variant: variant)
                    if let profile = item.synthesized {
                        result[key] = SoundRenderer.render(profile: profile, group: group, phase: phase, variant: variant)
                    } else {
                        let url = try item.audioURL(group: group, phase: phase, variant: variant)
                        if decoded[url] == nil { decoded[url] = try decode(url) }
                        // The recording already contains the physical key's character.
                        result[key] = decoded[url]!
                    }
                }
            }
        }
        return result
    }

    nonisolated private static func decode(_ url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
        let sourceFormat = file.processingFormat
        guard file.length > 0, file.length < AVAudioFramePosition(sourceFormat.sampleRate * 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: AVAudioFrameCount(file.length))
        else { throw AudioError.invalidRecording }
        try file.read(into: buffer)
        guard let channels = buffer.floatChannelData, buffer.frameLength > 0 else { throw AudioError.invalidRecording }
        let count = Int(buffer.frameLength)
        let channelCount = Int(sourceFormat.channelCount)
        let mono = (0..<count).map { index -> Float in
            var total: Float = 0
            for channel in 0..<channelCount { total += channels[channel][index] }
            return total / Float(channelCount)
        }
        let ratio = sourceFormat.sampleRate / SoundRenderer.sampleRate
        let outputCount = Int(Double(count) / ratio)
        return (0..<outputCount).map { index in
            let position = Double(index) * ratio
            let a = min(count - 1, Int(position))
            let b = min(count - 1, a + 1)
            let value = mono[a] + (mono[b] - mono[a]) * Float(position - Double(a))
            let fade = Float(min(1, Double(index) / 24) * min(1, Double(outputCount - 1 - index) / 48))
            return max(-1, min(1, value)) * fade
        }
    }
}
#endif
