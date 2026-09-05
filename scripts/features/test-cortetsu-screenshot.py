import subprocess
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
cli = repo / "scripts/cortetsu"
hypr = (repo / "config/hypr-user.lua").read_text(encoding="utf-8")
text = cli.read_text(encoding="utf-8")

assert "screenshot_cmd()" in text
assert 'ipc call picker openFreeze' in text
assert 'ipc call picker open' in text
assert "/usr/bin/caelestia" not in text
assert 'cortetsu screenshot -r -f' in hypr
assert "caelestia screenshot" not in hypr
result = subprocess.run(["bash", str(cli), "screenshot", "--bad"], text=True, capture_output=True)
assert result.returncode != 0 and "opción de screenshot desconocida" in result.stderr
print("PASS: screenshot keybind targets the Cortetsu runtime IPC")
