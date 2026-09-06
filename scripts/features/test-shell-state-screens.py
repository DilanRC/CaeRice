from pathlib import Path

repo = Path(__file__).resolve().parents[1]
patch = (repo.parent / "caelestia/patches/services__ShellState__cortetsu-screens.qml.patch").read_text(encoding="utf-8")
manifest = (repo.parent / "caelestia/patches/MANIFEST.tsv").read_text(encoding="utf-8")

assert "services__ShellState__cortetsu-screens.qml.patch\tservices/ShellState.qml" in manifest
assert 'import "../modules"' in patch
assert "model: CortetsuScreens.screens" in patch
assert patch.count("model: CortetsuScreens.screens") == 2
print("PASS: ShellState creates per-screen state from CortetsuScreens")
