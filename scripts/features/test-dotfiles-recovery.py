#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
DOTFILES = REPO / "core/dotfiles.py"


def run(env: dict[str, str], *args: str) -> str:
    result = subprocess.run(
        ["python3", str(DOTFILES), *args, "--repo", str(REPO)],
        cwd=REPO,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=True,
    )
    return result.stdout


with tempfile.TemporaryDirectory(prefix="cortetsu-dotfiles-recovery-") as tmp:
    root = Path(tmp)
    home = root / "home"
    data = home / ".local/share/cortetsu"
    home.mkdir(parents=True)
    env = os.environ.copy()
    env.update(HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"), CORTETSU_DATA_ROOT=str(data))

    run(env, "apply")
    current = (data / "dotfiles/current").resolve(strict=True)
    (current / "home/.config/cortetsu/ui.toml").write_text("corrupted=true\n", encoding="utf-8")

    recovered = run(env, "apply")
    new_current = (data / "dotfiles/current").resolve(strict=True)
    assert new_current != current
    assert "QUARANTINED invalid=" in recovered
    assert not current.exists()
    invalid = list((data / "dotfiles/invalid").iterdir())
    assert invalid and (invalid[0] / "home/.config/cortetsu/ui.toml").read_text(encoding="utf-8") == "corrupted=true\n"
    run(env, "verify")

print("PASS: invalid dotfiles generations are quarantined and recovered idempotently")
