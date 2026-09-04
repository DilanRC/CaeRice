#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
compiler_path = repo / "caelestia/bin/native-bottom-hub.py"
source_path = repo / "caelestia/modules-owned/modules/BottomHub.qml"

spec = importlib.util.spec_from_file_location("native_bottom_hub", compiler_path)
assert spec and spec.loader
compiler = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compiler)


def digest(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def assert_runtime(text: str) -> None:
    compiler.validate(text)
    assert "Colours." not in text
    assert "CortetsuDesign.colorTetsu" in text
    assert "CortetsuDesign.colorIndigo" in text
    assert "CortetsuDesign.colorVermillion" in text
    assert "CortetsuDesign.colorWashi" in text
    assert "CortetsuDesign.colorMuted" in text
    assert text.count("CortetsuSurface {") >= 4
    assert "scale: appMouse.containsMouse ? CortetsuDesign.hoverScale : 1" in text
    assert "duration: CortetsuDesign.motionFastMs" in text
    assert text.count("duration: CortetsuDesign.motionStandardMs") >= 2


parser = argparse.ArgumentParser()
parser.add_argument("--runtime", type=Path)
args = parser.parse_args()

source = source_path.read_text(encoding="utf-8")
with tempfile.TemporaryDirectory(prefix="cortetsu-bottom-hub-") as temp_dir:
    candidate = Path(temp_dir) / "BottomHub.qml"
    candidate.write_text(source, encoding="utf-8")

    first = compiler.transform(candidate.read_text(encoding="utf-8"))
    assert_runtime(first)
    first_hash = digest(first)
    candidate.write_text(first, encoding="utf-8")

    second = compiler.transform(candidate.read_text(encoding="utf-8"))
    assert digest(second) == first_hash, "native Bottom Hub compiler is not idempotent"
    assert_runtime(second)

if args.runtime:
    runtime = args.runtime.read_text(encoding="utf-8")
    assert_runtime(runtime)

print("PASS: Bottom Hub compiles to Cortetsu-owned palette, surfaces and motion without touching controllers")
