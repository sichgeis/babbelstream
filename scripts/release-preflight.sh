#!/usr/bin/env bash
# Shared by bundle and DMG packaging; no key/identity lookup or system changes.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_MODE="${BUILD_MODE:-development}"
VERSION="${VERSION:-$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")}"
BUILD_NUMBER="${BUILD_NUMBER:-$(tr -d '[:space:]' < "$ROOT_DIR/BUILD_NUMBER")}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
preflight_fail() { echo "Release preflight: $1" >&2; exit 1; }

case "$BUILD_MODE" in
  development) CONFIGURATION="${CONFIGURATION:-debug}" ;;
  candidate|distribution)
    CONFIGURATION="${CONFIGURATION:-release}"
    [[ "$CONFIGURATION" == release ]] || preflight_fail "candidate/distribution requires CONFIGURATION=release."
    ;;
  *) preflight_fail "BUILD_MODE must be development, candidate or distribution." ;;
esac
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || preflight_fail "VERSION must be numeric MAJOR.MINOR.PATCH."
[[ "$BUILD_NUMBER" =~ ^[1-9][0-9]{0,3}$ ]] || preflight_fail "BUILD_NUMBER must be an increasing integer from 1 to 9999."

if [[ "$BUILD_MODE" == distribution ]]; then
  [[ "$CODESIGN_IDENTITY" == "Developer ID Application: "* ]] || preflight_fail "distribution requires an explicit Developer ID Application identity; no ad-hoc/local fallback."
fi
if [[ "$BUILD_MODE" != development ]]; then
  [[ "$VERSION" == "$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")" ]] || preflight_fail "VERSION override must match the committed source."
  [[ "$BUILD_NUMBER" == "$(tr -d '[:space:]' < "$ROOT_DIR/BUILD_NUMBER")" ]] || preflight_fail "BUILD_NUMBER override must match the committed source."
  [[ -z "$(git -C "$ROOT_DIR" status --porcelain --untracked-files=normal)" ]] || preflight_fail "candidate/distribution requires a clean commit, including untracked files."
  EXPECTED_GIT_COMMIT="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
  [[ -z "${GIT_COMMIT:-}" || "$GIT_COMMIT" == "$EXPECTED_GIT_COMMIT" ]] || preflight_fail "GIT_COMMIT override must match HEAD."
  GIT_COMMIT="$EXPECTED_GIT_COMMIT"
  LATEST_RELEASE_TAG="$(git -C "$ROOT_DIR" describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)"
  if [[ -n "$LATEST_RELEASE_TAG" ]]; then
    PRIOR_BUILD="$(git -C "$ROOT_DIR" show "$LATEST_RELEASE_TAG:BUILD_NUMBER" 2>/dev/null || printf '1')"
    [[ "$PRIOR_BUILD" =~ ^[1-9][0-9]{0,3}$ ]] || preflight_fail "the previous release has an invalid build number."
    RELEASE_COMMIT="$(git -C "$ROOT_DIR" rev-parse "$LATEST_RELEASE_TAG^{commit}")"
    CURRENT_COMMIT="$(git -C "$ROOT_DIR" rev-parse HEAD)"
    if [[ "$LATEST_RELEASE_TAG" == "v$VERSION" && "$CURRENT_COMMIT" == "$RELEASE_COMMIT" && "$BUILD_NUMBER" == "$PRIOR_BUILD" ]]; then
      : # Reproduce the exact clean tagged artifact without inventing a new iteration.
    else
      (( BUILD_NUMBER > PRIOR_BUILD )) || preflight_fail "increment BUILD_NUMBER beyond $LATEST_RELEASE_TAG before preparing the next candidate."
    fi
  fi
  if [[ "$BUILD_MODE" == candidate && -z "$CODESIGN_IDENTITY" ]]; then
    CODESIGN_IDENTITY="-" # No implicit private signing-material lookup for candidates.
  fi
fi
export BUILD_MODE CONFIGURATION VERSION BUILD_NUMBER CODESIGN_IDENTITY
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'Preflight passed: %s, %s, version %s, build %s\n' "$BUILD_MODE" "$CONFIGURATION" "$VERSION" "$BUILD_NUMBER"
fi
