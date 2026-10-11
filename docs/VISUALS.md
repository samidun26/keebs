# Documentation visuals

The README uses Keebs' existing app icon and images rendered from its actual SwiftUI views on macOS. They use isolated demonstration settings, a silent audio fixture, and a “Preview mode” status. They do not show a user's desktop, recordings of keyboard input, or a granted system permission.

- `images/logo.png`: the 1024-pixel app icon, exported with the same generator used by the app build.
- `images/studio.png`: the desktop studio with Cream Full Travel selected.
- `images/menu-bar.png`: the actual menu bar panel with Holy Pandas selected.
- `images/preview.gif`: an animated profile preview cycling through Cream, Gateron Black Ink, Kailh Box Navy, and Topre.

## Refresh the assets

On macOS with Xcode or the Command Line Tools:

```sh
KEEBS_DOCS_OUTPUT="$PWD/docs/images" swift test --filter DocumentationCaptureTests
swift scripts/make-icon.swift /tmp/keebs-docs.iconset
cp /tmp/keebs-docs.iconset/icon_512x512@2x.png docs/images/logo.png
```

Alternatively, run **Capture documentation visuals** in GitHub Actions, download its artifact, and copy its four files into `docs/images/`. The export harness is skipped during ordinary test runs unless `KEEBS_DOCS_OUTPUT` is set. Review the exported images when the UI changes.
