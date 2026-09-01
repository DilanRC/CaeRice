#!/usr/bin/env python3
import importlib.util
import json
import os
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("configure", HERE / "configure-launcher-wallpaper-actions.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

assert [item["name"] for item in module.default_actions()] == [
    "Calculator", "Scheme", "Variant", "Light", "Dark", "Shutdown", "Reboot",
    "Logout", "Lock", "Sleep", "Settings",
]

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    config = root / "shell.json"
    config.write_text(json.dumps({"launcher": {"actions": [{"name": "Wallpaper"}, {"name": "Keep"}, {"name": "Random"}]}, "other": 7}), encoding="utf-8")
    os.chmod(config, 0o640)
    assert module.configure(config, root / "backup") is True
    saved = json.loads(config.read_text(encoding="utf-8"))
    assert saved["launcher"]["actions"] == [{"name": "Keep"}]
    backups = list((root / "backup").glob("wallpaper-manager-*/shell.json"))
    assert saved["other"] == 7 and len(backups) == 1
    assert (config.stat().st_mode & 0o777) == 0o640
    before = config.read_bytes()
    assert module.configure(config, root / "backup") is False
    assert config.read_bytes() == before
    empty = root / "empty.json"
    empty.write_text("{}", encoding="utf-8")
    assert module.configure(empty, dry_run=True) is True
    assert json.loads(empty.read_text(encoding="utf-8")) == {}
print("test-configure-launcher-wallpaper-actions: OK")
