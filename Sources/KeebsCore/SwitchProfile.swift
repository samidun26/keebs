import Foundation

public enum SwitchKind: String, Codable, CaseIterable, Sendable {
    case linear = "Linear", tactile = "Tactile", clicky = "Clicky", silent = "Silent"
}

public struct SwitchProfile: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let kind: SwitchKind
    public let character: String
    public let color: String
    public let frequency: Double
    public let decay: Double
    public let brightness: Double
    public let click: Double
    public let body: Double

    public static let library: [Self] = [
        .init(id: "moss", name: "Moss", kind: .linear, character: "Deep · rounded · soft", color: "B9C897", frequency: 175, decay: 0.038, brightness: 0.24, click: 0.08, body: 0.80),
        .init(id: "cream", name: "Cream", kind: .linear, character: "Creamy · smooth · warm", color: "E8D4AD", frequency: 260, decay: 0.028, brightness: 0.34, click: 0.12, body: 0.64),
        .init(id: "ink", name: "Ink", kind: .linear, character: "Dense · low · full", color: "A7B5CC", frequency: 140, decay: 0.047, brightness: 0.19, click: 0.06, body: 0.92),
        .init(id: "glass", name: "Glass", kind: .linear, character: "Bright · clean · crisp", color: "AECBD0", frequency: 630, decay: 0.020, brightness: 0.78, click: 0.18, body: 0.35),
        .init(id: "peach", name: "Peach", kind: .linear, character: "Light · gentle · poppy", color: "E5B09A", frequency: 380, decay: 0.026, brightness: 0.50, click: 0.15, body: 0.45),
        .init(id: "velvet", name: "Velvet", kind: .linear, character: "Muted · plush · mellow", color: "BDACCE", frequency: 195, decay: 0.021, brightness: 0.16, click: 0.03, body: 0.58),
        .init(id: "amber", name: "Amber", kind: .tactile, character: "Warm · textured · snappy", color: "DDBE79", frequency: 330, decay: 0.033, brightness: 0.42, click: 0.35, body: 0.65),
        .init(id: "fern", name: "Fern", kind: .tactile, character: "Earthy · deep · bouncy", color: "93B49E", frequency: 220, decay: 0.040, brightness: 0.30, click: 0.30, body: 0.78),
        .init(id: "plum", name: "Plum", kind: .tactile, character: "Rich · rounded · punchy", color: "C09BB5", frequency: 285, decay: 0.035, brightness: 0.39, click: 0.42, body: 0.74),
        .init(id: "stone", name: "Stone", kind: .tactile, character: "Solid · dry · precise", color: "B5B4AC", frequency: 450, decay: 0.019, brightness: 0.46, click: 0.29, body: 0.52),
        .init(id: "copper", name: "Copper", kind: .clicky, character: "Metallic · sharp · lively", color: "CFA88D", frequency: 920, decay: 0.029, brightness: 0.84, click: 0.92, body: 0.48),
        .init(id: "arctic", name: "Arctic", kind: .clicky, character: "Clear · bright · electric", color: "A5C5E2", frequency: 1250, decay: 0.023, brightness: 0.94, click: 1.0, body: 0.30),
        .init(id: "typewriter", name: "Typewriter", kind: .clicky, character: "Retro · rattly · bold", color: "D5C8A9", frequency: 720, decay: 0.052, brightness: 0.70, click: 0.85, body: 0.88),
        .init(id: "bubble", name: "Bubble", kind: .clicky, character: "Poppy · playful · light", color: "D8AED0", frequency: 560, decay: 0.031, brightness: 0.65, click: 0.65, body: 0.38),
        .init(id: "cloud", name: "Cloud", kind: .silent, character: "Soft · airy · subtle", color: "C8CCD7", frequency: 170, decay: 0.012, brightness: 0.09, click: 0.01, body: 0.30),
        .init(id: "sand", name: "Sand", kind: .silent, character: "Dry · hushed · delicate", color: "D5C2A2", frequency: 300, decay: 0.010, brightness: 0.14, click: 0.02, body: 0.24)
    ]
}

public struct SoundSettings: Codable, Equatable, Sendable {
    public var volume: Double = 0.55
    public var width: Double = 0.65
    public var room: Double = 0.12
    public var resonance: Double = 0.4
    public var variation: Bool = true
    public var releases: Bool = true
    public init() {}

    public mutating func sanitize() {
        volume = volume.isFinite ? min(1, max(0, volume)) : 0.55
        width = width.isFinite ? min(1, max(0, width)) : 0.65
        room = room.isFinite ? min(1, max(0, room)) : 0.12
        resonance = resonance.isFinite ? min(1, max(0, resonance)) : 0.4
    }
}
