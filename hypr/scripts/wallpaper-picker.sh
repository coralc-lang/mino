#!/usr/bin/env bash
# wallpaper-picker.sh — Super+Shift+W
set -euo pipefail
DIR="$HOME/Pictures/wallpapers"
HYPR="$HOME/.config/hypr"

[[ -d "$DIR" ]] || { notify-send "mino" "No wallpapers in $DIR"; exit 1; }

# ensure hyprctl env
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || ! -S "/run/user/$(id -u)/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket.sock" ]]; then
  export HYPRLAND_INSTANCE_SIGNATURE="$(ls -1t /run/user/$(id -u)/hypr 2>/dev/null | while read -r d; do
    [[ -S "/run/user/$(id -u)/hypr/$d/.socket.sock" ]] && { echo "$d"; break; }
  done)"
fi
if [[ -z "${WAYLAND_DISPLAY:-}" && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  pid="$(hyprctl instances 2>/dev/null | sed -n 's/.*pid: \([0-9]*\).*/\1/p' | head -n1)"
  if [[ -n "$pid" && -r "/proc/$pid/environ" ]]; then
    export WAYLAND_DISPLAY="$(tr '\0' '\n' < "/proc/$pid/environ" | sed -n 's/^WAYLAND_DISPLAY=//p' | head -n1)"
  fi
fi

pick="$(find "$DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -printf '%f\n' | sort | rofi -dmenu -i -p "wallpaper" -theme mino)"
[[ -z "${pick:-}" ]] && exit 0

path="$DIR/$pick"

# set live
hyprctl hyprpaper wallpaper ",${path}" >/dev/null 2>&1 || true

# update current theme wallpaper field (lua + conf) so reloads keep it
cur="$(cat "$HYPR/themes/current" 2>/dev/null || echo deep-sea)"
for f in "$HYPR/themes/${cur}.lua" "$HYPR/themes/${cur}.conf" "$HYPR/themes/current.lua" "$HYPR/themes/current.conf"; do
  [[ -f "$f" || -L "$f" ]] || continue
  # resolve symlink target for write
  target="$f"
  [[ -L "$f" ]] && target="$(readlink -f "$f")"
  [[ -f "$target" ]] || continue
  if [[ "$target" == *.lua ]]; then
    sed -i "s|^  wallpaper = \".*\"|  wallpaper = \"${path}\"|" "$target" 2>/dev/null || true
  else
    sed -i "s|^\$wallpaper   = .*|\$wallpaper   = ${path}|" "$target" 2>/dev/null || true
  fi
done

# refresh hyprpaper conf for cold start
cat > "$HYPR/hyprpaper.conf" <<PEOF
wallpaper {
    monitor =
    path = ${path}
    fit_mode = cover
}

splash = false
ipc = on
PEOF

# refresh hyprlock bg
if [[ -f "$HYPR/hyprlock.conf" ]]; then
  sed -i "s|^    path = .*|    path = ${path}|" "$HYPR/hyprlock.conf" 2>/dev/null || true
fi

notify-send -t 2000 "mino" "Wallpaper: $pick"
