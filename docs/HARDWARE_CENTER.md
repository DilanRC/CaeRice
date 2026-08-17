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

1. **Overview** — CPU, RAM, root storage, AMD/NVIDIA GPUs, battery/network and cooling summary. CPU can switch `% / GHz`; memory defaults to GiB and can switch `GiB / %`.
2. **Performance** — rolling CPU/RAM/network/NVMe/GPU graphs. Every graph shows a visible scale plus min/average/max. CPU can cycle Total → Core 0 → Core 1…; RAM can switch its second history between cache and swap.
3. **Processes** — live table, multi-term filtering, CPU/RAM/PID sorting, display mode `123 / %`, list freeze, process detail, Pause/Resume, Interrupt, Terminate and Force kill actions.
4. **Sensors** — per-core CPU load, CPU/GPU thermals and power, fans and battery data.
5. **I/O** — detailed root storage/NVMe throughput, IOPS and totals plus network rate/totals, IPv4, MAC and Wi-Fi metadata when exposed.

Keyboard: `1`–`5` switches pages, `R` refreshes, `Esc` closes.

## Telemetry

`~/.local/bin/caerice-hardware-probe` returns one compact JSON snapshot with:

- CPU total/per-core usage, average frequency, package temperature and governor.
- RAM used/available/cache/buffers plus swap usage.
- Root filesystem usage.
- Physical block-device read/write throughput, IOPS and cumulative read/write totals, with NVMe model/serial where exposed by sysfs.
- AMD GPU telemetry from `/sys/class/drm` when exported by the driver.
- NVIDIA GPU telemetry from `nvidia-smi` when available.
- Battery percentage/status/power.
- Active network interface, RX/TX rates/totals, IPv4/MAC and Wi-Fi SSID/signal/link bitrate when `iw` exposes them.
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
