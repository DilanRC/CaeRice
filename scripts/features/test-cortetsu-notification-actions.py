from pathlib import Path

repo = Path(__file__).resolve().parents[2]
modules = repo / "cortetsu/modules"
service = (modules / "CortetsuNotifications.qml").read_text(encoding="utf-8")
bin_dir = repo / "cortetsu/bin"
helper = (bin_dir / "cortetsu-notifications").read_text(encoding="utf-8")

# Controller exposes history/dismiss/clear/DND actions with no GlobalConfig coupling,
# and routes every mutation through the deterministic helper binary (never edits
# JSON inline in QML).
for marker in (
    "property var history: []",
    'function dismiss(id: var): void {\n        Quickshell.execDetached(["cortetsu-notifications", "dismiss", String(id)]);',
    'function clear(): void {\n        Quickshell.execDetached(["cortetsu-notifications", "clear"]);',
    'function toggleDnd(): void {\n        Quickshell.execDetached(["cortetsu-notifications", "dnd", "toggle"]);',
    'target: "cortetsu-notifications"',
    "function isDndEnabled(): bool { return root.dnd; }",
):
    assert marker in service, marker
assert "GlobalConfig." not in service
assert "Caelestia." not in service
assert "import qs." not in service

# Helper binary is a standalone, importable-free deterministic script (no LLM/API calls,
# no upstream QML coupling) that owns exactly the two Cortetsu-state files.
assert helper.startswith("#!/usr/bin/env python3")
for marker in ("def cmd_dismiss", "def cmd_clear", "def cmd_dnd", "notifs.json", "notification-status.json"):
    assert marker in helper, marker
assert "GlobalConfig." not in helper and "Caelestia." not in helper

print("PASS: CortetsuNotifications exposes history/dismiss/clear/DND through a deterministic, GlobalConfig-free helper")
