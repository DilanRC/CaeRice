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

def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts/features" / f"{name}.py")
    module = importlib.util.module_from_spec(spec); assert spec and spec.loader
    spec.loader.exec_module(module); return module

def payload(stage):
    if stage.exists(): raise RuntimeError(f"refusing existing stage: {stage}")
    stage.mkdir(parents=True)
    names = ("BottomHub.qml", "HubButton.qml", "OverviewController.qml", "ClipboardController.qml", "HardwareController.qml", "DisplayController.qml", "WallpaperController.qml")
    for name in names:
        destination = stage / "modules" / name; destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(OWNED / name, destination)
    shutil.copytree(OWNED / "wallpaper", stage / "modules/wallpaper")
    (stage / "patches").mkdir()
    shutil.copy2(ROOT / "caelestia/patches/services__Wallpapers.qml.patch", stage / "patches/services__Wallpapers.qml.patch")

def deploy(live, usercfg, hypr_usercfg, backup_root, production):
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
        (temp / "services").mkdir(); shutil.copy2(live / "services/Wallpapers.qml", temp / "services/Wallpapers.qml")
        result = subprocess.run(["patch", "-p1", "-d", str(temp)], input=(staged / "patches/services__Wallpapers.qml.patch").read_text(), text=True, capture_output=True)
        if result.returncode: raise RuntimeError("Wallpapers patch cannot apply: " + result.stdout + result.stderr)
        config = temp / "shell.json"; shutil.copy2(usercfg, config); configure.configure(config)
        backup = backup_root / datetime.now().strftime("wallpaper-manager-%Y%m%d-%H%M%S-%f"); backup.mkdir(parents=True)
        copies = [(wired / rel, live / rel) for rel in ("shell.qml", "components/ScreenState.qml", "modules/drawers/Panels.qml", "modules/drawers/ContentWindow.qml")]
        copies.append((wired / "user-config/hypr-user.lua", hypr_usercfg))
        copies += [(temp / "services/Wallpapers.qml", live / "services/Wallpapers.qml"), (config, usercfg)]
        copies += [(source, live / "modules" / source.relative_to(staged / "modules")) for source in (staged / "modules").rglob("*") if source.is_file()]
        manifest = []
        created_dirs = []
        for source, target in copies:
            item = {"target": str(target), "existed": target.exists(), "mode": stat.S_IMODE(target.stat().st_mode) if target.exists() else None}
            if target.exists():
                old = backup / "files" / str(len(manifest)); old.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(target, old); item["backup"] = str(old)
            manifest.append(item)
        for source, target in copies:
            missing_dirs = []
            parent = target.parent
            while not parent.exists():
                missing_dirs.append(parent)
                parent = parent.parent
            for directory in reversed(missing_dirs):
                directory.mkdir()
                created_dirs.append(str(directory))
            shutil.copy2(source, target)
            item = next(entry for entry in manifest if entry["target"] == str(target))
            if item["mode"] is not None:
                os.chmod(target, item["mode"])
        (backup / "manifest.json").write_text(json.dumps({"files": manifest, "createdDirs": created_dirs}, indent=2))
        return backup

def rollback(backup):
    manifest = json.loads((backup / "manifest.json").read_text())
    for item in reversed(manifest["files"]):
        target = Path(item["target"])
        if item["existed"]:
            shutil.copy2(item["backup"], target)
            os.chmod(target, item["mode"])
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
