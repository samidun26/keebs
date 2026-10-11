import Foundation
import CryptoKit

// Never print the private signing key. It is supplied only through the environment.
do {
    guard CommandLine.arguments.count == 3 else {
        throw NSError(domain: "KeebsRelease", code: 1, userInfo: [NSLocalizedDescriptionKey: "Usage: swift scripts/sign-release.swift ARCHIVE INFO_PLIST"])
    }
    guard let encoded = ProcessInfo.processInfo.environment["SPARKLE_PRIVATE_KEY"],
          let seed = Data(base64Encoded: encoded.trimmingCharacters(in: .whitespacesAndNewlines)), seed.count == 32 else {
        throw NSError(domain: "KeebsRelease", code: 2, userInfo: [NSLocalizedDescriptionKey: "Set SPARKLE_PRIVATE_KEY to the base64-encoded 32-byte Ed25519 seed."])
    }
    let key = try Curve25519.Signing.PrivateKey(rawRepresentation: seed)
    let plistData = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
    guard let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
          let publicKey = plist["SUPublicEDKey"] as? String,
          publicKey == key.publicKey.rawRepresentation.base64EncodedString(),
          let version = plist["CFBundleShortVersionString"] as? String,
          let build = plist["CFBundleVersion"] as? String else {
        throw NSError(domain: "KeebsRelease", code: 3, userInfo: [NSLocalizedDescriptionKey: "Signing key must match the app's SUPublicEDKey and version metadata."])
    }
    let archive = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
    let signature = try key.signature(for: archive)
    guard key.publicKey.isValidSignature(signature, for: archive) else {
        throw NSError(domain: "KeebsRelease", code: 4, userInfo: [NSLocalizedDescriptionKey: "Archive signature verification failed."])
    }
    let metadata: [String: Any] = [
        "signature": signature.base64EncodedString(), "length": archive.count,
        "version": version, "build": build, "minimumSystemVersion": plist["LSMinimumSystemVersion"] as? String ?? "14.0"
    ]
    let json = try JSONSerialization.data(withJSONObject: metadata, options: [.sortedKeys])
    FileHandle.standardOutput.write(json)
} catch {
    FileHandle.standardError.write(Data(("Release signing failed: " + error.localizedDescription + "\n").utf8))
    exit(1)
}
