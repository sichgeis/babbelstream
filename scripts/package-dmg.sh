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
STAGING_DIR="$DIST_DIR/dmg-staging"
VOLUME_NAME="${VOLUME_NAME:-$APP_NAME $VERSION}"
DMG_CODESIGN_IDENTITY="${DMG_CODESIGN_IDENTITY:-}"

cd "$ROOT_DIR"

CONFIGURATION="$CONFIGURATION" scripts/build-app.sh

if [[ ! -d "$APP_DIR" ]]; then
  echo "Expected app bundle not found: $APP_DIR" >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_DIR" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

hdiutil verify "$DMG_PATH" >/dev/null

if [[ -n "$DMG_CODESIGN_IDENTITY" ]]; then
  codesign --force --sign "$DMG_CODESIGN_IDENTITY" "$DMG_PATH" >/dev/null
  codesign --verify --verbose=2 "$DMG_PATH"
fi

shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"

echo "Built $DMG_PATH"
echo "Checksum $DMG_PATH.sha256"
