# Fish in Cortetsu

The `personal` profile treats Fish as the canonical interactive user shell.

Cortetsu does not invent or overwrite the user's Fish configuration. The live
`~/.config/fish` tree is first inspected and then snapshotted explicitly with:

```fish
python3 core/import_fish.py plan
python3 core/import_fish.py apply --commit
```

The importer stores accepted files below:

```text
dotfiles/imported/fish/home/.config/fish/
```

and writes a dedicated `CORTETSU FISH IMPORT` block to
`dotfiles/manifest.toml`. Every imported file uses the `user-shell` tag, so it
participates in the same immutable dotfiles and unified system generations as
Hyprland, Kitty, GTK and Qt.

## Safety rules

The importer:

- scans only `~/.config/fish`;
- accepts regular UTF-8 text files up to 2 MiB;
- skips symlinks, backups, temporary files and binary/non-UTF-8 content;
- always skips `fish_variables`, because universal-variable state is mutable
  machine state rather than declarative source configuration;
- blocks the whole apply when a file appears to contain a password, API key,
  access/refresh token, client secret or private key;
- stages only `dotfiles/manifest.toml` and `dotfiles/imported/fish`, leaving
  unrelated worktree changes untouched;
- replaces the imported Fish snapshot atomically so removed live files do not
  survive as stale repository artifacts.

## Zsh compatibility

A previously imported `.zshrc` is deliberately left intact for now. Fish is the
personal shell, but removing an already-managed Zsh target without a general
managed-target retirement mechanism could leave a stale link after generation
promotion. Cortetsu therefore preserves it until target retirement is handled
transactionally for all dotfiles, rather than deleting user configuration as a
special case.

## Expected machine verification

After importing Fish, run:

```fish
cortetsu install
cortetsu verify
cortetsu doctor
readlink -f ~/.config/fish/config.fish
```

The resolved Fish path should live below the current Cortetsu dotfiles
generation, and `doctor` should report the required `fish` command/package on
Arch/CachyOS.
