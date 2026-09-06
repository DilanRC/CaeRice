#!/usr/bin/env python3
import subprocess
import tempfile
import shutil
import json
import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
spec = importlib.util.spec_from_file_location("install_wallpaper_manager", HERE / "install-wallpaper-manager.py")
assert spec and spec.loader
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)

def tree(root: Path) -> list[tuple[str, int, bytes]]:
    return [(str(path.relative_to(root)), path.stat().st_mode & 0o777, path.read_bytes()) for path in sorted(root.rglob("*")) if path.is_file()]

with tempfile.TemporaryDirectory() as tmp:
    stage = Path(tmp) / "stage"
    result = subprocess.run(["python3", str(HERE / "install-wallpaper-manager.py"), "--stage", str(stage)], text=True, capture_output=True, check=True)
    assert "STAGED" in result.stdout
    assert (stage / "modules/wallpaper/Content.qml").is_file()
    assert (stage / "modules/WallpaperController.qml").is_file()
    assert (stage / "modules/OverlayPolicy.js").is_file()
    assert (stage / "modules/CortetsuWallpapers.qml").read_bytes() == installer.SERVICE.read_bytes()
    again = subprocess.run(["python3", str(HERE / "update-wallpaper-manager.py"), "--stage", str(stage)], text=True, capture_output=True)
    assert again.returncode != 0 and "refusing existing stage" in again.stderr
    live = Path(tmp) / "live"
    (live / "components").mkdir(parents=True); (live / "modules/drawers").mkdir(parents=True)
    (live / "shell.qml").write_text("ShellRoot {\n    HardwareController {}\n    BatteryMonitor {}\n}\n")
    (live / "components/ScreenState.qml").write_text("QtObject {\n    property bool hardware\n    property bool dashboard\n}\n")
    (live / "modules/drawers/Panels.qml").write_text("import qs.modules.hardware as Hardware\nimport qs.modules.notifications as Notifications\nItem {\n    readonly property alias hardware: hardware\n    readonly property alias dashboard: dashboard\n    Hardware.Wrapper { id: hardware }\n    Dashboard.Wrapper { id: dashboard }\n}\n")
    (live / "modules/drawers/ContentWindow.qml").write_text("Item {\n    onX: {\n        screenState.hardware = false;\n        panels.popouts.close();\n    }\n    WlrLayershell.layer: screenState.overview || screenState.clipboard || screenState.hardware ? WlrLayer.Overlay : WlrLayer.Top\n    WlrLayershell.keyboardFocus: screenState.overview || screenState.clipboard || screenState.hardware || screenState.launcher ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None\n    mask: screenState.overview || screenState.clipboard || screenState.hardware ? null : regions\n    function f(s) { if (s.overview || s.clipboard || s.hardware)\n                return true; }\n    onY: {\n            root.screenState.hardware = false;\n            panels.popouts.hasCurrent = false;\n    }\n}\n")
    config = Path(tmp) / "shell.json"; config.write_text(json.dumps({"launcher": {"actions": [{"name": "Wallpaper"}, {"name": "Kept"}]}}))
    hypr = Path(tmp) / "hypr-user.lua"; hypr.write_text('hl.bind(\n    "SUPER + H",\n    hl.dsp.global("cortetsu:hardware")\n)\n'); hypr.chmod(0o600)
    before_live = tree(live)
    before_hypr = (hypr.stat().st_mode & 0o777, hypr.read_bytes())
    deployed = subprocess.run(["python3", str(HERE / "install-wallpaper-manager.py"), "--apply", "--live", str(live), "--usercfg", str(config), "--hypr-usercfg", str(hypr), "--backup-root", str(Path(tmp) / "backups")], text=True, capture_output=True)
    assert deployed.returncode == 0, deployed.stdout + deployed.stderr
    backup = Path(deployed.stdout.strip().split("backup=")[1])
    assert "wallpaperManager" in (live / "components/ScreenState.qml").read_text()
    assert "previewGeneration" in (live / "modules/CortetsuWallpapers.qml").read_text()
    assert json.loads(config.read_text())["launcher"]["actions"] == [{"name": "Kept"}]
    assert hypr.stat().st_mode & 0o777 == 0o600
    v1_live = tree(live)
    v1_config = config.read_bytes()
    v1_hypr = (hypr.stat().st_mode & 0o777, hypr.read_bytes())
    second = subprocess.run(["python3", str(HERE / "install-wallpaper-manager.py"), "--apply", "--live", str(live), "--usercfg", str(config), "--hypr-usercfg", str(hypr), "--backup-root", str(Path(tmp) / "backups")], text=True, capture_output=True)
    assert second.returncode == 0, second.stdout + second.stderr
    second_backup = Path(second.stdout.strip().split("backup=")[1])
    subprocess.run(["python3", str(HERE / "install-wallpaper-manager.py"), "--rollback", str(second_backup)], check=True)
    assert tree(live) == v1_live
    assert config.read_bytes() == v1_config
    assert (hypr.stat().st_mode & 0o777, hypr.read_bytes()) == v1_hypr
    subprocess.run(["python3", str(HERE / "install-wallpaper-manager.py"), "--rollback", str(backup)], check=True)
    assert tree(live) == before_live
    assert (hypr.stat().st_mode & 0o777, hypr.read_bytes()) == before_hypr
    failed = Path(tmp) / "failed"
    shutil.copytree(live, failed)
    failed_config = Path(tmp) / "failed-shell.json"; shutil.copy2(config, failed_config)
    failed_hypr = Path(tmp) / "failed-hypr.lua"; shutil.copy2(hypr, failed_hypr)
    failed_before = tree(failed)
    failed_config_before = failed_config.read_bytes()
    failed_hypr_before = (failed_hypr.stat().st_mode & 0o777, failed_hypr.read_bytes())
    replacements = [0]
    def fail_after_first(source, target, item):
        replacements[0] += 1
        if replacements[0] == 2:
            raise OSError("injected replacement failure")
        installer.atomic_replace(source, target, item)
    try:
        installer.deploy(failed, failed_config, failed_hypr, Path(tmp) / "failed-backups", False, fail_after_first)
    except OSError as error:
        assert "injected replacement failure" in str(error)
    else:
        raise AssertionError("injected replacement failure did not abort deployment")
    backups = list((Path(tmp) / "failed-backups").iterdir())
    assert len(backups) == 1 and (backups[0] / "manifest.json").is_file()
    assert replacements[0] == 2
    assert tree(failed) == failed_before
    assert failed_config.read_bytes() == failed_config_before
    assert (failed_hypr.stat().st_mode & 0o777, failed_hypr.read_bytes()) == failed_hypr_before
    installer.rollback(backups[0])
    assert tree(failed) == failed_before
print("test-install-wallpaper-manager: OK (first-party service, idempotency, rollback, atomic failure rollback)")
