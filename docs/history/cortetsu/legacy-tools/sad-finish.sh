#!/usr/bin/env bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro del clon de Cortetsu" >&2; exit 1; }
LIVE="/etc/xdg/quickshell/caelestia"
python3 "$REPO/scripts/features/validate-sad.py"
if [[ -f "$LIVE/modules/DisplayController.qml" ]]; then
    bash "$REPO/scripts/features/update-sad.sh"
else
    bash "$REPO/scripts/features/install-sad.sh"
fi
python3 "$REPO/scripts/features/validate-sad.py"
python3 "$REPO/scripts/features/diagnose-sad.py"
echo "SAD complete: Hardware/Display retained; Gaming/Updater absent."
