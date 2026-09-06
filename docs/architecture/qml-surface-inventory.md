# Cortetsu QML surface inventory

Baseline: `9219189` (`Hide inactive popup backgrounds cleanly`).

The active first-party composition enters through `cortetsu/shell.qml`. The
`cortetsu/modules` tree owns visible Cortetsu surfaces. `cortetsu/base` is an
upstream compatibility tree and is counted here only where an owned module
composes it directly. `cortetsu/modules/nexus` is the detached settings and
control surface used by the owned popup wrapper.

Maturity is intentionally conservative. A surface is `VERIFIED` only after
static checks, real runtime interaction, keyboard checks, visual inspection,
and clean journal evidence. Technical gates alone do not promote a surface.

| Surface | Entrypoint | Direct visual dependencies | Maturity | Main product gap | Priority |
| --- | --- | --- | --- | --- | --- |
| BottomHub | `modules/BottomHub.qml`, `modules/CortetsuBottomHubView.qml` | `CortetsuAppRail`, `CortetsuModeSegment`, `CortetsuStatusSegment`, `CortetsuTraySegment` | FUNCTIONAL | density, hierarchy, keyboard focus, state polish | P0 |
| Launcher | `modules/launcher/Wrapper.qml`, `Content.qml`, `AppList.qml`, `ContentList.qml` | launcher services, `CortetsuSearchBar`, item delegates | FUNCTIONAL | result hierarchy, focus model, empty/loading states | P1 |
| Quick Settings / Utilities | `modules/utilities/Wrapper.qml`, `Content.qml` | utility cards, `CortetsuSurface`, toggle controls | FUNCTIONAL | control-surface composition and state feedback | P1 |
| Notifications | `modules/sidebar/Content.qml`, `modules/notifications/Wrapper.qml`, `Notification.qml` | notification model, action list, scroll container | VERIFIED | real notify-send card, two-monitor toast, always-visible Dismiss, empty state, Escape close, and clean journal verified | P1 |
| Wi-Fi / Network | `modules/bar/popouts/CortetsuNetworkPopup.qml`, `base/modules/bar/popouts/Network.qml` | network service, list rows, password popup | COMPONENTIZED | loading/error/disconnected states and density | P1 |
| Audio / Volume | `modules/bar/popouts/CortetsuAudioPopup.qml`, `base/modules/bar/popouts/AudioPopout.qml` | audio service, sliders and device rows | COMPONENTIZED | hierarchy, slider feedback, keyboard control | P1 |
| Bluetooth | `modules/bar/popouts/CortetsuBluetoothPopup.qml`, `base/modules/bar/popouts/Bluetooth.qml` | Bluetooth service, device rows | COMPONENTIZED | connection states and action affordances | P1 |
| Battery | `modules/bar/popouts/CortetsuBatteryPopup.qml`, `base/modules/bar/popouts/Battery.qml` | UPower state, battery details | COMPONENTIZED | critical/charging/full state communication | P1 |
| Keyboard Layout | `modules/bar/popouts/CortetsuKeyboardPopup.qml`, `base/modules/bar/popouts/kblayout/KbLayout.qml` | layout model, selection rows | COMPONENTIZED | selected/focus states and long labels | P2 |
| Lock Status | `modules/bar/popouts/CortetsuLockStatusPopup.qml`, `base/modules/bar/popouts/LockStatus.qml` | lock state, action rows | COMPONENTIZED | disabled/error feedback | P2 |
| Active Window | `modules/bar/popouts/CortetsuActiveWindowPopup.qml`, `base/modules/bar/popouts/ActiveWindow.qml` | Hyprland active toplevel | COMPONENTIZED | missing/long-title states | P2 |
| Window Info | `modules/bar/popouts/CortetsuWindowInfoPopup.qml`, `base/modules/windowinfo/WindowInfo.qml` | preview, details and buttons | COMPONENTIZED | information hierarchy and focus | P2 |
| Tray | `modules/CortetsuTraySegment.qml`, `modules/bar/popouts/CortetsuTrayMenu.qml` | tray items and nested menu | FUNCTIONAL | row rhythm, nested affordance, keyboard | P1 |
| Tray submenus | `base/modules/bar/popouts/TrayMenu.qml`, `modules/bar/popouts/CortetsuTrayMenu.qml` | menu rows, separators, submenu state | FUNCTIONAL | nested focus and close feedback | P1 |
| OSD | `modules/osd/Wrapper.qml`, `Content.qml` | OSD host and indicators | VERIFIED | two-monitor volume trigger, shared indicator surface, bounded levels, restored volume, and clean journal verified; brightness wheel remains a separate device-dependent check | P2 |
| Toasts | `modules/utilities/toasts/Toasts.qml`, `ToastItem.qml` | toaster service, action rows | VERIFIED | two-monitor runtime, stacking, five-second expiration, mouse and Escape dismissal verified; full notification-center promotion remains separate | P1 |
| Overview | `modules/overview/Wrapper.qml`, `Content.qml`, `WindowCard.qml` | Hyprland windows/workspaces | FUNCTIONAL | keyboard selection, selected-card identity, scrim, and focused-monitor routing verified; many-window, empty-workspace, drag, close, and floating-action matrix remains | P0 |
| Display | `modules/display/Wrapper.qml`, `Content.qml` | display controller and editor | FUNCTIONAL | dense settings layout and error states | P2 |
| Hardware | `modules/hardware/Wrapper.qml`, `Content.qml` | hardware controller, metric cards | FUNCTIONAL | information hierarchy and loading states | P2 |
| Wallpaper | `modules/wallpaper/Wrapper.qml`, `Content.qml` | `CortetsuWallpapers`, orbit controls | FUNCTIONAL | selection feedback and empty/error states | P2 |

## Wave 0 foundation status

Existing shared contracts are `CortetsuDesign.js`, `CortetsuTokens.qml`,
`CortetsuColours.qml`, `CortetsuSurface.qml`, `CortetsuButton.qml`,
`CortetsuListRow.qml`, `CortetsuSectionHeader.qml`, `CortetsuSlider.qml`,
`CortetsuToggle.qml`, `CortetsuText.qml`, and `CortetsuStateLayer.qml`.

This checkpoint adds keyboard focus and activation to the two most common
interactive primitives. It does not change popup anchoring, screen selection,
service ownership, or detached popup behavior.
