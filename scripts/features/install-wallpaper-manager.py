#!/usr/bin/env python3
"""Stage or explicitly deploy Wallpaper Manager; default mode never touches live state."""
from __future__ import annotations

import argparse
from datetime import datetime
import importlib.util
import json
import os
import stat
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OWNED = ROOT / "caelestia/modules-owned/modules"

V1_SERVICE_REQUIREMENTS = {
    "setRandom": ("previewGeneration += 1;", "queuedPreviewPath = \"\";", "getPreviewColoursProc.running = false;"),
    "setWallpaper": ("previewGeneration += 1;", "queuedPreviewPath = \"\";", "getPreviewColoursProc.running = false;"),
    "preview": ("previewGeneration += 1;", "queuedPreviewPath = path;", "if (getPreviewColoursProc.running)", "startLatestPreviewColours();"),
    "stopPreview": ("previewGeneration += 1;", "queuedPreviewPath = \"\";", "getPreviewColoursProc.running = false;"),
}
V1_SERVICE_GLOBALS = (
    "property int previewGeneration: 0",
    "property string queuedPreviewPath: \"\"",
    "function startLatestPreviewColours(): void",
    "getPreviewColoursProc.requestPath = queuedPreviewPath;",
    "getPreviewColoursProc.requestGeneration = previewGeneration;",
    "property int requestGeneration: -1",
    "property string requestPath: \"\"",
    "command: []",
    "onRunningChanged:",
    "if (!running && root.queuedPreviewPath)",
    "getPreviewColoursProc.requestGeneration !== root.previewGeneration",
    "getPreviewColoursProc.requestPath !== root.previewPath",
    "|| !root.showPreview",
)


def function_body(text: str, name: str) -> str:
    start = text.find(f"function {name}(")
    if start < 0:
        return ""
    open_brace = text.find("{", start)
    if open_brace < 0:
        return ""
    depth = 0
    for position in range(open_brace, len(text)):
        if text[position] == "{":
            depth += 1
        elif text[position] == "}":
            depth -= 1
            if depth == 0:
                return text[open_brace + 1:position]
    return ""


def is_complete_v1_service(text: str) -> bool:
    if not all(requirement in text for requirement in V1_SERVICE_GLOBALS):
        return False
    return all(
        all(requirement in function_body(text, name) for requirement in requirements)
        for name, requirements in V1_SERVICE_REQUIREMENTS.items()
    )


def prepare_wallpapers_service(source: Path, target: Path, patch_file: Path, patch_root: Path) -> str:
    original = source.read_text(encoding="utf-8")
    shutil.copy2(source, target)
    result = subprocess.run(
        ["patch", "--batch", "--forward", "-p1", "-d", str(patch_root)],
        input=patch_file.read_text(encoding="utf-8"), text=True, capture_output=True,
    )
    if result.returncode == 0:
        return "patched"
    shutil.copy2(source, target)
    if is_complete_v1_service(original):
        return "already-patched"
    raise RuntimeError("Wallpapers patch cannot apply and service is not a complete V1 patched state: " + result.stdout + result.stderr)

def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts/features" / f"{name}.py")
    module = importlib.util.module_from_spec(spec); assert spec and spec.loader
    spec.loader.exec_module(module); return module

def payload(stage):
    if stage.exists(): raise RuntimeError(f"refusing existing stage: {stage}")
    stage.mkdir(parents=True)
    names = ("BottomHub.qml", "HubButton.qml", "OverlayPolicy.js", "OverviewController.qml", "ClipboardController.qml", "HardwareController.qml", "DisplayController.qml", "WallpaperController.qml")
    for name in names:
        destination = stage / "modules" / name; destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(OWNED / name, destination)
    shutil.copytree(OWNED / "wallpaper", stage / "modules/wallpaper")
    (stage / "patches").mkdir()
    shutil.copy2(ROOT / "caelestia/patches/services__Wallpapers.qml.patch", stage / "patches/services__Wallpapers.qml.patch")

def missing_parent_dirs(copies):
    result = []
    seen = set()
    for _, target in copies:
        parent = target.parent
        pending = []
        while not parent.exists():
            pending.append(parent)
            parent = parent.parent
        for directory in reversed(pending):
            if directory not in seen:
                seen.add(directory)
                result.append(directory)
    return result


def snapshot(copies, backup, created_dirs):
    manifest = []
    for source, target in copies:
        item = {
            "target": str(target),
            "existed": target.exists(),
            "mode": stat.S_IMODE(target.stat().st_mode) if target.exists() else None,
            "uid": target.stat().st_uid if target.exists() else None,
            "gid": target.stat().st_gid if target.exists() else None,
        }
        if item["existed"]:
            old = backup / "files" / str(len(manifest))
            old.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, old)
            item["backup"] = str(old)
        manifest.append(item)
    data = {"files": manifest, "createdDirs": [str(directory) for directory in created_dirs]}
    (backup / "manifest.json").write_text(json.dumps(data, indent=2), encoding="utf-8")
    return data


def atomic_replace(source, target, item):
    descriptor, temporary = tempfile.mkstemp(prefix=".wallpaper-manager-", dir=target.parent)
    os.close(descriptor)
    temporary = Path(temporary)
    try:
        shutil.copy2(source, temporary)
        if item["mode"] is not None:
            os.chmod(temporary, item["mode"])
        if item["uid"] is not None and os.geteuid() == 0:
            os.chown(temporary, item["uid"], item["gid"])
        os.replace(temporary, target)
    finally:
        if temporary.exists():
            temporary.unlink()


def apply_transaction(copies, backup, replace_file=atomic_replace):
    created_dirs = missing_parent_dirs(copies)
    manifest = snapshot(copies, backup, created_dirs)
    mutation_started = False
    try:
        for directory in created_dirs:
            mutation_started = True
            directory.mkdir()
        for (source, target), item in zip(copies, manifest["files"]):
            mutation_started = True
            replace_file(source, target, item)
    except Exception as error:
        if mutation_started:
            try:
                rollback(backup)
            except Exception as rollback_error:
                raise RuntimeError(f"deployment failed and automatic rollback failed: {rollback_error}") from error
        raise


def deploy(live, usercfg, hypr_usercfg, backup_root, production, replace_file=atomic_replace):
    if live == Path("/etc/xdg/quickshell/caelestia") and not production:
        raise RuntimeError("refusing production live root without --production")
    required = [live / rel for rel in ("shell.qml", "components/ScreenState.qml", "modules/drawers/Panels.qml", "modules/drawers/ContentWindow.qml", "services/Wallpapers.qml")] + [usercfg, hypr_usercfg]
    missing = [str(path) for path in required if not path.is_file()]
    if missing: raise RuntimeError("missing exact target(s): " + ", ".join(missing))
    wire, configure = load("wire_sad_shell"), load("configure-launcher-wallpaper-actions")
    with tempfile.TemporaryDirectory(prefix="wallpaper-manager-stage-") as temp:
        temp = Path(temp); staged = temp / "payload"; payload(staged)
        texts, _ = wire.wire_all(live, hypr_usercfg, ("display", "wallpaper"))
        wired = temp / "wired"; wire.write_staged(texts, wired)
        (temp / "services").mkdir()
        prepare_wallpapers_service(
            live / "services/Wallpapers.qml",
            temp / "services/Wallpapers.qml",
            staged / "patches/services__Wallpapers.qml.patch",
            temp,
        )
        config = temp / "shell.json"; shutil.copy2(usercfg, config); configure.configure(config)
        backup = backup_root / datetime.now().strftime("wallpaper-manager-%Y%m%d-%H%M%S-%f"); backup.mkdir(parents=True)
        copies = [(wired / rel, live / rel) for rel in ("shell.qml", "components/ScreenState.qml", "modules/drawers/Panels.qml", "modules/drawers/ContentWindow.qml")]
        copies.append((wired / "user-config/hypr-user.lua", hypr_usercfg))
        copies += [(temp / "services/Wallpapers.qml", live / "services/Wallpapers.qml"), (config, usercfg)]
        copies += [(source, live / "modules" / source.relative_to(staged / "modules")) for source in (staged / "modules").rglob("*") if source.is_file()]
        apply_transaction(copies, backup, replace_file)
        return backup

def rollback(backup):
    manifest = json.loads((backup / "manifest.json").read_text())
    for item in reversed(manifest["files"]):
        target = Path(item["target"])
        if item["existed"]:
            atomic_replace(Path(item["backup"]), target, item)
        elif target.exists(): target.unlink()
    for directory in reversed(manifest["createdDirs"]):
        path = Path(directory)
        if path.exists(): path.rmdir()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stage", type=Path); parser.add_argument("--apply", action="store_true"); parser.add_argument("--rollback", type=Path)
    parser.add_argument("--live", type=Path, default=Path("/etc/xdg/quickshell/caelestia")); parser.add_argument("--usercfg", type=Path, default=Path.home() / ".config/caelestia/shell.json")
    parser.add_argument("--hypr-usercfg", type=Path, default=Path.home() / ".config/caelestia/hypr-user.lua")
    parser.add_argument("--backup-root", type=Path); parser.add_argument("--production", action="store_true")
    args = parser.parse_args()
    if args.rollback: rollback(args.rollback); print(f"ROLLED_BACK {args.rollback}"); return 0
    if args.stage and not args.apply: payload(args.stage); print(f"STAGED {args.stage}"); return 0
    if not args.apply or not args.backup_root: parser.error("use --stage, or --apply --backup-root")
    print(f"DEPLOYED backup={deploy(args.live, args.usercfg, args.hypr_usercfg, args.backup_root, args.production)}"); return 0
if __name__ == "__main__": raise SystemExit(main())
