#!/usr/bin/env bash
set -euo pipefail

DATA_ROOT="${CORTETSU_DATA_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/cortetsu}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$DATA_ROOT/migrations/$STAMP"
MARKER="$DATA_ROOT/.v2-migrated"

[[ ! -e "$MARKER" ]] || exit 0
mkdir -p "$BACKUP" "$CONFIG_HOME/cortetsu" "$STATE_HOME/cortetsu" "$CACHE_HOME/cortetsu"

backup_path() {
    local source="$1"
    local label="$2"
    if [[ -e "$source" || -L "$source" ]]; then
        mkdir -p "$BACKUP/$(dirname "$label")"
        cp -a "$source" "$BACKUP/$label"
    fi
}

copy_if_missing() {
    local source="$1"
    local destination="$2"
    local mode="${3:-}"
    if [[ -f "$source" && ! -e "$destination" ]]; then
        mkdir -p "$(dirname "$destination")"
        cp -a "$source" "$destination"
        [[ -z "$mode" ]] || chmod "$mode" "$destination"
    fi
}

backup_path "$CONFIG_HOME/caerice" "config/caerice"
backup_path "$STATE_HOME/caerice" "state/caerice"
backup_path "$CONFIG_HOME/quickshell/caelestia" "runtime/quickshell-caelestia"

copy_if_missing "$CONFIG_HOME/caelestia/calendar-client.json" "$CONFIG_HOME/cortetsu/calendar-client.json" 600
copy_if_missing "$CONFIG_HOME/caelestia/calendar-selection.json" "$CONFIG_HOME/cortetsu/calendar-selection.json" 600
copy_if_missing "$CACHE_HOME/caelestia/calendar-events.json" "$CACHE_HOME/cortetsu/calendar-events.json" 600
copy_if_missing "$STATE_HOME/caelestia/pomodoro.json" "$STATE_HOME/cortetsu/pomodoro.json" 600

if [[ -d "$CONFIG_HOME/caerice" ]]; then
    cp -an "$CONFIG_HOME/caerice/." "$CONFIG_HOME/cortetsu/" || true
fi
if [[ -d "$STATE_HOME/caerice" ]]; then
    cp -an "$STATE_HOME/caerice/." "$STATE_HOME/cortetsu/" || true
fi

# Migrate the Calendar refresh token without ever printing it. The old secret is
# only cleared after the canonical entry is confirmed stored.
if command -v secret-tool >/dev/null 2>&1; then
    canonical_secret="$(secret-tool lookup service cortetsu-google-calendar 2>/dev/null || true)"
    if [[ -z "$canonical_secret" ]]; then
        legacy_secret="$(secret-tool lookup service caerice-google-calendar 2>/dev/null || true)"
        if [[ -n "$legacy_secret" ]]; then
            if printf '%s' "$legacy_secret" | secret-tool store --label='Cortetsu Google Calendar refresh token' service cortetsu-google-calendar >/dev/null 2>&1; then
                secret-tool clear service caerice-google-calendar >/dev/null 2>&1 || true
            fi
        fi
        unset legacy_secret
    fi
    unset canonical_secret
fi

mkdir -p "$BACKUP/bin"
shopt -s nullglob
for old in "$HOME"/.local/bin/caerice-*; do
    cp -a "$old" "$BACKUP/bin/$(basename "$old")"
    rm -f "$old"
done
shopt -u nullglob

OLD_UNIT="caerice-power-auto.service"
if systemctl --user is-enabled "$OLD_UNIT" >/dev/null 2>&1; then
    printf 'enabled\n' > "$DATA_ROOT/.power-auto-was-enabled"
fi
systemctl --user disable --now "$OLD_UNIT" >/dev/null 2>&1 || true
if [[ -f "$CONFIG_HOME/systemd/user/$OLD_UNIT" ]]; then
    backup_path "$CONFIG_HOME/systemd/user/$OLD_UNIT" "systemd/$OLD_UNIT"
    rm -f "$CONFIG_HOME/systemd/user/$OLD_UNIT"
fi
systemctl --user daemon-reload >/dev/null 2>&1 || true

printf '%s\n' "$STAMP" > "$MARKER"
printf 'Cortetsu v2 migration backup: %s\n' "$BACKUP"
