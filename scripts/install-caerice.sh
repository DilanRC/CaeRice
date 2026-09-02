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
echo "CaeRice runtime: ${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia/current"
echo "No se escribió /etc/xdg/quickshell/caelestia."
echo "Reinicio: pkill -TERM -x qs; sleep 1; qs -c ~/.config/quickshell/caelestia/current -n -d"
