#!/usr/bin/env bash
set -euo pipefail
STATE="$HOME/.config/hypr/state"
OUT="$HOME/.config/waybar/config.jsonc"
WS_HELPER="$HOME/.config/hypr/scripts/waybar-workspace.sh"
SCRIPTS="$HOME/.config/hypr/scripts"
mkdir -p "$(dirname "$OUT")" "$STATE"
read_state() { [[ -f "$STATE/$1" ]] && cat "$STATE/$1" || echo "${2:-0}"; }
expanded="$(read_state waybar-expanded 0)"

if [[ "$expanded" == "1" ]]; then
  width=64
  net_wifi='󰤨 {essid}'; net_eth='󰈀 {ifname}'; net_disc='󰤮'
  vol_fmt='{icon} {volume}%'; bat_fmt='{icon} {capacity}%'
  cpu_fmt='󰻠 {usage}%'; mem_fmt='󰍛 {percentage}%'
  br_fmt='󰃠 {percentage}%'
else
  width=56
  net_wifi='󰤨'; net_eth='󰈀'; net_disc='󰤮'
  vol_fmt='{icon}'; bat_fmt='{icon}'
  cpu_fmt='󰻠'; mem_fmt='󰍛'
  br_fmt='󰃠'
fi

WS_HELPER="$WS_HELPER" OUT="$OUT" WIDTH="$width" \
NET_WIFI="$net_wifi" NET_ETH="$net_eth" NET_DISC="$net_disc" \
VOL="$vol_fmt" BAT="$bat_fmt" CPU="$cpu_fmt" MEM="$mem_fmt" BR="$br_fmt" \
SCRIPTS="$SCRIPTS" HOME_DIR="$HOME" \
python3 - <<'PY'
import json, os
out = os.environ["OUT"]
ws = os.environ["WS_HELPER"]
width = int(os.environ["WIDTH"])
home = os.environ["HOME_DIR"]
scripts = os.environ["SCRIPTS"]

cfg = {
  "layer": "top",
  "position": "right",
  "width": width,
  "height": "100%",
  "margin": "6px 6px 6px 0",
  "padding": "10px 4px",
  "spacing": 6,
  "reload_style_on_change": True,
  # TOP
  "modules-left": [
    "custom/launcher",
    "custom/workspace",
    "clock",
    "cpu",
    "memory",
  ],
  # MID
  "modules-center": [
    "pulseaudio",
    "backlight",
    "network",
    "battery",
  ],
  # BOTTOM
  "modules-right": [
    "custom/notifications",
    "custom/settings",
    "custom/session",
  ],
  "custom/launcher": {
    "format": "\U000f08c3",
    "tooltip": True,
    "tooltip-format": "mino utilities",
    "on-click": f"{scripts}/mino-menu.sh",
    "on-click-right": "rofi -show drun -theme mino",
  },
  "custom/workspace": {
    "exec": ws,
    "interval": 1,
    "format": "{}",
    "tooltip": True,
    "tooltip-format": "workspace · click next",
    "on-click": "hyprctl dispatch workspace e+1",
    "on-click-right": "hyprctl dispatch workspace e-1",
  },
  "clock": {
    # vertical HH / MM via chrono %n
    "format": "{:%H%n%M}",
    "format-alt": "{:%Y-%m-%d %H:%M:%S}",
    # hover shows calendar with today highlighted (waybar built-in)
    "tooltip-format": "{:%A\n%B %d, %Y}\n\n{calendar}",
    "interval": 30,
    "on-click": "",
    "on-click-right": "",
    "calendar": {
      "mode": "month",
      "mode-month": "month",
      "weeks-pos": "right",
      "format": {
        "months": "<span color='#88c0d0'><b>{}</b></span>",
        "days": "<span color='#e5e9f0'>{}</span>",
        "weeks": "<span color='#8b949e'>W{}</span>",
        "today": "<span color='#0f1419' background='#88c0d0'><b>{}</b></span>"
      }
    },
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
    "tooltip-format": "RAM {percentage}% - {used} / {total}",
  },
  "pulseaudio": {
    "format": os.environ["VOL"],
    "format-muted": "󰝟",
    "format-icons": {"default": ["󰕿", "󰖀", "󰕾"]},
    "scroll-step": 5,
    # click opens GTK slider (updates live via wpctl)
    "on-click": f"{scripts}/volume-slider.sh",
    "on-click-right": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    "on-scroll-up": "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+",
    "on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    "tooltip": True,
    "tooltip-format": "{volume}% | click for slider | scroll adjusts",
  },
  "backlight": {
    "format": os.environ["BR"],
    "format-icons": ["󰃞", "󰃟", "󰃠"],
    "on-scroll-up": "brightnessctl set +5%",
    "on-scroll-down": "brightnessctl set 5%-",
    "on-click": f"{scripts}/brightness-slider.sh",
    "tooltip": True,
    "tooltip-format": "Brightness {percent}% · min 1%",
  },
  "network": {
    "format-wifi": os.environ["NET_WIFI"],
    "format-ethernet": os.environ["NET_ETH"],
    "format-disconnected": os.environ["NET_DISC"],
    "tooltip-format-wifi": "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}\nclick to manage",
    "tooltip-format-ethernet": "{ifname}\n{ipaddr}/{cidr}",
    "tooltip-format-disconnected": "disconnected | click to connect",
    "on-click": f"{scripts}/network-menu.sh",
    "on-click-right": "nm-connection-editor || nmtui",
    "max-length": 20,
  },
  "battery": {
    "interval": 30,
    "states": {"warning": 30, "critical": 15},
    "format": os.environ["BAT"],
    "format-charging": "󰂄",
    "format-plugged": "󰚥",
    "format-full": "󰁹",
    "format-icons": ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"],
    "tooltip-format": "{capacity}% - {timeTo}",
    "on-click": "",
  },
  "custom/notifications": {
    "format": "󰂚",
    "tooltip": True,
    "tooltip-format": "Notifications",
    "on-click": "makoctl dismiss -a",
    "on-click-right": "makoctl restore",
    "on-click-middle": "makoctl mode -t dnd || true",
  },
  "custom/settings": {
    "format": "󰒓",
    "tooltip": True,
    "tooltip-format": "Settings",
    "on-click": f"{home}/.config/hypr/scripts/settings.sh",
  },
  "custom/session": {
    "format": "⏻",
    "tooltip": True,
    "tooltip-format": "Session",
    "on-click": f"{home}/.config/hypr/scripts/session-menu.sh",
    "on-click-right": "hyprlock",
  },
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"waybar config written (width={width})")
PY
