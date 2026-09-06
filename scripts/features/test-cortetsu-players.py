from pathlib import Path

text = (Path(__file__).resolve().parents[2] / "cortetsu/services/Players.qml").read_text(encoding="utf-8")
assert "Caelestia" not in text
assert "Quickshell.Services.Mpris" in text
for contract in ("property MprisPlayer manualActive", "getIdentity", "getArtUrl", 'target: "mpris"'):
    assert contract in text
print("PASS: Cortetsu owns the MPRIS player service contract")
