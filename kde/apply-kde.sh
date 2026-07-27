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
  # Papirus lives in /usr/share/icons, so this needs root. Non-fatal: pink
  # folders are cosmetic and the rest of the theme must still apply.
  if ! papirus-folders -C cat-mocha-pink --theme Papirus-Dark >/dev/null 2>&1; then
    echo "   needs root — run separately if you want pink folders:"
    echo "     sudo papirus-folders -C cat-mocha-pink --theme Papirus-Dark"
  fi
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
# Klassy ships as a KDecoration plugin, not a directory under
# /usr/share/kwin/decorations. Plasma 6.7 uses the kdecoration3 ABI; older
# releases used kdecoration2, so detect which is present rather than guessing.
KLASSY_SO=""
for d in /usr/lib/qt6/plugins/org.kde.kdecoration3 \
         /usr/lib/qt6/plugins/org.kde.kdecoration2 \
         "$HOME/.local/lib/qt6/plugins/org.kde.kdecoration3"; do
  if [ -f "$d/org.kde.klassy.so" ]; then
    KLASSY_SO="$d"
    break
  fi
done

if [ -n "$KLASSY_SO" ]; then
  # Group name must match the ABI version the plugin was built against.
  case "$KLASSY_SO" in
    *kdecoration3*) DECO_GROUP="org.kde.kdecoration3" ;;
    *)              DECO_GROUP="org.kde.kdecoration2" ;;
  esac
  say "using Klassy decoration (rounded corners) via $DECO_GROUP"
  kwriteconfig6 --file kwinrc --group "$DECO_GROUP" --key library org.kde.klassy
  kwriteconfig6 --file kwinrc --group "$DECO_GROUP" --key theme Klassy
  # Corner radius 8, matching the rice's `rounding = 8`.
  kwriteconfig6 --file klassyrc --group Common --key CornerRadius 8
else
  echo "   klassy not installed — keeping current decoration"
  echo "   (install with: yay -S klassy, then re-run this script for rounded corners)"
fi

# ── Kvantum (Qt widget style) ───────────────────────────────────────────────
# NB: `kvantummanager --set` returns 0 and pops open its GUI when handed a theme
# name that doesn't exist, so it can't be used to probe for a theme. Check the
# theme directory first, then write kvantum.kvconfig directly — no GUI, no guessing.
if command -v kvantummanager >/dev/null 2>&1; then
  KV_THEME=""
  for t in catppuccin-mocha-pink Catppuccin-Mocha-Pink; do
    if [ -d "/usr/share/Kvantum/$t" ] || [ -d "$HOME/.config/Kvantum/$t" ]; then
      KV_THEME="$t"
      break
    fi
  done
  if [ -n "$KV_THEME" ]; then
    say "setting Kvantum theme to $KV_THEME"
    mkdir -p ~/.config/Kvantum
    printf '[General]\ntheme=%s\n' "$KV_THEME" > ~/.config/Kvantum/kvantum.kvconfig
    mkdir -p ~/.config/environment.d
    echo 'QT_STYLE_OVERRIDE=kvantum' > ~/.config/environment.d/kvantum.conf
  else
    warn_kv="   no catppuccin Kvantum theme found — skipping"
    echo "$warn_kv"
    # Don't leave QT_STYLE_OVERRIDE pointing at an unconfigured Kvantum.
    rm -f ~/.config/environment.d/kvantum.conf
  fi
fi

# ── GTK ─────────────────────────────────────────────────────────────────────
# Generated here rather than stowed. kde-gtk-config owns ~/.config/gtk-{3,4}.0:
# it regenerates colors.css and assets/ from the Plasma colour scheme, and it
# rewrites settings.ini and gtk.css in place — replacing them outright, which
# destroys a symlink and silently detaches the repo from the live config. Same
# reasoning as kwinrc/kdeglobals above.
#
# This does NOT stop KDE rewriting these files; it stops those rewrites from
# showing up as dirty files in git. KDE preserves the values that matter (theme,
# cursor, icons) and only normalises formatting and appends machine-specific
# keys like gtk-xft-dpi, so re-running this script is enough to reassert the rice.
say "writing GTK settings"
for ver in 3.0 4.0; do
  d="$HOME/.config/gtk-$ver"
  mkdir -p "$d"

  cat > "$d/settings.ini" <<'EOF'
[Settings]
gtk-application-prefer-dark-theme=true
gtk-cursor-theme-name=catppuccin-mocha-pink-cursors
gtk-cursor-theme-size=24
gtk-font-name=Inter 10
gtk-icon-theme-name=Papirus-Dark
gtk-theme-name=catppuccin-mocha-pink-standard+default
EOF

  cp "$REPO/kde/gtk/gtk.css" "$d/gtk.css"
  # kde-gtk-config generates colors.css next to gtk.css and expects gtk.css to
  # pull it in. Copying our file over the top drops that import, so put it back
  # — but only if the file is actually there, or GTK logs a parse error on every
  # app launch.
  if [ -f "$d/colors.css" ]; then
    echo "@import 'colors.css';" >> "$d/gtk.css"
  fi
  echo "   gtk-$ver"
done

# ── Wallpaper ───────────────────────────────────────────────────────────────
WALL=$(find "$REPO/wallpapers" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | sort | head -1)
if [ -n "${WALL:-}" ]; then
  say "setting wallpaper: $(basename "$WALL")"
  plasma-apply-wallpaperimage "$WALL" || echo "   (wallpaper failed; set it manually)"
else
  echo "   no wallpaper in $REPO/wallpapers — skipping"
fi

# ── Animated lock screen ────────────────────────────────────────────────────
# No-ops cleanly if the plugin isn't installed or there's no video to play.
say "configuring the lock screen"
bash "$REPO/kde/apply-lockscreen.sh"

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
