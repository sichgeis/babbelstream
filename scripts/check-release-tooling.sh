#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/babbelstream-release-checks.XXXXXX")"
trap 'rm -rf "$FIXTURE_DIR"' EXIT
FIXTURE_LOG="$FIXTURE_DIR/.git/release-check.log"
mkdir -p "$FIXTURE_DIR/scripts"
cp "$ROOT_DIR/scripts/release-preflight.sh" "$FIXTURE_DIR/scripts/"
printf '0.4.6\n' > "$FIXTURE_DIR/VERSION"
printf '2\n' > "$FIXTURE_DIR/BUILD_NUMBER"
git -C "$FIXTURE_DIR" init -q
git -C "$FIXTURE_DIR" add .
git -C "$FIXTURE_DIR" -c user.name=Fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm fixture
git -C "$FIXTURE_DIR" -c tag.gpgsign=false tag v0.4.6
# Rebuilding an exact clean release tag must stay possible with the same build number.
env -u VERSION -u BUILD_NUMBER -u CONFIGURATION -u CODESIGN_IDENTITY -u GIT_COMMIT BUILD_MODE=candidate "$FIXTURE_DIR/scripts/release-preflight.sh" > /dev/null
printf '3\n' > "$FIXTURE_DIR/BUILD_NUMBER"
git -C "$FIXTURE_DIR" add BUILD_NUMBER
git -C "$FIXTURE_DIR" -c user.name=Fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm next-build

expect_failure() {
  local expected="$1"
  shift
  if env -u SDKROOT -u VERSION -u BUILD_NUMBER -u CONFIGURATION -u CODESIGN_IDENTITY -u GIT_COMMIT -u BUILD_MODE "$@" "$FIXTURE_DIR/scripts/release-preflight.sh" > "$FIXTURE_LOG" 2>&1; then
    echo "Expected preflight rejection: $expected" >&2; exit 1
  fi
  [[ "$(cat "$FIXTURE_LOG")" == *"$expected"* ]] || { cat "$FIXTURE_LOG"; exit 1; }
}
expect_failure 'no ad-hoc/local fallback' BUILD_MODE=distribution CODESIGN_IDENTITY=-
expect_failure 'no ad-hoc/local fallback' BUILD_MODE=distribution
expect_failure 'requires CONFIGURATION=release' BUILD_MODE=candidate CONFIGURATION=debug
expect_failure 'VERSION override must match' BUILD_MODE=candidate VERSION=9.9.9
expect_failure 'GIT_COMMIT override must match' BUILD_MODE=candidate GIT_COMMIT=unrelated
expect_failure 'must be an increasing integer' BUILD_NUMBER=0
expect_failure 'BUILD_MODE must be' BUILD_MODE=unknown

env -u VERSION -u BUILD_NUMBER -u CONFIGURATION -u CODESIGN_IDENTITY -u GIT_COMMIT BUILD_MODE=candidate "$FIXTURE_DIR/scripts/release-preflight.sh" > /dev/null
printf 'untracked fixture\n' > "$FIXTURE_DIR/untracked.txt"
expect_failure 'requires a clean commit' BUILD_MODE=candidate
rm "$FIXTURE_DIR/untracked.txt"
printf '2\n' > "$FIXTURE_DIR/BUILD_NUMBER"
git -C "$FIXTURE_DIR" add BUILD_NUMBER
git -C "$FIXTURE_DIR" -c user.name=Fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm invalid-build
expect_failure 'increment BUILD_NUMBER' BUILD_MODE=candidate

# Exercise signature acceptance/rejection using fixture output, never a private identity.
mkdir -p "$FIXTURE_DIR/bin"
cat > "$FIXTURE_DIR/bin/codesign" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  *--verify*) exit 0 ;;
  *--entitlements*)
    [[ "$*" == *--xml* ]] || { echo '[Dict] not XML'; exit 0; }
    cat "$FIXTURE_ENTITLEMENTS" ;;
  *) printf '%s\n' "$FIXTURE_SIGNATURE" >&2 ;;
esac
MOCK
chmod +x "$FIXTURE_DIR/bin/codesign"
printf '%s\n' '<?xml version="1.0"?><plist version="1.0"><dict><key>com.apple.security.device.audio-input</key><true/></dict></plist>' > "$FIXTURE_DIR/audio.plist"
printf '%s\n' '<?xml version="1.0"?><plist version="1.0"><dict><key>com.apple.security.device.audio-input</key><false/></dict></plist>' > "$FIXTURE_DIR/no-audio.plist"
printf '%s\n' '<?xml version="1.0"?><plist version="1.0"><dict><key>com.apple.security.device.audio-input</key><true/><key>com.apple.security.get-task-allow</key><true/></dict></plist>' > "$FIXTURE_DIR/debug.plist"
verify_fixture() {
  local signature="$1" entitlement="$2" mode="$3"
  env PATH="$FIXTURE_DIR/bin:$PATH" FIXTURE_SIGNATURE="$signature" FIXTURE_ENTITLEMENTS="$FIXTURE_DIR/$entitlement" "$ROOT_DIR/scripts/verify-app.sh" "$FIXTURE_DIR/NoApp.app" "$mode" > "$FIXTURE_LOG" 2>&1
}
verify_fixture 'CodeDirectory flags=0x10002(adhoc,runtime)' audio.plist candidate
verify_fixture $'CodeDirectory flags=0x10000(runtime)\nAuthority=Developer ID Application: Fixture\nTimestamp=fixture' audio.plist distribution
for output in 'CodeDirectory flags=0x2(adhoc)' $'CodeDirectory flags=0x10000(runtime)\nAuthority=Developer ID Application: Fixture' ; do
  if verify_fixture "$output" audio.plist distribution; then echo 'Invalid distribution signature accepted.' >&2; exit 1; fi
done
if verify_fixture 'CodeDirectory flags=0x10002(adhoc,runtime)' no-audio.plist candidate; then echo 'Missing audio entitlement accepted.' >&2; exit 1; fi
if verify_fixture 'CodeDirectory flags=0x10002(adhoc,runtime)' debug.plist candidate; then echo 'Debug task entitlement accepted.' >&2; exit 1; fi
if verify_fixture 'CodeDirectory flags=0x2(adhoc)' audio.plist candidate; then echo 'Missing runtime accepted.' >&2; exit 1; fi

echo "Release preflight fixture checks passed. No signing identity or credentials accessed."
