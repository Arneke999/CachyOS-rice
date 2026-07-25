#!/usr/bin/env bash
# ── apply-kde.sh ─────────────────────────────────────────────────────────────
# Applies the Catppuccin Mocha / Pink look to KDE Plasma.
#
# KDE rewrites its own rc files continuously, and on some writes replaces them
# outright — which would destroy a symlink. So instead of stowing kwinrc /
# kdeglobals, this script sets individual keys with kwriteconfig6. That is
# idempotent and safe to re-run at any time.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
say() { printf '\033[38;2;245;194;231m::\033[0m %s\n' "$*"; }

# ── Install the colour scheme & Konsole assets from the repo ─────────────────
say "installing colour scheme and Konsole assets"
mkdir -p ~/.local/share/color-schemes ~/.local/share/konsole
cp "$REPO/kde/colors/CatppuccinMochaPink.colors" ~/.local/share/color-schemes/
cp "$REPO/kde/konsole/CatppuccinMocha.colorscheme" ~/.local/share/konsole/
cp "$REPO/kde/konsole/Rice.profile" ~/.local/share/konsole/

# ── Colour scheme, cursor, icons ────────────────────────────────────────────
say "applying colour scheme"
plasma-apply-colorscheme CatppuccinMochaPink

if [ -d /usr/share/icons/catppuccin-mocha-pink-cursors ] \
   || [ -d ~/.local/share/icons/catppuccin-mocha-pink-cursors ]; then
  say "applying cursor theme"
  plasma-apply-cursortheme catppuccin-mocha-pink-cursors || \
    echo "   (cursor theme failed; set it in System Settings > Cursors)"
else
  echo "   catppuccin cursors not found — skipping (install catppuccin-cursors-mocha)"
fi

if command -v papirus-folders >/dev/null 2>&1; then
  say "tinting Papirus folders pink"
  papirus-folders -C cat-mocha-pink --theme Papirus-Dark >/dev/null
fi

# ── Fonts — Inter for UI, JetBrainsMono NF for fixed. Same as the lain rice. ─
say "setting fonts"
kwriteconfig6 --file kdeglobals --group General --key font        "Inter,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group General --key fixed       "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group General --key menuFont    "Inter,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group General --key toolBarFont "Inter,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "Inter,8,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group WM      --key activeFont  "Inter,10,-1,5,50,0,0,0,0,0"

# ── Icons ───────────────────────────────────────────────────────────────────
kwriteconfig6 --file kdeglobals --group Icons --key Theme "Papirus-Dark"

# ── The flat rule: no blur, no shadow. Mirrors hyprland.conf's decoration. ──
say "disabling blur and contrast effects (flat look)"
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
kwriteconfig6 --file kwinrc --group Plugins --key contrastEnabled false

# ── Motion: restrained, matching the rice's 175–300ms easings ───────────────
kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 0.75

# ── Window decoration ───────────────────────────────────────────────────────
if [ -d /usr/share/kwin/decorations/org.kde.klassy ] \
   || [ -d ~/.local/share/kwin/decorations/org.kde.klassy ]; then
  say "using Klassy decoration (rounded corners)"
  kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.klassy
  kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Klassy
else
  echo "   klassy not installed — keeping current decoration"
  echo "   (install with: yay -S klassy, then re-run this script for rounded corners)"
fi

# ── Kvantum (Qt widget style) ───────────────────────────────────────────────
if command -v kvantummanager >/dev/null 2>&1; then
  for t in Catppuccin-Mocha-Pink Catppuccin-Mocha catppuccin-mocha-pink; do
    if kvantummanager --set "$t" >/dev/null 2>&1; then
      say "Kvantum theme set to $t"
      mkdir -p ~/.config/environment.d
      echo 'QT_STYLE_OVERRIDE=kvantum' > ~/.config/environment.d/kvantum.conf
      break
    fi
  done
fi

# ── Wallpaper ───────────────────────────────────────────────────────────────
WALL=$(find "$REPO/wallpapers" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | sort | head -1)
if [ -n "${WALL:-}" ]; then
  say "setting wallpaper: $(basename "$WALL")"
  plasma-apply-wallpaperimage "$WALL" || echo "   (wallpaper failed; set it manually)"
else
  echo "   no wallpaper in $REPO/wallpapers — skipping"
fi

# ── Reload ──────────────────────────────────────────────────────────────────
say "reloading KWin"
if command -v qdbus6 >/dev/null 2>&1; then
  qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
elif command -v qdbus >/dev/null 2>&1; then
  qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo
say "done."
echo "   Log out and back in for the Qt style, cursor and fonts to fully apply."
