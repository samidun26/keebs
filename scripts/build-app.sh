#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Build Keebs.app on macOS 14+ with Xcode 15+ or the Command Line Tools." >&2
  exit 1
fi

build_args=(-c release)
if [[ "${KEEBS_UNIVERSAL:-0}" == "1" ]]; then
  build_args+=(--arch arm64 --arch x86_64)
fi
swift build "${build_args[@]}"
binary_path="$(swift build "${build_args[@]}" --show-bin-path)"
app_path="$PWD/dist/Keebs.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$binary_path/Keebs" "$app_path/Contents/MacOS/Keebs"
cp Resources/Info.plist "$app_path/Contents/Info.plist"
for bundle in "$binary_path"/*.bundle; do
  [[ -d "$bundle" ]] || continue
  cp -R "$bundle" "$app_path/Contents/Resources/"
done
swift scripts/make-icon.swift "$PWD/dist/Keebs.iconset"
iconutil -c icns "$PWD/dist/Keebs.iconset" -o "$app_path/Contents/Resources/Keebs.icns"
cp docs/THIRD_PARTY_NOTICES.md "$app_path/Contents/Resources/"
cp Sources/KeebsApp/Resources/Recordings/Mechvibes-LICENSE "$app_path/Contents/Resources/"
cp Sources/KeebsApp/Resources/Recordings/holy-pandas/LICENSE "$app_path/Contents/Resources/Holy-Pandas-LICENSE"
codesign --force --deep --sign "${KEEBS_SIGNING_IDENTITY:--}" "$app_path"
codesign --verify --deep --strict "$app_path"
echo "Built $app_path"
