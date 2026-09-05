#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import os
import tempfile
import threading
from importlib.machinery import SourceFileLoader
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO / "cortetsu/bin/cortetsu-power-auto-control"
PROFILES = ("power-saver", "balanced", "performance")


def load_module(home: Path):
    old_home = os.environ.get("HOME")
    os.environ["HOME"] = str(home)
    try:
        loader = SourceFileLoader("power_auto_control", str(MODULE_PATH))
        spec = importlib.util.spec_from_loader("power_auto_control", loader)
        assert spec and spec.loader
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        if old_home is None:
            os.environ.pop("HOME", None)
        else:
            os.environ["HOME"] = old_home


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="cortetsu-power-auto-test-") as tmp:
        module = load_module(Path(tmp))
        errors: list[BaseException] = []

        def writer(index: int) -> None:
            try:
                cfg = dict(module.DEFAULTS)
                cfg["enabled"] = bool(index % 2)
                cfg["low_battery_threshold"] = 5 + (index % 76)
                cfg["ac_profile"] = PROFILES[index % len(PROFILES)]
                module.save_config(cfg)
            except BaseException as exc:
                errors.append(exc)

        threads = [threading.Thread(target=writer, args=(i,)) for i in range(80)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()

        assert not errors, errors
        parsed = json.loads(module.CONFIG_PATH.read_text(encoding="utf-8"))
        normalized = module.normalize_config(parsed)
        assert parsed == normalized
        assert not list(module.CONFIG_PATH.parent.glob("*.tmp"))

    print("power-auto-control concurrent save: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
