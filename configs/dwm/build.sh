#!/usr/bin/env bash
# ================================================================
#  dwm build helper
#  Clones suckless dwm, applies config.h, compiles, installs.
#  Run as root (or with sudo) after install_dwm() installs deps.
# ================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/dwm-build-$$"

echo "[INFO] Cloning dwm from suckless.org..."
git clone --depth=1 https://git.suckless.org/dwm "$BUILD_DIR"

echo "[INFO] Applying config.h..."
cp "$SCRIPT_DIR/config.h" "$BUILD_DIR/config.h"

echo "[INFO] Compiling dwm..."
make -C "$BUILD_DIR"

echo "[INFO] Installing dwm..."
make -C "$BUILD_DIR" install

rm -rf "$BUILD_DIR"

echo "[OK] dwm compiled and installed to /usr/local/bin/dwm"
echo "[INFO] Start dwm by adding 'exec dwm' to ~/.xinitrc or your display manager session."
