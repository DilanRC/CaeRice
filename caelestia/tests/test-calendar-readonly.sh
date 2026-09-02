#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helper="$root/bin/caerice-calendar"
python3 - "$helper" <<'PY'
import ast, pathlib, sys
tree = ast.parse(pathlib.Path(sys.argv[1]).read_text())
scopes = next(node.value for node in ast.walk(tree) if isinstance(node, ast.Assign) and any(getattr(t, 'id', '') == 'SCOPES' for t in node.targets))
assert tuple(scopes.elts[i].value for i in range(len(scopes.elts))) == (
    'https://www.googleapis.com/auth/calendar.events.readonly',
    'https://www.googleapis.com/auth/calendar.calendarlist.readonly',
)
PY
if rg -n 'https://www\.googleapis\.com/auth/calendar(["\x27,)]|\.events(["\x27,)]))|events\.(insert|update|patch|delete|move|quickAdd)|calendarList\.(insert|update|patch|delete)|calendars\.(update|patch)' "$root/bin" --pcre2; then
  echo 'FAIL: writable Calendar scope or mutation path found' >&2; exit 1
fi
rg -q 'singleEvents.*true' "$helper"
rg -q 'nextPageToken' "$helper"
rg -q 'calendarId.*eventId' "$helper"
rg -q 'set-selection' "$helper"
echo 'PASS: Calendar integration is read-only, paginated, recurring-aware, and composite-keyed'
