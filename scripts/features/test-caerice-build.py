#!/usr/bin/env python3
"""E2E gate: legacy runtime -> two Cortetsu generations -> safe rollback."""
from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
upstream = Path(
    os.environ.get(
        "CORTETSU_UPSTREAM_SOURCE",
        os.environ.get(
            "CAERICE_UPSTREAM_SOURCE",
            str(Path.home() / ".local/share/caelestia-custom-system/upstream-git"),
        ),
    )
)

with tempfile.TemporaryDirectory(prefix="cortetsu-e2e-") as temporary:
    root = Path(temporary)
    data = root / "data"
    runtime = root / "runtime"
    legacy = root / "legacy-runtime"
    runtime.mkdir()
    legacy.mkdir()
    (legacy / "shell.qml").write_text("// legacy runtime without BUILD.json\n", encoding="utf-8")
    (runtime / "current").symlink_to(legacy, target_is_directory=True)

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
    assert first != legacy
    assert (first / "shell.qml").is_file()
    assert (first / "modules/calendar/Content.qml").is_file()
    assert (first / "BUILD.json").is_file()
    assert not (runtime / "previous").exists()
    assert (runtime / "legacy-previous").resolve() == legacy

    # Reproduce the exact migration edge case seen on an existing installation:
    # current is managed, but previous still points to a pre-BUILD.json runtime.
    (runtime / "previous").symlink_to(legacy, target_is_directory=True)
    subprocess.run([str(cli), "verify"], cwd=repo, env=env, check=True)

    subprocess.run([str(build)], cwd=repo, env=env, check=True)
    second = (runtime / "current").resolve()
    assert second != first
    assert (runtime / "previous").resolve() == first
    assert (runtime / "legacy-previous").resolve() == legacy

    subprocess.run([str(cli), "verify"], cwd=repo, env=env, check=True)
    subprocess.run([str(rollback)], cwd=repo, env=env, check=True)
    assert (runtime / "current").resolve() == first
    assert (runtime / "previous").resolve() == second
    assert (runtime / "legacy-previous").resolve() == legacy

print("PASS: legacy runtime quarantined, managed generations verified, and rollback stayed safe")
