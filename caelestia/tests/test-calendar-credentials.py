#!/usr/bin/env python3
from __future__ import annotations

import importlib.machinery
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

helper_path = Path(__file__).resolve().parents[1] / "bin/cortetsu-calendar"
loader = importlib.machinery.SourceFileLoader("calendar_helper", str(helper_path))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

client, error = module.normalize_client({"installed": {"client_id": "test-client", "client_secret": "test-secret"}})
assert error is None and client["client_id"] == "test-client"
client, error = module.normalize_client({"client_id": "flat-client"})
assert error is None and client["client_id"] == "flat-client"
for raw in ({}, {"installed": {}}, {"web": {"client_id": "web-client"}}):
    client, error = module.normalize_client(raw)
    assert client is None and error == "credential_error"

assert module.parse_callback_query("state=expected&code=ok", "expected") == ("ok", None)
assert module.parse_callback_query("state=wrong&code=ok", "expected") == (None, "oauth_state_mismatch")
assert module.parse_callback_query("state=expected&error=access_denied", "expected") == (None, "oauth_denied")
assert module.parse_callback_query("state=expected", "expected") == (None, "oauth_code_missing")

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    cache = root / "calendar-events.json"
    cache.write_text(json.dumps({"fetchedAt": time.time()}), encoding="utf-8")
    assert module.cache_is_fresh(cache)
    cache.write_text(json.dumps({"fetchedAt": time.time() - module.STALE_SECONDS - 1}), encoding="utf-8")
    assert not module.cache_is_fresh(cache)

    old_tz = os.environ.get("TZ")
    os.environ["TZ"] = "America/Costa_Rica"
    assert module.local_timezone_name() == "America/Costa_Rica"
    if old_tz is None:
        os.environ.pop("TZ", None)
    else:
        os.environ["TZ"] = old_tz

    config_home = root / "config"
    cache_home = root / "cache"
    client_file = config_home / "caelestia/calendar-client.json"
    client_file.parent.mkdir(parents=True)
    client_file.write_text(json.dumps({"installed": {"client_secret": "DO-NOT-PRINT"}}), encoding="utf-8")
    result = subprocess.run(
        [sys.executable, str(helper_path), "sync"],
        env={**os.environ, "XDG_CONFIG_HOME": str(config_home), "XDG_CACHE_HOME": str(cache_home)},
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 2 and "credential_error" in result.stdout
    assert "DO-NOT-PRINT" not in result.stdout + result.stderr

    client_file.write_text(json.dumps({"installed": {"client_id": "valid-client"}}), encoding="utf-8")
    result = subprocess.run(
        [sys.executable, str(helper_path), "sync"],
        env={**os.environ, "PATH": "", "XDG_CONFIG_HOME": str(config_home), "XDG_CACHE_HOME": str(cache_home)},
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 3 and "secret_service_unavailable" in result.stdout

print("PASS: Calendar credentials, OAuth state, cache freshness, timezone, and secret errors")
