import re
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
modules = repo / "caelestia/modules-owned/modules"
audio = (modules / "CortetsuAudio.qml").read_text(encoding="utf-8")
hub = (modules / "BottomHub.qml").read_text(encoding="utf-8")

for marker in ("Quickshell.Services.Pipewire", "Pipewire.defaultAudioSink", "PwObjectTracker", "CortetsuConfig.maxVolume", "CortetsuConfig.audioIncrement"):
    assert marker in audio, marker
assert "qs.services" not in audio
assert not re.search(r"(?<!Cortetsu)Audio\.", hub)
for marker in ("CortetsuAudio.volume", "CortetsuAudio.muted", "CortetsuAudio.incrementVolume()", "CortetsuAudio.decrementVolume()"):
    assert marker in hub, marker

print("PASS: Bottom Hub audio uses the native Cortetsu PipeWire backend")
