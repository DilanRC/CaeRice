from pathlib import Path

repo = Path(__file__).resolve().parents[2]
overview = repo / "cortetsu/modules/overview"
overview_content = (overview / "Content.qml").read_text()
legacy = ("Caelestia", "qs.components", "Colours.", "Tokens.", "StyledRect", "StyledText", "StyledClippingRect", "MaterialIcon")

for name in ("Wrapper.qml", "WindowCard.qml", "Content.qml"):
    text = (overview / name).read_text()
    for symbol in legacy:
        assert symbol not in text, f"{name}: {symbol}"

card = (overview / "WindowCard.qml").read_text()
assert "CortetsuDesign.colorSurface" in card
assert "CortetsuText" in card and "CortetsuIcon" in card
content_window = (repo / "cortetsu/modules/drawers/ContentWindow.qml").read_text()
assert "color: CortetsuDesign.colorScrim" in content_window
assert "id: viewportBackground" in overview_content
assert "acceptedButtons: Qt.LeftButton" in overview_content
assert "Keys.onSpacePressed" in overview_content

print("PASS: Overview wrapper and window cards use Cortetsu visual primitives")
