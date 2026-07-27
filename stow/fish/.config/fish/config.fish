# ── fish — CachyOS defaults + rice ───────────────────────────────────────────
# Keep the CachyOS config first so distro integrations stay intact, then layer
# the rice on top.
source /usr/share/cachyos-fish-config/cachyos-config.fish

# The CachyOS config defines fish_greeting to run fastfetch on every new shell.
# Override it with an empty function so terminals open clean. Run `fastfetch`
# by hand when you actually want it.
function fish_greeting
end

# Starship replaces the CachyOS prompt. Must come after the source above.
if status is-interactive
    starship init fish | source
end

# ── Catppuccin Mocha syntax highlighting ─────────────────────────────────────
set -g fish_color_normal              cdd6f4
set -g fish_color_command             89b4fa
set -g fish_color_param               f2cdcd
set -g fish_color_keyword             f38ba8
set -g fish_color_quote               a6e3a1
set -g fish_color_redirection         f5c2e7
set -g fish_color_end                 fab387
set -g fish_color_comment             7f849c
set -g fish_color_error               f38ba8
set -g fish_color_gray                6c7086
set -g fish_color_selection --background=313244
set -g fish_color_search_match --background=313244
set -g fish_color_option              a6e3a1
set -g fish_color_operator            f5c2e7
set -g fish_color_escape              eba0ac
set -g fish_color_autosuggestion      6c7086
set -g fish_color_cancel              f38ba8
set -g fish_color_valid_path --underline

set -g fish_pager_color_progress      6c7086
set -g fish_pager_color_prefix        f5c2e7
set -g fish_pager_color_completion    cdd6f4
set -g fish_pager_color_description   6c7086
set -g fish_pager_color_selected_background --background=313244

# ── Aliases (carried over from the NixOS rice) ───────────────────────────────
if type -q eza
    alias ls 'eza --group-directories-first --icons'
    alias ll 'eza -l --group-directories-first --icons --git'
    alias la 'eza -la --group-directories-first --icons --git'
    alias tree 'eza --tree --icons'
end
if type -q bat
    alias cat 'bat'
end

# ── Local user scripts ────────────────────────────────────────────────────────
if test -d ~/.local/bin
    fish_add_path ~/.local/bin
end
