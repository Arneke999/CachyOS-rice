# Palette — Catppuccin Mocha, Pink accent

Single source of truth. Every hex in this repo comes from this table. If you
change flavour, this is the file to rewrite first, then find/replace outward.

## Mocha

| Role | Name | Hex | Used for |
|---|---|---|---|
| bg | `base` | `#1e1e2e` | window / terminal background |
| bg- | `mantle` | `#181825` | panel, headerbars, sidebars |
| bg-- | `crust` | `#11111b` | deepest wells, SDDM |
| surface | `surface0` | `#313244` | borders, inactive window border |
| surface+ | `surface1` | `#45475a` | ANSI black, dividers |
| surface++ | `surface2` | `#585b70` | ANSI bright black |
| muted | `overlay0` | `#6c7086` | comments, git status, cmd_duration |
| muted+ | `overlay1` | `#7f849c` | disabled text |
| muted++ | `overlay2` | `#9399b2` | |
| fg-- | `subtext0` | `#a6adc8` | ANSI bright white |
| fg- | `subtext1` | `#bac2de` | ANSI white |
| **fg** | `text` | `#cdd6f4` | primary foreground |

## Accents

| Name | Hex | Role in this rice |
|---|---|---|
| **pink** | `#f5c2e7` | **primary accent** — cursor, selection, active border, prompt `❯` |
| mauve | `#cba6f7` | secondary — vim-cmd prompt, fastfetch logo 2 |
| sky | `#89dceb` | tertiary — URLs, fastfetch title |
| red | `#f38ba8` | error |
| rosewater | `#f5e0dc` | |
| flamingo | `#f2cdcd` | |
| maroon | `#eba0ac` | |
| peach | `#fab387` | |
| yellow | `#f9e2af` | warning |
| green | `#a6e3a1` | success / added |
| teal | `#94e2d5` | |
| sapphire | `#74c7ec` | |
| blue | `#89b4fa` | |
| lavender | `#b4befe` | |

## ANSI 16 (terminal palette)

Official Catppuccin Mocha mapping. Note magenta is `pink`, so shell colours
agree with the accent.

| # | Colour | Hex | | # | Bright | Hex |
|---|---|---|---|---|---|---|
| 0 | black | `#45475a` | | 8 | br-black | `#585b70` |
| 1 | red | `#f38ba8` | | 9 | br-red | `#f38ba8` |
| 2 | green | `#a6e3a1` | | 10 | br-green | `#a6e3a1` |
| 3 | yellow | `#f9e2af` | | 11 | br-yellow | `#f9e2af` |
| 4 | blue | `#89b4fa` | | 12 | br-blue | `#89b4fa` |
| 5 | magenta | `#f5c2e7` | | 13 | br-magenta | `#f5c2e7` |
| 6 | cyan | `#94e2d5` | | 14 | br-cyan | `#94e2d5` |
| 7 | white | `#bac2de` | | 15 | br-white | `#a6adc8` |

## Mapping from the lain rice

| Element | lain (NixOS) | here (Mocha) |
|---|---|---|
| background | `#0f0f11` | `#1e1e2e` |
| accent | `#ffb2b9` | `#f5c2e7` |
| inactive border | `rgb(505050)` | `#313244` |
| foreground | matugen `on_surface` | `#cdd6f4` |
| rounding | 8 | 8 |
| blur / shadow | off | off |
