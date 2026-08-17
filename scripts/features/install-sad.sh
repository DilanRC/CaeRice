#!/usr/bin/env bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"; [[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de CaeRice" >&2; exit 1; }

echo "==> Display Manager"
bash "$REPO/scripts/features/install-display-manager.sh"
mkdir -p "$HOME/.local/bin"
for helper in caerice-display-presets caerice-display-workspaces; do install -m 0755 "$REPO/caelestia/bin/$helper" "$HOME/.local/bin/$helper"; done
# install-display-manager copies every display/*.qml, including DisplayPresets/DisplayCapabilities.

echo "==> Gaming Center"
bash "$REPO/scripts/features/install-gaming-center.sh"

echo "==> CaeRice Updater"
bash "$REPO/scripts/features/install-caerice-updater.sh"

echo "==> Consolidated validation"
python3 "$REPO/scripts/features/validate-sad.py"

pkill -TERM -x qs 2>/dev/null || true
sleep 1
caelestia shell -d

echo
echo "SAD feature set installed:"
echo "  Super+H       Hardware Center"
echo "  Super+Shift+O Display Manager"
echo "  Super+Shift+G Gaming Center"
echo "  Super+Shift+U CaeRice Updater"
