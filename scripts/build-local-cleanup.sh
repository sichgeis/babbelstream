#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ "$(uname -m)" == arm64 ]] || exit 0
CMAKE="${CMAKE:-cmake}"
command -v "$CMAKE" >/dev/null || { echo 'Local cleanup requires CMake 3.20 or later.' >&2; exit 1; }
REVISION=8642541b255bfb5dc39cd351a178be09013a55d6
SOURCE="$ROOT_DIR/.build/llama-cleanup-source"
if [[ ! -d "$SOURCE/.git" ]]; then
  git clone --depth 1 --no-checkout https://github.com/ggml-org/llama.cpp.git "$SOURCE"
fi
if ! git -C "$SOURCE" cat-file -e "$REVISION^{commit}" 2>/dev/null; then git -C "$SOURCE" fetch origin "$REVISION"; fi
git -C "$SOURCE" checkout --detach "$REVISION" >/dev/null
[[ -z "$(git -C "$SOURCE" status --porcelain)" ]] || { echo 'Native runtime source must be clean.' >&2; exit 1; }
"$CMAKE" -S "$ROOT_DIR/NativeCleanup" -B "$ROOT_DIR/.build/local-cleanup" \
  -DLLAMA_SOURCE="$SOURCE" -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DCMAKE_C_FLAGS="-ffile-prefix-map=$ROOT_DIR=SOURCE" \
  -DCMAKE_CXX_FLAGS="-ffile-prefix-map=$ROOT_DIR=SOURCE"
"$CMAKE" --build "$ROOT_DIR/.build/local-cleanup" --target BabbelStreamLocalCleanup -j 6
