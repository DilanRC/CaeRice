#!/usr/bin/env python3
"""Small deterministic eval for Wave 0 coverage and scope boundaries."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
button = (ROOT / "cortetsu/components/CortetsuButton.qml").read_text()
row = (ROOT / "cortetsu/components/CortetsuListRow.qml").read_text()
hub_button = (ROOT / "cortetsu/modules/HubButton.qml").read_text()
app_rail = (ROOT / "cortetsu/modules/CortetsuAppRail.qml").read_text()
tray = (ROOT / "cortetsu/modules/CortetsuTraySegment.qml").read_text()
hub = (ROOT / "cortetsu/modules/BottomHub.qml").read_text()

checks = {
    "button exposes focus": "focused: root.activeFocus" in button,
    "row exposes focus": "focused: root.activeFocus" in row,
    "hub button exposes focus": "focused: root.activeFocus" in hub_button,
    "app rail exposes focus": "focused: appItem.activeFocus" in app_rail,
    "tray exposes focus": "focused: trayItem.activeFocus" in tray,
    "button supports keyboard": all(x in button for x in ("Keys.onEnterPressed", "Keys.onReturnPressed", "Keys.onSpacePressed")),
    "row supports keyboard": all(x in row for x in ("Keys.onEnterPressed", "Keys.onReturnPressed", "Keys.onSpacePressed")),
    "hub button supports keyboard": all(x in hub_button for x in ("Keys.onEnterPressed", "Keys.onReturnPressed", "Keys.onSpacePressed")),
    "app rail supports keyboard": all(x in app_rail for x in ("Keys.onEnterPressed", "Keys.onLeftPressed", "Keys.onRightPressed")),
    "tray supports keyboard": all(x in tray for x in ("Keys.onEnterPressed", "Keys.onMenuPressed")),
    "popup controller untouched": "bottomAnchorCenter" in hub and "closeAllPopouts" in hub,
}

missing = [name for name, passed in checks.items() if not passed]
if missing:
    raise SystemExit("FAIL: Wave 0 eval missing " + ", ".join(missing))

print(f"Wave 0 foundations eval: {len(checks)}/{len(checks)} (100%)")
