#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de CaeRice" >&2; exit 1; }

LIVE="/etc/xdg/quickshell/caelestia"
SRC="$REPO/caelestia/modules-owned/modules"
PROBE_SRC="$REPO/caelestia/bin/caerice-hardware-probe"
PROBE_DST="$HOME/.local/bin/caerice-hardware-probe"
POWER_SRC="$REPO/caelestia/bin/caerice-hardware-power"
POWER_DST="$HOME/.local/bin/caerice-hardware-power"
AUTO_SRC="$REPO/caelestia/bin/caerice-power-auto"
AUTO_DST="$HOME/.local/bin/caerice-power-auto"
AUTO_CTL_SRC="$REPO/caelestia/bin/caerice-power-auto-control"
AUTO_CTL_DST="$HOME/.local/bin/caerice-power-auto-control"
UNIT_SRC="$REPO/config/systemd/user/caerice-power-auto.service"
UNIT_DST="$HOME/.config/systemd/user/caerice-power-auto.service"

[[ -f "$LIVE/modules/HardwareController.qml" ]] || {
    echo "ERROR: Hardware Center todavía no está integrado. Ejecuta scripts/features/install-hardware-center.sh primero." >&2
    exit 2
}

for file in "$PROBE_SRC" "$POWER_SRC" "$AUTO_SRC" "$AUTO_CTL_SRC" "$UNIT_SRC"; do
    [[ -f "$file" ]] || { echo "ERROR: falta $file" >&2; exit 3; }
done

printf '==> telemetry preflight\n'
python3 "$PROBE_SRC" | python3 -m json.tool >/dev/null
sleep 0.2
python3 "$PROBE_SRC" | python3 -m json.tool >/dev/null
python3 "$POWER_SRC" | python3 -m json.tool >/dev/null
python3 "$AUTO_CTL_SRC" status | python3 -m json.tool >/dev/null

printf '==> QML live sync\n'
sudo install -m 0644 "$SRC/HardwareController.qml" "$LIVE/modules/HardwareController.qml"
sudo mkdir -p "$LIVE/modules/hardware"
for qml in "$SRC/hardware/"*.qml; do
    sudo install -m 0644 "$qml" "$LIVE/modules/hardware/$(basename "$qml")"
done

printf '==> helper sync\n'
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"
install -m 0755 "$PROBE_SRC" "$PROBE_DST"
install -m 0755 "$POWER_SRC" "$POWER_DST"
install -m 0755 "$AUTO_SRC" "$AUTO_DST"
install -m 0755 "$AUTO_CTL_SRC" "$AUTO_CTL_DST"
install -m 0644 "$UNIT_SRC" "$UNIT_DST"
systemctl --user daemon-reload

# Preserve user choice. Updating Hardware Center never enables automation by itself.
if systemctl --user is-enabled --quiet caerice-power-auto.service 2>/dev/null; then
    systemctl --user try-restart caerice-power-auto.service >/dev/null 2>&1 || true
fi

printf '==> restart Caelestia\n'
pkill -TERM -x qs 2>/dev/null || true
sleep 1
caelestia shell -d

echo
echo "Hardware Center actualizado. Prueba Super+H."
echo "Power helper: $POWER_DST"
echo "Power automation: instalada pero NO se activa automáticamente."
echo "Config: ~/.config/caerice/power-auto.json"
