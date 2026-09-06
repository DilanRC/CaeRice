#!/usr/bin/env python3
"""Create a fresh, non-live Wallpaper Manager update stage."""
from __future__ import annotations

import runpy
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.argv[0] = str(HERE / "install-wallpaper-manager.py")
runpy.run_path(sys.argv[0], run_name="__main__")
