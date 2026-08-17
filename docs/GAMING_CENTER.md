# CaeRice Gaming Center

Branch: `sad`

Bind: `Super+Shift+G`  
IPC: `qs -c caelestia ipc call gaming open`

Gaming Center is a native Caelestia panel. It does not replace Steam or write Steam VDF compatibility configuration. It inventories the local Steam installation and launches games through reversible per-process wrappers/environment only.

## Pages

1. **Dashboard** — Steam/Gamescope/GameMode/MangoHud/Wine/NVIDIA tooling, Proton inventory and current runtime status.
2. **Library** — installed Steam app manifests, library path, AppID and size, with filtering.
3. **Profile** — per-game launch profile and launch action.
4. **Runtime** — Steam/game-related processes and detected Steam AppIDs.

## Per-game profile

Profiles live at `~/.config/caerice/gaming-profiles.json` and are atomic JSON writes.

Supported fields:

- GameMode on/off.
- MangoHud on/off.
- Gamescope on/off.
- GPU preference: default, integrated or NVIDIA PRIME render offload.
- FPS cap.
- game resolution (`gamescope -w/-h`).
- Gamescope output resolution (`-W/-H`).
- scaler: auto/integer/fit/fill/stretch.
- filter: linear/nearest/fsr/nis/pixel.
- optional FSR/NIS sharpness.
- adaptive sync.
- fullscreen.

When Gamescope is active, MangoHud uses Gamescope's `--mangoapp`; otherwise the launched Steam process receives `MANGOHUD=1`.

The helper refuses to save a profile which requires an unavailable mandatory wrapper (for example Gamescope enabled while `gamescope` is not installed).

## GPU policy

- `default`: leaves GPU selection untouched.
- `integrated`: sets `DRI_PRIME=0` for the launched process tree.
- `nvidia`: uses NVIDIA PRIME render-offload environment variables only for the launched process tree.

There are no persistent global GPU variables, clock changes, undervolting, fan curves or GPU power-limit writes.

## Helpers

- `caerice-gaming-probe` — Steam libraries/manifests, Proton tools, runtime processes, GameMode and NVIDIA telemetry.
- `caerice-gaming-profile` — list/get/set/delete/command/launch per-game profiles.

Useful CLI checks:

```fish
~/.local/bin/caerice-gaming-probe | jq
~/.local/bin/caerice-gaming-profile list | jq
~/.local/bin/caerice-gaming-profile command --appid 123456 | jq
```

`command` shows the exact argv/environment without launching the game.

## Safety boundary

Gaming Center deliberately does **not**:

- edit Steam `localconfig.vdf`/compatibility mappings;
- bypass anti-cheat or DRM;
- write GPU clocks, voltages or fan curves;
- change a global Vulkan/PRIME preference;
- permanently enable GameMode optimizations.

All launch modifications terminate with the launched process tree.

## Validation

```fish
cd ~/CaeRice
git switch sad
git pull --ff-only
python3 scripts/features/validate-gaming-center.py
```

Tomorrow's QA should additionally launch one disposable/test title or a harmless Steam app, confirm wrappers, and check that closing Gaming Center leaves no probe running.
