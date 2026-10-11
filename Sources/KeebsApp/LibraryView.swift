#if os(macOS)
import SwiftUI
import KeebsCore

enum Palette {
    static let background = Color(hex: "17191B")
    static let panel = Color(hex: "1E2022")
    static let lifted = Color(hex: "25282A")
    static let cream = Color(hex: "EBE9DF")
    static let muted = Color(hex: "999D99")
    static let sage = Color(hex: "C3D2AC")
    static let line = Color.white.opacity(0.08)
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(red: Double((value >> 16) & 255) / 255,
                  green: Double((value >> 8) & 255) / 255,
                  blue: Double(value & 255) / 255)
    }
}

private enum CollectionFilter: String, CaseIterable {
    case all = "All switches", recorded = "Recordings", original = "Originals", favorites = "Favorites"
    var icon: String {
        switch self { case .all: return "square.grid.2x2"; case .recorded: return "waveform"; case .original: return "sparkles"; case .favorites: return "heart" }
    }
}

@MainActor
struct LibraryView: View {
    @EnvironmentObject var model: AppModel
    @State private var collection: CollectionFilter = .all
    @State private var category: SwitchKind?
    @State private var search = ""
    @State private var showAbout = false
    private var filtered: [LibraryItem] {
        LibraryItem.all.filter { item in
            (category == nil || item.kind == category) &&
            (search.isEmpty || "\(item.name) \(item.character) \(item.kind.rawValue)".localizedCaseInsensitiveContains(search)) &&
            (collection != .favorites || model.favorites.contains(item.id)) &&
            (collection != .recorded || item.isRecorded) &&
            (collection != .original || !item.isRecorded)
        }
    }
    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle().fill(Palette.line).frame(width: 1)
            VStack(spacing: 0) {
                topbar
                Rectangle().fill(Palette.line).frame(height: 1)
                HStack(alignment: .top, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            introduction
                            selectedHero
                            library
                            playground
                        }.padding(30)
                    }
                    Rectangle().fill(Palette.line).frame(width: 1)
                    MixInspector().frame(width: 266)
                }
            }
        }
        .foregroundStyle(Palette.cream).background(Palette.background)
        .tint(Palette.sage)
        .sheet(isPresented: $showAbout) { about }
        .alert("Keebs needs attention", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("Try again") { model.selectedID = model.selected.id }
            Button("Dismiss", role: .cancel) { model.error = nil }
        } message: { Text(model.error ?? "") }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "keyboard").font(.system(size: 23))
                Text("keebs").font(.system(size: 27, weight: .bold, design: .rounded))
            }.padding(.top, 45).padding(.bottom, 6)
            Text("MAKE EVERY KEY FEEL GOOD").font(.system(size: 8, weight: .medium)).tracking(1.4).foregroundStyle(Palette.muted)
                .padding(.bottom, 40)
            Text("YOUR COLLECTION").font(.system(size: 9, weight: .semibold)).tracking(1.8).foregroundStyle(Palette.muted).padding(.bottom, 14)
            ForEach(CollectionFilter.allCases, id: \.self) { filter in
                Button {
                    collection = filter
                    category = nil
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: filter.icon).frame(width: 16)
                        Text(filter.rawValue).font(.system(size: 12, weight: collection == filter ? .semibold : .regular))
                        Spacer(minLength: 0)
                        if filter == .all { Text("\(LibraryItem.all.count)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.muted) }
                    }.padding(.horizontal, 11).padding(.vertical, 12)
                        .foregroundStyle(collection == filter ? Palette.sage : Palette.muted)
                        .background(collection == filter ? Palette.sage.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 8))
                }.buttonStyle(.plain)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "headphones").font(.title3).foregroundStyle(Palette.sage)
                Text("A little more present.").font(.system(size: 12, weight: .medium))
                Text("Try headphones for the full stereo experience.").font(.system(size: 11)).foregroundStyle(Palette.muted).lineSpacing(3)
            }.padding(14).background(Palette.lifted.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
            Button { showAbout = true } label: {
                Label("About & sound credits", systemImage: "info.circle").font(.system(size: 11)).foregroundStyle(Palette.muted)
            }.buttonStyle(.plain).padding(.top, 22).padding(.bottom, 24)
        }.padding(.horizontal, 17).frame(width: 180).background(Palette.panel.opacity(0.5))
    }

    private var topbar: some View {
        HStack {
            Text("Sound studio").font(.system(size: 12, weight: .medium))
            Spacer()
            Circle().fill(model.enabled && model.monitorReady ? Palette.sage : Palette.muted).frame(width: 6, height: 6)
            Text(model.enabled ? model.status : "Sounds paused").font(.system(size: 10)).foregroundStyle(Palette.muted)
            Toggle("Sounds", isOn: $model.enabled).toggleStyle(.switch).controlSize(.mini).padding(.leading, 12)
        }.padding(.horizontal, 30).frame(height: 61)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THE SOUND OF YOUR FLOW").font(.system(size: 9, weight: .medium)).tracking(2.5).foregroundStyle(Palette.sage)
            Text("Your keyboard.\nA different feeling.").font(.system(size: 37, weight: .medium, design: .rounded)).tracking(-1.4).lineSpacing(-1)
            Text("Find your switch. Set the room. Get into the rhythm.").font(.system(size: 12)).foregroundStyle(Palette.muted)
            if model.needsPermission {
                HStack(spacing: 10) {
                    Image(systemName: "keyboard.badge.ellipsis")
                    Text("Enable Input Monitoring to hear Keebs in every app.").font(.system(size: 11))
                    Spacer()
                    Button("Enable") { model.requestPermission() }.buttonStyle(.bordered).controlSize(.small)
                }.padding(12).background(Palette.sage.opacity(0.08), in: RoundedRectangle(cornerRadius: 9)).padding(.top, 5)
            }
        }
    }

    private var selectedHero: some View {
        HStack(spacing: 24) {
            SwitchIllustration(color: Color(hex: model.selected.color), pressed: !model.heldKeys.isEmpty)
                .frame(width: 122, height: 135)
            VStack(alignment: .leading, spacing: 9) {
                Text("ON YOUR DESK").font(.system(size: 8, weight: .semibold)).tracking(2).foregroundStyle(Palette.sage)
                Text(model.selected.name).font(.system(size: 21, weight: .medium, design: .rounded))
                Text(model.selected.character).font(.system(size: 11)).foregroundStyle(Palette.muted)
                HStack(spacing: 8) {
                    Text(model.selected.kind.rawValue.uppercased())
                    Text("·")
                    Text(model.selected.isRecorded ? "RECORDED" : "SYNTHESIZED")
                }.font(.system(size: 8, weight: .medium)).tracking(1).foregroundStyle(Palette.muted)
                Button { model.preview() } label: {
                    Label(model.loading ? "Loading…" : "Listen", systemImage: model.loading ? "hourglass" : "play.fill")
                        .font(.system(size: 11, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Palette.sage, in: Capsule()).foregroundStyle(Palette.background)
                }.buttonStyle(.plain).disabled(model.loading).padding(.top, 5)
            }
            Spacer(minLength: 0)
        }.padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [Color(hex: model.selected.color).opacity(0.1), Palette.panel], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.line))
    }

    private var library: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack {
                Text(collection.rawValue).font(.system(size: 17, weight: .medium))
                Text("\(filtered.count)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.muted)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Palette.muted)
                    TextField("Find a sound", text: $search).textFieldStyle(.plain)
                }.font(.system(size: 11)).padding(9).frame(width: 150).background(Palette.panel, in: RoundedRectangle(cornerRadius: 7))
            }
            HStack(spacing: 7) {
                categoryButton("All", kind: nil)
                ForEach(SwitchKind.allCases, id: \.self) { categoryButton($0.rawValue, kind: $0) }
            }
            if filtered.isEmpty {
                ContentUnavailableView(collection == .favorites ? "No favorites yet" : "No switches found",
                                       systemImage: collection == .favorites ? "heart" : "magnifyingglass",
                                       description: Text(collection == .favorites ? "Tap a heart to keep a sound close." : "Try another search or switch type."))
                    .frame(height: 150)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
                    ForEach(filtered) { item in SwitchCard(item: item) }
                }
            }
        }
    }

    private func categoryButton(_ title: String, kind: SwitchKind?) -> some View {
        Button { category = kind } label: {
            Text(title).font(.system(size: 10, weight: .medium)).padding(.horizontal, 12).padding(.vertical, 7)
                .foregroundStyle(category == kind ? Palette.background : Palette.muted)
                .background(category == kind ? Palette.sage : Palette.panel, in: Capsule())
        }.buttonStyle(.plain)
    }

    private var playground: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Take it for a spin").font(.system(size: 17, weight: .medium))
                Spacer()
                Text("\(model.keyCount) KEYS THIS SESSION").font(.system(size: 8, design: .monospaced)).tracking(1).foregroundStyle(Palette.muted)
            }
            KeyboardPlayground().environmentObject(model)
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("A small joy, on every keystroke.").font(.title2)
            Text("Keebs is a native macOS sound studio with \(LibraryItem.all.filter(\.isRecorded).count) recorded switch sets and \(SwitchProfile.library.count) original synthesized profiles. It listens only to physical key codes, never characters, and pauses during macOS secure input.")
            Text("Recordings: Mechvibes, MIT license (Hai Nguyen and contributors). Holy Pandas and seven additional sets: Thomas Lai / kbsim, MIT license. Switch names identify the source recordings; Keebs has no affiliation with switch manufacturers.")
            Link("View source and full license notices", destination: URL(string: "https://github.com/samidun26/keebs")!)
            Text("Settings and favorites stay on this Mac. No analytics or keystroke history. Network access is used only for update checks and downloads.").foregroundStyle(Palette.muted)
            Button("Done") { showAbout = false }.buttonStyle(.borderedProminent)
        }.font(.system(size: 13)).lineSpacing(4).padding(30).frame(width: 500).background(Palette.background)
    }
}

@MainActor
private struct SwitchCard: View {
    @EnvironmentObject var model: AppModel
    let item: LibraryItem
    private var selected: Bool { model.selectedID == item.id }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Button { model.selectedID = item.id } label: {
                    SwitchIllustration(color: Color(hex: item.color), pressed: selected && !model.heldKeys.isEmpty).frame(width: 59, height: 62)
                }.buttonStyle(.plain).accessibilityLabel("Select \(item.name)")
                Spacer()
                Button { model.toggleFavorite(item.id) } label: {
                    Image(systemName: model.favorites.contains(item.id) ? "heart.fill" : "heart")
                        .font(.system(size: 12)).foregroundStyle(model.favorites.contains(item.id) ? Palette.sage : Palette.muted)
                }.buttonStyle(.plain).accessibilityLabel("Favorite \(item.name)")
            }
            Button { model.selectedID = item.id } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                    Text(item.character).font(.system(size: 9)).foregroundStyle(Palette.muted).lineLimit(1)
                    HStack {
                        Text(item.kind.rawValue.uppercased()).tracking(1)
                        Spacer()
                        Image(systemName: selected ? "checkmark.circle.fill" : (item.isRecorded ? "waveform" : "sparkles"))
                            .foregroundStyle(selected ? Palette.sage : Palette.muted)
                    }.font(.system(size: 8)).foregroundStyle(Palette.muted)
                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain)
        }.padding(16).background(selected ? Palette.sage.opacity(0.045) : Palette.panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Palette.sage.opacity(0.6) : Palette.line, lineWidth: 1))
    }
}

struct SwitchIllustration: View {
    let color: Color
    var pressed = false
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                Ellipse().fill(.black.opacity(0.22)).frame(width: size * 0.85, height: size * 0.22).offset(y: size * 0.36).blur(radius: 6)
                RoundedRectangle(cornerRadius: size * 0.10).fill(color.opacity(0.42)).frame(width: size * 0.77, height: size * 0.56).rotationEffect(.degrees(-9)).offset(y: size * 0.17)
                RoundedRectangle(cornerRadius: size * 0.10).fill(LinearGradient(colors: [color.opacity(0.85), color.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: size * 0.83, height: size * 0.57).rotationEffect(.degrees(-9)).offset(y: size * 0.03)
                    .overlay(RoundedRectangle(cornerRadius: size * 0.1).stroke(color.opacity(0.8), lineWidth: 1).frame(width: size * 0.83, height: size * 0.57).rotationEffect(.degrees(-9)).offset(y: size * 0.03))
                RoundedRectangle(cornerRadius: size * 0.07).fill(color.opacity(0.35)).frame(width: size * 0.57, height: size * 0.38).rotationEffect(.degrees(-9)).offset(y: -size * 0.10)
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.04).fill(color).frame(width: size * 0.29, height: size * 0.24)
                    Rectangle().fill(Palette.background.opacity(0.5)).frame(width: size * 0.04, height: size * 0.15)
                    Rectangle().fill(Palette.background.opacity(0.5)).frame(width: size * 0.16, height: size * 0.04)
                }.rotationEffect(.degrees(-9)).offset(y: -size * (pressed ? 0.08 : 0.20))
            }.frame(width: proxy.size.width, height: proxy.size.height)
                .animation(.easeOut(duration: 0.09), value: pressed)
        }.accessibilityHidden(true)
    }
}
#endif
