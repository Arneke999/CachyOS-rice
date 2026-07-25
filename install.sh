#!/usr/bin/env bash
# ── install.sh ───────────────────────────────────────────────────────────────
# Bootstraps the CachyOS rice on a fresh machine:
#   1. install packages (pacman + AUR via yay)
#   2. symlink dotfiles with GNU stow
#   3. apply the KDE Plasma theme
#
# Safe to re-run. Existing conflicting configs are backed up, not clobbered.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
say()  { printf '\033[38;2;245;194;231m::\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;249;226;175m!!\033[0m %s\n' "$*"; }

# ── Preflight ───────────────────────────────────────────────────────────────
command -v yay >/dev/null || { echo "yay is required. Install it first."; exit 1; }
[ "$XDG_CURRENT_DESKTOP" = "KDE" ] || warn "not a KDE session — the KDE step may not apply cleanly"

PACMAN_PKGS=(
  stow                      # dotfile symlink manager
  ttf-jetbrains-mono-nerd   # terminal font (from the NixOS rice)
  inter-font                # UI font (from the NixOS rice)
  papirus-icon-theme
  kvantum                   # Qt widget style engine
  starship
  neovim
  fastfetch
  bat
  eza
  kitty
  konsole
)

AUR_PKGS=(
  catppuccin-plasma-colorscheme-mocha
  kvantum-theme-catppuccin-git
  catppuccin-cursors-mocha
  papirus-folders-catppuccin-git
  klassy                    # rounded window decorations
)

say "installing packages from the official repos"
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

say "installing packages from the AUR"
# --needed so re-runs are cheap; failures on a single -git package shouldn't
# abort the whole install, so these go one at a time.
for p in "${AUR_PKGS[@]}"; do
  yay -S --needed --noconfirm "$p" || warn "failed to install $p (continuing)"
done

# ── Stow the dotfiles ───────────────────────────────────────────────────────
say "backing up any conflicting configs"
BK="$HOME/.config-backup-$(date +%F-%H%M%S)"
for f in \
  "$HOME/.config/kitty/kitty.conf" \
  "$HOME/.config/kitty/kitty.conf.in" \
  "$HOME/.config/alacritty/alacritty.toml" \
  "$HOME/.config/fish/config.fish" \
  "$HOME/.config/starship.toml" \
  "$HOME/.config/fastfetch/config.jsonc" \
  "$HOME/.config/bat/config" \
  "$HOME/.config/gtk-3.0/settings.ini" \
  "$HOME/.config/gtk-3.0/gtk.css" \
  "$HOME/.config/gtk-4.0/settings.ini" \
  "$HOME/.config/gtk-4.0/gtk.css"
do
  # Only move real files; existing symlinks into this repo are fine to leave.
  if [ -f "$f" ] && [ ! -L "$f" ]; then
    mkdir -p "$BK/$(dirname "${f#$HOME/}")"
    mv "$f" "$BK/${f#$HOME/}"
    echo "   moved $(basename "$f") -> $BK"
  fi
done

say "symlinking dotfiles with stow"
cd "$REPO/stow"
for pkg in */; do
  stow -t "$HOME" -R "${pkg%/}"
  echo "   stowed ${pkg%/}"
done
cd "$REPO"

# ── KDE ─────────────────────────────────────────────────────────────────────
say "applying the KDE Plasma theme"
bash "$REPO/kde/apply-kde.sh"

echo
say "install complete."
echo
echo "  Remaining manual steps:"
echo "    1. Log out and back in (Qt style, cursor, fonts)."
echo "    2. Panel layout is not scripted — see README.md > Panel."
echo "    3. Set your terminal font if you use Konsole: profile 'Rice'."
