#!/usr/bin/env python3
"""Regression guard for caerice-gaming-profile's canonical_appid().

Real gap this closes: appid was `str(appid)` with no validation, so
"123" and "00123" were two distinct JSON keys / two distinct profiles for
the same Steam game, and an unvalidated string reached
`steam -applaunch <appid>` verbatim. Runs the real binary under a
temporary $HOME so nothing here touches the user's actual gaming profiles.

Deliberately does NOT exercise the `open` subcommand: it calls the real
system `steam` binary via subprocess.Popen regardless of $HOME (steam.sh
resolves its own install path independently of the sandboxed HOME), so a
test run would launch the user's actual Steam client - confirmed the hard
way while QA'ing this fix. `get`/`set`/`delete` already exercise
canonical_appid() on every code path that matters (it runs once, centrally,
before any subcommand branches - see main()).
"""
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BIN = REPO / "caelestia/bin/caerice-gaming-profile"


def run(home: Path, *args: str) -> subprocess.CompletedProcess[str]:
    env = {**os.environ, "HOME": str(home)}
    return subprocess.run(
        [sys.executable, str(BIN), *args],
        env=env, text=True, capture_output=True, timeout=15, check=False,
    )


with tempfile.TemporaryDirectory() as tmp:
    home = Path(tmp)

    # --- valid appids -------------------------------------------------
    cp = run(home, "get", "--appid", "123")
    assert cp.returncode == 0, cp.stdout + cp.stderr
    assert json.loads(cp.stdout)["profile"]["appid"] == "123"

    cp = run(home, "get", "--appid", "00123")
    assert cp.returncode == 0, cp.stdout + cp.stderr
    body = json.loads(cp.stdout)
    assert body["profile"]["appid"] == "123", f"leading zeros not canonicalized: {body}"

    # --- invalid appids: exit != 0, valid JSON, ok:false, appid-related error
    invalid = ["", "abc", "-1", "+123", "1.5", " 123", "123 ", "１２３", "0", "4294967296"]
    for bad in invalid:
        cp = run(home, "get", "--appid", bad)
        assert cp.returncode != 0, f"{bad!r} should fail, got exit 0: {cp.stdout}"
        body = json.loads(cp.stdout)
        assert body.get("ok") is False, f"{bad!r}: {body}"
        assert "appid" in body.get("error", "").lower(), f"{bad!r}: {body}"

    # --- boundary: exactly uint32 max must be accepted -----------------
    cp = run(home, "get", "--appid", "4294967295")
    assert cp.returncode == 0, cp.stdout + cp.stderr
    assert json.loads(cp.stdout)["profile"]["appid"] == "4294967295"

    # --- set: canonicalization must land in persisted storage ----------
    cp = run(home, "set", "--appid", "00456", "--name", "Test Game", "--json", '{"fps_cap": 60}')
    assert cp.returncode == 0, cp.stdout + cp.stderr
    config = json.loads((home / ".config/caerice/gaming-profiles.json").read_text())
    assert list(config["profiles"].keys()) == ["456"], config["profiles"]
    assert "00456" not in config["profiles"]
    assert config["profiles"]["456"]["appid"] == "456"

    # Re-saving under the un-padded form must hit the *same* key, not a
    # second profile for the same game.
    cp = run(home, "set", "--appid", "456", "--name", "Test Game", "--json", '{"fps_cap": 120}')
    assert cp.returncode == 0, cp.stdout + cp.stderr
    config = json.loads((home / ".config/caerice/gaming-profiles.json").read_text())
    assert list(config["profiles"].keys()) == ["456"], config["profiles"]
    assert config["profiles"]["456"]["fps_cap"] == 120

    # --- delete: also canonicalizes before touching storage ------------
    cp = run(home, "delete", "--appid", "00456")
    assert cp.returncode == 0, cp.stdout + cp.stderr
    assert json.loads(cp.stdout)["deleted"] is True
    config = json.loads((home / ".config/caerice/gaming-profiles.json").read_text())
    assert config["profiles"] == {}, config["profiles"]

    # --- list is exempt (no --appid argument exists for it) ------------
    cp = run(home, "list")
    assert cp.returncode == 0, cp.stdout + cp.stderr

print(
    "test-gaming-appid: OK "
    f"(2 valid forms canonicalized, {len(invalid)} invalid appids rejected, "
    "boundary accepted, set/delete persistence canonicalized, no duplicate key)"
)
