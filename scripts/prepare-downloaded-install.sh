#!/bin/bash
# Standalone, release-pinned helper. Review this file before running it.
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
umask 077

VERSION=0.5.3
BUILD=11
SOURCE=b9c0641
SHA256=41b8aed841824c66862b65a11c576364300e3cbd07760370e81f76b77a6a99a2
CDHASH=8ae6266b8ce2389dd4b6f356fc8a66c120b7c85c
RELEASE_URL=https://github.com/sichgeis/babbelstream/releases/download/v0.5.3/BabbelStream-0.5.3.dmg
verify_only=false
if [[ "${1:-}" == --verify-only ]]; then verify_only=true; shift; fi
download=false
update=false
case "${1:-}" in
  --download) download=true; shift ;;
  --update) download=true; update=true; shift ;;
esac
if { $download && [[ $# != 0 ]]; } || { ! $download && [[ $# != 1 || ! -f "${1:-}" ]]; }; then
  echo 'Usage: bash prepare-downloaded-install.sh [--verify-only] {--download | --update | /path/to/BabbelStream-0.5.3.dmg}' >&2
  exit 1
fi
fail() { echo "$1" >&2; exit 1; }
[[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]] || fail 'This release requires an Apple Silicon Mac.'
os_version="$(sw_vers -productVersion)"
[[ "${os_version%%.*}" -ge 13 ]] || fail 'This release requires macOS 13 or later.'
if ! $verify_only; then
  [[ -t 0 && -t 1 ]] || fail 'Run interactively in Terminal. No noninteractive approval is accepted.'
  [[ "$EUID" -ne 0 ]] || fail 'Run as your normal user, without sudo.'
  for receipt in /opt/homebrew/Caskroom/babbelstream /usr/local/Caskroom/babbelstream; do
    [[ ! -e "$receipt" ]] || fail 'A Homebrew installation was found. Use its documented upgrade route or resolve ownership first.'
  done
  if [[ -L /Applications/BabbelStream.app && "$(readlink /Applications/BabbelStream.app)" == *Caskroom* ]]; then
    fail 'The Applications copy belongs to Homebrew. Resolve installation ownership first.'
  fi
  if pgrep -x BabbelStream >/dev/null; then
    fail 'Quit BabbelStream normally, then run the helper again. No processes were stopped.'
  fi
fi

if $update && ! $verify_only; then
  installed=/Applications/BabbelStream.app
  if [[ -e "$installed" ]]; then
    installed_plist="$installed/Contents/Info.plist"
    installed_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$installed_plist")" || fail 'Cannot read installed version. Resolve the existing installation manually.'
    installed_build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$installed_plist")" || fail 'Cannot read installed build.'
    [[ "$installed_version" =~ ^[0-9]{1,8}\.[0-9]{1,8}\.[0-9]{1,8}$ && "$installed_build" =~ ^[0-9]{1,8}$ ]] || fail 'Unexpected installed version format. Resolve manually.'
    # Compare numeric version components, then build. Never downgrade silently.
    IFS=. read -r installed_major installed_minor installed_patch <<< "$installed_version"
    IFS=. read -r release_major release_minor release_patch <<< "$VERSION"
    comparison=0
    for pair in "$installed_major:$release_major" "$installed_minor:$release_minor" "$installed_patch:$release_patch" "$installed_build:$BUILD"; do
      left="${pair%:*}"; right="${pair#*:}"
      if (( 10#$left > 10#$right )); then comparison=1; break; fi
      if (( 10#$left < 10#$right )); then comparison=-1; break; fi
    done
    [[ "$comparison" != 1 ]] || fail 'Installed app is newer than this helper. Get the current helper from the repository README; no downgrade performed.'
    if [[ "$comparison" == 0 ]]; then
      codesign --verify --deep --strict "$installed" >/dev/null 2>&1 || fail 'Installed signature is invalid. Resolve manually.'
      installed_signature="$(codesign --display --verbose=3 "$installed" 2>&1)"
      [[ "$installed_signature" == *"CDHash=$CDHASH"* ]] || fail 'Installed version matches but signature differs. Resolve manually.'
      echo "BabbelStream $VERSION (build $BUILD) is already installed. No changes needed."
      exit 0
    fi
  fi
fi

workspace="$(mktemp -d "${TMPDIR:-/tmp}/babbelstream-install.XXXXXX")"
mount_dir="$workspace/mounted"
mounted=false
keep=false
cleanup() {
  local result=$?
  trap - EXIT
  if $mounted; then
    if ! hdiutil detach "$mount_dir" >/dev/null 2>&1; then
      # Failed/interrupted attach may never have mounted anything. If the
      # mountpoint is a different filesystem, preserve it for manual ejection.
      if [[ "$(stat -f %d "$mount_dir")" != "$(stat -f %d "$workspace")" ]]; then
        echo 'Could not eject the temporary image. Eject it in Finder before removing its temporary folder.' >&2
        exit 1
      fi
    fi
  fi
  if ! $keep; then rm -rf "$workspace"; fi
  exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Verify a private snapshot, so replacing the user's download cannot change
# the image between hash verification and mounting. Never edit the download.
if $download; then
  echo "Downloading BabbelStream $VERSION from GitHub Releases. No provider or personal data is sent."
  curl --fail --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --connect-timeout 20 --max-time 600 --output "$workspace/release.dmg" "$RELEASE_URL" \
    || fail 'Download failed. No installation or quarantine change performed.'
else
  cp "$1" "$workspace/release.dmg"
fi
actual_hash="$(shasum -a 256 "$workspace/release.dmg")"
[[ "${actual_hash%% *}" == "$SHA256" ]] || fail 'Checksum mismatch. Nothing was prepared; download the pinned release again.'
hdiutil verify "$workspace/release.dmg" >/dev/null 2>&1 || fail 'DMG integrity verification failed.'
mkdir "$mount_dir"
# Mark before attaching so interruption during attach still attempts cleanup.
mounted=true
hdiutil attach -readonly -nobrowse -mountpoint "$mount_dir" "$workspace/release.dmg" >/dev/null 2>&1 || fail 'Could not mount the verified image.'
app="$mount_dir/BabbelStream.app"

verify_app() {
  local target="$1" plist="$1/Contents/Info.plist" signature entitlements
  [[ -d "$target" && ! -L "$target" && -f "$plist" ]] || fail 'Expected app bundle missing.'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist")" == com.sichgeis.babbelstream ]] || fail 'Unexpected bundle identifier.'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")" == BabbelStream ]] || fail 'Unexpected executable.'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")" == "$VERSION" ]] || fail 'Unexpected version.'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")" == "$BUILD" ]] || fail 'Unexpected build.'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :BabbelStreamGitCommit' "$plist")" == "$SOURCE" ]] || fail 'Unexpected source commit.'
  [[ "$(lipo -archs "$target/Contents/MacOS/BabbelStream")" == arm64 ]] || fail 'Unexpected executable architecture.'
  codesign --verify --deep --strict "$target" >/dev/null 2>&1 || fail 'App signature integrity verification failed.'
  signature="$(codesign --display --verbose=3 "$target" 2>&1)"
  [[ "$signature" == *"CDHash=$CDHASH"* && "$signature" == *'Signature=adhoc'* && "$signature" == *'(adhoc,runtime)'* ]] || fail 'Unexpected release signature.'
  entitlements="$workspace/entitlements.plist"
  codesign --display --xml --entitlements - "$target" > "$entitlements" 2>/dev/null
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.device.audio-input' "$entitlements")" == true ]] || fail 'Audio entitlement missing.'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.get-task-allow' "$entitlements" 2>/dev/null || true)" != true ]] || fail 'Unexpected debugger entitlement.'
}
verify_app "$app"
echo "Verified BabbelStream $VERSION, build $BUILD, source $SOURCE."
echo 'Checksum and ad-hoc signature integrity do not establish Apple verification or malware safety.'
if $verify_only; then
  echo 'Verification only: no quarantine attributes changed and no installation performed.'
  exit 0
fi

cat <<'NOTICE'

BabbelStream is NOT notarized by Apple.
This helper will copy the verified app into a private temporary folder and
remove ONLY com.apple.quarantine from that copy and its contents. This bypasses
the quarantine-based first-open check; it does not make the app Apple-verified.
Continue only if your device policy permits this installation. Company endpoint
controls may still block it. If they do, contact IT; do not attempt more bypasses.
The downloaded DMG, global security settings, permissions, Keychain and app data
will remain unchanged. No app will be installed or launched automatically.
NOTICE
printf '\nType PREPARE to consent, or press Return to cancel: '
IFS= read -r consent || exit 0
[[ "$consent" == PREPARE ]] || { echo 'Cancelled. Nothing prepared.'; exit 0; }

prepared="$workspace/BabbelStream.app"
ditto "$app" "$prepared"
verify_app "$prepared"
# Scope is only the verified copy owned by this invocation; never a user path.
attributes="$(xattr -r "$prepared")" || fail 'Could not inspect prepared-copy attributes.'
if [[ "$attributes" == *com.apple.quarantine* ]]; then
  xattr -dr com.apple.quarantine "$prepared" || fail 'Could not remove quarantine from the prepared copy.'
fi
attributes="$(xattr -r "$prepared")" || fail 'Could not inspect prepared-copy attributes.'
if [[ "$attributes" == *com.apple.quarantine* ]]; then
  fail 'Quarantine remains. Contact IT rather than attempting another bypass.'
fi
verify_app "$prepared"
hdiutil detach "$mount_dir" >/dev/null 2>&1 || fail 'Could not eject the temporary image.'
mounted=false
rm -f "$workspace/release.dmg" "$workspace/entitlements.plist"
rmdir "$mount_dir"
keep=true
printf '\nPrepared app: %s\n' "$prepared"
cat <<'NEXT'
In Finder, preserve your previous app as a rollback copy before replacing it.
Drag the prepared app into Applications; Finder handles any authorization prompt.
Then launch the Applications copy yourself and check its version in Diagnostics.
If launch is blocked, contact IT. Microphone and Accessibility require normal consent.
After installation, move the temporary folder containing this prepared app to Trash.
Temporary folders may also be removed by macOS; rerun the helper if needed.
NEXT
open -R "$prepared" || echo 'Could not reveal the app. Open the printed location in Finder.' >&2
