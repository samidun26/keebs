import Foundation
import CryptoKit

// This verifier accepts only public metadata and the app's embedded public key.
do {
    guard CommandLine.arguments.count == 4 else {
        throw NSError(domain: "KeebsRelease", code: 1)
    }
    let archive = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
    let metadataData = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
    let plistData = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[3]))
    guard let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any],
          let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
          let encodedKey = plist["SUPublicEDKey"] as? String,
          let publicKeyData = Data(base64Encoded: encodedKey),
          let encodedSignature = metadata["signature"] as? String,
          let signature = Data(base64Encoded: encodedSignature),
          metadata["version"] as? String == plist["CFBundleShortVersionString"] as? String,
          metadata["build"] as? String == plist["CFBundleVersion"] as? String,
          metadata["minimumSystemVersion"] as? String == plist["LSMinimumSystemVersion"] as? String,
          metadata["length"] as? Int == archive.count,
          metadata["sha256"] as? String == SHA256.hash(data: archive).map({ String(format: "%02x", $0) }).joined() else {
        throw NSError(domain: "KeebsRelease", code: 2)
    }
    let key = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
    guard key.isValidSignature(signature, for: archive) else {
        throw NSError(domain: "KeebsRelease", code: 3)
    }
    print("Verified signed Keebs archive against the installed public key.")
} catch {
    FileHandle.standardError.write(Data("Release verification failed.\n".utf8))
    exit(1)
}
