#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro del clon de CaeRice" >&2; exit 1; }
LIVE="/etc/xdg/quickshell/caelestia"

branch="$(git -C "$REPO" branch --show-current)"
[[ "$branch" == "sad" ]] || {
    echo "ERROR: sad-finish solo se ejecuta desde la rama sad; actual: $branch" >&2
    exit 2
}

printf '%s\n' "==> SAD repository validation"
python3 "$REPO/scripts/features/validate-sad.py"

integrated=true
for controller in DisplayController.qml GamingController.qml UpdaterController.qml; do
    [[ -f "$LIVE/modules/$controller" ]] || integrated=false
done

if $integrated; then
    printf '%s\n' "==> SAD live synchronization"
    bash "$REPO/scripts/features/update-sad.sh"
else
    printf '%s\n' "==> SAD first native integration"
    bash "$REPO/scripts/features/install-sad.sh"
fi

printf '%s\n' "==> SAD post-install repository validation"
python3 "$REPO/scripts/features/validate-sad.py"

printf '%s\n' "==> SAD live diagnostics"
python3 "$REPO/scripts/features/diagnose-sad.py"

cat <<'EOF'

SAD automated finalization complete.
No merge or branch deletion was performed.
Continue with docs/SAD_QA.md for real mouse/touchpad, monitor preview/hotplug,
Steam Launch Options, and updater transaction acceptance.
EOF
