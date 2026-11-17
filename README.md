# mino

Dark moody multi-theme Hyprland rice — Lua config, cyan/teal accent, sharp corners.

**by cerie**

## Themes

| name | accent | wallpaper |
|------|--------|-----------|
| deep-sea (default) | `#88c0d0` | digital-art-dark-cosmic-night-sky |
| midnight-violet | `#b48ead` | digital-art-moon-tree |
| ember | `#e09f6a` | arch_dark |
| mono-frost | `#a8c0d0` | surreal-underwater |

Cycle: **Super+Shift+T**

## Keybinds

| key | action |
|-----|--------|
| Super+Return | kitty |
| Super+Q | close window |
| Super+C | zeditor |
| Super+E | nautilus (thunar once installed) |
| Super+B | firefox |
| Super+R | rofi app launcher |
| Super+V | cliphist clipboard |
| Super+Shift+V | emoji (rofimoji) |
| Super+N | toggle side waybar |
| Super+Shift+T | cycle theme |
| Super+L | hyprlock |
| Super+F | fullscreen |
| Super+M | maximize |
| Super+Shift+F | toggle float |
| Super+Tab / Super+Shift+Tab | cycle windows |
| Super+Shift+arrows | swap windows |
| Super+Shift+S / PrtSc | screenshot |
| Super+Shift+, | settings menu |
| Super+1…9 | workspaces |
| Super+grave | scratchpad |

## Layout

```
~/.config/hypr/
  hyprland.lua          # entrypoint
  lua/                  # env, binds, rules, …
  themes/*.lua + *.palette
  scripts/apply-theme.sh | theme-cycle.sh | settings.sh | toggle-waybar.sh | waybar-config.sh
  state/                # toggles (cursor, workspaces, animations, …)
```

## Install

```bash
./install.sh              # symlink configs + enable services
./install.sh --packages   # print sudo package commands
```

Then restart Hyprland. No sudo is run by the installer for config files.

## SDDM

```bash
sudo cp -a sddm/mino /usr/share/sddm/themes/
# set Current=mino in /etc/sddm.conf
```

## Notes

- Hyprland ≥ 0.57 Lua config path (`hyprland.lua` preferred over `.conf`).
- waybar is **disabled** by default; **Super+N** toggles it.
- mako / hyprpaper / hypridle run as systemd user units.
- Kitty needs `sudo pacman -Syu` (openssl 4 / libcrypto.so.4).

## Extra binds

| Key | Action |
|---|---|
| Super+Shift+W | Wallpaper picker |
| Super+Alt+Shift+R | Reload Hyprland config |
| Super+I | Settings |
| Super+Shift+, | Settings |


## Settings toggles

- Animations, idle lock, **window transparency**, sidebar expand, cursor size
- Access: `Super+Shift+,` or `Super+I` (or gear in waybar)
