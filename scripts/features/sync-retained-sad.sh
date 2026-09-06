#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de Cortetsu" >&2; exit 1; }
LIVE="${CORTETSU_LIVE_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/cortetsu/current}"

python3 "$REPO/scripts/features/validate-sad.py"
bash "$REPO/scripts/features/apply-canonical-sad-wiring.sh"

# Synchronize retained Display Manager QML and helpers. Wallpaper Manager QML
# is owned by the base Cortetsu module install; canonical wiring above connects
# its ScreenState/controller/drawer surfaces together with Display.
install -m 0644 "$REPO/cortetsu/modules/DisplayController.qml" "$LIVE/modules/DisplayController.qml"
mkdir -p "$LIVE/modules/display"
for qml in "$REPO/cortetsu/modules/display/"*.qml; do
    install -m 0644 "$qml" "$LIVE/modules/display/$(basename "$qml")"
done
mkdir -p "$HOME/.local/bin"
for helper in cortetsu-display-probe cortetsu-display-plan cortetsu-display-transaction cortetsu-display-persist cortetsu-display-presets cortetsu-display-workspaces; do
    install -m 0755 "$REPO/cortetsu/bin/$helper" "$HOME/.local/bin/$helper"
done

bash "$REPO/scripts/features/purge-retired-centers.sh"
hyprctl reload >/dev/null
systemctl --user restart cortetsu-shell.service
sleep 1

if ! python3 "$REPO/scripts/features/diagnose-sad.py"; then
    echo "SAD synchronization finished, but live diagnostics failed." >&2
    exit 1
fi

echo "SAD synchronized: Hardware/Display/Wallpaper retained; Gaming/Updater removed."
