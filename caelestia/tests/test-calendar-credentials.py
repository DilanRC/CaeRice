#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import json
import tempfile
from pathlib import Path
import subprocess

helper_path = Path(__file__).parents[1] / "bin/caerice-calendar"
loader = importlib.machinery.SourceFileLoader("calendar_helper", str(helper_path))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

client, error = module.normalize_client({"installed": {"client_id": "test-client", "client_secret": "test-secret"}})
assert error is None and client["client_id"] == "test-client"
client, error = module.normalize_client({"client_id": "flat-client"})
assert error is None and client["client_id"] == "flat-client"
for raw in ({}, {"installed": {}}, {"web": {"client_id": "web-client"}}):
    client, error = module.normalize_client(raw)
    assert client is None and error == "credential_error"
with tempfile.TemporaryDirectory() as directory:
    missing = Path(directory) / "missing.json"
    assert not missing.exists()
    assert not module.load_json(missing, {})
    client_file = Path(directory) / "caelestia" / "calendar-client.json"
    client_file.parent.mkdir()
    client_file.write_text(json.dumps({"installed": {"client_secret": "DO-NOT-PRINT"}}))
    result = subprocess.run([str(Path(__file__).parents[1] / "bin/caerice-calendar"), "sync"], env={**__import__("os").environ, "XDG_CONFIG_HOME": directory}, capture_output=True, text=True)
    assert result.returncode == 2 and "credential_error" in result.stdout
    assert "DO-NOT-PRINT" not in result.stdout + result.stderr
print("PASS: desktop and flat credential normalization; invalid structures rejected")
