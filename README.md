# cachyos-rice

Catppuccin Mocha / Pink for CachyOS + KDE Plasma 6.

Ported from [NixOS-rice](https://github.com/Arneke999/NixOS-rice) — same terminal,
shell, editor and typography, restyled from that rice's wallpaper-driven
(matugen) lain palette to a fixed Catppuccin Mocha one.

![palette](https://img.shields.io/badge/flavour-mocha-%231e1e2e) ![accent](https://img.shields.io/badge/accent-pink-%23f5c2e7)

## Install

```bash
git clone https://github.com/Arneke999/cachyos-rice.git ~/Projects/cachyos-rice
cd ~/Projects/cachyos-rice
./install.sh
```

Then **log out and back in** — the Qt style, cursor theme and fonts need a fresh
session.

`install.sh` is idempotent; re-run it any time. It backs up conflicting configs
to `~/.config-backup-<timestamp>/` rather than overwriting them.

## What it does

1. **Packages** — pacman + AUR (`yay`). Fonts, Kvantum, Papirus, Catppuccin
   colour scheme / cursors / Kvantum theme, Klassy decorations.
2. **Dotfiles** — GNU stow symlinks everything in `stow/` into `~`.
3. **KDE** — `kde/apply-kde.sh` sets the colour scheme, cursor, icons, fonts,
   and the flat/no-blur rule via `kwriteconfig6` and `plasma-apply-*`.

## Layout

```
install.sh              entry point
stow/                   each dir is a stow package, symlinked into ~
  kitty/ alacritty/     terminals
  fish/ starship/       shell + prompt
  nvim/                 neovim (lazy.nvim, catppuccin)
  fastfetch/ bat/ gtk/
kde/
  colors/               Plasma colour scheme
  konsole/              Konsole colour scheme + profile
  apply-kde.sh          idempotent Plasma theming
docs/palette.md         every hex used, single source of truth
wallpapers/
```

## Why KDE configs aren't stowed

Plasma rewrites `kwinrc`, `kdeglobals` and `plasmashellrc` continuously, and on
some writes replaces the file outright — which destroys a symlink and silently
detaches the repo from your live config.

So `apply-kde.sh` sets individual keys with `kwriteconfig6` instead. Idempotent,
survives Plasma's rewrites, safe to re-run.

## Panel

The panel layout is **not** scripted. `plasma-org.kde.plasma.desktop-appletsrc`
is a blob of generated applet IDs that is brittle to script and breaks across
Plasma versions.

Configure it by hand once — floating, thin, `mantle #181825`, minimal widgets —
then copy the resulting file into `kde/` as a reference for the next machine.

## Changing flavour

There is no render step; hexes are baked into the config files. To switch
flavour or accent, rewrite `docs/palette.md` first, then find/replace outward:

```bash
grep -rl '#1e1e2e' stow/ kde/    # find every file using the Mocha base
```

## Rollback

```bash
cp -r ~/.config-backup-<date>/* ~/.config/
```

## Not covered

Steam, Discord and Brave each need their own Catppuccin theming. The `lain`
wallpapers are carried over but are tuned for `#0f0f11`, not Mocha's `#1e1e2e` —
consider adding a Catppuccin-native one.
