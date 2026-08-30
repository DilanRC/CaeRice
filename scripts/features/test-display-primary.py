#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "config" / "hypr-user.lua"


def monitor_block(output: str) -> str:
    text = CONFIG.read_text(encoding="utf-8")
    for match in re.finditer(r"hl\.monitor\(\{.*?\}\)", text, re.S):
        block = match.group(0)
        if re.search(rf'^\s*output\s*=\s*"{re.escape(output)}"', block, re.M):
            return block
    raise AssertionError(f"missing monitor block for {output}")


def field(block: str, name: str) -> str:
    match = re.search(rf'^\s*{re.escape(name)}\s*=\s*"([^"]+)"', block, re.M)
    assert match, f"missing {name} in block:\n{block}"
    return match.group(1)


assert field(monitor_block("HDMI-A-1"), "position") == "0x0"
assert field(monitor_block("eDP-1"), "position") == "auto-right"
