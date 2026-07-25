#!/usr/bin/env bash
# ── enable-services.sh ───────────────────────────────────────────────────────
# Enables the background session services (EasyEffects, OpenRGB) so they start
# with the desktop and load their saved configs.
#
# The unit files themselves are stowed from stow/systemd/, so this script only
# has to reload systemd and flip the enable switch. Idempotent — re-run freely.
#
# Why systemd user units rather than ~/.config/autostart/*.desktop:
#   - Plasma 6 on this machine is systemd-managed (plasma-*.service units), so
#     graphical-session.target is a real ordering point.
#   - Ordering After=pipewire matters for EasyEffects; .desktop autostart has no
#     way to express it.
#   - Restart=on-failure, plus `systemctl --user status` for debugging.
set -euo pipefail

say()  { printf '\033[38;2;245;194;231m::\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;249;226;175m!!\033[0m %s\n' "$*"; }

UNIT_DIR="$HOME/.config/systemd/user"

say "reloading the systemd user manager"
systemctl --user daemon-reload

enable_unit() {
  local unit="$1" bin="$2"
  if [ ! -e "$UNIT_DIR/$unit" ]; then
    warn "$unit not found in $UNIT_DIR — run stow first"
    return 0
  fi
  if ! command -v "$bin" >/dev/null 2>&1; then
    warn "$bin not installed — skipping $unit"
    return 0
  fi
  say "enabling $unit"
  systemctl --user enable "$unit"
  # Restart rather than start: picks up unit edits and replaces any instance
  # that was launched by hand from the app menu.
  systemctl --user restart "$unit"
}

# ── EasyEffects ─────────────────────────────────────────────────────────────
# A GUI-launched instance holds the PipeWire filter nodes; the unit can't take
# over until it's gone. Service mode reconnects to the same settings anyway.
if pgrep -x easyeffects >/dev/null 2>&1 \
   && ! systemctl --user is-active --quiet easyeffects.service; then
  say "stopping the hand-launched EasyEffects instance"
  easyeffects --quit >/dev/null 2>&1 || pkill -x easyeffects || true
  # Give PipeWire a moment to release the filter nodes.
  sleep 1
fi
enable_unit easyeffects.service easyeffects

# ── OpenRGB ─────────────────────────────────────────────────────────────────
# OpenRGB has its own autostart mechanism (`openrgb --autostart-enable`) which
# writes ~/.config/autostart/OpenRGB.desktop. Leave that off — two mechanisms
# would launch two instances fighting over the same USB/SMBus controllers.
if [ -e "$HOME/.config/autostart/OpenRGB.desktop" ]; then
  warn "found ~/.config/autostart/OpenRGB.desktop — disabling it in favour of the unit"
  openrgb --autostart-disable >/dev/null 2>&1 \
    || rm -f "$HOME/.config/autostart/OpenRGB.desktop"
fi

if [ ! -f "$HOME/.config/OpenRGB/main.orp" ]; then
  warn "no ~/.config/OpenRGB/main.orp — open OpenRGB, set your lighting, and"
  warn "save it as a profile named 'main', or edit the unit's --profile flag"
fi
enable_unit openrgb.service openrgb

echo
say "done. Current state:"
systemctl --user --no-pager --plain list-units \
  'easyeffects.service' 'openrgb.service' 2>/dev/null || true
