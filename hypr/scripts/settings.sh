#!/usr/bin/env bash
# settings.sh — Super+Shift+, settings menu (wofi)
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

status_mark() { [[ "$1" == "1" ]] && echo "●" || echo "○"; }

anim="$(read_state animations 1)"
idle="$(read_state idle 1)"
ws="$(read_state show-workspaces 0)"
expanded="$(read_state waybar-expanded 1)"
cursor="$(read_state cursor-size 24)"

# Build menu
menu="$(cat <<EOF
Toggle animations — $(status_mark "$anim")
Toggle idle / keep-screen-on — $(status_mark "$idle")
Show workspaces in panel — $(status_mark "$ws")
Waybar expanded — $(status_mark "$expanded")
Cursor size: ${cursor}px
Cycle theme
Reload Hyprland
Lock screen
EOF
)"

choice="$(printf '%s\n' "$menu" | wofi --dmenu --prompt "mino settings" \
  --width 360 --height 280 \
  -s "file://$HOME/.config/wlogout/style.css" 2>/dev/null \
  || printf '%s\n' "$menu" | wofi --dmenu --prompt "mino settings" --width 360 --height 280)"

[[ -z "${choice:-}" ]] && exit 0

case "$choice" in
  Toggle\ animations*)
    new="$(toggle_bool animations 1)"
    hyprctl keyword animations:enabled "$([[ $new == 1 ]] && echo true || echo false)" >/dev/null 2>&1 || true
    notify-send "mino" "Animations: $([[ $new == 1 ]] && echo on || echo off)"
    ;;
  Toggle\ idle*)
    new="$(toggle_bool idle 1)"
    if [[ "$new" == "1" ]]; then
      systemctl --user start hypridle.service 2>/dev/null || true
    else
      systemctl --user stop hypridle.service 2>/dev/null || true
      # wake screen if it was dimmed/off
      hyprctl dispatch dpms on >/dev/null 2>&1 || true
      brightnessctl -r >/dev/null 2>&1 || true
    fi
    notify-send "mino" "Idle/lock: $([[ $new == 1 ]] && echo on || echo off)"
    ;;
  Show\ workspaces*)
    new="$(toggle_bool show-workspaces 0)"
    write_state show-workspaces "$new"
    # regenerate waybar config module list
    if [[ -x "$SCRIPTS/waybar-config.sh" ]]; then
      "$SCRIPTS/waybar-config.sh"
    fi
    if pgrep -x waybar >/dev/null 2>&1; then
      systemctl --user try-restart waybar.service 2>/dev/null || { pkill -x waybar; sleep 0.2; systemctl --user start waybar.service 2>/dev/null || true; }
    fi
    notify-send "mino" "Workspaces: $([[ $new == 1 ]] && echo shown || echo hidden)"
    ;;
  Waybar\ expanded*)
    new="$(toggle_bool waybar-expanded 1)"
    if [[ -x "$SCRIPTS/waybar-config.sh" ]]; then
      "$SCRIPTS/waybar-config.sh"
    fi
    if pgrep -x waybar >/dev/null 2>&1; then
      systemctl --user try-restart waybar.service 2>/dev/null || true
    fi
    notify-send "mino" "Waybar: $([[ $new == 1 ]] && echo expanded || echo compact)"
    ;;
  Cursor\ size:*)
    # cycle 16 → 24 → 32 → 16
    case "$cursor" in
      16) next=24 ;;
      24) next=32 ;;
      *) next=16 ;;
    esac
    write_state cursor-size "$next"
    hyprctl setcursor default "$next" >/dev/null 2>&1 || true
    # persist for next session via env file used by install
    sed -i "s/^XCURSOR_SIZE=.*/XCURSOR_SIZE=${next}/" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$next" 2>/dev/null || true
    notify-send "mino" "Cursor size: ${next}px"
    ;;
  Cycle\ theme)
    exec "$SCRIPTS/theme-cycle.sh"
    ;;
  Reload\ Hyprland)
    hyprctl reload >/dev/null 2>&1 || true
    notify-send "mino" "Config reloaded"
    ;;
  Lock\ screen)
    exec hyprlock
    ;;
esac
