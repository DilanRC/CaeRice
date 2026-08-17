#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de CaeRice" >&2; exit 1; }

echo "==> Display Manager"
bash "$REPO/scripts/features/install-display-manager.sh"
mkdir -p "$HOME/.local/bin"
for helper in caerice-display-presets caerice-display-workspaces; do
    install -m 0755 "$REPO/caelestia/bin/$helper" "$HOME/.local/bin/$helper"
done

echo "==> Remove retired Gaming/Updater remnants + synchronize"
bash "$REPO/scripts/features/update-sad.sh"

echo "==> Consolidated validation"
python3 "$REPO/scripts/features/validate-sad.py"

echo
echo "SAD feature set installed:"
echo "  Super+H       Hardware Center"
echo "  Super+Shift+O Display Manager"
echo "  Gaming Center: removed"
echo "  CaeRice Updater: removed"
