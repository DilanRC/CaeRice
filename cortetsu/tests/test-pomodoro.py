#!/usr/bin/env python3
from __future__ import annotations

import fcntl
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
from importlib.machinery import SourceFileLoader
from pathlib import Path

helper = Path(__file__).resolve().parents[2] / "cortetsu/bin/cortetsu-pomodoro"
spec = importlib.util.spec_from_loader("pomodoro", SourceFileLoader("pomodoro", str(helper)))
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory() as directory:
    state_path = Path(directory) / "cortetsu/pomodoro.json"
    module.path = lambda: state_path
    state = module.load()
    assert state["phase"] == "IDLE" and state["schema"] == 2

    now = 1000.0
    state = {**module.DEFAULT, "phase": "FOCUS", "targetEndTimestamp": now - 1, "completedSessions": 0}
    state = module.advance(state, now)
    assert state["phase"] == "BREAK" and state["completedSessions"] == 1

    state = {**module.DEFAULT, "phase": "FOCUS", "targetEndTimestamp": now - 1, "completedSessions": 3}
    state = module.advance(state, now)
    assert state["phase"] == "LONG_BREAK" and state["completedSessions"] == 4
    assert state["targetEndTimestamp"] == now + state["longBreakMinutes"] * 60
    assert module.notification_for_transition("FOCUS", "LONG_BREAK") == (
        "Focus cycle complete", "Time for a long break"
    )

    state["targetEndTimestamp"] = now - 1
    state = module.advance(state, now)
    assert state["phase"] == "FOCUS"
    state = module.apply_command(state, "pause", now)
    assert state["phase"] == "PAUSED" and state["pausedPhase"] == "FOCUS"
    remaining = state["pausedRemainingMs"]
    state = module.apply_command(state, "resume", now)
    assert state["phase"] == "FOCUS" and state["targetEndTimestamp"] == now + remaining / 1000

    state = {**module.DEFAULT, "phase": "LONG_BREAK", "targetEndTimestamp": now + 30}
    assert module.apply_command(state, "skip", now)["phase"] == "FOCUS"
    module.save(state)
    assert module.load()["phase"] == "LONG_BREAK"
    module.write_event("Title", "Message")
    assert module.event_path().is_file()
    assert json.loads(module.event_path().read_text(encoding="utf-8"))["title"] == "Title"
    module.event_path().unlink()
    module.ensure_event_file()
    assert module.event_path().read_text(encoding="utf-8").strip() == '{"sequence": 0}'

    daemon_lock = module.daemon_lock_path()
    daemon_lock.parent.mkdir(parents=True, exist_ok=True)
    with daemon_lock.open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        result = subprocess.run(
            [sys.executable, str(helper), "daemon"],
            env={**os.environ, "XDG_STATE_HOME": directory},
            timeout=2,
            check=False,
        )
        assert result.returncode == 0

print("PASS: Pomodoro short/long breaks, pause/resume, canonical state, notifications, and singleton daemon")
