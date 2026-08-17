#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="${HOME}/.local/share/caelestia-custom-system"

if [[ ! -d /etc/xdg/quickshell/caelestia ]]; then
    echo "ERROR: no existe /etc/xdg/quickshell/caelestia" >&2
    exit 1
fi
mkdir -p "$BASE"
rm -rf "$BASE/patches" "$BASE/modules-owned"
cp -a "$REPO/caelestia/patches" "$BASE/patches"
cp -a "$REPO/caelestia/modules-owned" "$BASE/modules-owned"

echo "==> 1/11 Patches nativos + módulos propios"; bash "$REPO/caelestia/bin/install-patches.sh"
echo; echo "==> 2/11 hypr-user.lua"
if [[ -f "$REPO/caelestia/user-config/.config/caelestia/hypr-user.lua" ]]; then
    mkdir -p "$HOME/.config/caelestia"
    cp "$REPO/caelestia/user-config/.config/caelestia/hypr-user.lua" "$HOME/.config/caelestia/hypr-user.lua"
fi
echo; echo "==> 3/11 Theme bridge + Kitty"; python3 "$REPO/scripts/features/install-theme-bridge.py"
echo; echo "==> 4/11 Schemes + favoritos persistentes + Dock"; python3 "$REPO/scripts/features/finish-theme-dock.py"
echo; echo "==> 5/11 Brave Origin bridge"
if command -v brave-origin >/dev/null 2>&1 || command -v brave-origin-stable >/dev/null 2>&1; then
    python3 "$REPO/scripts/features/install-brave-origin-theme.py"
else
    echo "Brave Origin no está instalado; omitido"
fi

echo; echo "==> 6/11 Clipboard QML"
bash "$REPO/scripts/features/install-clipboard-qml.sh"

echo; echo "==> 7/11 Hardware Center"
bash "$REPO/scripts/features/install-hardware-center.sh"

echo; echo "==> 8/11 Display Manager"
bash "$REPO/scripts/features/install-display-manager.sh"

echo; echo "==> 9/11 Gaming Center"
bash "$REPO/scripts/features/install-gaming-center.sh"

echo; echo "==> 10/11 CaeRice Updater"
bash "$REPO/scripts/features/install-caerice-updater.sh"

echo; echo "==> 11/11 Verificación completa"
python3 "$REPO/scripts/features/validate-sad.py"

echo
echo "CaeRice reconstruido desde el repositorio."
echo "Reinicia Caelestia con:"
echo "  pkill -TERM -x qs"
echo "  sleep 1"
echo "  caelestia shell -d"
