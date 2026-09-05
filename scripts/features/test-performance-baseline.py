#!/usr/bin/env python3
from pathlib import Path


repo = Path(__file__).resolve().parents[2]
baseline = (repo / "docs/PERFORMANCE_BASELINE_2026-09-04.md").read_text(encoding="utf-8")
contract = (repo / "docs/PERFORMANCE.md").read_text(encoding="utf-8")

for marker in ("CPU at capture", "PSS", "Threads", "File descriptors", "Repeating user timers"):
    assert marker in baseline, marker
assert "nmcli monitor" in baseline
assert "does not attribute" in baseline
assert "60-second idle period" in baseline
assert "40 open/close cycles" in baseline
assert "shell idle" in contract and "sin subprocesses recurrentes" in contract
print("PASS: performance baseline records measurable shell metrics without blaming nmcli")
