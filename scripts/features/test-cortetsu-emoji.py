"""Regression: the emoji keybind and CLI are first-party, not `caelestia emoji`.

Before this fix, kbEmoji shelled out to the caelestia pip package's picker
(reading a data file bundled inside caelestia's own site-packages dir). This
proves cortetsu-emoji is real, wired into `cortetsu emoji`, has its own data
file, and that no active keybind still calls `caelestia emoji`.
"""
import subprocess
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
cli = repo / "scripts/cortetsu"
emoji_bin = repo / "cortetsu/bin/cortetsu-emoji"
data = repo / "cortetsu/data/emojis.txt"
keybinds = (repo / "dotfiles/home/.config/hypr/hyprland/keybinds.lua").read_text(encoding="utf-8")
cli_text = cli.read_text(encoding="utf-8")

assert emoji_bin.is_file(), "cortetsu/bin/cortetsu-emoji is missing"
assert data.is_file() and data.stat().st_size > 0, "cortetsu/data/emojis.txt is missing or empty"
assert "emoji_cmd()" in cli_text
assert "cortetsu-emoji" in cli_text
assert "cortetsu emoji -p" in keybinds
assert "caelestia emoji" not in keybinds

# The CLI wrapper rejects unknown flags the same way screenshot/record do.
result = subprocess.run(["bash", str(cli), "emoji", "--bad"], text=True, capture_output=True)
assert result.returncode != 0 and "opción de emoji desconocida" in result.stderr

# The binary itself: dump mode prints the local data file untouched.
result = subprocess.run(
    ["python3", str(emoji_bin)], text=True, capture_output=True,
    env={"CORTETSU_EMOJI_DATA": str(data), "PATH": "/usr/bin:/bin"},
)
assert result.returncode == 0
assert result.stdout == data.read_text(encoding="utf-8")

print("PASS: emoji keybind and CLI are first-party; no caelestia caller remains")
