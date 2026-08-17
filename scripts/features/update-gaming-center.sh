#!/usr/bin/env bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"; [[ -n "$REPO" ]] || exit 1
LIVE="/etc/xdg/quickshell/caelestia"; SRC="$REPO/caelestia/modules-owned/modules"
[[ -f "$LIVE/modules/GamingController.qml" ]] || { echo "ERROR: instala Gaming Center primero" >&2; exit 2; }
python3 "$REPO/scripts/features/validate-gaming-center.py"
sudo install -m 0644 "$SRC/GamingController.qml" "$LIVE/modules/GamingController.qml"; sudo mkdir -p "$LIVE/modules/gaming"; for qml in "$SRC/gaming/"*.qml; do sudo install -m 0644 "$qml" "$LIVE/modules/gaming/$(basename "$qml")"; done
mkdir -p "$HOME/.local/bin"; install -m 0755 "$REPO/caelestia/bin/caerice-gaming-probe" "$HOME/.local/bin/caerice-gaming-probe"; install -m 0755 "$REPO/caelestia/bin/caerice-gaming-profile" "$HOME/.local/bin/caerice-gaming-profile"
pkill -TERM -x qs 2>/dev/null || true; sleep 1; caelestia shell -d
echo "Gaming Center actualizado."
