import json
import os
import subprocess
import tempfile
from pathlib import Path

script = Path(__file__).resolve().parents[2] / "cortetsu/bin/cortetsu-scheme"
with tempfile.TemporaryDirectory() as directory:
    env = {**os.environ, "XDG_STATE_HOME": directory}
    subprocess.run([str(script), "set", "-v", "expressive"], env=env, check=True)
    result = subprocess.run([str(script), "get", "-nfv"], env=env, check=True, text=True, capture_output=True)
    assert result.stdout.splitlines() == ["dynamic", "default", "expressive"]
    listed = subprocess.run([str(script), "list"], env=env, check=True, text=True, capture_output=True)
    assert json.loads(listed.stdout)["dynamic"]["default"] == {}
print("PASS: Cortetsu scheme state is first-party and XDG-scoped")
