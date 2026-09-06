#!/usr/bin/env sh

cat "${XDG_STATE_HOME:-$HOME/.local/state}/cortetsu/sequences.txt" 2>/dev/null

exec "$@"
