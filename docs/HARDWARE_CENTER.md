# CaeRice Hardware Center

Branch: `feature/hardware-center`

## Goal

Native, theme-adaptive hardware dashboard opened with `Super+H`. It lives inside
Caelestia's existing drawer `ContentWindow`, so mouse/touchpad/keyboard input
uses the same window that already hosts Launcher, Overview and Clipboard.

## Resource model

- `HardwareController.qml` is always loaded and only tracks open/close state.
- `hardware/Wrapper.qml` uses a `Loader`.
- `hardware/Content.qml`, its pages, graphs and polling `Process` exist **only
  while Hardware Center is open**.
- While open, telemetry refreshes every 1500 ms.
- `caerice-hardware-probe` is a one-shot Python process; there is no extra
  permanent monitor daemon.
- Closing Hardware Center destroys the polling/UI tree.

## Pages

1. **Overview** — CPU, RAM, root storage, AMD/NVIDIA GPUs, battery/network and cooling summary.
2. **Performance** — rolling CPU/RAM/network/disk/GPU graphs with auto-scaled throughput graphs.
3. **Processes** — live table, multi-term filtering, CPU/RAM/PID sorting, pause, process detail and SIGTERM/SIGKILL actions.
4. **Sensors** — per-core CPU load, CPU/GPU thermals and power, fans and battery data.

Keyboard: `1`–`4` switches pages, `R` refreshes, `Esc` closes.

## Telemetry

`~/.local/bin/caerice-hardware-probe` returns one compact JSON snapshot with:

- CPU total/per-core usage, average frequency, package temperature and governor.
- RAM and swap usage.
- Root filesystem usage and root-device read/write throughput + IOPS.
- AMD GPU telemetry from `/sys/class/drm` when exported by the driver.
- NVIDIA GPU telemetry from `nvidia-smi` when available.
- Battery percentage/status/power.
- Active network interface and RX/TX rates.
- Exposed fan RPM values.
- Up to 80 processes with instantaneous CPU deltas, RAM, user, state, threads,
  parent PID, elapsed time and command line.
- Host, kernel, uptime and load average.

The probe degrades gracefully when a metric is not available.

## btop relationship

The interaction model intentionally takes inspiration from upstream btop:
resource histories, process filtering/sorting/details/signals, auto-scaled
network graphs, disk I/O, battery and sensor monitoring.

No btop C++/terminal UI source is vendored and Hardware Center does not launch
btop. CaeRice implements its own `/proc`/`/sys` collectors and QML interface so
all of this lives under `Super+H` and follows the Caelestia scheme.

Reference: https://github.com/aristocratos/btop

## Theme

The UI uses `Colours.palette.*` and `Tokens.*`. There are no independent accent
colours. It follows the active Caelestia scheme automatically.

## Install

First installation/integration:

```fish
cd ~/CaeRice
git switch feature/hardware-center
git pull --ff-only
bash scripts/features/install-hardware-center.sh
```

During development, once native integration already exists:

```fish
cd ~/CaeRice
git pull --ff-only
bash scripts/features/update-hardware-center.sh
```

The fast updater synchronizes every QML page plus the probe and restarts
Caelestia. The full installer creates a snapshot under
`~/.local/share/caelestia-custom-system/snapshots/hardware-center-*` before
changing native integration files.
