from pathlib import Path

repo = Path(__file__).resolve().parents[2]
overview = repo / "caelestia/modules-owned/modules/overview"
legacy = ("Caelestia", "qs.components", "Colours.", "Tokens.", "StyledRect", "StyledText", "StyledClippingRect", "MaterialIcon")

for name in ("Wrapper.qml", "WindowCard.qml"):
    text = (overview / name).read_text()
    for symbol in legacy:
        assert symbol not in text, f"{name}: {symbol}"

card = (overview / "WindowCard.qml").read_text()
assert "CortetsuDesign.colorSurface" in card
assert "CortetsuText" in card and "CortetsuIcon" in card

print("PASS: Overview wrapper and window cards use Cortetsu visual primitives")
