import json
import os
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
script = repo / "core/migrate_config.py"

with tempfile.TemporaryDirectory(prefix="cortetsu-config-test-") as directory:
    home = Path(directory)
    legacy = home / ".config/caelestia/shell.json"
    legacy.parent.mkdir(parents=True)
    legacy.write_text(json.dumps({
        "launcher": {"favouriteApps": ["steam", 7]},
        "bar": {"workspaces": {"shown": 6}, "tray": {"hiddenIcons": ["nm-applet", None]}},
    }), encoding="utf-8")
    env = {**os.environ, "XDG_CONFIG_HOME": str(home / ".config"), "XDG_DATA_HOME": str(home / ".local/share")}
    subprocess.run(["python3", str(script), "--home", str(home)], env=env, check=True)
    target = home / ".config/cortetsu/preferences.json"
    assert json.loads(target.read_text()) == {"schema": 1, "favouriteApps": ["steam"], "hiddenTrayIcons": ["nm-applet"], "workspacesShown": 6}
    backups = list((home / ".local/share/cortetsu/migrations").glob("*/preferences/legacy-shell.json"))
    assert len(backups) == 1
    subprocess.run(["python3", str(script), "--home", str(home)], env=env, check=True)
    assert len(list((home / ".local/share/cortetsu/migrations").glob("*/preferences/legacy-shell.json"))) == 1
print("PASS: functional preference migration is backed up and idempotent")
