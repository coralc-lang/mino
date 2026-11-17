#!/usr/bin/env bash
# session-menu.sh — power menu (wlogout if present, else rofi)
set -euo pipefail
if command -v wlogout >/dev/null 2>&1; then
  exec wlogout
fi
choice="$(printf '%s\n' "Lock" "Logout" "Suspend" "Reboot" "Shutdown" \
  | rofi -dmenu -i -p "session" -theme mino)"
case "$choice" in
  Lock) exec hyprlock ;;
  Logout) exec hyprctl dispatch exit ;;
  Suspend) exec systemctl suspend ;;
  Reboot) exec systemctl reboot ;;
  Shutdown) exec systemctl poweroff ;;
esac
