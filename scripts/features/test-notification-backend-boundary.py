from pathlib import Path

repo = Path(__file__).resolve().parents[2]
services = (repo / "cortetsu/services/Notifs.qml").read_text(encoding="utf-8")

assert "import Quickshell.Services.Notifications" in services
assert "CortetsuHypr.monitors.values" in services
assert "CortetsuShellState.anySidebarOpen()" in services
print("PASS: notification backend uses Cortetsu Hyprland and screen-state contracts")
