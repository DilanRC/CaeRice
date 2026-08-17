# CaeRice Hardware Center

Branch: `feature/hardware-center`

## Goal

Native, theme-adaptive hardware dashboard opened with `Super+H`. It lives inside
Caelestia's existing drawer `ContentWindow`, so mouse/touchpad/keyboard input
uses the same window that already hosts Launcher, Overview and Clipboard.

## Resource model

- `HardwareController.qml` is always loaded and only tracks open/close state.
- `hardware/Wrapper.qml` uses a `Loader`.
- `hardware/Content.qml`, its cards and polling `Process` exist **only while the
  Hardware Center is open**.
- While open, telemetry refreshes every 1500 ms.
- The probe is a one-shot Python process; there is no extra permanent daemon.
- Closing Hardware Center destroys the polling tree.

## Telemetry

`~/.local/bin/caerice-hardware-probe` returns one compact JSON snapshot with:

- CPU usage, average frequency, package temperature and governor.
- RAM and swap usage.
- Root filesystem usage.
- AMD GPU telemetry from `/sys/class/drm` when exported by the driver.
- NVIDIA GPU telemetry from `nvidia-smi` when available.
- Battery percentage/status/power.
- Active network interface and RX/TX rates.
- Exposed fan RPM values.
- Top CPU processes.
- Host, kernel, uptime and load average.

The probe degrades gracefully when a metric is not available.

## Theme

The UI uses `Colours.palette.*` and `Tokens.*`. There are no independent accent
colours. It should follow the active Caelestia scheme automatically.

## Install on the development machine

```fish
cd ~/CaeRice
git switch feature/hardware-center
git pull --ff-only
bash scripts/features/install-hardware-center.sh

pkill -TERM -x qs
sleep 1
caelestia shell -d
```

Open with `Super+H` or:

```fish
qs -c caelestia ipc call hardware open
```

The installer creates a snapshot under
`~/.local/share/caelestia-custom-system/snapshots/hardware-center-*` before
changing native Caelestia integration files.
