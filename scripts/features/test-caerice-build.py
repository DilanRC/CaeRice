#!/usr/bin/env python3
"""E2E gate: clean upstream tag -> staged CaeRice build -> final runtime."""
import os
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
upstream = Path(os.environ.get("CAERICE_UPSTREAM_SOURCE", str(Path.home() / ".local/share/caelestia-custom-system/upstream-git")))
with tempfile.TemporaryDirectory(prefix="caerice-e2e-") as tmp:
    root = Path(tmp)
    data, runtime, package = root / "data", root / "runtime", root / "package"
    package.mkdir()
    env = os.environ.copy()
    env.update(CAERICE_DATA_ROOT=str(data), CAERICE_RUNTIME_ROOT=str(runtime), CAERICE_PACKAGE_ROOT=str(package), CAERICE_UPSTREAM_SOURCE=str(upstream))
    subprocess.run([str(repo / "caelestia/bin/build-runtime.sh")], cwd=repo, env=env, check=True, stdout=subprocess.DEVNULL)
    current = runtime / "current"
    assert current.is_symlink() and (current / "shell.qml").is_file()
    assert (current / "compatibility.json").is_file()
    assert (current / "modules/calendar/Content.qml").is_file()
print("PASS: clean upstream -> staged CaeRice -> isolated runtime")
