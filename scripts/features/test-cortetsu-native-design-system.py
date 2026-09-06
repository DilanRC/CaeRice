#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
components = ROOT / "cortetsu/components"
design = (ROOT / "cortetsu/modules/CortetsuDesign.js").read_text(encoding="utf-8")
required = (
    "CortetsuButton.qml",
    "CortetsuToggle.qml",
    "CortetsuSlider.qml",
    "CortetsuListRow.qml",
    "CortetsuSectionHeader.qml",
    "containers/CortetsuPopupHost.qml",
)
for name in required:
    assert (components / name).is_file(), f"missing first-party primitive: {name}"

for token in ("colorSurfaceGlass", "colorSurfaceGlassStrong", "radiusPill", "rowHeight", "motionPanelMs"):
    assert token in design, f"design token missing: {token}"

host = (components / "containers/CortetsuPopupHost.qml").read_text(encoding="utf-8")
for token in ("Keys.onEscapePressed", "dismissOnOutside", "WlrKeyboardFocus.OnDemand", "z: 100", "signal closed()"):
    assert token in host, f"popup host contract missing: {token}"

for name in required[:-1]:
    text = (components / name).read_text(encoding="utf-8")
    assert "CortetsuDesign" in text, f"{name} does not consume Cortetsu tokens"
    assert "signal" in text or name == "CortetsuSectionHeader.qml", f"{name} has no interaction contract"

print("PASS: Cortetsu design primitives expose shared tokens, states and popup focus contract")
