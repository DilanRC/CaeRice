#!/usr/bin/env python3
"""E2E gate: exact upstream -> two Cortetsu generations -> rollback."""
from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
upstream = Path(
    os.environ.get(
        "CORTETSU_UPSTREAM_SOURCE",
        os.environ.get("CAERICE_UPSTREAM_SOURCE", str(Path.home() / ".local/share/caelestia-custom-system/upstream-git")),
    )
)
with tempfile.TemporaryDirectory(prefix="cortetsu-e2e-") as temporary:
    root = Path(temporary)
    data = root / "data"
    runtime = root / "runtime"
    env = os.environ.copy()
    env.update(
        CORTETSU_DATA_ROOT=str(data),
        CORTETSU_RUNTIME_ROOT=str(runtime),
        CORTETSU_UPSTREAM_SOURCE=str(upstream),
    )
    subprocess.run([str(repo / "caelestia/bin/build-runtime.sh")], cwd=repo, env=env, check=True)
    first = (runtime / "current").resolve()
    assert (first / "shell.qml").is_file()
    assert (first / "modules/calendar/Content.qml").is_file()
    assert (first / "BUILD.json").is_file()

    subprocess.run([str(repo / "caelestia/bin/build-runtime.sh")], cwd=repo, env=env, check=True)
    second = (runtime / "current").resolve()
    assert second != first and (runtime / "previous").resolve() == first

    subprocess.run([str(repo / "caelestia/bin/rollback-runtime.sh")], cwd=repo, env=env, check=True)
    assert (runtime / "current").resolve() == first
    assert (runtime / "previous").resolve() == second
print("PASS: clean upstream -> staged Cortetsu generations -> atomic rollback")
