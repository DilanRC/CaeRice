# CaeRice SAD integration branch

` sad ` is the single integration branch for the post-Hardware-Center work. It is intentionally **not** merged to `main` until the real-machine QA matrix in `docs/SAD_QA.md` is completed.

## Native centers

| Bind | Center | IPC |
|---|---|---|
| `Super+H` | Hardware Center | `hardware` |
| `Super+Shift+O` | Display Manager | `display` |
| `Super+Shift+G` | Gaming Center | `gaming` |
| `Super+Shift+U` | CaeRice Updater | `updater` |

All interactive centers live inside Caelestia's native `ContentWindow` path. The center controllers stay loaded; their heavy QML/probes are Loader-gated by the open state.

## Display Manager

Completed feature surface:

- physical-output inventory and GPU ownership;
- Writeback filtering;
- topology candidate editing;
- mode/Hz, scale, X/Y, transform and enable state;
- built-in Laptop/Dual/External candidates;
- named layouts;
- VRR/max-bpc/HDR/wide-colour capability reporting without assuming unknown support;
- dry run;
- 15-second live preview;
- independent auto-revert watchdog;
- Keep/Revert;
- exact-candidate persistent Save with backup/reload/verify/rollback;
- managed workspace ranges 1–10 / 11–20 after verified persistence.

## Gaming Center

Completed feature surface:

- Steam library/app-manifest inventory;
- Proton/GE-Proton inventory;
- GameMode, Gamescope, MangoHud, Wine and NVIDIA availability/runtime;
- per-game atomic profile storage;
- default/integrated/NVIDIA process-local GPU selection;
- GameMode and MangoHud toggles;
- Gamescope fullscreen, FPS, game/output resolution, scaler, filter, sharpness and adaptive-sync profile options;
- exact launch-command preview;
- detached Steam launch;
- running game/Steam process inventory.

It does not mutate Steam compatibility VDF files, bypass anti-cheat/DRM, or perform global GPU tuning.

## CaeRice Updater

Completed staged pipeline:

`Discover → Fetch → Test → Review → package update separately → Snapshot → Apply → Verify → Commit base → Rollback`

Core guards:

- isolated candidate cache;
- patch-by-patch compatibility classification;
- blockers stop Apply;
- explicit `APPLY` confirmation;
- live raw target hashes must match the exact tested upstream candidate;
- full live-tree snapshot before patching;
- post-apply validators;
- automatic rollback on apply/verify failure;
- separate guarded local commit for `PATCH_BASE_INFO.txt`;
- no automatic push;
- no automatic package-manager upgrade.

## Install / update

After the branch is checked out locally, first-time integration of the post-Hardware modules:

```fish
cd ~/CaeRice
git switch sad
git pull --ff-only
bash scripts/features/install-sad.sh
```

Development/live synchronization once all centers are integrated:

```fish
cd ~/CaeRice
git switch sad
git pull --ff-only
bash scripts/features/update-sad.sh
```

Full CaeRice reconstruction uses:

```fish
bash scripts/install-caerice.sh
```

## Automated QA

```fish
python3 scripts/features/validate-sad.py
python3 scripts/features/diagnose-sad.py
```

Automated success is necessary but not sufficient. Display transactions, monitor hotplug, Gaming launch wrappers and all Wayland input zones require real-machine QA before merge.

## Merge policy

Do not merge `sad` to `main` merely because static validators pass. Merge only after `docs/SAD_QA.md` is completed and any runtime fixes are committed back to `sad`.
