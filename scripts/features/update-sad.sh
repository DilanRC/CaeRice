#!/usr/bin/env bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"; [[ -n "$REPO" ]] || exit 1
LIVE="/etc/xdg/quickshell/caelestia"

python3 "$REPO/scripts/features/validate-sad.py"

# Display Manager
sudo install -m 0644 "$REPO/caelestia/modules-owned/modules/DisplayController.qml" "$LIVE/modules/DisplayController.qml"
sudo mkdir -p "$LIVE/modules/display"
for qml in "$REPO/caelestia/modules-owned/modules/display/"*.qml; do sudo install -m 0644 "$qml" "$LIVE/modules/display/$(basename "$qml")"; done
for helper in caerice-display-probe caerice-display-plan caerice-display-transaction caerice-display-persist caerice-display-presets caerice-display-workspaces; do install -m 0755 "$REPO/caelestia/bin/$helper" "$HOME/.local/bin/$helper"; done

# Gaming Center
sudo install -m 0644 "$REPO/caelestia/modules-owned/modules/GamingController.qml" "$LIVE/modules/GamingController.qml"
sudo mkdir -p "$LIVE/modules/gaming"
for qml in "$REPO/caelestia/modules-owned/modules/gaming/"*.qml; do sudo install -m 0644 "$qml" "$LIVE/modules/gaming/$(basename "$qml")"; done
for helper in caerice-gaming-probe caerice-gaming-profile; do install -m 0755 "$REPO/caelestia/bin/$helper" "$HOME/.local/bin/$helper"; done

# CaeRice Updater
sudo install -m 0644 "$REPO/caelestia/modules-owned/modules/UpdaterController.qml" "$LIVE/modules/UpdaterController.qml"
sudo mkdir -p "$LIVE/modules/updater"
for qml in "$REPO/caelestia/modules-owned/modules/updater/"*.qml; do sudo install -m 0644 "$qml" "$LIVE/modules/updater/$(basename "$qml")"; done
for helper in caerice-upstream-audit caerice-updater caerice-updater-commit-base; do install -m 0755 "$REPO/caelestia/bin/$helper" "$HOME/.local/bin/$helper"; done

pkill -TERM -x qs 2>/dev/null || true
sleep 1
caelestia shell -d
sleep 1

# `caelestia shell -d` may return success even when Quickshell rejects the QML
# configuration. Treat live IPC/log diagnostics as the authoritative restart
# health check so this updater never prints a false success message.
if ! python3 "$REPO/scripts/features/diagnose-sad.py"; then
    echo "SAD live synchronization completed, but Caelestia failed post-restart diagnostics." >&2
    exit 1
fi

echo "SAD modules synchronized, Caelestia restarted, and live diagnostics passed."
