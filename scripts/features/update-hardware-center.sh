#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de CaeRice" >&2; exit 1; }

LIVE="/etc/xdg/quickshell/caelestia"
SRC="$REPO/caelestia/modules-owned/modules"
PROBE_SRC="$REPO/caelestia/bin/caerice-hardware-probe"
PROBE_DST="$HOME/.local/bin/caerice-hardware-probe"

[[ -f "$LIVE/modules/HardwareController.qml" ]] || {
    echo "ERROR: Hardware Center todavía no está integrado. Ejecuta scripts/features/install-hardware-center.sh primero." >&2
    exit 2
}

printf '==> probe preflight\n'
python3 "$PROBE_SRC" | python3 -m json.tool >/dev/null
sleep 0.2
python3 "$PROBE_SRC" | python3 -m json.tool >/dev/null

printf '==> QML live sync\n'
sudo install -m 0644 "$SRC/HardwareController.qml" "$LIVE/modules/HardwareController.qml"
sudo mkdir -p "$LIVE/modules/hardware"
for qml in "$SRC/hardware/"*.qml; do
    sudo install -m 0644 "$qml" "$LIVE/modules/hardware/$(basename "$qml")"
done

mkdir -p "$HOME/.local/bin"
install -m 0755 "$PROBE_SRC" "$PROBE_DST"

printf '==> restart Caelestia\n'
pkill -TERM -x qs 2>/dev/null || true
sleep 1
caelestia shell -d

echo
echo "Hardware Center actualizado. Prueba Super+H."
