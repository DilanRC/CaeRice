#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_home="$(mktemp -d /tmp/cortetsu-legacy-eval.XXXXXX)"
mkdir -p "$tmp_home/.config/hypr" "$tmp_home/.local/bin"
touch "$tmp_home/.local/bin/cortetsu-pomodoro"
printf '%s\n' 'hl.exec_cmd("$HOME/.local/bin/caerice-pomodoro daemon")' > "$tmp_home/.config/hypr/execs.lua"
HOME="$tmp_home" XDG_CONFIG_HOME="$tmp_home/.config" \
    python3 "$repo/core/migrate_legacy_processes.py" migrate \
    --home "$tmp_home" --data-root "$tmp_home/data" > "$tmp_home/result"
grep -q 'MIGRATED pomodoro_files=1' "$tmp_home/result"
grep -q 'NO_PROCESS_SIGNALING' "$tmp_home/result"
! grep -q 'caerice-pomodoro' "$tmp_home/.config/hypr/execs.lua"
printf 'PASS: legacy migration eval\n'
