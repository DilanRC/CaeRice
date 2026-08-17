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
VALIDATOR="$REPO/scripts/features/validate-hardware-center.py"

[[ -f "$LIVE/modules/HardwareController.qml" ]] || {
    echo "ERROR: Hardware Center todavía no está integrado. Ejecuta scripts/features/install-hardware-center.sh primero." >&2
    exit 2
}

for file in "$PROBE_SRC" "$POWER_SRC" "$AUTO_SRC" "$AUTO_CTL_SRC" "$UNIT_SRC" "$VALIDATOR"; do
    [[ -f "$file" ]] || { echo "ERROR: falta $file" >&2; exit 3; }
done

printf '==> repository validation\n'
python3 "$VALIDATOR"

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

printf '==> installed helper validation\n'
"$PROBE_DST" | python3 -m json.tool >/dev/null
sleep 0.2
"$PROBE_DST" | python3 -m json.tool >/dev/null
"$POWER_DST" | python3 -m json.tool >/dev/null
"$AUTO_CTL_DST" status | python3 -m json.tool >/dev/null

printf '==> restart Caelestia\n'
pkill -TERM -x qs 2>/dev/null || true
sleep 1
caelestia shell -d

echo
echo "Hardware Center actualizado y validado. Prueba Super+H."
echo "Pages: 1 Overview · 2 Performance · 3 Processes · 4 Sensors · 5 I/O · 6 Power · 7 Auto · 8 Energy"
echo "Power automation: preserva tu elección; nunca se activa sola."
