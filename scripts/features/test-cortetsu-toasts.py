from pathlib import Path

repo = Path(__file__).resolve().parents[2]
toaster = (repo / "cortetsu/services/CortetsuToaster.qml").read_text(encoding="utf-8")
view = (repo / "cortetsu/modules/utilities/toasts/Toasts.qml").read_text(encoding="utf-8")
item = (repo / "cortetsu/modules/utilities/toasts/ToastItem.qml").read_text(encoding="utf-8")
panels = (repo / "cortetsu/modules/drawers/Panels.qml").read_text(encoding="utf-8")
hub = (repo / "cortetsu/modules/BottomHub.qml").read_text(encoding="utf-8")

for source in (toaster, view, item, panels, hub):
    for legacy in ("Caelestia", "GlobalConfig", "qs.services", "qs.components"):
        assert legacy not in source, legacy

assert "pragma Singleton" in toaster
assert "function toast" in toaster
assert "function dismiss" in toaster
assert "CortetsuToaster.toasts" in view
assert "onDismissed: CortetsuToaster.dismiss" in view
assert 'import "../utilities/toasts" as Toasts' in panels
assert "CortetsuToaster.toast" in hub
print("PASS: Cortetsu owns toast state, rendering, and event calls")
