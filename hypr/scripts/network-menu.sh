#!/usr/bin/env bash
# network-menu.sh — WiFi connect/disconnect via nmcli
set -euo pipefail

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

wifi_on="$(nmcli -t -f WIFI g 2>/dev/null)"
cur="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')"

items=()
if [[ "$wifi_on" == "enabled" ]]; then
  items+=("Wi-Fi: ON - turn off")
else
  items+=("Wi-Fi: OFF - turn on")
fi
[[ -n "$cur" ]] && items+=("Disconnect from ${cur}")
items+=("- Refresh scan -")
items+=("Open nmtui (TUI)")
items+=("Connection settings (nm-connection-editor)")

choice="$(printf '%s\n' "${items[@]}" | rofi -dmenu -i -p "network" -theme mino)"
[[ -z "${choice:-}" ]] && exit 0

case "$choice" in
  "Wi-Fi: ON"*) nmcli radio wifi off; notify-send -t 1500 "network" "Wi-Fi off" ;;
  "Wi-Fi: OFF"*) nmcli radio wifi on; sleep 0.4; notify-send -t 1500 "network" "Wi-Fi on" ;;
  "- Refresh scan -") nmcli dev wifi rescan 2>/dev/null || true; notify-send -t 1200 "network" "Rescanning" ;;
  "Open nmtui"*) foot -e nmtui >/dev/null 2>&1 & ;;
  "Connection settings"*) nm-connection-editor >/dev/null 2>&1 & ;;
  *)
    ssid="$(printf '%s' "$choice" | awk -F' \\| ' '{print $1}' | sed 's/ ●$//;s/ 🔒$//')"
    [[ -z "$ssid" ]] && exit 0
    if [[ "$choice" == *"●"* ]]; then
      if rofi -dmenu -i -p "disconnect ${ssid}?" -theme mino <<< $'Yes\nNo' | grep -q Yes; then
        nmcli con down id "$ssid" 2>/dev/null || true
        notify-send -t 1500 "network" "Disconnected ${ssid}"
      fi
      exit 0
    fi
    if nmcli dev wifi connect "$ssid" 2>/dev/null; then
      notify-send -t 1800 "network" "Connected: ${ssid}"
    else
      pass="$(rofi -dmenu -password -p "password · ${ssid}" -theme mino || true)"
      if [[ -n "${pass:-}" ]]; then
        nmcli dev wifi connect "$ssid" password "$pass" 2>/dev/null && notify-send -t 1800 "network" "Connected: ${ssid}"
      fi
    fi
    ;;
esac
