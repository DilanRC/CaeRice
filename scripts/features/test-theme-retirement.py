#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
HELPER = REPO / "scripts/maintenance/retire_legacy_theme.py"

with tempfile.TemporaryDirectory(prefix="cortetsu-retire-theme-test-") as tmp:
    root = Path(tmp)
    home = root / "home"
    data = home / ".local/share/cortetsu"
    home.mkdir(parents=True)

    generated = root / "old-caelestia-theme.conf"
    generated.write_text("background #000000\n", encoding="utf-8")

    kitty = home / ".config/kitty/caelestia-theme.conf"
    kitty.parent.mkdir(parents=True)
    kitty.symlink_to(generated)

    template = home / ".config/caelestia/templates/kitty-cortetsu.conf"
    template.parent.mkdir(parents=True)
    template.write_text("legacy template\n", encoding="utf-8")

    state = home / ".local/state/caelestia/theme/kitty-cortetsu.conf"
    state.parent.mkdir(parents=True)
    state.write_text("legacy state\n", encoding="utf-8")

    env = os.environ.copy()
    env["HOME"] = str(home)
    env["CORTETSU_DATA_ROOT"] = str(data)

    first = subprocess.run(
        ["python3", str(HELPER)],
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=True,
    )
    assert "retired=3" in first.stdout
    assert not kitty.exists() and not kitty.is_symlink()
    assert not template.exists()
    assert not state.exists()

    backups = list((data / "migrations").glob("*/retired-theme"))
    assert len(backups) == 1
    backup = backups[0]
    assert (backup / ".config/kitty/caelestia-theme.conf").read_text(encoding="utf-8") == "background #000000\n"
    assert (backup / ".config/caelestia/templates/kitty-cortetsu.conf").read_text(encoding="utf-8") == "legacy template\n"
    assert (backup / ".local/state/caelestia/theme/kitty-cortetsu.conf").read_text(encoding="utf-8") == "legacy state\n"

    second = subprocess.run(
        ["python3", str(HELPER)],
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=True,
    )
    assert "already retired" in second.stdout

print("PASS: inert Caelestia Kitty artifacts retire with backup and remain idempotent")
