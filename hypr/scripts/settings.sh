#!/usr/bin/env bash
# settings.sh — Super+Shift+, or Super+I  (rofi, single-click)
set -euo pipefail

HYPR="$HOME/.config/hypr"
STATE="$HYPR/state"
SCRIPTS="$HYPR/scripts"
mkdir -p "$STATE"

read_state() { [[ -f "$STATE/$1" ]] && cat "$STATE/$1" || echo "${2:-0}"; }
write_state() { printf '%s\n' "$2" > "$STATE/$1"; }

toggle_bool() {
  local key="$1" default="${2:-0}"
  local cur next
  cur="$(read_state "$key" "$default")"
  if [[ "$cur" == "1" ]]; then next=0; else next=1; fi
  write_state "$key" "$next"
  printf '%s' "$next"
}

onoff() { [[ "$1" == "1" ]] && echo ON || echo OFF; }

restart_waybar() {
  if pgrep -x waybar >/dev/null 2>&1; then
    systemctl --user try-restart waybar.service 2>/dev/null || {
      pkill -x waybar 2>/dev/null || true
      sleep 0.15
      systemctl --user start waybar.service 2>/dev/null || true
    }
  fi
}

regen_waybar() {
  [[ -x "$SCRIPTS/waybar-config.sh" ]] && "$SCRIPTS/waybar-config.sh" || true
}

apply_opacity() {
  # decoration.lua reads state on reload
  hyprctl reload >/dev/null 2>&1 || true
}

anim="$(read_state animations 1)"
idle="$(read_state idle 1)"
trans="$(read_state transparency 1)"
expanded="$(read_state waybar-expanded 0)"
cursor="$(read_state cursor-size 16)"

# rofi dmenu — single click selects
choice="$(printf '%s\n' \
  "Animations: $(onoff "$anim")" \
  "Idle/lock: $(onoff "$idle")" \
  "Window transparency: $(onoff "$trans")" \
  "Sidebar expanded: $(onoff "$expanded")" \
  "Cursor size: ${cursor}px" \
  "Cycle theme" \
  "Wallpaper picker" \
  "Reload config" \
  "Lock screen" \
  | rofi -dmenu -i -p "mino settings" -theme mino)"

[[ -z "${choice:-}" ]] && exit 0

case "$choice" in
  Animations:*)
    new="$(toggle_bool animations 1)"
    hyprctl reload >/dev/null 2>&1 || true
    notify-send -t 1500 "mino" "Animations $(onoff "$new")"
    ;;
  Idle/lock:*)
    new="$(toggle_bool idle 1)"
    if [[ "$new" == "1" ]]; then
      systemctl --user start hypridle.service 2>/dev/null || true
    else
      systemctl --user stop hypridle.service 2>/dev/null || true
      hyprctl dispatch dpms on >/dev/null 2>&1 || true
      brightnessctl -r >/dev/null 2>&1 || true
    fi
    notify-send -t 1500 "mino" "Idle/lock $(onoff "$new")"
    ;;
  Window\ transparency:*)
    new="$(toggle_bool transparency 1)"
    apply_opacity
    notify-send -t 1500 "mino" "Transparency $(onoff "$new")"
    ;;
  Sidebar\ expanded:*)
    new="$(toggle_bool waybar-expanded 0)"
    regen_waybar
    restart_waybar
    notify-send -t 1500 "mino" "Sidebar $(onoff "$new")"
    ;;
  Cursor\ size:*)
    case "$cursor" in
      16) next=24 ;;
      24) next=32 ;;
      *) next=16 ;;
    esac
    write_state cursor-size "$next"
    hyprctl setcursor default "$next" >/dev/null 2>&1 || true
    sed -i "s/^gtk-cursor-theme-size=.*/gtk-cursor-theme-size=${next}/" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$next" 2>/dev/null || true
    notify-send -t 1500 "mino" "Cursor ${next}px"
    ;;
  Cycle\ theme)
    exec "$SCRIPTS/theme-cycle.sh"
    ;;
  Wallpaper\ picker)
    exec "$SCRIPTS/wallpaper-picker.sh"
    ;;
  Reload\ config)
    hyprctl reload >/dev/null 2>&1 || true
    notify-send -t 1500 "mino" "Config reloaded"
    ;;
  Lock\ screen)
    exec hyprlock
    ;;
esac
