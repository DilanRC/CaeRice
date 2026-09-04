#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

repo = Path(__file__).resolve().parents[2]
modules = repo / "caelestia/modules-owned/modules"

# No arbitrary shell pipelines inside QML. Commands must remain explicit and
# inspectable, or move behind a typed/native backend.
for path in modules.rglob("*.qml"):
    text = path.read_text(encoding="utf-8")
    assert "sh -c" not in text, f"arbitrary shell in QML: {path.relative_to(repo)}"

# High-frequency hardware polling is permitted only while the consuming page is
# visible. This keeps closed Control Center pages cold.
for relative in (
    "hardware/EnergyPage.qml",
    "hardware/PowerPage.qml",
    "hardware/PowerAutomationPage.qml",
):
    text = (modules / relative).read_text(encoding="utf-8")
    assert "running: root.visible" in text, f"hidden-page polling regression: {relative}"
    assert "onVisibleChanged: { if (visible) refresh(); }" in text, f"missing wake-on-visible: {relative}"

# Cortetsu owns interaction character even while colours remain adaptive through
# the temporary shell adapter.
hub = (modules / "HubButton.qml").read_text(encoding="utf-8")
design = (modules / "CortetsuDesign.js").read_text(encoding="utf-8")
assert 'import "CortetsuDesign.js" as CortetsuDesign' in hub
assert "CortetsuDesign.hoverScale" in hub
assert hub.count("CortetsuDesign.motionFastMs") >= 2
assert "hoverScale = 1.04" in design
assert "motionFastMs = 100" in design
assert "mouse.containsMouse ? 1.06 : 1" not in hub
assert "duration: 110" not in hub

# Canonical state belongs to Cortetsu, while Caelestia paths are allowed only
# where they are genuine upstream configuration contracts.
calendar = (repo / "caelestia/bin/cortetsu-calendar").read_text(encoding="utf-8")
pomodoro = (repo / "caelestia/bin/cortetsu-pomodoro").read_text(encoding="utf-8")
assert '/ "cortetsu"' in calendar
assert 'state_home / "cortetsu/pomodoro.json"' in pomodoro

print("PASS: Cortetsu quality gate: cold hidden pages, owned restrained motion, canonical state, no QML shell pipelines")
