# Cortetsu performance baseline

Snapshot of the active session captured on 2026-09-04 at 19:14:00 CST.

## Shell process

| Metric | Value |
|---|---:|
| Main process | `/usr/bin/qs -p ~/.config/quickshell/cortetsu/current -n` |
| CPU at capture | 2.6% |
| RSS | 432,384 kB |
| PSS | 294,060 kB |
| Threads | 117 |
| File descriptors | 90 |
| Direct child processes | 1 |
| Repeating user timers | 0 |

The only direct child of the shell service is `nmcli monitor`, which is the
existing network backend used by the active shell. This baseline records it as
an implementation detail and does not attribute the shell resource usage to
that process.

## User-session helpers

The active session had four Cortetsu-owned helper processes at capture time:

- `cortetsu-pomodoro daemon`
- `cortetsu-power-auto`
- `cortetsu-wallpaper-color-daemon` and its managed child

The legacy process scan reported no live `caerice-pomodoro` or
`caelestia-wallpaper-color-daemon` processes.

Ten `nmcli monitor` processes were visible in the complete user session,
including the one owned by the shell. This count is recorded for future
comparison only. It is not a diagnosis or an attribution of the baseline.

## Measurement contract

This is a point-in-time baseline, not a release gate. A release measurement
must repeat the capture after a 60-second idle period and add startup latency,
overlay first-frame latency, 40 open/close cycles, QML warnings and external
process creation. Compare like-for-like sessions and preserve the command
output with the release evidence.
