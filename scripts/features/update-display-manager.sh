#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de CaeRice" >&2; exit 1; }
LIVE="/etc/xdg/quickshell/caelestia"
SRC="$REPO/caelestia/modules-owned/modules"

[[ -f "$LIVE/modules/DisplayController.qml" ]] || {
    echo "ERROR: Display Manager no está integrado. Ejecuta scripts/features/install-display-manager.sh primero." >&2
    exit 2
}

python3 "$REPO/scripts/features/validate-display-manager.py"

sudo install -m 0644 "$SRC/DisplayController.qml" "$LIVE/modules/DisplayController.qml"
sudo mkdir -p "$LIVE/modules/display"
for qml in "$SRC/display/"*.qml; do
    sudo install -m 0644 "$qml" "$LIVE/modules/display/$(basename "$qml")"
done
mkdir -p "$HOME/.local/bin"
install -m 0755 "$REPO/caelestia/bin/caerice-display-probe" "$HOME/.local/bin/caerice-display-probe"
install -m 0755 "$REPO/caelestia/bin/caerice-display-plan" "$HOME/.local/bin/caerice-display-plan"

pkill -TERM -x qs 2>/dev/null || true
sleep 1
caelestia shell -d

echo
echo "Display Manager actualizado. Prueba Super+Shift+O."
