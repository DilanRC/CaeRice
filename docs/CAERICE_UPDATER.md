# CaeRice Updater

Branch: `sad`

Bind: `Super+Shift+U`  
IPC: `qs -c caelestia ipc call updater open`

This is a compatibility updater for the CaeRice patch layer. It is intentionally separate from the system package manager: it never runs `pacman -Syu` for the user and never combines an unreviewed Caelestia package upgrade with patch application.

## Pipeline

1. **Discover** — inspect installed packages, current CaeRice patch base, repo state, patch manifest and live hashes.
2. **Fetch** — fetch an explicit upstream Caelestia ref/tag into an isolated cache.
3. **Test** — apply the CaeRice patch series to an isolated copy of that candidate and classify every patch.
4. **Review** — show clean/offset/upstream-equivalent/conflict/missing results.
5. **Package update separately** — the actual Caelestia package update remains a deliberate user/system action.
6. **Snapshot** — before live patching, copy the complete live Caelestia tree and user config.
7. **Apply** — requires `--confirm APPLY`, requires the live raw targets to hash-match the candidate which was tested, and applies CaeRice modules/patches.
8. **Verify** — runs the CaeRice validators.
9. **Commit base** — `caerice-updater-commit-base` can create a local git commit for the new `PATCH_BASE_INFO.txt` only when no unrelated working-tree changes exist. It never pushes.
10. **Rollback** — restore the saved live tree/config from the last or selected snapshot.

## Patch classifications

- `clean`: normal forward application succeeds.
- `offset/3way`: normal check fails but a 3-way application is available.
- `upstream-equivalent`: the reverse check indicates the patch's effect is already present in the candidate.
- `conflict`: blocks Apply.
- `missing`: patch file is unavailable and blocks Apply.

## Critical guards

`Apply` is rejected unless:

- the exact candidate was fetched;
- the exact candidate commit passed Test with zero blockers;
- `--confirm APPLY` is present;
- every live raw patch target matches the tested upstream candidate hash;
- a snapshot can be created.

This live-hash rule is what keeps package installation and CaeRice compatibility migration separate. If the installed/live Caelestia tree is not the exact tested upstream candidate, Apply refuses to continue instead of guessing.

If an installer or post-apply validator fails, the updater restores the snapshot.

## State

- candidates: `~/.cache/caerice-updater/candidates/`
- report: `~/.local/state/caerice/updater-report.json`
- state: `~/.local/state/caerice/updater-state.json`
- snapshots: `~/.local/share/caelestia-custom-system/snapshots/updater-*`

## CLI

```fish
~/.local/bin/caerice-updater discover | jq
~/.local/bin/caerice-updater fetch --ref vX.Y.Z | jq
~/.local/bin/caerice-updater test --ref vX.Y.Z | jq
~/.local/bin/caerice-updater status | jq
```

Privileged Apply is intentionally done from a terminal so sudo and the exact ref remain visible:

```fish
~/.local/bin/caerice-updater apply --ref vX.Y.Z --confirm APPLY | jq
```

Rollback:

```fish
~/.local/bin/caerice-updater rollback | jq
```

After a verified Apply changes the patch base, inspect the local commit guard:

```fish
~/.local/bin/caerice-updater-commit-base status | jq
```

and explicitly commit only that base advancement:

```fish
~/.local/bin/caerice-updater-commit-base commit --confirm COMMIT | jq
```

No push is performed automatically.

## Validation

```fish
cd ~/CaeRice
git switch sad
git pull --ff-only
python3 scripts/features/validate-caerice-updater.py
```

Tomorrow's QA must exercise Fetch/Test against a harmless known ref and must test Apply only against a live Caelestia tree which actually matches that tested candidate.
