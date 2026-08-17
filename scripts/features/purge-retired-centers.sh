#!/usr/bin/env bash
set -euo pipefail

LIVE="${CAERICE_LIVE_ROOT:-/etc/xdg/quickshell/caelestia}"
BASE="$HOME/.local/share/caelestia-custom-system"

# Runtime QML.
sudo rm -f "$LIVE/modules/GamingController.qml" "$LIVE/modules/UpdaterController.qml"
sudo rm -rf "$LIVE/modules/gaming" "$LIVE/modules/updater"

# Installed helpers and private user state.
rm -f \
    "$HOME/.local/bin/caerice-gaming-probe" \
    "$HOME/.local/bin/caerice-gaming-profile" \
    "$HOME/.local/bin/caerice-upstream-audit" \
    "$HOME/.local/bin/caerice-updater" \
    "$HOME/.local/bin/caerice-updater-commit-base" \
    "$HOME/.config/caerice/gaming-profiles.json" \
    "$HOME/.local/state/caerice/gaming-last-open.json" \
    "$HOME/.local/state/caerice/updater-report.json" \
    "$HOME/.local/state/caerice/updater-state.json"
rm -rf "$HOME/.cache/caerice-updater"

# Stale copies in the local reconstruction cache.
rm -f "$BASE/modules-owned/modules/GamingController.qml" "$BASE/modules-owned/modules/UpdaterController.qml"
rm -rf "$BASE/modules-owned/modules/gaming" "$BASE/modules-owned/modules/updater"

# Historical data owned only by the removed centers. Shared snapshots stay.
if [[ -d "$BASE/snapshots" ]]; then
    find "$BASE/snapshots" -mindepth 1 -maxdepth 1 -type d \
        \( -name 'gaming-center-*' -o -name 'updater-center-*' -o -name 'updater-*' \) \
        -exec rm -rf -- {} +
fi

rmdir "$HOME/.config/caerice" 2>/dev/null || true
rmdir "$HOME/.local/state/caerice" 2>/dev/null || true

echo "Retired Gaming/Updater artifacts purged."
