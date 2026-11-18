#!/usr/bin/env bash
# settings.sh — expanded control center (Super+Shift+, / Super+I)
set -euo pipefail

HYPR="$HOME/.config/hypr"
STATE="$HYPR/state"
SCRIPTS="$HYPR/scripts"
mkdir -p "$STATE"

read_state() { [[ -f "$STATE/$1" ]] && cat "$STATE/$1" || echo "${2:-0}"; }
write_state() { printf '%s\n' "$2" > "$STATE/$1"; }

toggle_bool() {
  local key="$1" default="${2:-0}" cur next
  cur="$(read_state "$key" "$default")"
  if [[ "$cur" == "1" ]]; then next=0; else next=1; fi
  write_state "$key" "$next"
  printf '%s' "$next"
}
onoff() { [[ "$1" == "1" ]] && echo ON || echo OFF; }

restart_waybar() {
  systemctl --user try-restart waybar.service 2>/dev/null || {
    pkill -x waybar 2>/dev/null || true
    sleep 0.15
    systemctl --user start waybar.service 2>/dev/null || true
  }
}
regen_waybar() { [[ -x "$SCRIPTS/waybar-config.sh" ]] && "$SCRIPTS/waybar-config.sh" || true; }

anim="$(read_state animations 1)"
idle="$(read_state idle 1)"
trans="$(read_state transparency 1)"
expanded="$(read_state waybar-expanded 0)"
cursor="$(read_state cursor-size 16)"

# Top-level: categories then quick toggles
choice="$(printf '%s\n' \
  "▸ Appearance & panel" \
  "▸ Sound & display" \
  "▸ Network & Bluetooth" \
  "▸ System utilities" \
  "▸ Keybinds & favorites" \
  "────────" \
  "Animations: $(onoff "$anim")" \
  "Idle/lock: $(onoff "$idle")" \
  "Window transparency: $(onoff "$trans")" \
  "Sidebar expanded: $(onoff "$expanded")" \
  "Cursor size: ${cursor}px" \
  "────────" \
  "Cycle theme" \
  "Wallpaper picker" \
  "Reload config" \
  "Lock screen" \
  | rofi -dmenu -i -p "mino settings" -theme mino)"

[[ -z "${choice:-}" ]] && exit 0

case "$choice" in
  "▸ Appearance"*)
    sub="$(printf '%s\n' \
      "Toggle animations" \
      "Toggle sidebar expand" \
      "Cycle cursor size" \
      "Cycle theme" \
      "Wallpaper picker" \
      "Toggle window transparency" \
      | rofi -dmenu -i -p "appearance" -theme mino)"
    case "$sub" in
      "Toggle animations") write_state animations "$(toggle_bool animations 1)"; hyprctl reload >/dev/null 2>&1 || true; notify-send -t 1200 mino "Animations $(onoff "$(read_state animations 1)")" ;;
      "Toggle sidebar expand") write_state waybar-expanded "$(toggle_bool waybar-expanded 0)"; regen_waybar; restart_waybar ;;
      "Cycle cursor size")
        cur="$(read_state cursor-size 16)"
        case "$cur" in 16) next=24 ;; 24) next=32 ;; *) next=16 ;; esac
        write_state cursor-size "$next"
        hyprctl setcursor default "$next" >/dev/null 2>&1 || true
        sed -i "s/^gtk-cursor-theme-size=.*/gtk-cursor-theme-size=${next}/" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size "$next" 2>/dev/null || true
        notify-send -t 1200 mino "Cursor ${next}px"
        ;;
      "Cycle theme") exec "$SCRIPTS/theme-cycle.sh" ;;
      "Wallpaper picker") exec "$SCRIPTS/wallpaper-picker.sh" ;;
      "Toggle window transparency") write_state transparency "$(toggle_bool transparency 1)"; hyprctl reload >/dev/null 2>&1 || true ;;
    esac
    ;;
  "▸ Sound"*)
    sub="$(printf '%s\n' "Volume slider" "Mute toggle" "Brightness slider" "Open pavucontrol" | rofi -dmenu -i -p "sound/display" -theme mino)"
    case "$sub" in
      "Volume slider") exec "$SCRIPTS/volume-slider.sh" ;;
      "Mute toggle") wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
      "Brightness slider") exec "$SCRIPTS/brightness-slider.sh" ;;
      "Open pavucontrol") pavucontrol >/dev/null 2>&1 & ;;
    esac
    ;;
  "▸ Network"*)
    exec "$SCRIPTS/network-menu.sh"
    ;;
  "▸ System"*)
    sub="$(printf '%s\n' \
      "Process monitor (btop)" \
      "Disk usage" \
      "Package updates (check)" \
      "System info" \
      "Screenshot folder" \
      "Clipboard history" \
      "Edit hyprland.lua" \
      "Edit binds.lua" \
      "Restart waybar" \
      | rofi -dmenu -i -p "system" -theme mino)"
    case "$sub" in
      "Process monitor"*) foot -e btop >/dev/null 2>&1 & ;;
      "Disk usage") foot -e sh -c 'df -hT -x tmpfs -x devtmpfs; echo; read -p "Enter: "' >/dev/null 2>&1 & ;;
      "Package updates"*) foot -e sh -c 'echo "Checking updates…"; checkupdates 2>/dev/null || pacman -Qu; echo; echo "Full upgrade: sudo pacman -Syu"; read -p "Enter: "' >/dev/null 2>&1 & ;;
      "System info") foot -e sh -c 'hostnamectl 2>/dev/null; echo; uptime; echo; free -h; echo; read -p "Enter: "' >/dev/null 2>&1 & ;;
      "Screenshot folder") xdg-open "$HOME/Pictures/Screenshots" >/dev/null 2>&1 || true ;;
      "Clipboard history") foot -e sh -c 'cliphist list | wofi --dmenu | cliphist decode | wl-copy' >/dev/null 2>&1 & ;;
      "Edit hyprland.lua") foot -e sh -c "\$EDITOR '$HYPR/hyprland.lua' 2>/dev/null || nano '$HYPR/hyprland.lua'" >/dev/null 2>&1 & ;;
      "Edit binds.lua") foot -e sh -c "\$EDITOR '$HYPR/lua/binds.lua' 2>/dev/null || nano '$HYPR/lua/binds.lua'" >/dev/null 2>&1 & ;;
      "Restart waybar") restart_waybar ;;
    esac
    ;;
  "▸ Keybinds"*)
    exec "$SCRIPTS/edit-keybinds.sh"
    ;;
  "Animations:"*)
    new="$(toggle_bool animations 1)"
    hyprctl reload >/dev/null 2>&1 || true
    notify-send -t 1200 mino "Animations $(onoff "$new")"
    ;;
  "Idle/lock:"*)
    new="$(toggle_bool idle 1)"
    if [[ "$new" == "1" ]]; then
      systemctl --user start hypridle.service 2>/dev/null || true
    else
      systemctl --user stop hypridle.service 2>/dev/null || true
      hyprctl dispatch dpms on >/dev/null 2>&1 || true
      brightnessctl -r >/dev/null 2>&1 || true
    fi
    notify-send -t 1200 mino "Idle/lock $(onoff "$new")"
    ;;
  "Window transparency:"*)
    new="$(toggle_bool transparency 1)"
    hyprctl reload >/dev/null 2>&1 || true
    notify-send -t 1200 mino "Transparency $(onoff "$new")"
    ;;
  "Sidebar expanded:"*)
    new="$(toggle_bool waybar-expanded 0)"
    regen_waybar
    restart_waybar
    notify-send -t 1200 mino "Sidebar $(onoff "$new")"
    ;;
  "Cursor size:"*)
    cur="$(read_state cursor-size 16)"
    case "$cur" in 16) next=24 ;; 24) next=32 ;; *) next=16 ;; esac
    write_state cursor-size "$next"
    hyprctl setcursor default "$next" >/dev/null 2>&1 || true
    sed -i "s/^gtk-cursor-theme-size=.*/gtk-cursor-theme-size=${next}/" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$next" 2>/dev/null || true
    notify-send -t 1200 mino "Cursor ${next}px"
    ;;
  "Cycle theme") exec "$SCRIPTS/theme-cycle.sh" ;;
  "Wallpaper picker") exec "$SCRIPTS/wallpaper-picker.sh" ;;
  "Reload config") hyprctl reload >/dev/null 2>&1 || true; notify-send -t 1200 mino "Reloaded" ;;
  "Lock screen") exec hyprlock ;;
esac
