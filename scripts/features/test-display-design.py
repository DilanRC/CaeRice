import re
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
display = repo / "caelestia/modules-owned/modules/display"
legacy = ("Caelestia", "qs.components", "Colours.", "Tokens.", "StyledRect", "StyledText", "MaterialIcon")

for path in sorted(display.glob("*.qml")):
    text = path.read_text()
    for symbol in legacy:
        assert symbol not in text, f"{path.name}: {symbol}"
    assert not re.search(r"(?<!Cortetsu)StateLayer\b", text), path.name

assert "CortetsuStateLayer" in (display / "Editor.qml").read_text()
print("PASS: Display Manager uses Cortetsu visual primitives")
