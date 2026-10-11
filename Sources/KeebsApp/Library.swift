#if os(macOS)
import Foundation
import KeebsCore

struct LibraryItem: Identifiable, Equatable {
    let id: String
    let name: String
    let kind: SwitchKind
    let character: String
    let color: String
    let synthesized: SwitchProfile?
    let folder: String?
    let author: String
    var isRecorded: Bool { folder != nil }

    static let all: [Self] = [
        .recording("cream-travel", "Cream · Full Travel", .linear, "Smooth · warm · creamy", "E8D4AD"),
        .recording("mxblack-travel", "MX Black · Full Travel", .linear, "Dense · deep · solid", "A7B5CC"),
        .recording("mxblue-travel", "MX Blue · Full Travel", .clicky, "Bright · sharp · classic", "A5C5E2"),
        .recording("mxbrown-travel", "MX Brown · Full Travel", .tactile, "Warm · tactile · balanced", "CFA88D"),
        .recording("turquoise", "Turquoise · Full Travel", .linear, "Clean · lively · textured", "AECBD0"),
        .recording("holy-pandas", "Holy Pandas", .tactile, "Rounded · snappy · full", "DDBE79", author: "Thomas Lai / kbsim"),
        .recording("alpaca", "Alpaca", .linear, "Soft · smooth · rounded", "E4B1BD", author: "Thomas Lai / kbsim"),
        .recording("blackink", "Gateron Black Ink", .linear, "Deep · smooth · weighty", "A0A7B8", author: "Thomas Lai / kbsim"),
        .recording("redink", "Gateron Red Ink", .linear, "Light · clean · lively", "D99A91", author: "Thomas Lai / kbsim"),
        .recording("boxnavy", "Kailh Box Navy", .clicky, "Bold · crisp · resonant", "93ACCA", author: "Thomas Lai / kbsim"),
        .recording("bluealps", "SKCM Blue Alps", .clicky, "Vintage · sharp · textured", "8DB9DB", author: "Thomas Lai / kbsim"),
        .recording("topre", "Topre", .tactile, "Soft · rounded · thocky", "B8A4CF", author: "Thomas Lai / kbsim"),
        .recording("buckling", "Buckling Spring", .clicky, "Metallic · springy · classic", "D1C5AD", author: "Thomas Lai / kbsim")
    ] + SwitchProfile.library.map {
        Self(id: $0.id, name: $0.name, kind: $0.kind, character: $0.character,
             color: $0.color, synthesized: $0, folder: nil, author: "Keebs original synthesis")
    }

    private static func recording(_ id: String, _ name: String, _ kind: SwitchKind,
                                  _ character: String, _ color: String,
                                  author: String = "Mechvibes contributors") -> Self {
        Self(id: id, name: name, kind: kind, character: character, color: color,
             synthesized: nil, folder: id, author: author)
    }

    func audioURL(group: KeyGroup, phase: KeyPhase, variant: Int) throws -> URL {
        guard let folder else { throw AudioError.missingRecording }
        let prefix = "Recordings/\(folder)"
        let pressPrefix = folder == "holy-pandas" ? "" : "press/"
        let key: String
        switch group {
        case .regular: key = phase == .down ? "GENERIC_R\(variant)" : "GENERIC"
        case .space: key = "SPACE"
        case .enter: key = "ENTER"
        case .delete: key = "BACKSPACE"
        }
        let path = "\(prefix)/\(phase == .down ? pressPrefix : "release/")\(key).mp3"
        // SwiftPM's flat development bundle can treat the copied Resources
        // directory as its resource root; universal builds use Contents/Resources.
        if let root = Bundle.module.resourceURL {
            for base in [root.appendingPathComponent("Resources"), root] {
                let url = base.appendingPathComponent(path)
                if FileManager.default.fileExists(atPath: url.path) { return url }
            }
        }
        if group != .regular { return try audioURL(group: .regular, phase: phase, variant: variant) }
        throw AudioError.missingRecording
    }
}

enum AudioError: LocalizedError {
    case missingRecording, invalidRecording
    var errorDescription: String? {
        switch self {
        case .missingRecording: return "This sound recording is missing. Rebuild Keebs with its resource bundle."
        case .invalidRecording: return "This recording could not be decoded."
        }
    }
}
#endif
