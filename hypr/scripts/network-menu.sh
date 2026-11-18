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
    local pid
    pid="$(hyprctl instances 2>/dev/null | sed -n 's/.*pid: \([0-9]*\).*/\1/p' | head -n1)"
    if [[ -n "$pid" && -r "/proc/$pid/environ" ]]; then
      export WAYLAND_DISPLAY="$(tr '\0' '\n' < "/proc/$pid/environ" | sed -n 's/^WAYLAND_DISPLAY=//p' | head -n1)"
    fi
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

# list networks (SSID | signal | security | in-use)
while IFS=: read -r active ssid sec sig; do
  [[ -z "$ssid" ]] && continue
  [[ "$ssid" == "--" ]] && continue
  mark=""
  [[ "$active" == "yes" ]] && mark=" ●"
  secmark=""
  [[ -n "$sec" && "$sec" != "--" ]] && secmark=" 🔒"
  items+=("${ssid}${mark} | ${sig}%${secmark}")
done < <(nmcli -t -f ACTIVE,SSID,SECURITY,SIGNAL dev wifi 2>/dev/null | sort -t: -k4 -nr)

items+=("- Refresh scan -")
items+=("Open nmtui (TUI)")
items+=("Connection settings (nm-connection-editor)")

choice="$(printf '%s\n' "${items[@]}" | rofi -dmenu -i -p "network" -theme mino)"
[[ -z "${choice:-}" ]] && exit 0

case "$choice" in
  "Wi-Fi: ON"*) nmcli radio wifi off; notify-send -t 1500 "network" "Wi-Fi off" ;;
  "Wi-Fi: OFF"*) nmcli radio wifi on; sleep 0.4; notify-send -t 1500 "network" "Wi-Fi on" ;;
  "Disconnect from"*) nmcli con down id "$cur" 2>/dev/null || nmcli dev disconnect wlan0; notify-send -t 1500 "network" "Disconnected" ;;
  "- Refresh scan -") nmcli dev wifi rescan 2>/dev/null || true; notify-send -t 1200 "network" "Rescanning…" ;;
  "Open nmtui"*) foot -e nmtui >/dev/null 2>&1 & ;;
  "Connection settings"*) nm-connection-editor >/dev/null 2>&1 & ;;
  *|*)
    # parse "SSID | 90% 🔒"
    ssid="$(printf '%s' "$choice" | awk -F' \\| ' '{print $1}' | sed 's/ ●$//;s/ 🔒$//')"
    [[ -z "$ssid" ]] && exit 0
    if [[ "$choice" == *"●"* ]]; then
      # already connected — offer disconnect
      if rofi -dmenu -i -p "disconnect ${ssid}?" -theme mino <<< $'Yes\nNo' | grep -q Yes; then
        nmcli con down id "$ssid" 2>/dev/null || true
        notify-send -t 1500 "network" "Disconnected ${ssid}"
      fi
      exit 0
    fi
    # try connect (saved or open)
    if nmcli con up id "$ssid" 2>/dev/null; then
      notify-send -t 1800 "network" "Connected: ${ssid}"
    else
      # need password
      pass="$(rofi -dmenu -password -p "password · ${ssid}" -theme mino || true)"
      if [[ -n "${pass:-}" ]]; then
        if nmcli dev wifi connect "$ssid" password "$pass" 2>/dev/null; then
          notify-send -t 1800 "network" "Connected: ${ssid}"
        else
          # try WPS/open
          nmcli dev wifi connect "$ssid" 2>/dev/null && notify-send -t 1800 "network" "Connected: ${ssid}" \
            || notify-send -t 2500 "network" "Failed: ${ssid}"
        fi
      fi
    fi
    ;;
esac
