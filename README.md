# Keebs

A native macOS mechanical keyboard sound studio: a full SwiftUI desktop app with a menu bar shortcut, 22 sound profiles, and a little more presence in every keystroke.

Requires **macOS 14 or later**. No dependencies beyond Apple's frameworks.

## Run on your Mac

Install Xcode 15+ or Apple's Command Line Tools, then:

```sh
git clone https://github.com/samidun26/keebs.git
cd keebs
swift test
bash scripts/build-app.sh
open dist/Keebs.app
```

For both Apple Silicon and Intel, use `KEEBS_UNIVERSAL=1 bash scripts/build-app.sh`. Open `Package.swift` in Xcode to edit and debug. Use the packaged app for permission and login-item checks; Swift Package previews and an unbundled executable do not provide the same app identity.

Click **Enable** and allow Keebs under **System Settings → Privacy & Security → Input Monitoring**. If macOS requests it, quit and reopen the app. Preview buttons and the focused keyboard test area also work without system-wide permission. Move the app into `/Applications` before enabling launch at login, and keep it in a stable location when testing permissions.

## The experience

- Six recorded switch sets: Cream Full Travel, MX Black, MX Blue, MX Brown, Turquoise, and Holy Pandas. Five press variations per set; separate release sounds. Dedicated Space, Return, and Delete recordings where available; MX Blue uses its generic samples for those keys.
- Sixteen original synthesized profiles across linear, tactile, clicky, and silent categories, explicitly labeled as synthesis rather than recordings of a commercial switch.
- Physical key positions control stereo panning. Space, Return, and Delete have their own sound character. Repeated OS keydown events are ignored.
- Preloaded 48 kHz samples, 32 overlapping voices, room reverb, low-frequency desk resonance, and a peak limiter. Volume, stereo width, natural variation, and key releases are adjustable.
- Search, category filters, favorites, an interactive keyboard playground, persistent settings, optional launch at login, and a menu bar panel for quick switching and pausing. **⌘⇧M** toggles sound while Keebs is the active app.
- Listen-only key capture. No typed characters are read, no keystroke history is saved, and macOS secure input pauses capture. Sleep, wake, and audio-device changes reset or reload playback.

The app makes no network requests and sends no analytics. Settings and favorites live in macOS UserDefaults. Stereo positions use an ANSI layout approximation; unknown key codes are centered. Modifier-only presses currently do not play sounds.

## Recordings and licenses

Bundled recordings come from [Mechvibes](https://github.com/hainguyents13/mechvibes) at pinned commit `326252a13e7bef4f1c35d08ef0189b5af6f8ba02`, under its MIT license. Holy Pandas has its own MIT notice, credited to Thomas Lai, and points to [kbsim](https://github.com/tplai/kbsim). Original files are preserved; Keebs decodes, converts to mono, resamples, and applies short boundary fades at load time.

See [third-party notices](docs/THIRD_PARTY_NOTICES.md) and [asset provenance](docs/audio-provenance.json) for attribution and original Git blob hashes. Keebs is independent of Klack and switch manufacturers; it uses no Klack code, artwork, or audio.

## Validation and distribution

GitHub Actions runs the Swift tests on macOS, builds a universal `.app`, validates the resource bundle and signature, and uploads `Keebs-macOS.zip` as a workflow artifact. Tests cover waveform bounds, release energy, unique profile output, key repeat suppression, reset behavior, stereo placement, and settings clamping.

The default build uses an **ad hoc signature** for local testing. A public downloadable release needs a Developer ID signature and notarization; `KEEBS_SIGNING_IDENTITY` accepts your signing identity, but the script does not notarize. This repository's first implementation still requires the interactive checks in [macOS validation](docs/MACOS_VALIDATION.md); CI cannot approve Input Monitoring or judge the sound experience.
