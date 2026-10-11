import AppKit
import CoreGraphics
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

guard CommandLine.arguments.count == 2, let pid = Int32(CommandLine.arguments[1]),
      let app = NSRunningApplication(processIdentifier: pid), !app.isTerminated
else { fail("The packaged Keebs process is not running.") }
guard app.activationPolicy == .accessory else {
    fail("Keebs must run as an accessory app with no Dock icon; policy: \(app.activationPolicy.rawValue)")
}
guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                              kCGNullWindowID) as? [[String: Any]]
else { fail("Could not inspect the packaged app's window metadata.") }
let studioWindows = windows.filter {
    ($0[kCGWindowOwnerPID as String] as? Int) == Int(pid)
        && ($0[kCGWindowLayer as String] as? Int) == 0
}
guard studioWindows.isEmpty else { fail("Keebs must launch in the menu bar without opening a studio window.") }
print("Verified accessory activation policy and no visible studio on launch.")
