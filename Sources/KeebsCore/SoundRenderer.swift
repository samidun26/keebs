import Foundation

public enum SoundRenderer {
    public static let sampleRate = 48_000.0

    /// Deterministic original sounds, not recordings of commercial switches.
    public static func render(profile: SwitchProfile, group: KeyGroup, phase: KeyPhase, variant: Int) -> [Float] {
        let duration = phase == .down ? 0.16 : 0.10
        let count = Int(sampleRate * duration)
        let groupPitch: Double = [.regular: 1, .space: 0.62, .enter: 0.78, .delete: 0.87][group]!
        let pitch = groupPitch * (1 + Double(variant - 2) * 0.018) * (phase == .up ? 1.28 : 1)
        let frequency = profile.frequency * pitch
        let decay = profile.decay * (phase == .up ? 0.55 : 1) * (group == .space ? 1.35 : 1)
        let gain = (phase == .up ? 0.46 : 0.82) * (profile.kind == .silent ? 0.42 : 1)
        var seed = UInt64(variant + 31) &* 1_664_525 &+ UInt64(group.rawValue * 79 + phase.rawValue * 157)
        var smooth = 0.0
        return (0..<count).map { index in
            let t = Double(index) / sampleRate
            seed = seed &* 6_364_136_223_846_793_005 &+ 1
            let noise = Double(seed >> 33) / Double(UInt32.max >> 1) * 2 - 1
            smooth += (0.08 + profile.brightness * 0.72) * (noise - smooth)
            let attack = min(1, t / 0.0008)
            let body = sin(2 * .pi * frequency * t) * exp(-t / decay) * profile.body
                + sin(2 * .pi * frequency * 2.31 * t) * exp(-t / (decay * 0.45)) * 0.17
            let contact = smooth * exp(-t / 0.008) * (0.22 + profile.brightness * 0.34)
            let clickTime = phase == .down ? 0.004 : 0.001
            let clickT = max(0, t - clickTime)
            let click = t >= clickTime ? sin(2 * .pi * 3100 * pitch * clickT) * exp(-clickT / 0.002) * profile.click * 0.42 : 0
            let tail = min(1, Double(count - 1 - index) / 64)
            return Float(tanh((body + contact + click) * gain) * attack * tail)
        }
    }

}
