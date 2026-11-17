#!/usr/bin/env bash
# waybar-config.sh — regenerate waybar/config.jsonc from state flags
set -euo pipefail

STATE="$HOME/.config/hypr/state"
OUT="$HOME/.config/waybar/config.jsonc"
WS_HELPER="$HOME/.config/hypr/scripts/waybar-workspace.sh"
mkdir -p "$(dirname "$OUT")" "$STATE"

read_state() { [[ -f "$STATE/$1" ]] && cat "$STATE/$1" || echo "${2:-0}"; }

expanded="$(read_state waybar-expanded 0)"

if [[ "$expanded" == "1" ]]; then
  width=160
  clock_format='{:%H:%M}'
  net_wifi='󰤨 {essid}'
  net_eth='󰈀 {ifname}'
  net_disc='󰤮'
  vol_fmt='{icon} {volume}%'
  bat_fmt='{icon} {capacity}%'
  cpu_fmt='󰻠 {usage}%'
  mem_fmt='󰍛 {percentage}%'
else
  width=36
  clock_format='{:%H\n%M}'
  net_wifi='󰤨'
  net_eth='󰈀'
  net_disc='󰤮'
  vol_fmt='{icon}'
  bat_fmt='{icon}'
  cpu_fmt='󰻠'
  mem_fmt='󰍛'
fi

# Write with python for safe JSON (no nested-quote hell)
WS_HELPER="$WS_HELPER" OUT="$OUT" WIDTH="$width" \
CLOCK="$clock_format" NET_WIFI="$net_wifi" NET_ETH="$net_eth" NET_DISC="$net_disc" \
VOL="$vol_fmt" BAT="$bat_fmt" CPU="$cpu_fmt" MEM="$mem_fmt" \
HOME_DIR="$HOME" \
python3 - <<'PY'
import json, os
out = os.environ["OUT"]
ws = os.environ["WS_HELPER"]
width = int(os.environ["WIDTH"])
home = os.environ["HOME_DIR"]

cfg = {
  "layer": "top",
  "position": "right",
  "width": width,
  "height": "100%",
  "margin": "4px 4px 4px 0",
  "padding": "6px 2px",
  "spacing": 2,
  "reload_style_on_change": True,
  "modules-left": [
    "custom/launcher",
    "custom/workspace",
    "clock",
    "cpu",
    "memory",
    "pulseaudio",
    "network",
    "battery",
    "custom/notifications",
    "custom/settings",
    "custom/session",
  ],
  "modules-center": [],
  "modules-right": [],
  "custom/launcher": {
    "format": "\U000f08c3",
    "tooltip": False,
    "on-click": "",
    "on-click-right": "",
  },
  "custom/workspace": {
    "exec": ws,
    "interval": 1,
    "format": "{}",
    "tooltip": False,
    "on-click": "hyprctl dispatch workspace e+1",
  },
  "clock": {
    "format": os.environ["CLOCK"],
    "format-alt": "{:%Y-%m-%d %H:%M:%S}",
    "tooltip-format": "<tt><small>{calendar}</small></tt>",
    "interval": 30,
    "on-click": "",
    "on-click-right": "",
  },
  "cpu": {
    "format": os.environ["CPU"],
    "interval": 2,
    "tooltip": True,
    "tooltip-format": "CPU {usage}%",
  },
  "memory": {
    "format": os.environ["MEM"],
    "interval": 3,
    "tooltip": True,
    "tooltip-format": "RAM {percentage}% — {used:GiB}G",
  },
  "pulseaudio": {
    "format": os.environ["VOL"],
    "format-muted": "\U000f075f",
    "format-icons": {"default": ["\U000f053f", "\U000f0540", "\U000f054e"]},
    "scroll-step": 5,
    "on-click": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    "on-click-right": "pavucontrol",
    "on-scroll-up": "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+",
    "on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-",
    "tooltip": True,
  },
  "network": {
    "format-wifi": os.environ["NET_WIFI"],
    "format-ethernet": os.environ["NET_ETH"],
    "format-disconnected": os.environ["NET_DISC"],
    "tooltip-format-wifi": "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}",
    "tooltip-format-ethernet": "{ifname}\n{ipaddr}/{cidr}",
    "tooltip-format-disconnected": "disconnected",
    "on-click": "nm-connection-editor || nmtui",
    "max-length": 20,
  },
  "battery": {
    "interval": 30,
    "states": {"warning": 30, "critical": 15},
    "format": os.environ["BAT"],
    "format-charging": "\U000f0284",
    "format-plugged": "\U000f06a5",
    "format-full": "\U000f0479",
    "format-icons": [
      "\U000f047a","\U000f047b","\U000f047c","\U000f047d","\U000f047e",
      "\U000f047f","\U000f0480","\U000f0481","\U000f0482","\U000f0479"
    ],
    "tooltip-format": "{capacity}% — {timeTo}",
    "on-click": "",
  },
  "custom/notifications": {
    "format": "\U000f029a",
    "tooltip": True,
    "on-click": "makoctl dismiss -a",
    "on-click-right": "makoctl restore",
    "on-click-middle": "makoctl mode -t dnd || true",
  },
  "custom/settings": {
    "format": "\U000f0593",
    "tooltip": False,
    "on-click": f"{home}/.config/hypr/scripts/settings.sh",
  },
  "custom/session": {
    "format": "\U000f0445",
    "tooltip": False,
    "on-click": f"{home}/.config/hypr/scripts/session-menu.sh",
    "on-click-right": "hyprlock",
  },
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"waybar config written (width={width})")
PY
