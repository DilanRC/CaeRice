# Hyprland import

Cortetsu can import the active `~/.config/hypr` tree into the immutable dotfiles platform without adopting the directory as one opaque symlink, and without ever making `~/.config/caelestia` a Lua module root.

The importer has two scopes:

- **`modules`** (default) discovers every regular UTF-8 file under `~/.config/hypr/hyprland/` — the per-domain Hyprland config (`env.lua`, `keybinds.lua`, `rules.lua`, ...). One manifest entry per file, so rollback stays granular.
- **`core`** imports a fixed, load-bearing set of files that make that tree resolvable at all: the loader (`hyprland.lua`), `variables.lua`, the transitive `utils/functions.lua` and `utils/json.lua`, and the `scheme/default.lua` fallback palette. This set is enumerated explicitly, not discovered, because it is small and every file in it is required for Hyprland to load without error.

`scheme/current.lua` is deliberately **not** imported by either scope: it is live, per-user theme state that `hyprland.lua` bootstraps from `scheme/default.lua` on first run (see the `maybe_copy` call at the top of the loader). Treating it as a fixed dotfile would fight live theme switching.

## Why `core` exists

Before the `core` scope existed, only the `hyprland/` module subtree was dotfiles-managed. The loader itself, `variables.lua`, `utils/functions.lua`, `utils/json.lua` and `scheme/default.lua` lived only on the live host. A prior migration session deleted `~/.config/caelestia/hyprland` (the tree the loader used to fall back to via `package.path`) and the recovery was applied directly to `~/.config/hypr`, but never captured back into the repo. `cortetsu install` from a clean checkout would have reproduced the exact regression this fixed, because the reproducible source never had these files.

`scripts/features/test-hyprland-self-contained.py` is the regression test for this: it loads `hyprland.lua` from the repo's `dotfiles/home/.config/hypr` in a throwaway `$HOME` that has **no** `~/.config/caelestia` at all, and asserts every required module and its transitive dependencies resolve anyway.

## Safety

The importer:

- ignores backup and temporary paths, including Cortetsu's own timestamped-backup convention (`name.bak-20260905-131903`, `name.bak.20260905-131903`), not just a plain `.bak` suffix;
- skips symlinks, binary/non-UTF8 files and files larger than 1 MiB;
- blocks `apply` when a candidate appears to contain a password, API key, access/refresh token or client secret;
- refuses to overwrite an already-dirty repo-side Hyprland import area (scoped to just the files each scope touches, so `modules` and `core` can be applied back-to-back);
- rewrites only its own scope's generated manifest block (`# BEGIN CORTETSU HYPRLAND IMPORT` for `modules`, `# BEGIN CORTETSU HYPRLAND CORE IMPORT` for `core`);
- validates the manifest before touching any real file, so a bad manifest never leaves file copies ahead of what it declares;
- with `--commit`, stages only the files it wrote plus `dotfiles/manifest.toml`.

## Flow

```bash
python3 core/import_hyprland.py plan --scope modules
python3 core/import_hyprland.py plan --scope core
python3 core/import_hyprland.py apply --commit --scope modules
python3 core/import_hyprland.py apply --commit --scope core
./scripts/cortetsu test
cortetsu dotfiles apply
cortetsu dotfiles verify
```

After the helper has been installed, the equivalent entrypoint is:

```bash
cortetsu-import-hyprland plan --scope core
cortetsu-import-hyprland apply --commit --scope core
```

The imported source-of-truth lives under:

```text
dotfiles/home/.config/hypr/hyprland/     (modules scope)
dotfiles/home/.config/hypr/              (core scope: hyprland.lua, variables.lua, utils/, scheme/default.lua, verify.fish)
```

and the generated manifest entries use the `hyprland` profile tag.

## Regression coverage

- `scripts/features/test-hyprland-import.py` — the importer's own contract (both scopes): discovery vs fixed-set scanning, backup/binary/symlink/secret filtering, manifest block hygiene, commit scoping.
- `scripts/features/test-hyprland-self-contained.py` — dynamic proof that the imported tree loads under `lua5.4` with no `~/.config/caelestia` present, plus a static gate forbidding any file in the repo from referencing the deleted `.config/caelestia/hyprland` tree.
- `scripts/features/test-shortcut-namespace.py` — the Hyprland-side global shortcut dispatch (`hl.dsp.global("cortetsu:...")`) and the QML-side `GlobalShortcut { appid: "cortetsu" }` patch stay on the same namespace.
