# Hyprland Theme Rice — Complete Plan

> Status: **IMPLEMENTED** (restart Hyprland once to leave the old Lua session)  
> Date: 2026-11-17  
> Machine: Arch Linux · Hyprland 0.56.2 (uwsm) · eDP-1 1366×768 · bash  
> Verify: `hyprland --verify-config` → **config ok**

---

## 1. Goals

Build a **self-owned, multi-theme Hyprland rice** from scratch:

- Plain `.conf` (no Lua — caelestia leftovers die)
- **Dark & moody**, cyan/teal accent
- Sharp corners, tight gaps, subtle glass (blur + opacity + vibrancy)
- Snappy animations
- **Full rice**: Hyprland + kitty + waybar side panel + mako + hyprlauncher + hyprpaper + hypridle/hyprlock + light GTK css
- **4 named themes**, cycle with **Super+Shift+T**
- **No workspace icons** in the panel — Super+1…9 only
- Purge every ml4w / mydotfiles / caelestia / lua remnant

---

## 2. Verified baseline

| Item | Finding |
|------|---------|
| Active config | Hyprland loads `hyprland.lua` (caelestia). **Must delete `.lua`** or conf is ignored. |
| Broken ml4w symlinks | 24 paths → `~/.mydotfiles` (missing) |
| mako 1.11.0 | Installed, no user config; unit at `/usr/lib/systemd/user/mako.service` |
| swaync | Running as user service → disable |
| waybar / hyprpaper / hypridle | Installed; units exist; all disabled |
| hyprlauncher | Installed; hyprlang conf at `~/.config/hypr/hyprlauncher.conf` |
| kitty | Installed; config was broken symlink |
| Wallpapers | `~/Projects/Wallpapers/` (source) → staged into **`~/Pictures/wallpapers/`** |
| Fonts | JetBrains Mono Nerd **already present** — no install needed |
| GTK | `adw-gtk3-dark` + Papirus-Dark + `prefer-dark` (keep) |
| Qt | **Skip** entirely |
| Cursor | `default` size 24 |
| Shell | bash; real `~/.bashrc` kept |

---

## 3. Target file tree

```
~/.config/hypr/
├── hyprland.conf                 # sole entrypoint
├── hypr-theme-rice-plan.md       # this file
├── xdph.conf                     # keep (screencopy)
├── conf.d/
│   ├── 10-env.conf
│   ├── 20-monitors.conf
│   ├── 30-input.conf
│   ├── 40-general.conf
│   ├── 50-decoration.conf
│   ├── 60-animations.conf
│   ├── 70-binds.conf
│   ├── 80-workspaces.conf
│   ├── 90-windowrules.conf
│   └── 95-autostart.conf
├── themes/
│   ├── current                   # symlink → active theme name
│   ├── deep-sea.conf
│   ├── deep-sea.palette
│   ├── midnight-violet.conf
│   ├── midnight-violet.palette
│   ├── ember.conf
│   ├── ember.palette
│   ├── mono-frost.conf
│   └── mono-frost.palette
├── scripts/
│   ├── theme-cycle.sh            # Super+Shift+T
│   └── apply-theme.sh            # symlink + generate app colors + reload
└── generated/                    # machine-written (git-ignore style)
    ├── kitty.conf
    ├── mako
    ├── waybar.css
    ├── hyprlock.conf
    └── gtk.css

~/.config/waybar/                 # fresh (config.jsonc + style.css)
~/.config/kitty/kitty.conf        # fresh
~/.config/mako/config             # fresh
~/.config/hypr/hyprpaper.conf
~/.config/hypr/hypridle.conf
~/.config/hypr/hyprlock.conf
~/.config/hypr/hyprlauncher.conf
~/.config/gtk-3.0/{settings.ini,gtk.css}
~/.config/gtk-4.0/gtk.css
~/Pictures/wallpapers/            # default wallpapers live here
```

---

## 4. Visual spec (shared across all themes)

| Setting | Value |
|---------|-------|
| Vibe | Dark & moody, cyan/teal accent |
| `rounding` | **0** (sharp) |
| `gaps_in` | **4** |
| `gaps_out` | **6** |
| `border_size` | **1** |
| Active border | `$accent` |
| Inactive border | `$border_dim` |
| Opacity active | **0.92** |
| Opacity inactive | **0.82** |
| Fullscreen opacity | **1.0** |
| Blur | enabled, size **6**, passes **2** |
| Vibrancy | **0.15** |
| Shadow | enabled, range 12, colour `$shadow` |
| Animations | bezier `quick = 0.15, 0, 0.1, 1` · windows speed 4 · workspaces speed 5 · slide |
| Group bars | **None** (plain tiled windows) |
| Special ws dim | 0.3 |

### Theme palettes

| Theme | Accent | Background | Character |
|-------|--------|------------|-----------|
| **deep-sea** (default) | `#88c0d0` teal | `#0f1419` blue-black | cold ocean night |
| **midnight-violet** | `#b48ead` violet | `#12101a` | cool purple haze |
| **ember** | `#e09f6a` amber | `#14110e` | warm dark ember |
| **mono-frost** | `#a8c0d0` icy | `#101214` | near-grayscale frost |

Each theme = one `.conf` (hyprland `$vars` + blocks) + one `.palette` (hex KEY=VAL for app generator).

### Default wallpaper

`~/Pictures/wallpapers/digital-art-dark-cosmic-night-sky.jpg`  
(also staged: `arch_dark.png`, `surreal-underwater-*.jpg`, `digital-art-moon-tree-wallpaper.jpg`)

---

## 5. App scope

| App | Approach |
|-----|----------|
| **Waybar** | **On-demand side panel** (vertical, right edge). Modules: clock, volume, battery, network, notifications, launcher, session. **No workspace module.** Toggle **Super+N** → start/stop `waybar.service`. Not enabled at login. |
| **Kitty** | Fresh conf; `include` generated ANSI palette |
| **Mako** | Fresh conf; colors from `generated/mako`; `makoctl reload` on switch |
| **Hyprlauncher** | **Super+Space**; hyprlang conf themed dark |
| **hyprpaper** | Preloads default wallpaper; reload on theme change |
| **hypridle** | lock 5 min · dpms off 5.5 min · suspend 30 min |
| **hyprlock** | blurred screenshot bg + accent input field + clock |
| **GTK** | Keep adw-gtk3-dark / Papirus-Dark; light accent `gtk.css` only |
| **Qt** | Untouched |
| **Notifications** | **mako only**; swaync disabled |

---

## 6. Keybinds (theme-related + essentials)

| Bind | Action |
|------|--------|
| `Super+Shift+T` | Cycle theme (next of 4) |
| `Super+N` | Toggle waybar side panel |
| `Super+Space` | hyprlauncher |
| `Super+Return` | kitty |
| `Super+L` | hyprlock |
| `Super+Q` | close window |
| `Super+1…9` | workspace focus (no icons) |
| `Super+Shift+1…9` | move window to workspace |
| `Super+Escape` | kill active (hyprctl kill) |
| `Super+V` | togglefloating |
| `Super+F` | fullscreen |
| `Super+E` | nautilus |
| `Super+B` | firefox |
| `Super+M` | exit menu / hyprctl dispatch exit |
| `Print` | screenshot (grim/slurp if present, else hyprctl) |

(Keep it lean — expand later as needed.)

---

## 7. Cleanup list

### 7a. Broken mydotfiles/ml4w symlinks (delete)

```
~/.config/bashrc
~/.config/edge-flags.conf
~/.config/gtk-3.0
~/.config/gtk-4.0
~/.config/kitty
~/.config/matugen
~/.config/ml4w-dotfiles-settings
~/.config/nwg-dock-hyprland
~/.config/ohmyposh
~/.config/qt6ct
~/.config/quickshell
~/.config/rofi
~/.config/sidepad
~/.config/swaync
~/.config/vim
~/.config/walker
~/.config/waybar
~/.config/waypaper
~/.config/wlogout
~/.config/xsettingsd
~/.config/zshrc
~/.gtkrc-2.0
~/.Xresources
~/.zshrc
```

### 7b. Stale Hyprland / caelestia (delete)

```
~/.config/hypr/hyprland.lua          # CRITICAL — else conf ignored
~/.config/hypr/hyprland.conf.save
~/.config/hypr/variables.lua
~/.config/hypr/scheme/
~/.config/hypr/config/               # lua modules
~/.config/hypr/hyprland/             # lua modules
~/.config/caelestia/
~/.config/hypr.bak/
~/.config/noctalia/
```

### 7c. Keep

```
~/.bashrc  ~/.bash_profile  ~/.profile
~/.config/hypr/xdph.conf
~/Pictures/wallpapers/
~/Projects/Wallpapers/               # source archive, leave alone
```

---

## 8. Systemd (user units — **no sudo**)

```bash
# stop the old notification daemon
systemctl --user disable --now swaync.service

# enable the rice daemons
systemctl --user daemon-reload
systemctl --user enable --now mako.service hyprpaper.service hypridle.service

# waybar stays DISABLED (on-demand via Super+N)
systemctl --user disable --now waybar.service 2>/dev/null || true
```

### Packages

```bash
# JetBrains Nerd Font already installed — nothing required.
# Optional only if you want extras later:
# sudo pacman -S --needed ttf-jetbrains-mono-nerd
```

No sudo needed for anything under `~/.config`.

---

## 9. Theme switch pipeline

`scripts/apply-theme.sh <name>`:

1. Validate `themes/<name>.conf` exists  
2. `ln -sfn <name> themes/current`  
3. Source `themes/<name>.palette` → write `generated/{kitty.conf,mako,waybar.css,hyprlock.conf,gtk.css}`  
4. `hyprctl reload`  
5. `makoctl reload`  
6. If waybar running: `systemctl --user try-restart waybar`  
7. `hyprctl hyprpaper preload` + `hyprctl hyprpaper wallpaper` if changed  

`scripts/theme-cycle.sh`: reads `themes/current`, advances through ordered list, calls `apply-theme.sh`.

Bound to **Super+Shift+T**.

---

## 10. Implementation order

1. ✅ Stage wallpapers → `~/Pictures/wallpapers/`
2. ⬜ Write this plan MD  
3. ⬜ Purge cleanup list (7a + 7b)  
4. ⬜ Scaffold `hyprland.conf` + `conf.d/*`  
5. ⬜ Write 4 themes (`.conf` + `.palette`)  
6. ⬜ Write `apply-theme.sh` + `theme-cycle.sh`  
7. ⬜ App configs: kitty, mako, waybar, hyprpaper, hypridle, hyprlock, hyprlauncher, gtk  
8. ⬜ Run apply for default theme (deep-sea)  
9. ⬜ Systemd commands (section 8)  
10. ⬜ `hyprctl reload` + verify (lua gone, theme loads, services up)  

---

## 11. Verification checklist

- [ ] `hyprland.log` says config is `hyprland.conf`, **not** `.lua`
- [ ] No broken `mydotfiles`/`ml4w` symlinks remain under `~`
- [ ] `ls ~/.config/hypr/themes/current` → `deep-sea`
- [ ] `hyprctl reload` succeeds without errors
- [ ] `makoctl status` works; test notify shows themed
- [ ] Super+N shows/hides side waybar
- [ ] Super+Shift+T cycles all 4 themes; borders/blur update
- [ ] Super+Space opens hyprlauncher
- [ ] hyprpaper shows cosmic night sky
- [ ] hyprlock triggers via Super+L
- [ ] swaync inactive; mako active
