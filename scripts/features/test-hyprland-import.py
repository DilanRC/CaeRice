#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "core/import_hyprland.py"


def run(*args: str, cwd: Path, check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=check)


with tempfile.TemporaryDirectory(prefix="cortetsu-hypr-import-test-") as tmp:
    root = Path(tmp)
    repo = root / "repo"
    home = root / "home"
    active = home / ".config/hypr/hyprland"
    (repo / "dotfiles").mkdir(parents=True)
    active.mkdir(parents=True)

    (repo / "dotfiles/manifest.toml").write_text(
        'schema = 1\n\n[defaults]\nprofile = "personal"\n', encoding="utf-8"
    )
    (active / "execs.lua").write_text('hl.exec_cmd("systemctl --user start cortetsu-shell.service")\n', encoding="utf-8")
    (active / "keybinds.lua").write_text('create_bind("SUPER + RETURN", terminal)\n', encoding="utf-8")
    (active / "keybinds.lua.bak").write_text('caelestia shell -d\n', encoding="utf-8")
    (active / "blob.bin").write_bytes(b"a\0b")
    os.symlink("execs.lua", active / "linked.lua")

    run("git", "init", cwd=repo, check=True)
    run("git", "config", "user.name", "Cortetsu Test", cwd=repo, check=True)
    run("git", "config", "user.email", "test@example.invalid", cwd=repo, check=True)
    run("git", "add", ".", cwd=repo, check=True)
    run("git", "commit", "-m", "base", cwd=repo, check=True)

    plan = run("python3", str(SCRIPT), "plan", "--repo", str(repo), "--home", str(home), cwd=REPO)
    assert plan.returncode == 0, plan.stdout
    assert "import       execs.lua" in plan.stdout
    assert "import       keybinds.lua" in plan.stdout
    assert "keybinds.lua.bak [backup/temp]" in plan.stdout
    assert "blob.bin [binary]" in plan.stdout
    assert "linked.lua [symlink]" in plan.stdout

    applied = run(
        "python3", str(SCRIPT), "apply", "--commit", "--repo", str(repo), "--home", str(home), cwd=REPO
    )
    assert applied.returncode == 0, applied.stdout
    imported = repo / "dotfiles/home/.config/hypr/hyprland"
    assert (imported / "execs.lua").is_file()
    assert (imported / "keybinds.lua").is_file()
    assert not (imported / "keybinds.lua.bak").exists()
    manifest = (repo / "dotfiles/manifest.toml").read_text(encoding="utf-8")
    assert "# BEGIN CORTETSU HYPRLAND IMPORT" in manifest
    assert '.config/hypr/hyprland/execs.lua' in manifest
    assert '.config/hypr/hyprland/keybinds.lua' in manifest
    assert "keybinds.lua.bak" not in manifest
    assert run("git", "status", "--porcelain", cwd=repo).stdout.strip() == ""

    before = run("git", "rev-parse", "HEAD", cwd=repo, check=True).stdout.strip()
    (active / "secret.lua").write_text('api_key = "do-not-import"\n', encoding="utf-8")
    blocked_plan = run("python3", str(SCRIPT), "plan", "--repo", str(repo), "--home", str(home), cwd=REPO)
    assert blocked_plan.returncode == 2
    assert "BLOCKED" in blocked_plan.stdout and "secret.lua" in blocked_plan.stdout
    blocked_apply = run("python3", str(SCRIPT), "apply", "--repo", str(repo), "--home", str(home), cwd=REPO)
    assert blocked_apply.returncode == 1
    assert "posibles secretos" in blocked_apply.stdout
    after = run("git", "rev-parse", "HEAD", cwd=repo, check=True).stdout.strip()
    assert before == after
    assert not (imported / "secret.lua").exists()

print("PASS: Hyprland importer is deterministic, backup-aware, secret-safe, and commit-scoped")
