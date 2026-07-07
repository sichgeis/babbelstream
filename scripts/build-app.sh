#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-debug}"
APP_NAME="BabbelStream"
BUNDLE_IDENTIFIER="com.sichgeis.babbelstream"
LOCAL_CODESIGN_IDENTITY="${LOCAL_CODESIGN_IDENTITY:-BabbelStream Local Code Signing}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
GIT_COMMIT="${GIT_COMMIT:-unknown}"
APP_ICON_SOURCE="$ROOT_DIR/Resources/AppIcon.svg"
APP_ICON_NAME="$APP_NAME.icns"
ICONSET_DIR="$DIST_DIR/$APP_NAME.iconset"
ICON_PNG="$DIST_DIR/$APP_NAME-icon-1024.png"

make_app_icon() {
  if [[ ! -f "$APP_ICON_SOURCE" ]]; then
    echo "Expected app icon source not found: $APP_ICON_SOURCE" >&2
    exit 1
  fi

  if ! command -v qlmanage >/dev/null 2>&1; then
    echo "qlmanage is required to render $APP_ICON_SOURCE into app icon PNGs." >&2
    exit 1
  fi

  if ! command -v sips >/dev/null 2>&1; then
    echo "sips is required to resize app icon PNGs." >&2
    exit 1
  fi

  if ! command -v iconutil >/dev/null 2>&1; then
    echo "iconutil is required to build the app .icns file." >&2
    exit 1
  fi

  rm -rf "$ICONSET_DIR" "$ICON_PNG"
  mkdir -p "$ICONSET_DIR"

  qlmanage -t -s 1024 -o "$DIST_DIR" "$APP_ICON_SOURCE" >/dev/null 2>&1
  local rendered_png="$DIST_DIR/$(basename "$APP_ICON_SOURCE").png"
  if [[ ! -f "$rendered_png" ]]; then
    echo "Could not render app icon PNG from $APP_ICON_SOURCE" >&2
    exit 1
  fi

  mv "$rendered_png" "$ICON_PNG"

  sips -z 16 16 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

  iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/$APP_ICON_NAME"
  rm -rf "$ICONSET_DIR" "$ICON_PNG"
}

cd "$ROOT_DIR"

if [[ "$GIT_COMMIT" == "unknown" ]] && command -v git >/dev/null 2>&1; then
  GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
  if [[ "$GIT_COMMIT" != "unknown" ]] && ! git diff --quiet --ignore-submodules -- 2>/dev/null; then
    GIT_COMMIT="$GIT_COMMIT-dirty"
  fi
  if [[ "$GIT_COMMIT" != "unknown" && "$GIT_COMMIT" != *-dirty ]] && ! git diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
    GIT_COMMIT="$GIT_COMMIT-dirty"
  fi
fi

swift build -c "$CONFIGURATION" --product "$APP_NAME"
BIN_PATH="$(swift build -c "$CONFIGURATION" --show-bin-path)"
EXECUTABLE="$BIN_PATH/$APP_NAME"

if [[ ! -x "$EXECUTABLE" ]]; then
  echo "Expected executable not found: $EXECUTABLE" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$EXECUTABLE" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
make_app_icon

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_IDENTIFIER</string>
  <key>CFBundleIconFile</key>
  <string>$APP_ICON_NAME</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>BabbelStreamGitCommit</key>
  <string>$GIT_COMMIT</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSMicrophoneUsageDescription</key>
  <string>BabbelStream records audio only when you start a test recording or use push-to-talk, then deletes temporary audio after processing.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  if [[ -z "$CODESIGN_IDENTITY" ]]; then
    if security find-identity -v -p codesigning 2>/dev/null | grep -F "\"$LOCAL_CODESIGN_IDENTITY\"" >/dev/null; then
      CODESIGN_IDENTITY="$LOCAL_CODESIGN_IDENTITY"
    else
      CODESIGN_IDENTITY="-"
    fi
  fi

  codesign --force --sign "$CODESIGN_IDENTITY" "$APP_DIR" >/dev/null
  echo "Signed with identity: $CODESIGN_IDENTITY"
  if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
    echo "Warning: ad-hoc signing changes the app identity on rebuilds; Accessibility may not stay trusted."
    echo "Run scripts/create-local-codesign-identity.sh once for a stable local signing identity."
  fi
fi

echo "Built $APP_DIR"
