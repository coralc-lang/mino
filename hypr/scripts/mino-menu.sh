#!/usr/bin/env bash
# mino-menu.sh — expandable utilities hub (Super / waybar arch icon)
set -euo pipefail
HYPR="$HOME/.config/hypr"
SCRIPTS="$HYPR/scripts"
FAV="$HYPR/state/favorites"
mkdir -p "$HYPR/state"
[[ -f "$FAV" ]] || printf '%s\n' firefox zeditor thunar foot > "$FAV"

ensure_env() {
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || ! -S "/run/user/$(id -u)/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket.sock" ]]; then
    export HYPRLAND_INSTANCE_SIGNATURE="$(ls -1t /run/user/$(id -u)/hypr 2>/dev/null | while read -r d; do
      [[ -S "/run/user/$(id -u)/hypr/$d/.socket.sock" ]] && { echo "$d"; break; }
    done)"
  fi
  if [[ -z "${WAYLAND_DISPLAY:-}" && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    local pid; pid="$(hyprctl instances 2>/dev/null | sed -n 's/.*pid: \([0-9]*\).*/\1/p' | head -n1)"
    [[ -n "$pid" && -r "/proc/$pid/environ" ]] && export WAYLAND_DISPLAY="$(tr '\0' '\n' < "/proc/$pid/environ" | sed -n 's/^WAYLAND_DISPLAY=//p' | head -n1)"
  fi
}
ensure_env

# Build menu with categories
mapfile -t favs < "$FAV"
items=()
items+=("── Favorites ──")
for a in "${favs[@]}"; do
  [[ -z "$a" ]] && continue
  items+=("★ ${a}")
done
items+=("── Apps ──")
items+=("  All applications…")
items+=("── Tools ──")
items+=("  Settings")
items+=("  Wallpaper picker")
items+=("  Theme cycle")
items+=("  Volume slider")
items+=("  Brightness slider")
items+=("  Network")
items+=("  Screenshots folder")
items+=("  Clipboard history")
items+=("  Process monitor (btop)")
items+=("  Disk usage")
items+=("  Package updates")
items+=("  Edit keybinds")
items+=("  Edit favorites")
items+=("  Reload Hyprland config")
items+=("  Lock screen")

choice="$(printf '%s\n' "${items[@]}" | rofi -dmenu -i -p "mino" -theme mino)"
[[ -z "${choice:-}" ]] && exit 0
# trim leading spaces
choice="$(printf '%s' "$choice" | sed 's/^[[:space:]]*//')"

case "$choice" in
  "──"*) exit 0 ;;
  ★\ *)
    app="${choice#★ }"
    # if it's a command name, launch
    if command -v "$app" >/dev/null 2>&1; then
      "$app" >/dev/null 2>&1 &
    else
      rofi -show drun -theme mino -filter "$app"
    fi
    ;;
  "All applications"*) rofi -show drun -theme mino ;;
  Settings) exec "$SCRIPTS/settings.sh" ;;
  "Wallpaper picker") exec "$SCRIPTS/wallpaper-picker.sh" ;;
  "Theme cycle") exec "$SCRIPTS/theme-cycle.sh" ;;
  "Volume slider") exec "$SCRIPTS/volume-slider.sh" ;;
  "Brightness slider") exec "$SCRIPTS/brightness-slider.sh" ;;
  Network) exec "$SCRIPTS/network-menu.sh" ;;
  "Screenshots folder") xdg-open "$HOME/Pictures/Screenshots" >/dev/null 2>&1 || thunar "$HOME/Pictures/Screenshots" >/dev/null 2>&1 & ;;
  "Clipboard history") foot -e sh -c 'cliphist list | wofi --dmenu | cliphist decode | wl-copy; sleep 0.2' >/dev/null 2>&1 & ;;
  "Process monitor"*) foot -e btop >/dev/null 2>&1 & ;;
  "Disk usage") foot -e sh -c 'df -h; echo; echo "Press enter"; read' >/dev/null 2>&1 & ;;
  "Package updates") foot -e sh -c 'echo "=== Updates ==="; checkupdates 2>/dev/null || pacman -Qu; echo; echo "Run: sudo pacman -Syu"; echo "Press enter"; read' >/dev/null 2>&1 & ;;
  "Edit keybinds") exec "$SCRIPTS/edit-keybinds.sh" ;;
  "Edit favorites") exec "$SCRIPTS/edit-favorites.sh" ;;
  "Reload Hyprland config") hyprctl reload >/dev/null 2>&1; notify-send -t 1200 mino "Config reloaded" ;;
  "Lock screen") exec hyprlock ;;
esac
