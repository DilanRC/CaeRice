#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
IMPORTER = REPO / "core/import_fish.py"


def run(home: Path, repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["HOME"] = str(home)
    return subprocess.run(
        ["python3", str(IMPORTER), *args, "--repo", str(repo), "--home", str(home)],
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=check,
    )


with tempfile.TemporaryDirectory(prefix="cortetsu-fish-import-test-") as tmp:
    root = Path(tmp)
    home = root / "home"
    repo = root / "repo"
    fish = home / ".config/fish"
    fish.mkdir(parents=True)
    (fish / "conf.d").mkdir()
    (fish / "functions").mkdir()

    (fish / "config.fish").write_text("set -gx EDITOR nvim\n", encoding="utf-8")
    (fish / "conf.d/10-env.fish").write_text("set -gx PAGER less\n", encoding="utf-8")
    (fish / "functions/cproj.fish").write_text("function cproj\n  cd ~/Code\nend\n", encoding="utf-8")
    (fish / "fish_plugins").write_text("jorgebucaran/fisher\n", encoding="utf-8")
    (fish / "fish_variables").write_text("SETUVAR fish_color_command:blue\n", encoding="utf-8")
    (fish / "old.bak").write_text("ignored\n", encoding="utf-8")

    (repo / "dotfiles").mkdir(parents=True)
    (repo / "dotfiles/manifest.toml").write_text(
        'schema = 1\n\n[defaults]\nprofile = "personal"\n',
        encoding="utf-8",
    )
    subprocess.run(["git", "init", "-q", str(repo)], check=True)
    subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
    subprocess.run(["git", "-C", str(repo), "config", "user.name", "Cortetsu Test"], check=True)
    subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
    subprocess.run(["git", "-C", str(repo), "commit", "-qm", "initial"], check=True)

    unrelated = repo / "UNRELATED"
    unrelated.write_text("keep me out of staged import\n", encoding="utf-8")

    plan = run(home, repo, "plan")
    assert ".config/fish/config.fish" in plan.stdout
    assert ".config/fish/conf.d/10-env.fish" in plan.stdout
    assert ".config/fish/functions/cproj.fish" in plan.stdout
    assert ".config/fish/fish_plugins" in plan.stdout
    assert "fish_variables" in plan.stdout and "state/backup/temp" in plan.stdout
    assert "old.bak" in plan.stdout

    first = run(home, repo, "apply", "--commit")
    assert "COMMIT created=Fish import" in first.stdout
    manifest = (repo / "dotfiles/manifest.toml").read_text(encoding="utf-8")
    assert "# BEGIN CORTETSU FISH IMPORT" in manifest
    assert 'target = ".config/fish/config.fish"' in manifest
    assert 'tags = ["user-shell"]' in manifest
    assert "fish_variables" not in manifest
    assert not subprocess.check_output(["git", "-C", str(repo), "show", "--name-only", "--format="], text=True).strip().endswith("UNRELATED")
    assert unrelated.exists()

    # Re-import is deterministic and removes files that disappeared from live Fish config.
    (fish / "functions/cproj.fish").unlink()
    second = run(home, repo, "apply", "--commit")
    assert "COMMIT created=Fish import" in second.stdout
    assert not (repo / "dotfiles/imported/fish/home/.config/fish/functions/cproj.fish").exists()

    # Potential secrets block apply rather than entering the repository.
    (fish / "conf.d/99-secret.fish").write_text("set -gx API_KEY=super-secret\n", encoding="utf-8")
    blocked = run(home, repo, "apply", check=False)
    assert blocked.returncode == 2
    assert "posibles secretos" in blocked.stdout

print("PASS: Fish importer snapshots ~/.config/fish, skips mutable state/backups, blocks secrets and isolates git staging")
