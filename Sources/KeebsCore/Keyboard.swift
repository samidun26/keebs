import Foundation

public enum KeyGroup: Int, CaseIterable, Sendable { case regular, space, enter, delete }
public enum KeyPhase: Int, CaseIterable, Sendable { case down, up }

public struct PhysicalKey: Sendable {
    public let code: UInt16
    public var group: KeyGroup {
        switch code {
        case 49: return .space
        case 36, 76: return .enter
        case 51, 117: return .delete
        default: return .regular
        }
    }
    public var pan: Float {
        // ANSI physical positions; unknown/media keys stay centered.
        let rows: [[UInt16]] = [
            [50,18,19,20,21,23,22,26,28,25,29,27,24,51],
            [48,12,13,14,15,17,16,32,34,31,35,33,30,42],
            [57,0,1,2,3,5,4,38,40,37,41,39,36],
            [56,6,7,8,9,11,45,46,43,47,44,60],
            [59,58,55,49,54,61,62,123,125,124]
        ]
        if code == 49 { return 0 }
        for row in rows {
            if let index = row.firstIndex(of: code) {
                return Float(index) / Float(row.count - 1) * 2 - 1
            }
        }
        return 0
    }
    public init(code: UInt16) { self.code = code }
}

public struct KeyTracker {
    private var held: Set<UInt16> = []
    public init() {}
    public mutating func accept(code: UInt16, phase: KeyPhase, isRepeat: Bool = false) -> Bool {
        if phase == .down {
            guard !isRepeat else { return false }
            return held.insert(code).inserted
        }
        return held.remove(code) != nil
    }
    public mutating func reset() { held.removeAll() }
}
