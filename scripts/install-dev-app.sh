#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="BabbelStream"
VERSION="${VERSION:-$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")}"
CONFIGURATION="${CONFIGURATION:-debug}"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
NO_LAUNCH="${NO_LAUNCH:-0}"
RESTART_ONLY="${RESTART_ONLY:-0}"
WAIT_FOR_INSTALL="${WAIT_FOR_INSTALL:-0}"
INSTALL_WAIT_SECONDS="${INSTALL_WAIT_SECONDS:-120}"
DMG_NAME="${DMG_NAME:-$APP_NAME-$VERSION.dmg}"
DMG_PATH="$ROOT_DIR/dist/$DMG_NAME"
INSTALL_APP_DIR="$INSTALL_DIR/$APP_NAME.app"
INSTALL_EXECUTABLE="$INSTALL_APP_DIR/Contents/MacOS/$APP_NAME"
PREVIOUS_INSTALL_MTIME="0"

truthy() {
  case "${1:-}" in
    1 | true | TRUE | yes | YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

fail() {
  echo "$1" >&2
  exit 1
}

validate_install_target() {
  [[ -n "$INSTALL_DIR" ]] || fail "INSTALL_DIR must not be empty."
  [[ "$INSTALL_DIR" != "/" ]] || fail "INSTALL_DIR must not be root."
  [[ "$INSTALL_APP_DIR" == */"$APP_NAME.app" ]] || fail "Refusing unsafe install target: $INSTALL_APP_DIR"
  [[ "$INSTALL_APP_DIR" != "/" ]] || fail "Refusing to install to root."
}

running_pids_matching() {
  local pattern="$1"
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -f "$pattern" 2>/dev/null || true
    return 0
  fi

  ps -axo pid=,command= 2>/dev/null \
    | awk -v pattern="$pattern" '
        index($0, pattern) > 0 &&
        index($0, "awk") == 0 &&
        index($0, "pgrep") == 0 &&
        index($0, "ps -axo") == 0 {
          print $1
        }
      ' \
    || true
}

running_app_pids() {
  running_pids_matching "/$APP_NAME.app/Contents/MacOS/$APP_NAME"
}

wait_until_stopped() {
  local attempt
  for attempt in {1..20}; do
    if [[ -z "$(running_app_pids)" ]]; then
      return 0
    fi
    sleep 0.25
  done
  return 1
}

quit_running_app() {
  local pids
  pids="$(running_app_pids)"
  if [[ -z "$pids" ]]; then
    return 0
  fi

  echo "Stopping running $APP_NAME instance(s): $pids"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "tell application id \"com.sichgeis.babbelstream\" to quit" >/dev/null 2>&1 || true
  fi

  if ! wait_until_stopped; then
    pids="$(running_app_pids)"
    if [[ -n "$pids" ]]; then
      kill $pids >/dev/null 2>&1 || true
      wait_until_stopped || fail "Could not stop running $APP_NAME process(es): $(running_app_pids)"
    fi
  fi
}

launch_installed_app() {
  if truthy "$NO_LAUNCH"; then
    echo "Launch skipped because NO_LAUNCH=1."
    return 0
  fi

  [[ -x "$INSTALL_EXECUTABLE" ]] || fail "Installed executable is missing or not executable: $INSTALL_EXECUTABLE"

  open "$INSTALL_APP_DIR"

  local attempt
  for attempt in {1..20}; do
    if [[ -n "$(running_pids_matching "$INSTALL_EXECUTABLE")" ]]; then
      echo "Running $INSTALL_EXECUTABLE"
      return 0
    fi
    sleep 0.25
  done

  fail "$APP_NAME did not appear to start from $INSTALL_EXECUTABLE"
}

open_drag_install_dmg() {
  [[ -f "$DMG_PATH" ]] || fail "Expected DMG not found: $DMG_PATH"
  open "$DMG_PATH"
  cat <<MESSAGE

Opened $DMG_PATH

Drag $APP_NAME.app onto the Applications link in the Finder window.
If Finder asks to replace an existing app, choose Replace.
If macOS asks for administrator authorization, approve it in Finder.

After copying, run:
  RESTART_ONLY=1 scripts/install-dev-app.sh
MESSAGE
}

install_marker_mtime() {
  if [[ -e "$INSTALL_APP_DIR" ]]; then
    stat -f %m "$INSTALL_APP_DIR" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

wait_for_manual_install() {
  local elapsed=0
  echo "Waiting up to $INSTALL_WAIT_SECONDS seconds for $INSTALL_APP_DIR..."
  while (( elapsed < INSTALL_WAIT_SECONDS )); do
    if [[ -x "$INSTALL_EXECUTABLE" ]] && [[ "$(install_marker_mtime)" != "$PREVIOUS_INSTALL_MTIME" ]]; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done

  fail "Timed out waiting for $INSTALL_APP_DIR. Drag the app manually, then run RESTART_ONLY=1 scripts/install-dev-app.sh."
}

cd "$ROOT_DIR"
validate_install_target

if truthy "$RESTART_ONLY"; then
  [[ -d "$INSTALL_APP_DIR" ]] || fail "Cannot restart; installed app not found: $INSTALL_APP_DIR"
  echo "Restart-only mode: skipping build and DMG packaging."
  quit_running_app
  launch_installed_app
  exit 0
fi

CONFIGURATION="$CONFIGURATION" VERSION="$VERSION" DMG_NAME="$DMG_NAME" scripts/package-dmg.sh
PREVIOUS_INSTALL_MTIME="$(install_marker_mtime)"
quit_running_app
open_drag_install_dmg

if truthy "$WAIT_FOR_INSTALL"; then
  wait_for_manual_install
  quit_running_app
  launch_installed_app
fi
