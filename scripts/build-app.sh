#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/release-preflight.sh"
APP_NAME="BabbelStream"
VERSION="${VERSION:-$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")}"
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

  rm -rf "$ICONSET_DIR" "$ICON_PNG"
  mkdir -p "$ICONSET_DIR"

  qlmanage -t -s 1024 -o "$DIST_DIR" "$APP_ICON_SOURCE" >/dev/null 2>&1
  local rendered_png="$DIST_DIR/$(basename "$APP_ICON_SOURCE").png"
  if [[ ! -f "$rendered_png" ]]; then
    echo "Could not render app icon PNG from $APP_ICON_SOURCE" >&2
    exit 1
  fi

  mv "$rendered_png" "$ICON_PNG"

  # Write PNG entries directly instead of using iconutil: it stores 16/32 px as
  # ARGB PackBits (ic04/ic05), which corrupts light artwork at 16 px. The 1x
  # 16/32 px slots stay empty because macOS misreads PNG data in icp4/icp5; it
  # scales those sizes down from the @2x entries instead.
  local entry type px png_size
  : > "$ICONSET_DIR/body"
  for entry in ic11:32 ic12:64 ic07:128 ic13:256 ic08:256 ic14:512 ic09:512 ic10:1024; do
    type="${entry%%:*}"
    px="${entry##*:}"
    sips -z "$px" "$px" "$ICON_PNG" --out "$ICONSET_DIR/$type.png" >/dev/null
    png_size="$(wc -c < "$ICONSET_DIR/$type.png")"
    { printf '%s' "$type"; write_be32 $((png_size + 8)); cat "$ICONSET_DIR/$type.png"; } >> "$ICONSET_DIR/body"
  done

  { printf 'icns'; write_be32 $(($(wc -c < "$ICONSET_DIR/body") + 8)); cat "$ICONSET_DIR/body"; } > "$RESOURCES_DIR/$APP_ICON_NAME"
  rm -rf "$ICONSET_DIR" "$ICON_PNG"
}

write_be32() {
  printf "\\x$(printf '%02x' $((($1 >> 24) & 255)))\\x$(printf '%02x' $((($1 >> 16) & 255)))\\x$(printf '%02x' $((($1 >> 8) & 255)))\\x$(printf '%02x' $(($1 & 255)))"
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

"$ROOT_DIR/scripts/swift-project.sh" build -c "$CONFIGURATION" --product "$APP_NAME"
BIN_PATH="$("$ROOT_DIR/scripts/swift-project.sh" build -c "$CONFIGURATION" --show-bin-path)"
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

if command -v codesign >/dev/null 2>&1; then
  if [[ -z "$CODESIGN_IDENTITY" ]]; then
    if security find-identity -v -p codesigning 2>/dev/null | grep -F "\"$LOCAL_CODESIGN_IDENTITY\"" >/dev/null; then
      CODESIGN_IDENTITY="$LOCAL_CODESIGN_IDENTITY"
    else
      CODESIGN_IDENTITY="-"
    fi
  fi
else
  [[ "$BUILD_MODE" == development ]] || { echo "codesign is required for candidate/distribution." >&2; exit 1; }
  CODESIGN_IDENTITY="not signed"
fi

if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  CODE_SIGNING_SUMMARY="ad-hoc"
else
  CODE_SIGNING_SUMMARY="$CODESIGN_IDENTITY"
fi

plist_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}
CODE_SIGNING_PLIST_VALUE="$(plist_escape "$CODE_SIGNING_SUMMARY")"
GIT_COMMIT_PLIST_VALUE="$(plist_escape "$GIT_COMMIT")"
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
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>BabbelStreamBuildMode</key>
  <string>$BUILD_MODE</string>
  <key>BabbelStreamGitCommit</key>
  <string>$GIT_COMMIT_PLIST_VALUE</string>
  <key>BabbelStreamCodeSigning</key>
  <string>$CODE_SIGNING_PLIST_VALUE</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSMicrophoneUsageDescription</key>
  <string>BabbelStream records audio only when you start a test recording or use its tap-or-hold dictation shortcut, deletes successful audio after processing, and retains stopped failed recordings locally until retry succeeds or you delete them.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  SIGNING_ARGUMENTS=(--force --sign "$CODESIGN_IDENTITY")
  if [[ "$BUILD_MODE" != development ]]; then
    SIGNING_ARGUMENTS+=(--options runtime --entitlements "$ROOT_DIR/Resources/BabbelStream.entitlements")
  fi
  if [[ "$BUILD_MODE" == distribution ]]; then
    SIGNING_ARGUMENTS+=(--timestamp)
  else
    SIGNING_ARGUMENTS+=(--timestamp=none)
  fi
  codesign "${SIGNING_ARGUMENTS[@]}" "$APP_DIR" >/dev/null
  "$ROOT_DIR/scripts/verify-app.sh" "$APP_DIR" "$BUILD_MODE"
  echo "Signed with identity: $CODESIGN_IDENTITY"
  if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
    echo "Warning: ad-hoc signing changes the app identity on rebuilds; Accessibility may not stay trusted."
    echo "Run scripts/create-local-codesign-identity.sh once for a stable local signing identity."
  fi
fi

echo "Built $APP_DIR"
