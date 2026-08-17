#!/usr/bin/env python3
"""Regression guard: CaeRice Updater's "upstream ref/tag" field must never
reach `git fetch` unsanitized.

Real bug: the Updater UI (updater/Content.qml refInput) is a free-text field
whose trimmed value is passed straight through as `caerice-updater fetch
--ref <value>` -> `git fetch --depth 1 origin <value>`. git treats a leading
"-" as an option, not a refname, so `--ref '--upload-pack=/tmp/x'` makes git
execute /tmp/x as the upload-pack helper - arbitrary code execution as the
user, with no confirmation prompt. Verified locally against an isolated bare
repo before writing the fix (not included here to avoid shipping a live
exploit primitive in the test suite).

This test proves: (1) the leading-dash guard rejects the exact payload shape
that granted RCE, without touching git or the network; (2) legitimate
refs/tags/commits are unaffected.
"""
import importlib.util
from importlib.machinery import SourceFileLoader
from pathlib import Path

HERE = Path(__file__).resolve().parent
loader = SourceFileLoader("caerice_updater", str(HERE.parent.parent / "caelestia/bin/caerice-updater"))
spec = importlib.util.spec_from_loader(loader.name, loader)
updater = importlib.util.module_from_spec(spec)
loader.exec_module(updater)

malicious = [
    "--upload-pack=/tmp/evil.sh",
    "--upload-pack=touch /tmp/pwned",
    "-o",
    "--exec=whoami",
    "-",
]
for ref in malicious:
    assert not updater.is_git_safe_ref(ref), f"should reject: {ref!r}"
    result, code = updater.fetch(ref)
    assert result["ok"] is False and code == 4, f"fetch() must refuse {ref!r} before touching git, got {result}"

legit = ["main", "v2.4.1", "refs/heads/feature/x", "a1b2c3d4", "release-2026.08"]
for ref in legit:
    assert updater.is_git_safe_ref(ref), f"should accept legitimate ref: {ref!r}"

print("test-updater-ref-injection: OK "
      f"({len(malicious)} payloads rejected, {len(legit)} legitimate refs accepted)")
