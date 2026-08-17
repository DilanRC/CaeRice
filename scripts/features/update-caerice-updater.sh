#!/usr/bin/env bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"; [[ -n "$REPO" ]] || exit 1
LIVE="/etc/xdg/quickshell/caelestia"; SRC="$REPO/caelestia/modules-owned/modules"
[[ -f "$LIVE/modules/UpdaterController.qml" ]] || { echo "ERROR: instala CaeRice Updater primero" >&2; exit 2; }
python3 "$REPO/scripts/features/validate-caerice-updater.py"
sudo install -m 0644 "$SRC/UpdaterController.qml" "$LIVE/modules/UpdaterController.qml"
sudo mkdir -p "$LIVE/modules/updater"
for qml in "$SRC/updater/"*.qml; do sudo install -m 0644 "$qml" "$LIVE/modules/updater/$(basename "$qml")"; done
mkdir -p "$HOME/.local/bin"
for helper in caerice-upstream-audit caerice-updater caerice-updater-commit-base; do install -m 0755 "$REPO/caelestia/bin/$helper" "$HOME/.local/bin/$helper"; done
pkill -TERM -x qs 2>/dev/null || true
sleep 1
caelestia shell -d
echo "CaeRice Updater actualizado."
