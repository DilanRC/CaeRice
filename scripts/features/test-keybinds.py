#!/usr/bin/env python3
from __future__ import annotations

import importlib.machinery
import importlib.util
import tempfile
from pathlib import Path
from types import SimpleNamespace

REPO = Path(__file__).resolve().parents[2]
HELPER = REPO / "caelestia/bin/caerice-keybinds"

loader = importlib.machinery.SourceFileLoader("caerice_keybinds", str(HELPER))
spec = importlib.util.spec_from_loader(loader.name, loader)
assert spec is not None
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="caerice-keybinds-") as temp:
        root = Path(temp)
        module.DEFAULTS = root / "variables.lua"
        module.OVERRIDES = root / "hypr-vars.lua"
        module.USER = root / "hypr-user.lua"
        module.SNAPSHOTS = root / "snapshots"
        module.subprocess.run = lambda *args, **kwargs: SimpleNamespace(returncode=0, stdout="[]", stderr="")
        module.DEFAULTS.write_text(
            'return {\n    browser = "firefox",\n    kbBrowser = "SUPER + W",\n'
            '    kbNextWs = { "SUPER + Right", "SUPER + Page_Down" },\n}\n',
            encoding="utf-8",
        )
        module.OVERRIDES.write_text('return {\n    kbBrowser = "SUPER + B",\n}\n', encoding="utf-8")
        module.USER.write_text(
            'hl.bind(\n    "SUPER + G",\n    hl.dsp.exec_cmd("github-desktop")\n)\n',
            encoding="utf-8",
        )
        module.USER.write_text(
            module.USER.read_text(encoding="utf-8")
            + '\nhl.bind(\n    "SUPER + O",\n    hl.dsp.exec_cmd("spotify")\n)\n'
            + '\nhl.bind(\n    "SUPER + A",\n    hl.dsp.exec_cmd("claude-desktop")\n)\n',
            encoding="utf-8",
        )
        real_reload_and_verify = module.reload_and_verify
        module.reload_and_verify = lambda chord, snapshot: None

        bindings = module.list_bindings()
        browser = next(item for item in bindings if item["id"] == "var:kbBrowser:0")
        assert browser["chord"] == "SUPER + B"
        assert browser["command"] == "firefox"
        assert browser["description"] == "firefox"
        assert browser["appQuery"] == "firefox"
        assert any(item["id"] == "var:kbNextWs:1" and item["chord"] == "SUPER + Page_Down" for item in bindings)
        custom = next(item for item in bindings if item["chord"] == "SUPER + G")
        duplicate = next(item for item in bindings if item["chord"] == "SUPER + O")

        module.delete_binding(duplicate["id"])
        user = module.USER.read_text(encoding="utf-8")
        assert '"SUPER + O"' not in user
        assert 'hl.dsp.exec_cmd("github-desktop")\n)\n\nhl.bind(\n    "SUPER + A"' in user
        assert len(module.binding_blocks(user)) == 2

        module.set_binding("var:kbNextWs:1", "CTRL + SUPER + Right")
        assert 'kbNextWs = { "SUPER + Right", "CTRL + SUPER + Right" },' in module.OVERRIDES.read_text(encoding="utf-8")

        module.set_binding(custom["id"], "SUPER + SHIFT + G")
        assert '"SUPER + SHIFT + G"' in module.USER.read_text(encoding="utf-8")

        try:
            module.set_binding("var:kbBrowser:0", "SUPER + SHIFT + G")
        except module.KeybindError:
            pass
        else:
            raise AssertionError("duplicate shortcut was accepted")

        module.add_app("org.example.App", "Example", "example --open", "SUPER + ALT + E")
        user = module.USER.read_text(encoding="utf-8")
        assert "CaeRice app shortcut: Example" in user
        assert "hl.dsp.exec_cmd([[example --open]])" in user
        generated = next(item for item in module.list_bindings() if item.get("appId") == "org.example.App")
        assert generated["appName"] == "Example"
        assert generated["command"] == "example --open"

        module.delete_binding(generated["id"])
        assert "CaeRice app shortcut: Example" not in module.USER.read_text(encoding="utf-8")

        module.delete_binding("var:kbNextWs:0")
        assert 'kbNextWs = "CTRL + SUPER + Right",' in module.OVERRIDES.read_text(encoding="utf-8")

        module.delete_binding("var:kbNextWs:0")
        assert "kbNextWs = {}," in module.OVERRIDES.read_text(encoding="utf-8")
        assert not any(item["id"].startswith("var:kbNextWs:") for item in module.list_bindings())

        before_delete = module.OVERRIDES.read_text(encoding="utf-8")
        module.subprocess.run = lambda *args, **kwargs: SimpleNamespace(returncode=1, stdout="", stderr="rejected")
        try:
            module.delete_binding("var:kbBrowser:0")
        except module.KeybindError:
            pass
        else:
            raise AssertionError("failed delete was accepted")
        assert module.OVERRIDES.read_text(encoding="utf-8") == before_delete

        before = module.OVERRIDES.read_text(encoding="utf-8")
        module.reload_and_verify = real_reload_and_verify
        module.subprocess.run = lambda *args, **kwargs: SimpleNamespace(returncode=0, stdout="[]", stderr="")
        try:
            module.set_binding("var:kbBrowser:0", "SUPER + F12")
        except module.KeybindError:
            pass
        else:
            raise AssertionError("missing runtime bind was accepted")
        assert module.OVERRIDES.read_text(encoding="utf-8") == before

    print("Keybind editor gate tests: OK")


if __name__ == "__main__":
    main()
