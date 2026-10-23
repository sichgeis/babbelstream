#!/usr/bin/env bash
set -euo pipefail
APP_PATH="${1:?Usage: verify-app.sh APP_PATH [development|candidate|distribution]}"
VERIFY_MODE="${2:-candidate}"
case "$VERIFY_MODE" in development|candidate|distribution) ;; *) echo "Invalid verification mode." >&2; exit 1 ;; esac
codesign --verify --strict --verbose=2 "$APP_PATH"
SIGNATURE="$(codesign --display --verbose=3 "$APP_PATH" 2>&1)"
if [[ "$VERIFY_MODE" != development ]]; then
  [[ "$SIGNATURE" == *"(runtime)"* ]] || { echo "Hardened runtime missing." >&2; exit 1; }
  ENTITLEMENTS_FILE="$(mktemp "${TMPDIR:-/tmp}/babbelstream-entitlements.XXXXXX")"
  trap 'rm -f "$ENTITLEMENTS_FILE"' EXIT
  codesign --display --entitlements - "$APP_PATH" > "$ENTITLEMENTS_FILE" 2>/dev/null
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.device.audio-input' "$ENTITLEMENTS_FILE")" == true ]] || { echo "Audio-input entitlement missing." >&2; exit 1; }
  if [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.get-task-allow' "$ENTITLEMENTS_FILE" 2>/dev/null || true)" == true ]]; then
    echo "Distribution must not permit debugger task access." >&2; exit 1
  fi
fi
if [[ "$VERIFY_MODE" == distribution ]]; then
  [[ "$SIGNATURE" == *"Authority=Developer ID Application:"* && "$SIGNATURE" == *"Timestamp="* ]] || { echo "Developer ID signature and secure timestamp required." >&2; exit 1; }
fi
printf 'App signature verified (%s).\n' "$VERIFY_MODE"
