from pathlib import Path

path = Path(__file__).resolve().parents[2] / "cortetsu/modules/launcher/AppList.qml"
source = path.read_text(encoding="utf-8")
assert "Qt.font(" not in source
assert source.count("font.pixelSize: CortetsuTypography.") >= 8
print("PASS: launcher uses valid font properties")
