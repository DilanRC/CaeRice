#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import tomllib
from pathlib import Path

repo = Path(__file__).resolve().parents[2]

subprocess.run(["python3", str(repo / "core/theme.py"), "check", "--repo", str(repo)], check=True)

kitty = (repo / "dotfiles/imported/desktop/home/.config/kitty/kitty.conf").read_text(encoding="utf-8")
assert "include cortetsu-theme.conf" in kitty
assert "state/caelestia/theme" not in kitty
assert "kitty-caerice" not in kitty
assert "include caelestia-theme.conf" not in kitty

with (repo / "dotfiles/manifest.toml").open("rb") as handle:
    manifest = tomllib.load(handle)
entries = {entry["target"]: entry for entry in manifest["entry"]}
assert entries[".config/kitty/cortetsu-theme.conf"]["source"].startswith("dotfiles/generated/theme/")
assert entries[".config/gtk-3.0/cortetsu-colors.css"]["source"].startswith("dotfiles/generated/theme/")
assert entries[".config/gtk-4.0/cortetsu-colors.css"]["source"].startswith("dotfiles/generated/theme/")
assert entries[".config/kdeglobals"]["source"].startswith("dotfiles/generated/theme/")

for relative in (
    "dotfiles/imported/desktop/home/.config/gtk-3.0/gtk.css",
    "dotfiles/imported/desktop/home/.config/gtk-4.0/gtk.css",
):
    text = (repo / relative).read_text(encoding="utf-8")
    assert text.startswith('@import "cortetsu-colors.css";')
    assert "@define-color accent_color #c6c6c6" not in text

for relative in (
    "dotfiles/imported/desktop/home/.config/gtk-3.0/thunar.css",
    "dotfiles/imported/desktop/home/.config/gtk-4.0/thunar.css",
):
    text = (repo / relative).read_text(encoding="utf-8")
    assert "@accent_color" in text
    assert "#c6c6c6" not in text
    assert "#0e0e0e" not in text

kde = (repo / "dotfiles/generated/theme/home/.config/kdeglobals").read_text(encoding="utf-8")
assert "ColorScheme=Cortetsu" in kde
assert "Name=Cortetsu" in kde
assert "Caelestia" not in kde

design = (repo / "caelestia/modules-owned/modules/CortetsuDesign.js").read_text(encoding="utf-8")
assert 'var colorSumi = "#0B0D10"' in design
assert 'var colorVermillion = "#D64B32"' in design
assert "var motionFastMs = 100" in design

install = (repo / "scripts/install-cortetsu.sh").read_text(encoding="utf-8")
assert "core/theme.py\" check" in install
assert "core/theme.py\" adopt" in install
assert "install-theme-bridge.py" not in install

print("PASS: ui.toml owns Cortetsu shell/Kitty/GTK/KDE theme outputs without active Caelestia desktop mutation")
