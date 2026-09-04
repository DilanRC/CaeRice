#!/usr/bin/env bash
set -euo pipefail

BASE="$HOME/.local/share/cortetsu/upstream"
LIVE="/etc/xdg/quickshell/caelestia"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BASE/reinstall-backups/bottomhub-$STAMP"

mkdir -p "$BACKUP"

echo "==> BACKUP"
for rel in modules/utilities/Wrapper.qml modules/drawers/Regions.qml modules/drawers/Panels.qml modules/drawers/ContentWindow.qml modules/BottomHub.qml modules/HubButton.qml; do
    mkdir -p "$BACKUP/$(dirname "$rel")"
    sudo cp "$LIVE/$rel" "$BACKUP/$rel"
    sudo chown "$USER":"$(id -gn)" "$BACKUP/$rel"
    echo "backed up: $rel"
done

echo
echo "==> DRY-RUN (nada se toca todavia)"
for p in modules__utilities__Wrapper.qml.patch modules__drawers__Regions.qml.patch modules__drawers__Panels.qml.patch modules__drawers__ContentWindow.qml.patch; do
    echo "-- $p --"
    sudo patch --dry-run -p1 -d "$LIVE" < "$BASE/patches/$p"
done

echo
echo "==> APLICANDO PATCHES"
for p in modules__utilities__Wrapper.qml.patch modules__drawers__Regions.qml.patch modules__drawers__Panels.qml.patch modules__drawers__ContentWindow.qml.patch; do
    sudo patch -p1 -d "$LIVE" < "$BASE/patches/$p"
    echo "applied: $p"
done

echo
echo "==> MODULOS PROPIOS"
sudo install -m 0644 "$BASE/modules-owned/modules/BottomHub.qml" "$LIVE/modules/BottomHub.qml"
sudo install -m 0644 "$BASE/modules-owned/modules/HubButton.qml" "$LIVE/modules/HubButton.qml"
echo "installed: BottomHub.qml, HubButton.qml"

echo
echo "Backup: $BACKUP"
echo
echo "Ahora reload:"
echo "  hyprctl reload"
echo "  pkill -f 'qs -c caelestia'"
echo "  sleep 1"
echo "  caelestia shell -d"
