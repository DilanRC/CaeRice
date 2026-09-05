import re
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
modules = repo / "cortetsu/modules"
controllers = tuple(modules.glob("*Controller.qml"))

assert controllers
for controller in controllers:
    text = controller.read_text()
    assert "import Caelestia" not in text, controller
    assert "import qs.components" not in text, controller
    assert "import qs.services" not in text, controller
    if "CustomShortcut" in text:
        raise AssertionError(controller)
    if re.search(r"(?<!Cortetsu)ShellState\.", text):
        raise AssertionError(controller)

shortcut = (modules / "CortetsuShortcut.qml").read_text()
state = (modules / "CortetsuShellState.qml").read_text()
assert 'appid: "cortetsu"' in shortcut
assert "import qs.services" not in state
assert "ShellState.forScreen" not in state and "ShellState.forActive" not in state
assert "registerState" in state and "CortetsuHypr.focusedMonitor" in state

print("PASS: controllers use Cortetsu shortcut and shell-state boundaries")
