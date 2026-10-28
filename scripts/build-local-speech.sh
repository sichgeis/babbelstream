#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$(uname -m)" != arm64 ]]; then echo "Local speech is Apple Silicon only; remote build is unchanged."; exit 0; fi
LOCAL_CONFIGURATION="${CONFIGURATION:-release}"
# Deliberate opt-in for the deferred full runtime. Never silently advertise MLX
# models when their helper could not be built.
if [[ "${BABBELSTREAM_MLX:-0}" == 1 ]]; then
  xcrun --find metal >/dev/null 2>&1 || { echo 'Full local speech requires Xcode with the Metal toolchain.' >&2; exit 1; }
fi
"$ROOT_DIR/scripts/swift-project.sh" build --package-path "$ROOT_DIR/NativeSpeech" -c "$LOCAL_CONFIGURATION" --product BabbelStreamLocalSpeech
