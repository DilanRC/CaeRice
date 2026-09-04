# Hyprland import

Cortetsu can import the active `~/.config/hypr/hyprland` tree into the immutable dotfiles platform without adopting the directory as one opaque symlink.

The importer discovers regular UTF-8 configuration files and writes one manifest entry per file. This keeps rollback granular and lets Cortetsu coexist with other files under `~/.config/hypr` during the transition.

## Safety

The importer:

- ignores backup and temporary paths such as `*.bak`, `*.old`, `legacy-backup*`, cache and backup directories;
- skips symlinks, binary/non-UTF8 files and files larger than 1 MiB;
- blocks `apply` when a candidate appears to contain a password, API key, access/refresh token or client secret;
- refuses to overwrite an already-dirty repo-side Hyprland import area;
- rewrites only the generated `# BEGIN CORTETSU HYPRLAND IMPORT` manifest block;
- with `--commit`, stages only the generated Hyprland tree and `dotfiles/manifest.toml`.

## Flow

```bash
python3 core/import_hyprland.py plan
python3 core/import_hyprland.py apply --commit
./scripts/cortetsu test
cortetsu install
cortetsu verify
```

After the helper has been installed, the equivalent entrypoint is:

```bash
cortetsu-import-hyprland plan
cortetsu-import-hyprland apply --commit
```

The imported source-of-truth lives under:

```text
dotfiles/home/.config/hypr/hyprland/
```

and the generated manifest entries use the `hyprland` profile tag.
