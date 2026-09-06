#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import tempfile
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
DOTFILES = REPO / "core/dotfiles.py"
SYSTEM = REPO / "core/system.py"


def run(env: dict[str, str], script: Path, *args: str) -> str:
    result = subprocess.run(
        ["python3", str(script), *args, "--repo", str(REPO)],
        cwd=REPO,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=True,
    )
    return result.stdout


with tempfile.TemporaryDirectory(prefix="cortetsu-system-recovery-") as tmp:
    root = Path(tmp)
    home = root / "home"
    data = home / ".local/share/cortetsu"
    runtime = root / "runtime"
    shell = runtime / "shell-1"
    home.mkdir(parents=True)
    shell.mkdir(parents=True)
    (shell / "shell.qml").write_text("// test shell\n", encoding="utf-8")
    (shell / "BUILD_ID").write_text("shell-1\n", encoding="utf-8")
    (shell / "BUILD.json").write_text(json.dumps({
        "schema": 1,
        "sourceProject": "Cortetsu",
        "buildId": "shell-1",
    }) + "\n", encoding="utf-8")
    env = os.environ.copy()
    env.update(
        HOME=str(home),
        XDG_CONFIG_HOME=str(home / ".config"),
        CORTETSU_DATA_ROOT=str(data),
        CORTETSU_RUNTIME_ROOT=str(runtime),
    )

    run(env, DOTFILES, "apply")
    (runtime / "current").symlink_to(shell, target_is_directory=True)
    first = run(env, SYSTEM, "promote")
    assert "PROMOTED system=" in first
    current = (data / "system/current").resolve(strict=True)
    payload = json.loads((current / "SYSTEM.json").read_text(encoding="utf-8"))
    payload["dotfilesGeneration"] = str(root / "missing-dotfiles-generation")
    (current / "SYSTEM.json").write_text(json.dumps(payload) + "\n", encoding="utf-8")

    recovered = run(env, SYSTEM, "promote")
    assert "QUARANTINED invalid=" in recovered
    assert not current.exists()
    assert list((data / "system/invalid").iterdir())
    run(env, SYSTEM, "verify")

print("PASS: invalid system generations are quarantined and recovered")
