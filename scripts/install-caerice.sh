#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="${HOME}/.local/share/caelestia-custom-system"

if [[ ! -d /etc/xdg/quickshell/caelestia ]]; then
    echo "ERROR: no existe /etc/xdg/quickshell/caelestia" >&2
    exit 1
fi

echo "==> 0/9 Regresiones de integración Bottom Hub"
python3 "$REPO/scripts/features/test-bottom-hub-target.py"
python3 "$REPO/scripts/features/test-bottom-hub-v3.py"
python3 "$REPO/scripts/features/test-bottom-hub-v4.py"
python3 "$REPO/scripts/features/test-retained-overlay-wiring.py"
python3 "$REPO/scripts/features/test-keybinds.py"
python3 "$REPO/scripts/features/eval-keybind-editor.py"
python3 "$REPO/scripts/features/test-shell-normalizer.py"

mkdir -p "$BASE"
rm -rf "$BASE/patches" "$BASE/modules-owned"
cp -a "$REPO/caelestia/patches" "$BASE/patches"
cp -a "$REPO/caelestia/modules-owned" "$BASE/modules-owned"

echo; echo "==> 1/9 Patches nativos + módulos propios"; bash "$REPO/caelestia/bin/install-patches.sh"
echo; echo "==> 2/9 hypr-user.lua"
if [[ -f "$REPO/caelestia/user-config/.config/caelestia/hypr-user.lua" ]]; then
    mkdir -p "$HOME/.config/caelestia"
    cp "$REPO/caelestia/user-config/.config/caelestia/hypr-user.lua" "$HOME/.config/caelestia/hypr-user.lua"
fi
echo; echo "==> 3/9 Theme bridge + Kitty"; python3 "$REPO/scripts/features/install-theme-bridge.py"
echo; echo "==> 4/9 Schemes + favoritos persistentes + Bottom Hub"; python3 "$REPO/scripts/features/finish-theme-dock.py"
echo; echo "==> 5/9 Brave Origin bridge"
if command -v brave-origin >/dev/null 2>&1 || command -v brave-origin-stable >/dev/null 2>&1; then
    python3 "$REPO/scripts/features/install-brave-origin-theme.py"
else
    echo "Brave Origin no está instalado; omitido"
fi

echo; echo "==> 6/9 Clipboard QML"; bash "$REPO/scripts/features/install-clipboard-qml.sh"
echo; echo "==> 7/9 Hardware Center"; bash "$REPO/scripts/features/install-hardware-center.sh"
echo; echo "==> 8/9 Display Manager + purge de centros retirados"; bash "$REPO/scripts/features/update-sad.sh"
echo; echo "==> 9/9 Verificación completa"; python3 "$REPO/scripts/features/validate-sad.py"

echo
echo "CaeRice reconstruido desde el repositorio."
echo "Runtime retenido: Bottom Hub, Overview, Clipboard, Hardware Center y Display Manager."
echo "Gaming Center y CaeRice Updater permanecen eliminados."
