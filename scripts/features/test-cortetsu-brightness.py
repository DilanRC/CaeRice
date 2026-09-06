from pathlib import Path

source = Path(__file__).resolve().parents[2] / "cortetsu/services/Brightness.qml"
text = source.read_text(encoding="utf-8")
assert "Caelestia" not in text
for contract in ("component Monitor", "getMonitorForScreen", "setFor", 'target: "brightness"', "monitorName: modelData?.name ?? \"\"", 'command: monitor.monitorName.length > 0'):
    assert contract in text
print("PASS: Cortetsu owns the Brightness service contract")
