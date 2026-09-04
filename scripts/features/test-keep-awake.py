#!/usr/bin/env python3
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
unit = repo / "config/systemd/user/cortetsu-keep-awake.service"
installer = repo / "scripts/install-cortetsu.sh"

unit_text = unit.read_text(encoding="utf-8")
installer_text = installer.read_text(encoding="utf-8")

assert "systemd-inhibit" in unit_text
assert "--what=idle:sleep" in unit_text
assert "--mode=block" in unit_text
assert "/usr/bin/sleep infinity" in unit_text
assert "cortetsu-keep-awake.service" in installer_text
assert 'systemctl --user enable --now "$KEEP_AWAKE_UNIT"' in installer_text
assert "pkill" not in unit_text and "killpg" not in unit_text
print("PASS: keep-awake unit and installer persistence")
