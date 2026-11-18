#!/usr/bin/env bash
# hypr-restart.sh — genuinely restart Hyprland compositor
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -1t /run/user/$(id -u)/hypr 2>/dev/null | while read -r d; do
  [ -S "/run/user/$(id -u)/hypr/$d/.socket.sock" ] && { echo "$d"; break; }
done)}"
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" && -S "/run/user/$(id -u)/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket.sock" ]]; then
  hyprctl dispatch exit
else
  pkill -x Hyprland 2>/dev/null || true
fi
