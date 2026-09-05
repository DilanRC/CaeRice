from pathlib import Path

repo = Path(__file__).resolve().parents[2]
patch = (repo / "caelestia/patches/services__NotificationConfig.qml.patch").read_text(encoding="utf-8")

assert "-import qs.services" in patch
assert "CortetsuHypr.monitors.values" in patch
assert "CortetsuShellState.anySidebarOpen()" in patch
print("PASS: notification backend uses Cortetsu Hyprland and screen-state contracts")
