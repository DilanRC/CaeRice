from pathlib import Path

repo = Path(__file__).resolve().parents[2]
patch = (repo / "caelestia/patches/components__misc__CustomShortcut.qml.patch").read_text()
hypr = (repo / "config/hypr-user.lua").read_text()

assert '+    appid: "cortetsu"' in patch
assert 'appid: "caelestia"' not in "\n".join(
    line[1:] for line in patch.splitlines() if line.startswith("+") and not line.startswith("+++")
)
assert 'hl.dsp.global("caelestia:' not in hypr
assert 'hl.dsp.global("cortetsu:' in hypr

print("PASS: global shortcuts use the Cortetsu application namespace")
