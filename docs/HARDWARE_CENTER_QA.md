# Hardware Center acceptance checklist

Run after `bash scripts/features/update-hardware-center.sh`.

## Automated

```fish
python3 scripts/features/validate-hardware-center.py
python3 scripts/features/diagnose-hardware-center.py
```

Expected: validator `status: OK`, live QML hashes `MATCH`, no Hardware Center QML errors.

## UI

- `Super+H` opens and toggles; `Esc`, close button and outside click close it.
- Empty space inside the panel never closes it.
- Keys `1` through `8` select the matching page.
- Active Caelestia scheme recolours every page without hardcoded accents.

### 1 Overview

- CPU `% / GHz` toggle works.
- RAM defaults to GiB and toggles to `%`.
- CPU/RAM/storage/GPU/battery/network/cooling values update.

### 2 Performance

- Histories fill only while Hardware Center is open.
- CPU cycles Total and every logical core.
- RAM toggles Cache/Swap.
- Network and disk auto-scale; graphs show min/avg/max and current scale.

### 3 Processes

- Filter accepts multiple terms.
- CPU/RAM/PID sorting works.
- `123 / %` changes CPU/RAM representation.
- List pause freezes only the list.
- Selected-process Pause/Resume, Interrupt, Terminate and Force kill work on a disposable process.

### 4 Sensors

- Per-core bars update.
- CPU/GPU temperature and power fields degrade cleanly when unavailable.
- Fan RPM values render without duplicate UI breakage.

### 5 I/O

- Root filesystem usage renders.
- Physical NVMe model/device and throughput/IOPS/totals render.
- Network interface, IPv4, MAC, SSID, signal and bitrate render when available.

### 6 Power

- Available `powerprofilesctl` profiles are selectable.
- Selected profile is verified after change.
- CPU `amd-pstate`/governor/EPP/platform-profile state renders.
- AMD runtime power state and NVIDIA P-state/clocks/power render.

### 7 Auto

- Starts disabled on first install.
- Updating Cortetsu never enables it automatically.
- AC, battery and low-battery profiles are configurable.
- Low threshold increments/decrements in 5% steps.
- `Apply current rule once` works while disabled without enabling the service.
- Enabling starts the user service; disabling stops and disables it.
- Recent rule/profile events appear and can be cleared.

### 8 Energy

- Battery/CPU/AMD/NVIDIA power histories populate while the page exists.
- Battery energy and health render.
- Remaining or charge-time estimate appears only when the kernel exposes usable draw data.
- Missing CPU package power is shown as unavailable, not fabricated.

## Resource check

After closing Hardware Center:

```fish
ps -ef | grep -E 'cortetsu-hardware-(probe|power)' | grep -v grep
```

Expected: no persistent main/power probe processes.

If Auto is disabled:

```fish
systemctl --user is-active cortetsu-power-auto.service
```

Expected: `inactive`.
