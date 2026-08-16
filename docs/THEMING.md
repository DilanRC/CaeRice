# CaeRice theming architecture

CaeRice should not hard-code a separate palette per module. The shell, custom QML and external applications should all derive from the same Caelestia scheme.

## 1. Colour source

Caelestia CLI ships multiple scheme families, plus the dynamic Material scheme generated from the wallpaper.

Current upstream families include:

- `caelestia`
- `catppuccin`
- `darkgreen`
- `dracula`
- `everblush`
- `everforest`
- `gruvbox`
- `nord`
- `oldworld`
- `onedark`
- `rosepine`
- `shadotheme`
- `solarized`
- `tokyonight`
- `dynamic` (generated from the wallpaper)

Families can expose variants/flavours and light/dark modes depending on the scheme.

## 2. Shell visual contract

Custom CaeRice QML must use the same services as native Caelestia:

- `Colours.palette.*` for opaque Material roles.
- `Colours.tPalette.*` only when inheriting the user's shell transparency is intentional.
- `Tokens.*` for spacing, padding, rounding, typography and animation.
- `import qs.services` whenever `Colours` is referenced.
- `import Caelestia.Config` whenever `Tokens` is referenced.

Avoid fixed RGB/hex colours in normal UI components. Fixed colours are acceptable only for semantic content that must not follow the theme.

## 3. Global shell shape

Use `~/.config/caelestia/shell.json` for supported appearance scales. Use `shell-tokens.json` only for a small curated CaeRice token overlay; it is an advanced upstream interface and should not be copied wholesale.

The goal is for Dock, Launcher, Clipboard, Overview and future CaeRice panels to share the same:

- surface hierarchy;
- corner radii;
- spacing rhythm;
- typography hierarchy;
- motion durations/easing;
- active/hover/selected semantics.

## 4. External application bridge

Caelestia CLI can propagate the active scheme to several targets from `~/.config/caelestia/cli.json`, including Hyprland, Spicetify, GTK, Qt, Chromium, btop/nvtop/htop and Cava. Only targets actually used on the machine should be enabled.

For applications not covered directly, use Caelestia user templates in:

`~/.config/caelestia/templates/`

Generated files are written to:

`~/.local/state/caelestia/theme/`

Kitty should use a user template instead of a hard-coded standalone palette.

## 5. Dock favourites

CaeRice Dock intentionally uses `GlobalConfig.launcher.favouriteApps`, the same source as the launcher. A favourite is rendered even when it has zero windows; running apps are appended afterwards.

The custom launcher already supports right-clicking an application card to toggle `favouriteApps`. The next UI pass should make this discoverable with a visible pin affordance instead of relying on a hidden right-click gesture.

Do not create a second independent favourites database unless upstream persistence proves insufficient. One source of truth avoids launcher/dock drift.
