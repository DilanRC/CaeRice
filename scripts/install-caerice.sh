#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "==> CaeRice: validación y build aislado"
"$REPO/caelestia/bin/check-package-updates.sh" || true
CAERICE_UPSTREAM_SOURCE="${CAERICE_UPSTREAM_SOURCE:-$HOME/.local/share/caelestia-custom-system/upstream-git}" "$REPO/caelestia/bin/build-runtime.sh"
mkdir -p "$HOME/.local/bin"
install -m 0755 "$REPO/caelestia/bin/caerice-calendar" "$HOME/.local/bin/caerice-calendar"
install -m 0755 "$REPO/caelestia/bin/caerice-pomodoro" "$HOME/.local/bin/caerice-pomodoro"
install -m 0755 "$REPO/caelestia/bin/rollback-runtime.sh" "$HOME/.local/bin/caerice-rollback"
HYPR_USER="$HOME/.config/caelestia/hypr-user.lua"
mkdir -p "$(dirname "$HYPR_USER")"
if [[ -f "$HYPR_USER" ]]; then
    cp "$HYPR_USER" "$HYPR_USER.bak.$(date +%Y%m%d-%H%M%S)"
fi
tmp_hypr="${HYPR_USER}.tmp.$$"
install -m 0644 "$REPO/config/hypr-user.lua" "$tmp_hypr"
mv -Tf "$tmp_hypr" "$HYPR_USER"
echo "Hyprland keybinds: $HYPR_USER"
echo "CaeRice runtime: ${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia/current"
echo "No se escribió /etc/xdg/quickshell/caelestia."
echo "Reinicio: pkill -TERM -x qs; sleep 1; qs -p ~/.config/quickshell/caelestia/current -n -d"
