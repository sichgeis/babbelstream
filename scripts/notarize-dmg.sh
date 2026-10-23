#!/usr/bin/env bash
# Run only after explicit authorization to submit this artifact to Apple.
set -euo pipefail
DMG_PATH="${1:?Usage: NOTARY_PROFILE=approved-profile notarize-dmg.sh DMG_PATH}"
: "${NOTARY_PROFILE:?Set an explicitly approved existing notarytool Keychain profile; credentials are never accepted inline.}"
[[ -f "$DMG_PATH" && "$DMG_PATH" == *.dmg ]] || { echo "Expected a signed distribution DMG." >&2; exit 1; }
codesign --verify --strict --verbose=2 "$DMG_PATH"
SIGNATURE="$(codesign --display --verbose=3 "$DMG_PATH" 2>&1)"
[[ "$SIGNATURE" == *"Authority=Developer ID Application:"* && "$SIGNATURE" == *"Timestamp="* ]] || { echo "Developer ID signature and secure timestamp required before submission." >&2; exit 1; }
RESULT_PATH="$DMG_PATH.notary-result.plist"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait --output-format plist > "$RESULT_PATH"
SUBMISSION_ID="$(/usr/libexec/PlistBuddy -c 'Print :id' "$RESULT_PATH")"
xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "$NOTARY_PROFILE" "$DMG_PATH.notary-log.json"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :status' "$RESULT_PATH")" == Accepted ]] || { echo "Notarization was not accepted; review the saved notary log." >&2; exit 1; }
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
echo "Notarized and stapled; checksum regenerated. Review the saved notary log for warnings and complete clean-Mac installation QA before publication."
