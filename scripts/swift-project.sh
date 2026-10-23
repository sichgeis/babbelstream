#!/usr/bin/env bash
set -euo pipefail
# Keep project SDK selection local; never change xcode-select or SDK symlinks.
# The CLT macOS 27 SDK needs SwiftUI macro plugins absent from this installation.
if [[ -z "${SDKROOT:-}" ]]; then
  SDK_NAME="${BABBELSTREAM_SDK:-macosx26.5}"
  if ! SDKROOT="$(xcrun --sdk "$SDK_NAME" --show-sdk-path 2>/dev/null)"; then
    echo "BabbelStream requires the validated macOS 26.5 SDK or an explicitly validated SDKROOT/BABBELSTREAM_SDK override. Install a matching Apple toolchain; no global settings were changed." >&2
    exit 1
  fi
  export SDKROOT
fi
exec swift "$@"
