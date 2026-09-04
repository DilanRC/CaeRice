#!/usr/bin/env bash
set -euo pipefail

LIVE="${CORTETSU_LIVE_ROOT:-/etc/xdg/quickshell/caelestia}"
BASE="$HOME/.local/share/cortetsu/upstream"

# Runtime QML.
sudo rm -f "$LIVE/modules/GamingController.qml" "$LIVE/modules/UpdaterController.qml"
sudo rm -rf "$LIVE/modules/gaming" "$LIVE/modules/updater"

# Installed helpers and private user state.
rm -f \
    "$HOME/.local/bin/cortetsu-gaming-probe" \
    "$HOME/.local/bin/cortetsu-gaming-profile" \
    "$HOME/.local/bin/cortetsu-upstream-audit" \
    "$HOME/.local/bin/cortetsu-updater" \
    "$HOME/.local/bin/cortetsu-updater-commit-base" \
    "$HOME/.config/cortetsu/gaming-profiles.json" \
    "$HOME/.local/state/cortetsu/gaming-last-open.json" \
    "$HOME/.local/state/cortetsu/updater-report.json" \
    "$HOME/.local/state/cortetsu/updater-state.json"
rm -rf "$HOME/.cache/cortetsu-updater"

# Stale copies in the local reconstruction cache.
rm -f "$BASE/modules-owned/modules/GamingController.qml" "$BASE/modules-owned/modules/UpdaterController.qml"
rm -rf "$BASE/modules-owned/modules/gaming" "$BASE/modules-owned/modules/updater"

# Historical data owned only by the removed centers. Shared snapshots stay.
if [[ -d "$BASE/snapshots" ]]; then
    find "$BASE/snapshots" -mindepth 1 -maxdepth 1 -type d \
        \( -name 'gaming-center-*' -o -name 'updater-center-*' -o -name 'updater-*' \) \
        -exec rm -rf -- {} +
fi

rmdir "$HOME/.config/cortetsu" 2>/dev/null || true
rmdir "$HOME/.local/state/cortetsu" 2>/dev/null || true

echo "Retired Gaming/Updater artifacts purged."
