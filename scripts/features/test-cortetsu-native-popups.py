#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
popouts = ROOT / "cortetsu/modules/bar/popouts"
content = (ROOT / "cortetsu/base/modules/bar/popouts/Content.qml").read_text(encoding="utf-8")

for name, service in (
    ("CortetsuNetworkPopup.qml", "CortetsuNetwork"),
    ("CortetsuAudioPopup.qml", "CortetsuAudio"),
    ("CortetsuBluetoothPopup.qml", "Bluetooth"),
):
    text = (popouts / name).read_text(encoding="utf-8")
    assert "CortetsuSurface" in text and "CortetsuListRow" in text
    assert "CortetsuDesign" in text and service in text
    assert "No devices nearby" in text or "No networks available" in text or "No device" in text

assert "sourceComponent: CortetsuNetworkPopup" in content
assert "sourceComponent: CortetsuAudioPopup" in content
assert "sourceComponent: CortetsuBluetoothPopup" in content
assert "sourceComponent: Network {" not in content
assert "sourceComponent: AudioPopout {" not in content
assert "sourceComponent: Bluetooth {" not in content
print("PASS: Wi-Fi, audio and Bluetooth popouts are first-party views over owned services")
