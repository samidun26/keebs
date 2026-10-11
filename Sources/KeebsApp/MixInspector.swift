#if os(macOS)
import SwiftUI
import KeebsCore

@MainActor
struct MixInspector: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                HStack {
                    Text("Make it yours").font(.system(size: 17, weight: .medium))
                    Spacer()
                    Image(systemName: "slider.horizontal.3").foregroundStyle(Palette.muted)
                }
                Text("Small adjustments. A whole new atmosphere.").font(.system(size: 11)).foregroundStyle(Palette.muted).lineSpacing(4)
                divider
                control("Volume", icon: "speaker.wave.2", value: model.mixBinding(\.volume),
                        detail: "A comfortable level for your flow.")
                control("Stereo width", icon: "arrow.left.and.right", value: model.mixBinding(\.width),
                        detail: "Each key finds its place, left to right.")
                control("Room", icon: "square.dashed", value: model.mixBinding(\.room),
                        detail: "A little space around every keystroke.")
                control("Desk resonance", icon: "waveform.path", value: model.mixBinding(\.resonance),
                        detail: "Add warmth and body to the low end.")
                divider
                VStack(alignment: .leading, spacing: 18) {
                    option("Natural variation", detail: "Five press variations, less repetition.", value: model.mixBinding(\.variation))
                    option("Key release", detail: "Hear the switch return, too.", value: model.mixBinding(\.releases))
                }
                divider
                VStack(alignment: .leading, spacing: 12) {
                    Text("AT A GLANCE").font(.system(size: 8, weight: .semibold)).tracking(1.7).foregroundStyle(Palette.muted)
                    info("Source", value: model.selected.isRecorded ? "Real recording" : "Original synthesis")
                    info("Playback", value: "48 kHz · stereo")
                    info("Key capture", value: "Local · listen only")
                    Text(model.selected.author).font(.system(size: 9)).foregroundStyle(Palette.muted).padding(.top, 3)
                }
                Button("Reset sound mix") { model.resetMix() }.buttonStyle(.plain).font(.system(size: 10)).foregroundStyle(Palette.sage)
                divider
                option("Launch at login", detail: "Keep your favorite sound close.", value: Binding(get: { model.launchAtLogin }, set: { model.setLogin($0) }))
                if model.needsPermission {
                    Button("Open Input Monitoring settings") { model.openPermissions() }.font(.system(size: 10)).buttonStyle(.plain).foregroundStyle(Palette.sage)
                }
            }.padding(23)
        }.background(Palette.panel.opacity(0.4))
    }

    private var divider: some View { Rectangle().fill(Palette.line).frame(height: 1) }
    private func control(_ title: String, icon: String, value: Binding<Double>, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Palette.muted).frame(width: 17)
                Text(title).font(.system(size: 12, weight: .medium))
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%").font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.sage)
            }
            Slider(value: value, in: 0...1).controlSize(.small).accessibilityLabel(title)
            Text(detail).font(.system(size: 9)).foregroundStyle(Palette.muted).lineSpacing(3)
        }
    }
    private func option(_ title: String, detail: String, value: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Toggle(title, isOn: value).font(.system(size: 11, weight: .medium)).toggleStyle(.switch).controlSize(.mini)
            Text(detail).font(.system(size: 9)).foregroundStyle(Palette.muted).lineSpacing(3)
        }
    }
    private func info(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Palette.muted)
            Spacer()
            Text(value)
        }.font(.system(size: 9))
    }
}
#endif
