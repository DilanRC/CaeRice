#!/usr/bin/env python3
"""E2E gate: unmanaged runtime -> two Cortetsu generations -> safe rollback."""
from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
upstream = Path(
    os.environ.get(
        "CORTETSU_UPSTREAM_SOURCE",
        str(Path.home() / ".local/share/cortetsu/upstream/upstream-git"),
    )
)

with tempfile.TemporaryDirectory(prefix="cortetsu-e2e-") as temporary:
    root = Path(temporary)
    data = root / "data"
    runtime = root / "runtime"
    unmanaged = root / "unmanaged-runtime"
    runtime.mkdir()
    unmanaged.mkdir()
    (unmanaged / "shell.qml").write_text("// pre-v2 runtime without BUILD.json\n", encoding="utf-8")
    (runtime / "current").symlink_to(unmanaged, target_is_directory=True)

    env = os.environ.copy()
    env.update(
        CORTETSU_DATA_ROOT=str(data),
        CORTETSU_RUNTIME_ROOT=str(runtime),
        CORTETSU_UPSTREAM_SOURCE=str(upstream),
    )

    build = repo / "caelestia/bin/build-runtime.sh"
    rollback = repo / "caelestia/bin/rollback-runtime.sh"
    cli = repo / "scripts/cortetsu"

    subprocess.run([str(build)], cwd=repo, env=env, check=True)
    first = (runtime / "current").resolve()
    assert first != unmanaged
    assert (first / "shell.qml").is_file()
    assert (first / "modules/calendar/Content.qml").is_file()
    assert (first / "BUILD.json").is_file()
    assert not (runtime / "previous").exists()
    assert (runtime / "legacy-previous").resolve() == unmanaged

    # Reproduce an upgrade edge case: current is managed while previous still
    # points at an unmanaged pre-v2 generation. Verification must quarantine it.
    (runtime / "previous").symlink_to(unmanaged, target_is_directory=True)
    subprocess.run([str(cli), "verify"], cwd=repo, env=env, check=True)

    subprocess.run([str(build)], cwd=repo, env=env, check=True)
    second = (runtime / "current").resolve()
    assert second != first
    assert (runtime / "previous").resolve() == first
    assert (runtime / "legacy-previous").resolve() == unmanaged

    subprocess.run([str(cli), "verify"], cwd=repo, env=env, check=True)
    subprocess.run([str(rollback)], cwd=repo, env=env, check=True)
    assert (runtime / "current").resolve() == first
    assert (runtime / "previous").resolve() == second
    assert (runtime / "legacy-previous").resolve() == unmanaged

print("PASS: unmanaged runtime quarantined, managed generations verified, and rollback stayed safe")
