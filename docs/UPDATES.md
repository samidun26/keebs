# In-app updates

Keebs 0.1.2 uses Sparkle 2.10.0. Choose **Keebs → Check for Updates…**, use the keyboard icon in the menu bar, or use the studio's update controls. Sparkle downloads, verifies the Ed25519 archive signature, and installs/relaunches after confirmation. Settings stay in UserDefaults. Automatic checks are optional; automatic installation and system profiling are disabled.

Development builds use ad hoc code signing and signed update archives. No Apple Developer account is needed for this update flow. Gatekeeper and Input Monitoring may still require user action. Developer ID signing and notarization are needed for smooth public distribution.

## One-time activation

1. Merge the updater and slider fixes into `main`.
2. In [GitHub Actions repository secrets](https://github.com/samidun26/keebs/settings/secrets/actions), create `SPARKLE_PRIVATE_KEY`. Use the complete base64 line in the separately supplied `keebs-update-signing-key.txt` file. Keep a secure backup; never paste it into source, issues, PRs, or chat. Only its public key is committed in `Resources/Info.plist`.
3. Create and push tag `v0.1.2` from the merged commit. **Publish signed update** tests and builds a universal app, verifies the signing key matches the embedded public key, signs the archive, and publishes `Keebs-macOS.zip` and `appcast.xml` together as a GitHub Release.
4. Install the updater-enabled app once. Older 0.1.1 builds cannot upgrade themselves. Checks work after the first signed release is published; until then, GitHub's feed URL returns a not-found response.

## Future releases

Increase `CFBundleShortVersionString` (for example `0.1.3`) and the integer `CFBundleVersion` (for example `4`). Merge, then tag that commit `v0.1.3`. Keep the app name, bundle identifier, and public key stable. Do not reuse build numbers, move tags backward, or publish releases out of order. Sparkle compares build numbers to prevent downgrades.

The latest release hosts the feed:

`https://github.com/samidun26/keebs/releases/latest/download/appcast.xml`

To package locally on macOS, build/archive with `ditto`, supply `SPARKLE_PRIVATE_KEY` securely through the environment, and run:

```sh
swift scripts/sign-release.swift dist/Keebs-macOS.zip Resources/Info.plist > dist/signature.json
python3 scripts/create-appcast.py --metadata dist/signature.json --archive dist/Keebs-macOS.zip --tag v0.1.2 --output dist/appcast.xml
```

The signature JSON contains only public metadata. The private key is never logged or bundled. A missing or mismatched key stops signing.

## Interactive verification

Install 0.1.2 in Applications and save a mix/favorite. Publish a newer signed version. Check from both menus, cancel once, then install/relaunch and verify the new version, preserved settings, audio, sliders, and Input Monitoring. In an isolated test feed, try a corrupted archive or one signed by a different key: Sparkle must reject it. Check automatic-check preferences across relaunch and behavior without network. CI verifies packaging/signing; it does not establish a complete interactive installation on a user's Mac.
