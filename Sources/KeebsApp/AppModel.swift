#if os(macOS)
import AppKit
import Combine
import ServiceManagement
import AVFoundation
import Carbon
import SwiftUI
import KeebsCore

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedID: String { didSet { selectSound() } }
    // Never write back into a @Published property from its own observer.
    @Published private(set) var settings: SoundSettings { didSet { audio.apply(settings); persist() } }
    @Published var enabled: Bool {
        didSet {
            previewTask?.cancel()
            tracker.reset()
            heldKeys.removeAll()
            if enabled && !loading {
                do { try audio.start() } catch { self.error = error.localizedDescription }
            } else { audio.suspend() }
            persist()
        }
    }
    @Published var favorites: Set<String> { didSet { persist() } }
    @Published var status = "Checking keyboard access…"
    @Published var monitorReady = false
    @Published var loading = true
    @Published var error: String?
    @Published var heldKeys: Set<UInt16> = []
    @Published var keyCount = 0
    @Published var launchAtLogin = false
    private let audio: any KeyboardAudioOutput
    private let monitor = InputMonitor()
    private var tracker = KeyTracker()
    private var configObserver: NSObjectProtocol?
    private var recoveryTask: Task<Void, Never>?
    private var previewTask: Task<Void, Never>?
    private let defaults: UserDefaults
    var selected: LibraryItem { LibraryItem.all.first { $0.id == selectedID } ?? LibraryItem.all[0] }
    var needsPermission: Bool { !CGPreflightListenEventAccess() }

    init(defaults: UserDefaults = .standard, audio: (any KeyboardAudioOutput)? = nil, monitorInput: Bool = true) {
        self.defaults = defaults
        self.audio = audio ?? KeyboardAudio()
        let stored = defaults
        let savedID = stored.string(forKey: "selectedProfile")
        selectedID = LibraryItem.all.first { $0.id == savedID }?.id ?? LibraryItem.all[0].id
        enabled = stored.object(forKey: "enabled") as? Bool ?? true
        favorites = Set(stored.stringArray(forKey: "favorites") ?? [])
        var restored = stored.data(forKey: "soundSettings").flatMap { try? JSONDecoder().decode(SoundSettings.self, from: $0) } ?? SoundSettings()
        restored.sanitize()
        settings = restored
        launchAtLogin = monitorInput && SMAppService.mainApp.status == .enabled
        self.audio.onReady = { [weak self] message in
            guard let self else { return }
            loading = false
            error = message
            if !enabled { self.audio.suspend() }
        }
        monitor.onKey = { [weak self] code, phase, repeated in
            Task { @MainActor [weak self] in self?.handle(code, phase, repeated) }
        }
        monitor.onStatus = { [weak self] message, ready in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.status != message { self.status = message }
                if self.monitorReady != ready { self.monitorReady = ready }
            }
        }
        monitor.onReset = { [weak self] in
            Task { @MainActor [weak self] in
                self?.previewTask?.cancel()
                self?.tracker.reset()
                self?.heldKeys.removeAll()
                self?.audio.suspend()
            }
        }
        if monitorInput {
            configObserver = NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange,
                                                                   object: self.audio.configurationSource, queue: nil) { [weak self] _ in
                Task { @MainActor [weak self] in self?.scheduleAudioRecovery() }
            }
        }
        selectSound()
        if monitorInput { monitor.begin() }
    }

    func handle(_ code: UInt16, _ phase: KeyPhase, _ repeated: Bool) {
        guard enabled, !loading, !IsSecureEventInputEnabled(), tracker.accept(code: code, phase: phase, isRepeat: repeated) else { return }
        if phase == .down { heldKeys.insert(code); keyCount += 1 }
        else { heldKeys.remove(code) }
        do { try audio.play(key: PhysicalKey(code: code), phase: phase) }
        catch { self.error = error.localizedDescription }
    }

    func localKey(_ code: UInt16, _ phase: KeyPhase, _ repeated: Bool) {
        // The system-wide tap already observes keys inside this app when authorized.
        if !monitorReady { handle(code, phase, repeated) }
    }

    func resetLocalKeys() {
        if !monitorReady { tracker.reset(); heldKeys.removeAll(); audio.silence() }
    }

    func preview(_ code: UInt16 = 0) {
        guard !loading else { return }
        previewTask?.cancel()
        previewTask = Task {
            do {
                try audio.play(key: PhysicalKey(code: code), phase: .down)
                heldKeys.insert(code)
                try await Task.sleep(for: .milliseconds(90))
                heldKeys.remove(code)
                try audio.play(key: PhysicalKey(code: code), phase: .up)
            } catch is CancellationError { heldKeys.remove(code) }
            catch { self.error = error.localizedDescription }
        }
    }

    func toggleFavorite(_ id: String) {
        if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
    }

    func requestPermission() { monitor.requestPermission() }
    func openPermissions() { monitor.openPermissionSettings() }

    func setLogin(_ value: Bool) {
        do {
            if value { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            launchAtLogin = SMAppService.mainApp.status == .enabled
            if value && SMAppService.mainApp.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
        } catch { self.error = error.localizedDescription }
    }

    func mixBinding<Value>(_ keyPath: WritableKeyPath<SoundSettings, Value>) -> Binding<Value> {
        Binding(get: { self.settings[keyPath: keyPath] }, set: { value in
            var next = self.settings
            next[keyPath: keyPath] = value
            self.updateMix(next)
        })
    }

    private func updateMix(_ value: SoundSettings) {
        var next = value
        next.sanitize()
        guard next != settings else { return }
        settings = next
    }

    func resetMix() { updateMix(SoundSettings()) }

    func stepProfile(_ direction: Int) {
        let count = LibraryItem.all.count
        let index = LibraryItem.all.firstIndex { $0.id == selectedID } ?? 0
        selectedID = LibraryItem.all[(index + direction % count + count) % count].id
    }

    private func scheduleAudioRecovery() {
        recoveryTask?.cancel()
        recoveryTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
            self?.selectSound()
        }
    }

    private func selectSound() {
        previewTask?.cancel()
        tracker.reset()
        heldKeys.removeAll()
        loading = true
        error = nil
        audio.apply(settings)
        audio.prepare(selected)
        persist()
    }

    private func persist() {
        defaults.set(selectedID, forKey: "selectedProfile")
        defaults.set(enabled, forKey: "enabled")
        defaults.set(Array(favorites), forKey: "favorites")
        if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: "soundSettings") }
    }
}
#endif
