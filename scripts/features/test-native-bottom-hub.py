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
workspace_component_path = repo / "caelestia/modules-owned/modules/CortetsuWorkspaceDots.qml"

spec = importlib.util.spec_from_file_location("native_bottom_hub", compiler_path)
assert spec and spec.loader
compiler = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compiler)


def digest(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def assert_workspace_component(text: str) -> None:
    assert 'import "CortetsuDesign.js" as CortetsuDesign' in text
    assert "required property int workspaceCount" in text
    assert "required property int workspaceOffset" in text
    assert "required property int activeWsId" in text
    assert text.count("CortetsuDesign.motionStandardMs") >= 2
    assert "CortetsuDesign.colorIndigo" in text
    assert "CortetsuDesign.colorMuted" in text
    assert "Hypr.dispatch(" in text
    assert "Colours." not in text
    assert "Tokens." not in text
    assert "StyledRect" not in text
    assert "Caelestia.Config" not in text


def assert_runtime(text: str) -> None:
    compiler.validate(text)
    assert "Colours." not in text
    assert "CortetsuDesign.colorTetsu" in text
    assert "CortetsuDesign.colorIndigo" in text
    assert "CortetsuDesign.colorVermillion" in text
    assert "CortetsuDesign.colorWashi" in text
    assert "CortetsuDesign.colorMuted" in text
    assert text.count("CortetsuSurface {") >= 4
    assert text.count("CortetsuWorkspaceDots {") == 1
    assert "id: workspaceDot\n" not in text
    assert "scale: appMouse.containsMouse ? CortetsuDesign.hoverScale : 1" in text
    assert "duration: CortetsuDesign.motionFastMs" in text


parser = argparse.ArgumentParser()
parser.add_argument("--runtime", type=Path)
args = parser.parse_args()

workspace_source = workspace_component_path.read_text(encoding="utf-8")
assert_workspace_component(workspace_source)

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

    runtime_workspace = args.runtime.with_name("CortetsuWorkspaceDots.qml")
    assert runtime_workspace.is_file(), "runtime did not include CortetsuWorkspaceDots.qml"
    assert_workspace_component(runtime_workspace.read_text(encoding="utf-8"))

print("PASS: Bottom Hub delegates workspace presentation to a Cortetsu first-party component without touching controllers")
