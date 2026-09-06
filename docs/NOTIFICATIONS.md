# Notifications (Zero-Caelestia Task 9)

## What this covers

`caelestia/patches/services__NotificationConfig.qml.patch` touches four upstream
files: `services/Notifs.qml`, `services/NotifData.qml`, `services/GameMode.qml`,
`modules/notifications/Notification.qml`. It already replaces every
`GlobalConfig.*` read with a `CortetsuConfig.*` equivalent (see
`cortetsu/modules/CortetsuConfig.qml`: `notificationExpire`,
`suppressNotificationsInFullscreen`, `notificationDefaultExpireTimeout`,
`notificationFullscreenExpireTimeout`, `notificationActionOnClick`,
`toastDndChanged`, `toastGameModeChanged`) and persists DND to
`$XDG_STATE_HOME/cortetsu/notification-status.json` via a `FileView` instead of
upstream's `PersistentProperties`/`reloadableId`. That migration predates this
task (commit `a491e64`); `grep -n 'GlobalConfig\|Caelestia\.Config'` against the
patch only matches diff `-` lines (text being removed), never a surviving `+`
line — i.e. the merged result has zero live GlobalConfig/Caelestia.Config
reads.

This task adds the first-party facade Cortetsu code (bottom hub, future
notification-center UI, CLI) should use instead of reaching into the patched
upstream singleton directly:

- `cortetsu/modules/CortetsuNotifications.qml` — reactive singleton exposing
  `count`, `history` (full persisted notification array), `dnd`, and the
  actions `dismiss(id)`, `clear()`, `toggleDnd()`. It watches
  `cortetsu/notifs.json` and `cortetsu/notification-status.json` via
  `FileView` and never edits JSON inline — every mutation shells out to:
- `cortetsu/bin/cortetsu-notifications` — deterministic Python CLI
  (`count | history | dismiss ID | clear | dnd status|on|off|toggle`) that
  owns those two files. Unit-tested in `cortetsu/tests/test-notifications.py`
  with no QML runtime required.
- `IpcHandler { target: "cortetsu-notifications" }` in the singleton exposes
  `clear`, `dismiss`, `toggleDnd`, `isDndEnabled`, `count` for
  `qs ipc call cortetsu-notifications <fn>` from outside the QML tree
  (shortcuts, scripts), mirroring the `WallpaperController`/`CortetsuRecorder`
  pattern already used for wallpaper and screen recording.

## Toast surface contract

Visible toasts are rendered by `cortetsu/modules/BottomHub.qml` inside each
monitor's top-layer `PanelWindow`, immediately above the BottomHub bar. The
window grows to fit the toast stack and uses a click mask so the toast region
and bar remain interactive without intercepting the rest of the screen.

Mouse click, Escape, and the per-item action keys dismiss the newest visible
toast. Toasts take exclusive keyboard focus only while the stack is visible,
then release it when the stack becomes empty. The current implementation caps
the visible stack at five items and expires each item after five seconds.

## What is explicitly out of scope, and why

Fully eliminating the patch (deleting
`services__NotificationConfig.qml.patch` and its `MANIFEST.tsv` line) would
require reimplementing `services/Notifs.qml`'s `NotificationServer` — the
actual freedesktop `org.freedesktop.Notifications` DBus server, urgency/action
dispatch, hint parsing, and per-notification image caching in
`services/NotifData.qml` — as first-party Cortetsu code with zero patch. That
is a full notification-daemon rewrite (comparable in scope to `mako` or
`dunst`), not a config-coupling removal, and every other still-patched service
in `MANIFEST.tsv` (`services/Hypr.qml`, `services/Time.qml`,
`services/Audio.qml`, `services/Players.qml`, etc.) is in the same
intermediate state: GlobalConfig removed from the patch, upstream service
itself not yet replaced. Notifications follow the same increment as those.
The patch is **not** deleted this round — only a part of what it enables
(GlobalConfig removal) is done, plus a new first-party layer on top of its
output.

`cortetsu/modules` may never `import qs.services` (enforced by
`scripts/features/test-zero-caelestia-gate.py` and
`scripts/features/test-cortetsu-notifications.py`), so
`CortetsuNotifications.qml` cannot call into the live `Notifs` singleton's
in-memory list directly (e.g. to close one specific still-open toast). Its
`dismiss`/`clear` therefore operate on the **persisted snapshot**
(`cortetsu/notifs.json`) only. If the live shell's own `Notifs.qml` still
considers a notification open, its own save timer can re-write that entry
back into the snapshot on its next list mutation — this is expected, not a
bug, and mirrors the same file-boundary tradeoff already accepted for DND.
Actually clearing all *currently visible* toasts (not just history) is
already possible with zero GlobalConfig coupling via upstream's own
untouched `IpcHandler { target: "notifs" }` (`qs ipc call notifs clear`,
`qs ipc call notifs toggleDnd`) — that code path was never part of the patch
diff and needed no migration.

## DBus notification ownership (read-only investigation)

On the machine this was investigated on:

```
$ busctl --user list | grep -i notif
org.freedesktop.Notifications   <pid> mako   dilan  :1.670  user@1000.service
```

**`mako` currently owns `org.freedesktop.Notifications`, not Quickshell/`qs`.**
`qs` only owns `org.kde.StatusNotifierWatcher` /
`org.kde.StatusNotifierHost-*` (the tray, unrelated to notifications) on this
session. This means the patched `services/Notifs.qml`'s
`NotificationServer { ... }` is very likely **not** the active notification
backend right now — `mako` is intercepting `Notify()` calls first, so
Caelestia/Cortetsu's own DND, expiry-timeout, and toast logic may not be
exercised for real desktop notifications at all on this host today.

This is a real architectural fork Dilan should decide, not something to guess
past:

1. Keep `mako` as the actual notification daemon and treat
   `CortetsuNotifications`/the patched `Notifs.qml` popup/DND/toast pipeline
   as effectively dead code for real notifications (it would still work for
   any notification `mako` doesn't grab first, or if `mako.service` is ever
   stopped).
2. Disable `mako.service` and let Quickshell's `NotificationServer` own
   `org.freedesktop.Notifications`, making Cortetsu's DND/expiry/toast
   pipeline the live one.

**To verify or change this on the real host (not run from this sandbox, per
the no-host-mutation constraint on this task):**

```sh
# Confirm current owner:
busctl --user list | grep -i notif
busctl --user status org.freedesktop.Notifications

# If Dilan chooses option 2 (hand ownership to qs):
systemctl --user disable --now mako.service
# then restart the shell so qs's NotificationServer can claim the name.
```

No code in this change assumes either answer — `CortetsuNotifications.qml`
and `cortetsu-notifications` work identically regardless of which daemon
currently owns the DBus name, since they only ever touch Cortetsu's own
XDG-state snapshot files.

## Shared toast channel with Pomodoro

`cortetsu/bin/cortetsu-pomodoro` does not call DBus/`notify-send` directly. It
writes `$XDG_STATE_HOME/cortetsu/pomodoro-notification.json`
(`write_event`/`event_path`), which `cortetsu/modules/BottomHub.qml` watches
and renders via `Toaster.toast(event.title, event.message, "timer")` — the
same `Toaster` singleton the patched `Notifs.qml`/`GameMode.qml` use for DND
and game-mode toasts (`toastDndChanged`, `toastGameModeChanged`). One toast
channel, confirmed by reading both call sites; no duplicate toast pipeline
was introduced.

## Status

- GlobalConfig/Caelestia.Config in the patch: 0 (already migrated before this
  task; verified by inspection, not just the audit bucket).
- First-party facade added this task: `CortetsuNotifications.qml` (history,
  dismiss, clear, DND toggle, IPC handler) + `cortetsu-notifications` CLI +
  tests.
- Patch **not** deleted: the DBus notification server itself
  (`NotificationServer`, image caching, action/urgency dispatch in
  `NotifData.qml`) is still upstream-owned, same as every other still-patched
  service in `MANIFEST.tsv`. Deleting the patch would require a full
  first-party notification-daemon rewrite, out of scope for this increment.
