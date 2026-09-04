#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
HYPR_USER="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/hypr-user.lua"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

atomic_symlink() {
    local target="$1"
    local link="$2"
    local temporary="${link}.tmp.$$"
    rm -f "$temporary"
    ln -s "$target" "$temporary"
    mv -Tf "$temporary" "$link"
}

printf '==> Cortetsu: validación y construcción aislada\n'
"$REPO/caelestia/bin/check-package-updates.sh" || true
"$REPO/caelestia/bin/build-runtime.sh"

printf '==> Helpers y aliases de compatibilidad\n'
mkdir -p "$BIN_DIR"
while IFS= read -r -d '' source; do
    name="$(basename "$source")"
    install -m 0755 "$source" "$BIN_DIR/$name"
    canonical="cortetsu-${name#caerice-}"
    atomic_symlink "$name" "$BIN_DIR/$canonical"
done < <(find "$REPO/caelestia/bin" -maxdepth 1 -type f -name 'caerice-*' -print0 | sort -z)

install -m 0755 "$REPO/caelestia/bin/rollback-runtime.sh" "$BIN_DIR/cortetsu-rollback"
atomic_symlink "cortetsu-rollback" "$BIN_DIR/caerice-rollback"
install -m 0755 "$REPO/caelestia/bin/caelestia" "$BIN_DIR/caelestia"
if [[ -x "$REPO/scripts/cortetsu" ]]; then
    install -m 0755 "$REPO/scripts/cortetsu" "$BIN_DIR/cortetsu"
fi

printf '==> Configuración de usuario\n'
mkdir -p "$(dirname "$HYPR_USER")"
if [[ -f "$HYPR_USER" ]] && ! cmp -s "$REPO/config/hypr-user.lua" "$HYPR_USER"; then
    cp -a "$HYPR_USER" "$HYPR_USER.bak.$(date +%Y%m%d-%H%M%S)"
fi
temporary_hypr="${HYPR_USER}.tmp.$$"
install -m 0644 "$REPO/config/hypr-user.lua" "$temporary_hypr"
mv -Tf "$temporary_hypr" "$HYPR_USER"

if [[ -f "$REPO/scripts/features/install-theme-bridge.py" ]]; then
    python3 "$REPO/scripts/features/install-theme-bridge.py"
fi

if compgen -G "$REPO/config/systemd/user/*.service" >/dev/null; then
    mkdir -p "$SYSTEMD_USER_DIR"
    for service in "$REPO"/config/systemd/user/*.service; do
        install -m 0644 "$service" "$SYSTEMD_USER_DIR/$(basename "$service")"
    done
    systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

runtime_root="${CORTETSU_RUNTIME_ROOT:-${CAERICE_RUNTIME_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia}}"
printf '\nCortetsu runtime: %s/current\n' "$runtime_root"
printf 'No se escribió /etc/xdg/quickshell/caelestia.\n'
printf 'Reinicio: pkill -TERM -x qs; sleep 1; qs -p %q -n -d\n' "$runtime_root/current"
