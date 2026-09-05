import importlib.util
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
script = repo / "scripts/audit-zero-caelestia.py"
spec = importlib.util.spec_from_file_location("zero_gate", script)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

with tempfile.TemporaryDirectory(prefix="cortetsu-zero-gate-") as directory:
    root = Path(directory)
    active = root / "caelestia/modules-owned/modules"
    active.mkdir(parents=True)
    (active / "Bad.qml").write_text("import Caelestia.Config\nItem { color: Colours.palette.x }\n")
    history = root / "caelestia/history"
    history.mkdir(parents=True)
    (history / "old.qml").write_text("GlobalConfig.foo\n")
    maintenance = root / "scripts/maintenance"
    maintenance.mkdir(parents=True)
    (maintenance / "old.sh").write_text("caelestia shell -d\n")
    patches = root / "caelestia/patches"
    patches.mkdir(parents=True)
    (patches / "change.patch").write_text("--- a/x.qml\n+++ b/x.qml\n-GlobalConfig.old\n+Item {}\n")
    findings = gate.audit(root)
    assert findings["Caelestia.Config"] == ["caelestia/modules-owned/modules/Bad.qml:1"]
    assert findings["Caelestia import"] == ["caelestia/modules-owned/modules/Bad.qml:1"]
    assert findings["Colours"] == ["caelestia/modules-owned/modules/Bad.qml:2"]
    assert "GlobalConfig" not in findings
    assert findings["Caelestia patches"] == ["caelestia/patches/change.patch"]

print("PASS: Zero-Caelestia gate detects active dependencies and excludes history only")
