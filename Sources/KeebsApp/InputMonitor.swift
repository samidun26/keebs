#if os(macOS)
import AppKit
import Carbon
import KeebsCore

/// A listen-only tap. Never reads characters, stores text, or changes an event.
final class InputMonitor {
    var onKey: ((UInt16, KeyPhase, Bool) -> Void)?
    var onStatus: ((String, Bool) -> Void)?
    var onReset: (() -> Void)?
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var timer: Timer?
    private var secure = false
    private var sleeping = false
    private var wasReady = false
    private var observers: [NSObjectProtocol] = []

    func begin() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.poll() }
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.sleeping = true
            self?.disconnect()
            self?.onReset?()
        })
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.sleeping = false
            self?.poll()
        })
    }

    func requestPermission() {
        CGRequestListenEventAccess()
        openPermissionSettings()
    }

    func openPermissionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    private func poll() {
        guard !sleeping else { return }
        let nowSecure = IsSecureEventInputEnabled()
        if nowSecure != secure { secure = nowSecure; onReset?() }
        guard CGPreflightListenEventAccess() else {
            disconnect()
            updateStatus("Input Monitoring needed", ready: false)
            return
        }
        if tap == nil { connect() }
        updateStatus(secure ? "Paused for secure input" : (tap == nil ? "Keyboard access unavailable" : "Listening on this Mac"), ready: tap != nil && !secure)
    }

    private func updateStatus(_ message: String, ready: Bool) {
        if wasReady && !ready { onReset?() }
        wasReady = ready
        onStatus?(message, ready)
    }

    private func connect() {
        let mask = (CGEventMask(1) << CGEventType.keyDown.rawValue) | (CGEventMask(1) << CGEventType.keyUp.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<InputMonitor>.fromOpaque(context).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                monitor.onReset?()
                if let tap = monitor.tap, CGPreflightListenEventAccess() { CGEvent.tapEnable(tap: tap, enable: true) }
                return Unmanaged.passUnretained(event)
            }
            guard type == .keyDown || type == .keyUp,
                  !IsSecureEventInputEnabled(), CGPreflightListenEventAccess() else {
                return Unmanaged.passUnretained(event)
            }
            let code = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            let repeated = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            monitor.onKey?(code, type == .keyDown ? .down : .up, repeated)
            return Unmanaged.passUnretained(event)
        }
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                               options: .listenOnly, eventsOfInterest: mask,
                               callback: callback, userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let tap else { return }
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source { CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes) }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func disconnect() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
    }

    deinit {
        timer?.invalidate()
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        disconnect()
    }
}
#endif
