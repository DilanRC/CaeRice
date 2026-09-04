#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/cortetsu/upstream"
LIVE="/etc/xdg/quickshell/caelestia"
STAMP="$(date +%Y%m%d-%H%M%S)"
PRE="$BASE/snapshots/before-sync-$STAMP"

if [[ ! -d "$BASE/files" ]]; then
    echo "No existe $BASE/files. Ejecuta bootstrap.sh primero." >&2
    exit 1
fi

mkdir -p "$PRE"
cp -a "$BASE/files/." "$PRE/"

SYSTEM_FILES=(
  "shell.qml"
  "components/ScreenState.qml"
  "services/Hypr.qml"
  "utils/NetworkConnection.qml"
  "modules/Shortcuts.qml"
  "modules/BottomHub.qml"
  "modules/HubButton.qml"
  "modules/OverviewController.qml"
  "modules/overview/Wrapper.qml"
  "modules/overview/Content.qml"
  "modules/overview/WindowCard.qml"
  "modules/sidebar/Wrapper.qml"
  "modules/launcher/AppList.qml"
  "modules/launcher/Content.qml"
  "modules/launcher/ContentList.qml"
  "modules/launcher/Wrapper.qml"
  "modules/drawers/Regions.qml"
  "modules/drawers/Panels.qml"
  "modules/drawers/ContentWindow.qml"
)

for rel in "${SYSTEM_FILES[@]}"; do
    src="$LIVE/$rel"
    dst="$BASE/files/etc/xdg/quickshell/caelestia/$rel"
    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        sudo cp "$src" "$dst"
        sudo chown "$USER":"$(id -gn)" "$dst"
        echo "sync: $rel"
    fi
done

if [[ -f "$HOME/.config/caelestia/hypr-user.lua" ]]; then
    cp "$HOME/.config/caelestia/hypr-user.lua" \
       "$BASE/files/home/.config/caelestia/hypr-user.lua"
fi

if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    cp "$HOME/.config/hypr/hyprland.lua" \
       "$BASE/files/home/.config/hypr/hyprland.lua"
fi

(
    cd "$BASE/files"
    find . -type f -print0 | sort -z | xargs -0 sha256sum
) > "$BASE/MANIFEST.sha256"

echo
echo "Fuente actualizada."
echo "Snapshot previo: $PRE"
