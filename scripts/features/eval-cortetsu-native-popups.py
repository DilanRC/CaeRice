#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
popouts = ROOT / "cortetsu/modules/bar/popouts"
required = ("CortetsuNetworkPopup.qml", "CortetsuAudioPopup.qml", "CortetsuBluetoothPopup.qml")
for name in required:
    text = (popouts / name).read_text(encoding="utf-8")
    for token in ("CortetsuSurface", "CortetsuSectionHeader", "CortetsuListRow"):
        assert token in text, f"{name} lacks {token}"
    assert "CortetsuDesign.radiusLarge" in text
assert (ROOT / "cortetsu/base/modules/bar/popouts/Content.qml").is_file()
password = (popouts / "CortetsuWifiPasswordPopup.qml").read_text(encoding="utf-8")
assert password.count("CortetsuButton") >= 2
assert "NetworkConnection.connectWithPassword" in password
print("PASS: native popup eval covers network, audio and Bluetooth hierarchy and states")
