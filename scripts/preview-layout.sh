#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
scripts/swift-project.sh build --product BabbelStreamChecks
BIN_PATH="$(scripts/swift-project.sh build --show-bin-path)"
PREVIEW_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/babbelstream-layout.XXXXXX")"
PREVIEW_APP="$PREVIEW_ROOT/BabbelStreamLayoutPreview.app"
mkdir -p "$PREVIEW_APP/Contents/MacOS"
cp "$BIN_PATH/BabbelStreamChecks" "$PREVIEW_APP/Contents/MacOS/BabbelStreamLayoutPreview"
cat > "$PREVIEW_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.sichgeis.babbelstream.layout-preview</string>
<key>CFBundleName</key><string>BabbelStream Layout Preview</string>
<key>CFBundleExecutable</key><string>BabbelStreamLayoutPreview</string>
<key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
PLIST
printf 'Fixture-only preview: %s\nQuit the preview when finished; then remove this disposable bundle.\n' "$PREVIEW_APP"
open "$PREVIEW_APP" --args --layout-preview "$@"
