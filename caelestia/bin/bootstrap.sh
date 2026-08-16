#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/caelestia-custom-system"
LIVE="/etc/xdg/quickshell/caelestia"
STAMP="$(date +%Y%m%d-%H%M%S)"
SNAP="$BASE/snapshots/$STAMP"

mkdir -p "$BASE/files/etc/xdg/quickshell/caelestia"
mkdir -p "$BASE/files/home/.config/caelestia"
mkdir -p "$BASE/files/home/.config/hypr"
mkdir -p "$BASE/snapshots"
mkdir -p "$BASE/audit"

SYSTEM_FILES=(
  "shell.qml"
  "components/ScreenState.qml"
  "services/Hypr.qml"
  "utils/NetworkConnection.qml"
  "modules/Shortcuts.qml"
  "modules/CustomDock.qml"
  "modules/OverviewController.qml"
  "modules/overview/Wrapper.qml"
  "modules/overview/Content.qml"
  "modules/overview/WindowCard.qml"
  "modules/launcher/AppList.qml"
  "modules/launcher/Content.qml"
  "modules/launcher/ContentList.qml"
  "modules/launcher/Wrapper.qml"
  "modules/drawers/Regions.qml"
  "modules/drawers/Panels.qml"
  "modules/drawers/ContentWindow.qml"
)

copy_live_system_file() {
    local rel="$1"
    local src="$LIVE/$rel"
    local dst="$BASE/files/etc/xdg/quickshell/caelestia/$rel"

    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        sudo cp "$src" "$dst"
        sudo chown "$USER":"$(id -gn)" "$dst"
        echo "capturado: $rel"
    else
        echo "omitido (no existe): $rel"
    fi
}

echo "==> Capturando personalización Caelestia"
for rel in "${SYSTEM_FILES[@]}"; do
    copy_live_system_file "$rel"
done

echo
echo "==> Capturando configuración Hyprland"
if [[ -f "$HOME/.config/caelestia/hypr-user.lua" ]]; then
    cp "$HOME/.config/caelestia/hypr-user.lua" \
       "$BASE/files/home/.config/caelestia/hypr-user.lua"
fi

if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    cp "$HOME/.config/hypr/hyprland.lua" \
       "$BASE/files/home/.config/hypr/hyprland.lua"
fi

echo
echo "==> Generando snapshot $STAMP"
mkdir -p "$SNAP"
cp -a "$BASE/files/." "$SNAP/"

(
    cd "$BASE/files"
    find . -type f -print0 | sort -z | xargs -0 sha256sum
) > "$BASE/MANIFEST.sha256"

cat > "$BASE/SOURCE_INFO.txt" <<EOF
captured_at=$(date --iso-8601=seconds)
hostname=$(hostname)
kernel=$(uname -r)
caelestia_package=$(pacman -Q caelestia-shell 2>/dev/null || true)
quickshell_package=$(pacman -Q quickshell 2>/dev/null || pacman -Q quickshell-git 2>/dev/null || true)
EOF

echo
echo "Sistema fuente creado en:"
echo "  $BASE"
echo
echo "Siguiente:"
echo "  bash $BASE/bin/audit.sh"
