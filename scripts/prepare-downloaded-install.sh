#!/bin/bash
# Standalone, release-pinned helper. Review this file before running it.
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
umask 077

VERSION=0.6.0
BUILD=14
SOURCE=c36c28c
SHA256=2752d399f5b1575be0a0ed9e5e8bb107a8b6b029584c196653c7a9db66f98ce4
CDHASH=cfab070efd8afedb6fad882575b7ad2db29b68c3
RELEASE_URL=https://github.com/sichgeis/babbelstream/releases/download/v0.6.0/BabbelStream-0.6.0.dmg
verify_only=false
download=false
update=false
fail() { echo "$1" >&2; exit 1; }
provider_url='' routing='' transcription_model='' cleanup_model='' image_path=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verify-only) verify_only=true; shift ;;
    --download|--update)
      ! $download && [[ -z "$image_path" ]] || fail 'Choose one installer source.'
      download=true; [[ "$1" != --update ]] || update=true; shift ;;
    --provider-url|--model-routing|--transcription-model|--cleanup-model)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail 'Configuration option requires a value.'
      case "$1" in
        --provider-url) [[ -z "$provider_url" ]] || fail 'Duplicate provider option.'; provider_url="$2" ;;
        --model-routing) [[ -z "$routing" ]] || fail 'Duplicate routing option.'; routing="$2" ;;
        --transcription-model) [[ -z "$transcription_model" ]] || fail 'Duplicate transcription option.'; transcription_model="$2" ;;
        --cleanup-model) [[ -z "$cleanup_model" ]] || fail 'Duplicate cleanup option.'; cleanup_model="$2" ;;
      esac
      shift 2 ;;
    --*) fail 'Unknown option. API keys must be entered in the app, never in this command.' ;;
    *) [[ -z "$image_path" ]] && ! $download || fail 'Choose one installer source.'; image_path="$1"; shift ;;
  esac
done
if ! $download && [[ -z "$image_path" || ! -f "$image_path" ]]; then
  fail 'Usage: bash prepare-downloaded-install.sh [--verify-only] {--download | --update | DMG_PATH} [--provider-url HTTPS_ORIGIN --model-routing ROUTING --transcription-model MODEL --cleanup-model MODEL]'
fi
configure=false
if [[ -n "$provider_url$routing$transcription_model$cleanup_model" ]]; then
  [[ -n "$provider_url" && -n "$routing" && -n "$transcription_model" && -n "$cleanup_model" ]] || fail 'Supply all four provider configuration options, or none.'
  # Accept HTTPS origins only. Exclude credentials, query/fragment, paths,
  # whitespace and shell/plist syntax before displaying or storing values.
  [[ "$provider_url" =~ ^https://([A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?)(:([0-9]{1,5}))?/?$ ]] || fail 'Provider URL must be an HTTPS origin without credentials, path, query or fragment.'
  provider_port="${BASH_REMATCH[4]:-}"
  [[ "$provider_url" != *..* ]] || fail 'Invalid provider hostname.'
  if [[ -n "$provider_port" ]]; then
    (( 10#$provider_port >= 1 && 10#$provider_port <= 65535 )) || fail 'Invalid provider port.'
  fi
  case "$routing" in standard-openai|litellm-openai-namespace) ;; *) fail 'Unsupported model routing.' ;; esac
  case "$transcription_model" in gpt-transcribe|gpt-4o-transcribe|gpt-4o-mini-transcribe) ;; *) fail 'Unsupported transcription model.' ;; esac
  [[ "$cleanup_model" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]{0,127}$ ]] || fail 'Invalid cleanup model identifier.'
  configure=true
fi
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

# The current main helper carries reviewed trust pins. Latest-release metadata
# may reject stale pins, but must never select unverified replacement bytes.
if $download; then
  latest_url="$(curl --head --silent --show-error --fail --location \
    --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --connect-timeout 20 --max-time 60 --output /dev/null --write-out '%{url_effective}' \
    https://github.com/sichgeis/babbelstream/releases/latest)" \
    || fail 'Could not check the latest public release. Try again later; nothing was changed.'
  [[ "$latest_url" == "https://github.com/sichgeis/babbelstream/releases/tag/v$VERSION" ]] \
    || fail 'This helper is behind the latest public release or release metadata is unexpected. Get the current helper from main; if it still fails, contact the maintainer to refresh verified pins. Nothing was changed.'
fi

already_current=false
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
      echo "BabbelStream $VERSION (build $BUILD) is already installed."
      $configure || { echo 'No changes needed.'; exit 0; }
      already_current=true
    fi
  fi
fi

workspace="$(mktemp -d "${TMPDIR:-/tmp}/babbelstream-install.XXXXXX")"
mount_dir="$workspace/mounted"
mounted=false
keep=false
preferences_pending=false
domain=com.sichgeis.babbelstream
configuration_keys=(provider.baseURL provider.transcriptionEndpointPath provider.cleanupEndpointPath provider.transcriptionModel provider.transcriptionModelRouting provider.cleanupModel provider.transcriptionModelPickerMigrationVersion provider.personalOpenAIFallback.enabled provider.personalOpenAIFallback.directModeEnabled provider.apiKey.saved.approvedOrigin)
restore_provider_preferences() {
  local key expected actual
  defaults import "$domain" "$workspace/preferences-before.plist" >/dev/null 2>&1 || return 1
  # defaults import MERGES a dictionary. Remove only our own newly added keys;
  # never clear a whole domain or erase unrelated preferences.
  for key in "${configuration_keys[@]}"; do
    if ! /usr/libexec/PlistBuddy -c "Print :$key" "$workspace/preferences-before.plist" >/dev/null 2>&1; then
      if defaults read "$domain" "$key" >/dev/null 2>&1; then
        defaults delete "$domain" "$key" >/dev/null 2>&1 || return 1
      fi
    fi
  done
  defaults export "$domain" "$workspace/preferences-restored.plist" >/dev/null 2>&1 || return 1
  for key in "${configuration_keys[@]}"; do
    if expected="$(/usr/libexec/PlistBuddy -c "Print :$key" "$workspace/preferences-before.plist" 2>/dev/null)"; then
      actual="$(/usr/libexec/PlistBuddy -c "Print :$key" "$workspace/preferences-restored.plist" 2>/dev/null)" || return 1
      [[ "$actual" == "$expected" ]] || return 1
    elif /usr/libexec/PlistBuddy -c "Print :$key" "$workspace/preferences-restored.plist" >/dev/null 2>&1; then
      return 1
    fi
  done
}
cleanup() {
  local result=$?
  trap - EXIT
  if $preferences_pending; then
    if ! restore_provider_preferences; then
      echo 'Could not restore prior settings. Keep the private temporary folder for recovery and contact support:' >&2
      printf '%s\n' "$workspace" >&2
      keep=true
      # A retained recovery snapshot must not keep a failed installer mounted.
      if $mounted; then hdiutil detach "$mount_dir" >/dev/null 2>&1 || true; fi
      exit 1
    fi
  fi
  if $mounted && ! $keep; then
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
if $already_current; then
  app="$installed"
elif $download; then
  echo "Downloading BabbelStream $VERSION from GitHub Releases. No provider or personal data is sent."
  curl --fail --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --connect-timeout 20 --max-time 600 --output "$workspace/release.dmg" "$RELEASE_URL" \
    || fail 'Download failed. No installation or quarantine change performed.'
else
  cp "$image_path" "$workspace/release.dmg"
fi
if ! $already_current; then
actual_hash="$(shasum -a 256 "$workspace/release.dmg")"
[[ "${actual_hash%% *}" == "$SHA256" ]] || fail 'Checksum mismatch. Nothing was prepared; download the pinned release again.'
hdiutil verify "$workspace/release.dmg" >/dev/null 2>&1 || fail 'DMG integrity verification failed.'
mkdir "$mount_dir"
# Mark before attaching so interruption during attach still attempts cleanup.
mounted=true
hdiutil attach -readonly -nobrowse -mountpoint "$mount_dir" "$workspace/release.dmg" >/dev/null 2>&1 || fail 'Could not mount the verified image.'
app="$mount_dir/BabbelStream.app"
fi

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
NOTICE
if ! $already_current; then
cat <<'INSTALL_NOTICE'
This helper will open a private writable view of the verified installer and
remove ONLY com.apple.quarantine from its app copy and contents. This bypasses
the quarantine-based first-open check; it does not make the app Apple-verified.
INSTALL_NOTICE
else
  echo 'The installed app is current: only the confirmed provider settings will change; no download or quarantine change.'
fi
cat <<'NOTICE'
Continue only if your device policy permits this installation. Company endpoint
controls may still block it. If they do, contact IT; do not attempt more bypasses.
The downloaded DMG, global security settings, permissions, Keychain and dictation
data will remain unchanged. No app will be installed or launched automatically.
NOTICE
if $configure; then
  printf '\nProvider settings to save (replacing these fields if already configured):\n  URL: %s\n  Routing: %s\n  Transcription: %s\n  Cleanup: %s\n' "$provider_url" "$routing" "$transcription_model" "$cleanup_model"
  echo 'Paths: /v1/audio/transcriptions and /v1/chat/completions.'
  echo 'Personal OpenAI fallback and direct-personal mode: OFF.'
  echo 'Existing keys are not read or deleted. Enter your own approved key in the app and Apply Settings before use.'
fi
printf '\nType PREPARE to consent (any letter case), or press Return to cancel: '
IFS= read -r consent || exit 0
[[ "$consent" == [Pp][Rr][Ee][Pp][Aa][Rr][Ee] ]] || { echo 'Cancelled. Nothing prepared.'; exit 0; }

configure_provider() {
  $configure || return 0
  if pgrep -x BabbelStream >/dev/null; then fail 'Quit BabbelStream before configuring; no settings changed.'; fi
  local before="$workspace/preferences-before.plist" after="$workspace/preferences-after.plist" domains
  if ! defaults export "$domain" "$before" >/dev/null 2>&1; then
    domains="$(defaults domains)" || fail 'Could not inspect preference domains.'
    if printf '%s\n' "$domains" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -Fxq "$domain"; then
      fail 'Existing settings could not be read; nothing changed.'
    fi
    plutil -create xml1 "$before"
  fi
  cp "$before" "$after"
  local keys=("${configuration_keys[@]}")
  local types=(string string string string string string integer bool bool string)
  local values=("$provider_url" /v1/audio/transcriptions /v1/chat/completions "$transcription_model" "$routing" "$cleanup_model" 1 false false unassociated)
  local i key expected actual
  for (( i=0; i<${#keys[@]}; i++ )); do
    key="${keys[$i]}"
    /usr/libexec/PlistBuddy -c "Delete :$key" "$after" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c "Add :$key ${types[$i]} ${values[$i]}" "$after" >/dev/null || fail 'Could not prepare provider settings; nothing changed.'
  done
  # The backup and merge are private, temporary, and contain no Keychain secrets.
  # Do not bind an existing key to a new destination, including legacy stores.
  if pgrep -x BabbelStream >/dev/null; then fail 'The app started during preparation; settings were not changed.'; fi
  preferences_pending=true
  defaults import "$domain" "$after" >/dev/null 2>&1 || fail 'Could not save provider settings; restoring the previous settings.'
  for (( i=0; i<${#keys[@]}; i++ )); do
    actual="$(defaults read "$domain" "${keys[$i]}")" || fail 'Could not verify saved settings; restoring the previous settings.'
    expected="${values[$i]}"; [[ "${types[$i]}" != bool ]] || expected=0
    [[ "$actual" == "$expected" ]] || fail 'Saved settings differ; restoring the previous settings.'
  done
  preferences_pending=false
  rm -f "$before" "$after"
  echo 'Provider settings saved. Open the app, enter your personal API key and choose Apply Settings.'
}
if $already_current; then configure_provider; exit 0; fi

# A private shadow keeps the release DMG bytes intact while allowing the app's
# quarantine attribute to change. The original Finder artwork/layout and the
# Applications shortcut remain exactly where the released image put them.
hdiutil detach "$mount_dir" >/dev/null 2>&1 || fail 'Could not eject the verification image.'
# Keep cleanup armed while the new attach is in flight.
hdiutil attach -shadow "$workspace/install.shadow" -nobrowse -noautoopen \
  -mountpoint "$mount_dir" "$workspace/release.dmg" >/dev/null 2>&1 \
  || fail 'Could not open a private writable installer view.'
prepared="$mount_dir/BabbelStream.app"
verify_app "$prepared"
[[ -L "$mount_dir/Applications" && "$(readlink "$mount_dir/Applications")" == /Applications ]] \
  || fail 'Installer Applications shortcut is missing or unexpected.'
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
configure_provider
rm -f "$workspace/entitlements.plist"
# Finder needs the mounted installer after the helper exits. Keep its private
# backing image/shadow until the user ejects it and discards the temporary folder.
keep=true
printf '\nInstaller window: %s\nTemporary installer files: %s\n' "$mount_dir" "$workspace"
cat <<'NEXT'
In Finder, preserve your previous app as a rollback copy before replacing it.
In the installer window, drag BabbelStream onto the Applications folder.
Finder handles any authorization prompt. The app is not installed automatically.
Then launch the Applications copy yourself and check its version in Diagnostics.
If launch is blocked, contact IT. Microphone and Accessibility require normal consent.
After copying, eject the installer window with Command-E, then move the
temporary installer folder printed above to Trash.
Temporary folders may also be removed by macOS; rerun the helper if needed.
NEXT
open "$mount_dir" || echo 'Could not open the installer window. Open the printed location in Finder.' >&2
