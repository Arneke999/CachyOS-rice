# CachyOS-rice

Catppuccin Mocha / Pink for CachyOS + KDE Plasma 6.

Ported from [NixOS-rice](https://github.com/Arneke999/NixOS-rice) — same terminal,
shell, editor and typography, restyled from that rice's wallpaper-driven
(matugen) lain palette to a fixed Catppuccin Mocha one.

![palette](https://img.shields.io/badge/flavour-mocha-%231e1e2e) ![accent](https://img.shields.io/badge/accent-pink-%23f5c2e7)

## Install

```bash
git clone https://github.com/Arneke999/CachyOS-rice.git ~/Projects/cachyos-rice
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
3. **Services** — `scripts/enable-services.sh` enables the background session
   services (EasyEffects, OpenRGB). See [Background services](#background-services).
4. **KDE** — `kde/apply-kde.sh` sets the colour scheme, cursor, icons, fonts,
   GTK theming and the flat/no-blur rule via `kwriteconfig6` and
   `plasma-apply-*`.

## Layout

```
install.sh              entry point
stow/                   each dir is a stow package, symlinked into ~
  kitty/ alacritty/     terminals
  fish/ starship/       shell + prompt
  nvim/                 neovim (lazy.nvim, catppuccin)
  fastfetch/ bat/
  systemd/              user units for background services
kde/
  colors/               Plasma colour scheme
  konsole/              Konsole colour scheme + profile
  gtk/gtk.css           GTK named colours, copied out by apply-kde.sh
  apply-kde.sh          idempotent Plasma theming
  apply-lockscreen.sh   animated (video) lock screen
scripts/
  enable-services.sh    enables the systemd user units
docs/palette.md         every hex used, single source of truth
wallpapers/
  video/                lock screen loops
```

## Animated lock screen

Nothing stock animates — every Plasma wallpaper plugin that ships with the
desktop (`org.kde.image`, `slideshow`, `potd`, `color`, `tiled`) is a still
image. The animated lock screens you see are a third-party wallpaper plugin,
**Smart Video Wallpaper Reborn**, which is the one that supports the lock
screen greeter and not just the desktop.

```sh
yay -S plasma6-wallpapers-smart-video-wallpaper-reborn
# drop a looping video in wallpapers/video/  (see the README there)
kde/apply-lockscreen.sh
loginctl lock-session          # test it
```

`apply-kde.sh` runs it too, and it no-ops cleanly when the plugin is missing or
there's no video, so nothing breaks on a machine that hasn't installed it.

The settings it writes to `kscreenlockerrc`, and why:

| Key | Value | Reason |
|---|---|---|
| `FillMode` | `2` PreserveAspectCrop | Fills the screen; letterboxing looks broken |
| `MuteMode` | `5` Always | The greeter has no volume control — unmuted audio can't be stopped without logging in |
| `PauseMode` | `3` Never | Other modes pause on maximized/active windows, meaningless on a lock screen |
| `ScreenOffPausesVideo` | `true` | Stop decoding once the monitor sleeps |
| `BackgroundColor` | `#1e1e2e` | Mocha base, shown before the first frame decodes |

Caveats:

- **Have the escape hatch ready before you need it.** A misbehaving video
  plugin means staring at a broken lock screen. `kde/apply-lockscreen.sh
  --reset` puts the stock image plugin back; it's much nicer to run that than
  to edit `kscreenlockerrc` blind from a TTY.
- The script **refuses to write anything** if the plugin isn't installed, since
  pointing the greeter at a missing plugin gives you a black screen with no
  wallpaper controls.
- Upstream reports Qt crashes on **AMD** GPUs ([QTBUG-124586]); switching the
  Qt media backend to GStreamer is the workaround. Not an issue on the NVIDIA
  card here.
- A video wallpaper decodes continuously. `ScreenOffPausesVideo` covers the
  idle case, but this is a desktop-shaped tradeoff — think twice on a laptop
  (the plugin has battery-threshold options for that).

[QTBUG-124586]: https://bugreports.qt.io/browse/QTBUG-124586

## Background services

EasyEffects and OpenRGB start with the desktop as **systemd user units**
(`stow/systemd/.config/systemd/user/`), not `~/.config/autostart/*.desktop`.
Plasma 6 here is systemd-managed, so `graphical-session.target` is a real
ordering point — which `.desktop` autostart has no way to express, and
EasyEffects genuinely needs to start after PipeWire.

| Unit | Runs | Config it loads |
|---|---|---|
| `easyeffects.service` | `easyeffects --service-mode` (no window) | `~/.config/easyeffects/db/` — read automatically |
| `openrgb.service` | `openrgb --startminimized --profile main` | `~/.config/OpenRGB/main.orp` |

Both are `PartOf=graphical-session.target`, so they stop on logout rather than
lingering.

```sh
bash scripts/enable-services.sh     # enable + (re)start, idempotent
systemctl --user status openrgb.service
journalctl --user -u openrgb.service -f
systemctl --user disable --now easyeffects.service   # opt out
```

Things worth knowing:

- **OpenRGB takes ~10s** to log `Profile loaded successfully` — hardware
  detection runs first. That's normal, not a hang.
- **Don't also use OpenRGB's built-in autostart** (`openrgb
  --autostart-enable`). Two mechanisms means two instances fighting over the
  same USB/SMBus controllers; `enable-services.sh` turns it off if it finds it.
- The packaged **system-wide** `openrgb.service` is a different thing — it runs
  `--server` as root against `/etc/openrgb` and never sees your profile. Leave
  it disabled.
- OpenRGB is a **Qt5** app and there is no Qt5 Wayland platform plugin here, so
  the unit pins `QT_QPA_PLATFORM=xcb` and clears the qt6-only Kvantum style
  override. Without those it still works, but logs two errors per start.
- SMBus/i2c access needs no root: the packaged udev rules tag `/dev/i2c-*` with
  `uaccess`, so the seat's active user gets an ACL. Running in the *user*
  session is what makes that apply.
- `mkdir -p ~/.config/systemd/user` before stowing — otherwise stow folds the
  tree, symlinks the whole directory into this repo, and `systemctl --user
  enable` writes its `.wants/` symlinks inside your git checkout. `install.sh`
  does this for you.

## Why KDE configs aren't stowed

Plasma rewrites `kwinrc`, `kdeglobals` and `plasmashellrc` continuously, and on
some writes replaces the file outright — which destroys a symlink and silently
detaches the repo from your live config.

So `apply-kde.sh` sets individual keys with `kwriteconfig6` instead. Idempotent,
survives Plasma's rewrites, safe to re-run.

**GTK is the same story.** `kde-gtk-config` owns `~/.config/gtk-3.0` and
`gtk-4.0`: it generates `colors.css` and `assets/` from the active Plasma colour
scheme, and rewrites `settings.ini` and `gtk.css` in place. Stowing those files
meant every KDE GTK write showed up as a dirty file in this repo — and it had
already replaced the `gtk.css` symlink with a real file, silently detaching it.

So GTK is generated too. `kde/gtk/gtk.css` holds the named colours (GTK3 and
GTK4 share them), and `apply-kde.sh` copies it to both directories and writes
`settings.ini` alongside.

This doesn't stop KDE rewriting those files — nothing does. It stops the
rewrites from touching the repo. KDE preserves the values that matter (theme,
cursor, icons) and only normalises formatting and appends machine-specific keys
like `gtk-xft-dpi`, so re-running `apply-kde.sh` reasserts the rice.

One gotcha the script handles: `kde-gtk-config` expects `gtk.css` to end with
`@import 'colors.css';`. Copying our file over the top drops that line, so the
script re-appends it — but only when `colors.css` exists, since a dangling
import makes GTK log a parse error on every app launch.

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
