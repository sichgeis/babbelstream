#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="BabbelStream"
VERSION="${VERSION:-0.1.0}"
CONFIGURATION="${CONFIGURATION:-debug}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_NAME="${DMG_NAME:-$APP_NAME-$VERSION.dmg}"
DMG_PATH="$DIST_DIR/$DMG_NAME"
RW_DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION-rw.dmg"
STAGING_DIR="$DIST_DIR/dmg-staging"
VOLUME_NAME="${VOLUME_NAME:-$APP_NAME $VERSION}"
DMG_CODESIGN_IDENTITY="${DMG_CODESIGN_IDENTITY:-}"
BACKGROUND_SOURCE="$ROOT_DIR/Resources/DmgBackground.svg"
BACKGROUND_DIR_NAME=".background"
BACKGROUND_PNG_NAME="installer-background.png"
DMG_BACKGROUND_SIZE="${DMG_BACKGROUND_SIZE:-660}"
DMG_BACKGROUND_WIDTH="${DMG_BACKGROUND_WIDTH:-660}"
DMG_BACKGROUND_HEIGHT="${DMG_BACKGROUND_HEIGHT:-420}"
DMG_WINDOW_X="${DMG_WINDOW_X:-200}"
DMG_WINDOW_Y="${DMG_WINDOW_Y:-120}"
DMG_WINDOW_WIDTH="${DMG_WINDOW_WIDTH:-660}"
DMG_WINDOW_HEIGHT="${DMG_WINDOW_HEIGHT:-448}"
DMG_ICON_SIZE="${DMG_ICON_SIZE:-128}"
DMG_APP_ICON_X="${DMG_APP_ICON_X:-180}"
DMG_APP_ICON_Y="${DMG_APP_ICON_Y:-232}"
DMG_APPLICATIONS_ICON_X="${DMG_APPLICATIONS_ICON_X:-480}"
DMG_APPLICATIONS_ICON_Y="${DMG_APPLICATIONS_ICON_Y:-232}"

fail() {
  echo "$1" >&2
  exit 1
}

render_dmg_background() {
  [[ -f "$BACKGROUND_SOURCE" ]] || fail "Expected DMG background not found: $BACKGROUND_SOURCE"
  command -v qlmanage >/dev/null 2>&1 || fail "qlmanage is required to render the DMG background."
  command -v sips >/dev/null 2>&1 || fail "sips is required to size the DMG background."

  local background_dir="$STAGING_DIR/$BACKGROUND_DIR_NAME"
  local rendered_background="$background_dir/$(basename "$BACKGROUND_SOURCE").png"
  local final_background="$background_dir/$BACKGROUND_PNG_NAME"
  mkdir -p "$background_dir"
  qlmanage -t -s "$DMG_BACKGROUND_SIZE" -o "$background_dir" "$BACKGROUND_SOURCE" >/dev/null 2>&1
  [[ -f "$rendered_background" ]] || fail "Could not render DMG background: $rendered_background"
  sips -c "$DMG_BACKGROUND_HEIGHT" "$DMG_BACKGROUND_WIDTH" "$rendered_background" --out "$final_background" >/dev/null
  rm -f "$rendered_background"
}

attach_dmg() {
  local mount_output mount_dir
  mount_output="$(hdiutil attach "$1" -readwrite -noverify -noautoopen)"
  mount_dir="$(printf '%s\n' "$mount_output" | awk -F '\t' '/\/Volumes\// { print $NF; exit }')"
  [[ -n "$mount_dir" ]] || fail "Could not determine mounted DMG path."
  echo "$mount_dir"
}

detach_mounted_dmg() {
  if [[ -n "${MOUNT_DIR:-}" && -d "$MOUNT_DIR" ]]; then
    hdiutil detach "$MOUNT_DIR" >/dev/null || true
    MOUNT_DIR=""
  fi
}

detach_existing_volume() {
  local existing_mount="/Volumes/$VOLUME_NAME"
  if [[ -d "$existing_mount" ]]; then
    hdiutil detach "$existing_mount" >/dev/null || fail "Could not detach existing mounted volume: $existing_mount"
  fi
}

prettify_dmg_window() {
  command -v osascript >/dev/null 2>&1 || fail "osascript is required to set the DMG Finder layout."

  local window_right=$((DMG_WINDOW_X + DMG_WINDOW_WIDTH))
  local window_bottom=$((DMG_WINDOW_Y + DMG_WINDOW_HEIGHT))
  local background_path="$MOUNT_DIR/$BACKGROUND_DIR_NAME/$BACKGROUND_PNG_NAME"

  osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {$DMG_WINDOW_X, $DMG_WINDOW_Y, $window_right, $window_bottom}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to $DMG_ICON_SIZE
    set text size of viewOptions to 12
    set background picture of viewOptions to (POSIX file "$background_path" as alias)
    set position of item "$APP_NAME.app" of container window to {$DMG_APP_ICON_X, $DMG_APP_ICON_Y}
    set extension hidden of item "$APP_NAME.app" of container window to true
    set position of item "Applications" of container window to {$DMG_APPLICATIONS_ICON_X, $DMG_APPLICATIONS_ICON_Y}
    close
    open
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT
}

copy_finder_metadata() {
  local attempt
  for attempt in {1..10}; do
    if [[ -f "$MOUNT_DIR/.DS_Store" ]]; then
      cp "$MOUNT_DIR/.DS_Store" "$STAGING_DIR/.DS_Store"
      return 0
    fi

    sleep 0.5
  done

  fail "Finder did not write DMG layout metadata."
}

create_compressed_dmg() {
  hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -fs HFS+ \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null
}

cd "$ROOT_DIR"

CONFIGURATION="$CONFIGURATION" scripts/build-app.sh

if [[ ! -d "$APP_DIR" ]]; then
  fail "Expected app bundle not found: $APP_DIR"
fi

trap detach_mounted_dmg EXIT
detach_existing_volume

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_DIR" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"
render_dmg_background

rm -f "$DMG_PATH" "$RW_DMG_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -fs HFS+ \
  -ov \
  -format UDRW \
  "$RW_DMG_PATH" >/dev/null

MOUNT_DIR="$(attach_dmg "$RW_DMG_PATH")"
prettify_dmg_window
copy_finder_metadata
hdiutil detach "$MOUNT_DIR" >/dev/null
MOUNT_DIR=""
rm -f "$RW_DMG_PATH"
create_compressed_dmg

hdiutil verify "$DMG_PATH" >/dev/null

if [[ -n "$DMG_CODESIGN_IDENTITY" ]]; then
  codesign --force --sign "$DMG_CODESIGN_IDENTITY" "$DMG_PATH" >/dev/null
  codesign --verify --verbose=2 "$DMG_PATH"
fi

shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"

echo "Built $DMG_PATH"
echo "Checksum $DMG_PATH.sha256"
