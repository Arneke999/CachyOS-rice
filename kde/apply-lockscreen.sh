#!/usr/bin/env bash
# ── apply-lockscreen.sh ──────────────────────────────────────────────────────
# Sets an animated (video) lock screen using the Smart Video Wallpaper Reborn
# plugin.
#
# Plasma's own wallpaper plugins (org.kde.image / slideshow / potd) are all
# still images — nothing stock animates. This plugin is the one that explicitly
# supports the *lock screen* greeter and not just the desktop.
#
#   Install:  yay -S plasma6-wallpapers-smart-video-wallpaper-reborn
#
# Usage:
#   ./apply-lockscreen.sh                 # use the first video in wallpapers/video/
#   ./apply-lockscreen.sh /path/to.mp4    # use a specific file
#
# Idempotent. Safe to re-run.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
say()  { printf '\033[38;2;245;194;231m::\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;249;226;175m!!\033[0m %s\n' "$*"; }

PLUGIN="luisbocanegra.smart.video.wallpaper.reborn"

# ── Escape hatch ────────────────────────────────────────────────────────────
# Puts the greeter back on the stock still-image plugin. Worth knowing before
# you need it: if the video plugin ever misbehaves you are staring at a broken
# lock screen, and fixing it from a TTY is nicer than fixing it blind.
if [ "${1:-}" = "--reset" ]; then
  say "reverting the lock screen to the stock image plugin"
  kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
  WALL=$(find "$REPO/wallpapers" -maxdepth 1 -type f \
          \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | sort | head -1 || true)
  if [ -n "$WALL" ]; then
    kwriteconfig6 --file kscreenlockerrc \
      --group Greeter --group Wallpaper --group org.kde.image --group General \
      --key Image "file://$WALL"
    echo "   image: $(basename "$WALL")"
  fi
  say "done."
  exit 0
fi

# ── Is the plugin actually installed? ───────────────────────────────────────
# Check before writing anything. Pointing the greeter at a plugin that isn't
# there gives you a black lock screen with no wallpaper controls — recoverable,
# but only by editing the config back out blind.
FOUND=""
for d in "/usr/share/plasma/wallpapers/$PLUGIN" \
         "$HOME/.local/share/plasma/wallpapers/$PLUGIN"; do
  [ -d "$d" ] && { FOUND="$d"; break; }
done

if [ -z "$FOUND" ]; then
  warn "$PLUGIN is not installed — not touching the lock screen config."
  echo "   Install it, then re-run this script:"
  echo "     yay -S plasma6-wallpapers-smart-video-wallpaper-reborn"
  exit 0
fi
say "found plugin at $FOUND"

# ── Pick the video ──────────────────────────────────────────────────────────
VIDEO="${1:-}"
if [ -z "$VIDEO" ]; then
  VIDEO=$(find "$REPO/wallpapers/video" -maxdepth 1 -type f \
            \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \) \
            2>/dev/null | sort | head -1 || true)
fi

if [ -z "$VIDEO" ] || [ ! -f "$VIDEO" ]; then
  warn "no video found — nothing to apply."
  echo "   Drop a looping video in $REPO/wallpapers/video/ and re-run,"
  echo "   or pass one directly:  $0 /path/to/video.mp4"
  exit 0
fi

VIDEO="$(cd "$(dirname "$VIDEO")" && pwd)/$(basename "$VIDEO")"   # absolutise
say "using video: $(basename "$VIDEO")"

# GitHub rejects files >100MB and warns past 50MB. A lock screen loop that big
# belongs in Git LFS, not in the tree.
SIZE_MB=$(( $(stat -c%s "$VIDEO") / 1024 / 1024 ))
if [ "$SIZE_MB" -gt 45 ] && [ "${VIDEO#$REPO/}" != "$VIDEO" ]; then
  warn "${SIZE_MB}MB is large for a git repo — consider Git LFS or a shorter loop."
fi

# ── Build the VideoUrls value ───────────────────────────────────────────────
# Stored as a JSON array of objects. `filename` goes straight to Qt's
# MediaPlayer source, so use a file:// URL rather than a bare path.
VIDEO_JSON=$(printf '[{"filename":"file://%s","enabled":true,"duration":0,"customDuration":0,"playbackRate":0.0,"alternativePlaybackRate":0.0,"loop":false}]' "$VIDEO")

cfg() {
  kwriteconfig6 --file kscreenlockerrc \
    --group Greeter --group Wallpaper --group "$PLUGIN" --group General \
    --key "$1" "$2"
}

say "configuring the lock screen greeter"
kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin "$PLUGIN"

cfg VideoUrls "$VIDEO_JSON"
# PreserveAspectCrop — fill the screen, crop the overflow. Letterboxing on a
# lock screen looks broken.
cfg FillMode 2
# MuteMode 5 = Always. Non-negotiable: the greeter has no volume control, so an
# unmuted video means audio you cannot stop without logging in.
cfg MuteMode 5
# PauseMode 3 = Never. The other modes pause based on maximized/active windows,
# which is meaningless on a lock screen — it would just never play.
cfg PauseMode 3
# ...but do stop decoding once the monitor sleeps. No point rendering video at
# a screen that's off.
cfg ScreenOffPausesVideo true
# BlurMode 5 = Never. FillMode already covers the screen.
cfg BlurMode 5
# Matches the rice: Catppuccin Mocha base, shown before the first frame decodes.
cfg BackgroundColor "#1e1e2e"

echo
say "done."
echo "   Test it without locking yourself out of anything:  loginctl lock-session"
echo "   Revert to a still image:  $REPO/kde/apply-lockscreen.sh --reset"
