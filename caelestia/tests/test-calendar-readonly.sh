#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helper="$root/bin/caerice-calendar"
python3 - "$helper" <<'PY'
from __future__ import annotations
import ast
import re
import sys
from pathlib import Path
source = Path(sys.argv[1]).read_text(encoding="utf-8")
tree = ast.parse(source)
scopes_node = next(
    node.value for node in ast.walk(tree)
    if isinstance(node, ast.Assign)
    and any(getattr(target, "id", "") == "SCOPES" for target in node.targets)
)
scopes = tuple(element.value for element in scopes_node.elts)
assert scopes == (
    "https://www.googleapis.com/auth/calendar.events.readonly",
    "https://www.googleapis.com/auth/calendar.calendarlist.readonly",
)
for forbidden in (
    r"https://www\.googleapis\.com/auth/calendar(?:[\"',)]|\.events[\"',)])",
    r"events\.(?:insert|update|patch|delete|move|quickAdd)",
    r"calendarList\.(?:insert|update|patch|delete)",
    r"calendars\.(?:update|patch)",
):
    assert not re.search(forbidden, source), forbidden
for required in (
    '"singleEvents": "true"', '"showDeleted": "false"',
    '"calendarId": calendar["calendarId"]', '"eventId": event_id',
    '"set-selection"', "nextPageToken",
):
    assert required in source, required
PY
echo "PASS: Calendar integration remains read-only, paginated, recurring-aware, and composite-keyed"
