#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
script = repo / "core/migrate_legacy_processes.py"
with tempfile.TemporaryDirectory(prefix="legacy-process-") as tmp:
    root = Path(tmp)
    home = root / "home"
    config = home / ".config/hypr"
    bin_dir = home / ".local/bin"
    data = root / "data"
    config.mkdir(parents=True)
    bin_dir.mkdir(parents=True)
    (bin_dir / "cortetsu-pomodoro").touch()
    (bin_dir / "cortetsu-wallpaper-color-daemon").touch()
    execs = config / "execs.lua"
    execs.write_text(
        'hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/caelestia-wallpaper-color-daemon")\n'
        'hl.exec_cmd("$HOME/.local/bin/caerice-pomodoro daemon")\n', encoding="utf-8"
    )
    env = os.environ.copy()
    env.update(HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"))
    scan = subprocess.run(["python3", str(script), "scan", "--home", str(home)], env=env, text=True, capture_output=True, check=True)
    assert "wallpaper-color: FOUND" in scan.stdout
    assert "pomodoro: FOUND" in scan.stdout
    subprocess.run(["python3", str(script), "migrate", "--home", str(home), "--data-root", str(data)], env=env, check=True)
    updated = execs.read_text(encoding="utf-8")
    assert "cortetsu-pomodoro daemon" in updated
    assert "caerice-pomodoro" not in updated
    assert "cortetsu-wallpaper-color-daemon" in updated
    marker = (data / "legacy-processes.last").read_text(encoding="utf-8")
    assert "changed=1" in marker and "deferred=0" in marker
    backups = list((data / "migrations").glob("*/legacy-processes/config/hypr/execs.lua"))
    assert backups and "caerice-pomodoro" in backups[0].read_text(encoding="utf-8")
    subprocess.run(["python3", str(script), "migrate", "--home", str(home), "--data-root", str(data)], env=env, check=True)
    assert "caerice-pomodoro" not in execs.read_text(encoding="utf-8")

source = script.read_text(encoding="utf-8")
assert "pkill" not in source and "os.kill" not in source and "killpg" not in source
print("PASS: legacy process migration is backed up, idempotent, and signal-free")
