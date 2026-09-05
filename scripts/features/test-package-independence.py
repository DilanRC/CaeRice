import tomllib
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
manifest = tomllib.loads((repo / "packages/arch.toml").read_text(encoding="utf-8"))
shell = manifest["group"]["shell"]

assert "quickshell-git" in shell["packages"]
assert "caelestia-shell" not in shell["packages"]
assert "qs" in shell["commands"]
print("PASS: Cortetsu package contract requires Quickshell, not caelestia-shell")
