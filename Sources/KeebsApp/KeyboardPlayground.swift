#if os(macOS)
import AppKit
import SwiftUI
import KeebsCore

@MainActor
struct KeyboardPlayground: View {
    @EnvironmentObject var model: AppModel
    private let rows: [[(String, UInt16)]] = [
        [("Q",12),("W",13),("E",14),("R",15),("T",17),("Y",16),("U",32),("I",34),("O",31),("P",35)],
        [("A",0),("S",1),("D",2),("F",3),("G",5),("H",4),("J",38),("K",40),("L",37)],
        [("Z",6),("X",7),("C",8),("V",9),("B",11),("N",45),("M",46)]
    ]
    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 5) {
                    ForEach(rows[index], id: \.1) { key in keyCap(key.0, code: key.1) }
                }
            }
            HStack(spacing: 6) {
                keyCap("delete", code: 51, width: 67)
                keyCap("space", code: 49, width: 180)
                keyCap("return", code: 36, width: 67)
            }
            KeyCaptureArea(onKey: model.localKey, onBlur: model.resetLocalKeys)
                .frame(height: 40).padding(.top, 10)
                .overlay(alignment: .center) {
                    Text(model.enabled ? "Click here, then type. Or tap a key above." : "Sounds paused. Tap a key above to preview.")
                        .font(.system(size: 10)).foregroundStyle(Palette.muted).allowsHitTesting(false)
                }
                .background(Palette.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
            Text("Only physical key positions are used. Your words are never recorded.")
                .font(.system(size: 8)).foregroundStyle(Palette.muted).padding(.top, 5)
        }.padding(20).frame(maxWidth: .infinity).background(Palette.panel, in: RoundedRectangle(cornerRadius: 12))
    }

    private func keyCap(_ title: String, code: UInt16, width: CGFloat = 33) -> some View {
        Button { model.preview(code) } label: {
            Text(title).font(.system(size: title.count > 1 ? 9 : 10, design: .monospaced))
                .frame(width: width, height: 30)
                .foregroundStyle(model.heldKeys.contains(code) ? Palette.background : Palette.muted)
                .background(model.heldKeys.contains(code) ? Palette.sage : Palette.lifted, in: RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Palette.line))
        }.buttonStyle(.plain).accessibilityLabel("Preview \(title)")
    }
}

@MainActor
private struct KeyCaptureArea: NSViewRepresentable {
    let onKey: (UInt16, KeyPhase, Bool) -> Void
    let onBlur: () -> Void
    func makeNSView(context: Context) -> CaptureView {
        let view = CaptureView()
        view.onKey = onKey
        view.onBlur = onBlur
        return view
    }
    func updateNSView(_ view: CaptureView, context: Context) { view.onKey = onKey; view.onBlur = onBlur }

    final class CaptureView: NSView {
        var onKey: ((UInt16, KeyPhase, Bool) -> Void)?
        var onBlur: (() -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }
        override func keyDown(with event: NSEvent) {
            // Command shortcuts must continue through the app's responder chain.
            if event.modifierFlags.contains(.command) { super.keyDown(with: event); return }
            onKey?(event.keyCode, .down, event.isARepeat)
        }
        override func keyUp(with event: NSEvent) { onKey?(event.keyCode, .up, false) }
        override func becomeFirstResponder() -> Bool { needsDisplay = true; return true }
        override func resignFirstResponder() -> Bool { onBlur?(); needsDisplay = true; return true }
        override func draw(_ dirtyRect: NSRect) {
            if window?.firstResponder === self {
                NSColor(Color(hex: "C3D2AC").opacity(0.6)).setStroke()
                let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 8, yRadius: 8)
                border.lineWidth = 1
                border.stroke()
            }
        }
    }
}
#endif
