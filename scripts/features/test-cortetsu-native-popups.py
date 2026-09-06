#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
popouts = ROOT / "cortetsu/modules/bar/popouts"
content = (ROOT / "cortetsu/base/modules/bar/popouts/Content.qml").read_text(encoding="utf-8")
hub = (ROOT / "cortetsu/modules/BottomHub.qml").read_text(encoding="utf-8")
wrapper = (ROOT / "cortetsu/modules/bar/popouts/Wrapper.qml").read_text(encoding="utf-8")

for name, service in (
    ("CortetsuNetworkPopup.qml", "CortetsuNetwork"),
    ("CortetsuAudioPopup.qml", "CortetsuAudio"),
    ("CortetsuBluetoothPopup.qml", "Bluetooth"),
):
    text = (popouts / name).read_text(encoding="utf-8")
    assert "CortetsuSurface" in text and "CortetsuListRow" in text
    assert "CortetsuDesign" in text and service in text
    assert "No devices nearby" in text or "No networks available" in text or "No device" in text

password = (popouts / "CortetsuWifiPasswordPopup.qml").read_text(encoding="utf-8")
for token in ("TextField", "Keys.onEscapePressed", "NetworkConnection.connectWithPassword", "8000", "errorText"):
    assert token in password, token

assert "sourceComponent: CortetsuNetworkPopup" in content
assert "sourceComponent: CortetsuAudioPopup" in content
assert "sourceComponent: CortetsuBluetoothPopup" in content
assert "sourceComponent: CortetsuWifiPasswordPopup" in content
assert "sourceComponent: CortetsuDetachedPopup" in wrapper
assert "sourceComponent: Rectangle" not in wrapper
assert "Nexus" not in wrapper
clip_wrapper = (ROOT / "cortetsu/modules/bar/popouts/ClipWrapper.qml").read_text(encoding="utf-8")
assert "content.bottomAttached || content.closing" in clip_wrapper
assert "anchors.leftMargin: (-implicitWidth - 5)" not in clip_wrapper
assert "transformOrigin: Item.Bottom" in clip_wrapper
assert "closeTimer" in wrapper
for token in ('function control(mode: string): bool', 'function detachedControl(mode: string): bool', 'componentsFor(screen)?.popouts', '"kblayout"', '"lockstatus"'):
    assert token in hub, token
for name in ("CortetsuBatteryPopup.qml", "CortetsuActiveWindowPopup.qml", "CortetsuKeyboardPopup.qml", "CortetsuLockStatusPopup.qml", "CortetsuTrayMenu.qml"):
    owned = (popouts / name).read_text(encoding="utf-8")
    assert "CortetsuSurface" in owned or "CortetsuListRow" in owned or "CortetsuButton" in owned
    assert "CortetsuDesign" in owned
for legacy in ("sourceComponent: Battery", "sourceComponent: ActiveWindow", "sourceComponent: KbLayout", "sourceComponent: LockStatus", "sourceComponent: TrayMenu"):
    assert legacy not in content, legacy
assert "sourceComponent: Network {" not in content
assert "sourceComponent: AudioPopout {" not in content
assert "sourceComponent: Bluetooth {" not in content
print("PASS: Wi-Fi, audio and Bluetooth popouts are first-party views over owned services")
