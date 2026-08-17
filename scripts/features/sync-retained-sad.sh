#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de CaeRice" >&2; exit 1; }
LIVE="/etc/xdg/quickshell/caelestia"

python3 "$REPO/scripts/features/validate-sad.py"
bash "$REPO/scripts/features/apply-canonical-sad-wiring.sh"

# Synchronize retained Display Manager QML and helpers.
sudo install -m 0644 "$REPO/caelestia/modules-owned/modules/DisplayController.qml" "$LIVE/modules/DisplayController.qml"
sudo mkdir -p "$LIVE/modules/display"
for qml in "$REPO/caelestia/modules-owned/modules/display/"*.qml; do
    sudo install -m 0644 "$qml" "$LIVE/modules/display/$(basename "$qml")"
done
mkdir -p "$HOME/.local/bin"
for helper in caerice-display-probe caerice-display-plan caerice-display-transaction caerice-display-persist caerice-display-presets caerice-display-workspaces; do
    install -m 0755 "$REPO/caelestia/bin/$helper" "$HOME/.local/bin/$helper"
done

bash "$REPO/scripts/features/purge-retired-centers.sh"
hyprctl reload >/dev/null
pkill -TERM -x qs 2>/dev/null || true
sleep 1
caelestia shell -d
sleep 1

if ! python3 "$REPO/scripts/features/diagnose-sad.py"; then
    echo "SAD synchronization finished, but live diagnostics failed." >&2
    exit 1
fi

echo "SAD synchronized: Hardware/Display retained; Gaming/Updater removed."
