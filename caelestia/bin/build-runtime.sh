#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE="${CAERICE_DATA_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/caerice}"
RUNTIME="${CAERICE_RUNTIME_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia}"
PACKAGE_ROOT="${CAERICE_PACKAGE_ROOT:-/etc/xdg/quickshell/caelestia}"
UPSTREAM="${CAERICE_UPSTREAM_SOURCE:-$HOME/.local/share/caelestia-custom-system/upstream-git}"
STAMP="$(date +%Y%m%d-%H%M%S)"
STAGE="$BASE/builds/$STAMP"
SNAPSHOT="$BASE/snapshots/pre-migration-$STAMP"
die(){ echo "ERROR: $*" >&2; exit 1; }
[[ -f "$UPSTREAM/shell.qml" ]] || die "falta upstream limpio: $UPSTREAM"
mkdir -p "$BASE/builds" "$RUNTIME" "$SNAPSHOT"
mkdir -p "$STAGE"
exec 9>"$BASE/build.lock"
flock -n 9 || die "ya hay una construcción en curso"
if [[ -d "$PACKAGE_ROOT" ]]; then cp -a "$PACKAGE_ROOT/." "$SNAPSHOT/"; fi
if git -C "$UPSTREAM" rev-parse --verify refs/tags/v2.4.0 >/dev/null 2>&1; then
    git -C "$UPSTREAM" archive v2.4.0 | tar -x -C "$STAGE"
else
    cp -a "$UPSTREAM/." "$STAGE/"
fi
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == patch || -z "$patchname" ]] && continue
    pf="$REPO/caelestia/patches/$patchname"
    if patch --dry-run -p1 -d "$STAGE" < "$pf" >/dev/null 2>&1; then
        patch -p1 -d "$STAGE" < "$pf" >/dev/null
    elif patch --dry-run -R -p1 -d "$STAGE" < "$pf" >/dev/null 2>&1; then
        echo "SKIP already in clean baseline: $rel"
    else
        die "patch conflict in staging: $rel"
    fi
done < "$REPO/caelestia/patches/MANIFEST.tsv"
cp -a "$REPO/caelestia/modules-owned/modules/." "$STAGE/modules/"
python3 "$REPO/caelestia/bin/compose-panels.py" "$STAGE"
cp "$REPO/caelestia/compatibility.json" "$STAGE/compatibility.json"
cp "$REPO/caelestia/composition.json" "$STAGE/composition.json"
python3 "$REPO/scripts/features/test-bottom-hub-target.py"
python3 "$REPO/scripts/features/test-bottom-hub-v3.py"
python3 "$REPO/scripts/features/test-bottom-hub-v4.py"
python3 "$REPO/scripts/features/test-retained-overlay-wiring.py"
python3 "$REPO/scripts/features/test-contentwindow-overview-base.py"
python3 "$REPO/scripts/features/test-wallpaper-manager.py"
python3 "$REPO/scripts/features/test-keybinds.py"
python3 "$REPO/scripts/features/test-shell-normalizer.py"
bash "$REPO/caelestia/tests/test-calendar-readonly.sh"
python3 "$REPO/caelestia/tests/test-pomodoro.py"
test -f "$STAGE/shell.qml" && test -f "$STAGE/modules/calendar/Content.qml" || die "staging incompleto"
printf '%s\n' "$STAMP" > "$STAGE/BUILD_ID"
atomic_link() {
    local target="$1" link="$2" tmp="${2}.tmp.$$"
    ln -s "$target" "$tmp"
    mv -Tf "$tmp" "$link"
}
if [[ -e "$RUNTIME/current" || -L "$RUNTIME/current" ]]; then atomic_link "$(readlink -f "$RUNTIME/current")" "$RUNTIME/previous"; fi
atomic_link "$STAGE" "$RUNTIME/current"
printf 'PROMOTED current=%s previous=%s\n' "$(readlink -f "$RUNTIME/current")" "$(readlink -f "$RUNTIME/previous" 2>/dev/null || true)"
printf 'SNAPSHOT %s\n' "$SNAPSHOT"
