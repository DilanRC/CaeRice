import re
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
hardware = repo / "cortetsu/modules/hardware"
legacy = ("Caelestia", "qs.components", "Colours.", "Tokens.", "StyledRect", "StyledText", "MaterialIcon")

for path in sorted(hardware.glob("*.qml")):
    text = path.read_text()
    for symbol in legacy:
        assert symbol not in text, f"{path.name}: {symbol}"
    assert not re.search(r"(?<!Cortetsu)StateLayer\b", text), path.name

assert "CortetsuStateLayer" in (hardware / "Content.qml").read_text()
print("PASS: Hardware Center uses Cortetsu visual primitives")
