#!/usr/bin/env bash
# waybar-config.sh — regenerate waybar/config.jsonc from state flags
set -euo pipefail

STATE="$HOME/.config/hypr/state"
OUT="$HOME/.config/waybar/config.jsonc"
mkdir -p "$(dirname "$OUT")" "$STATE"

read_state() { [[ -f "$STATE/$1" ]] && cat "$STATE/$1" || echo "${2:-0}"; }

ws="$(read_state show-workspaces 0)"
expanded="$(read_state waybar-expanded 0)"

mods=('"custom/launcher"' '"custom/workspace"' '"clock"' '"cpu"' '"memory"' '"pulseaudio"' '"network"' '"battery"' '"custom/notifications"' '"custom/settings"' '"custom/session"')
modules="[$(IFS=,; echo "${mods[*]}")]"

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

# JSON-safe: workspace id via bash -c with escaped quotes
ws_exec='bash -c '"'"'printf %s "$(hyprctl activeworkspace 2>/dev/null | sed -n "s/^workspace ID \\([0-9]*\\).*/\\1/p" | head -n1)"'"'"''

# settings/session paths for on-click (double-escape $ for heredoc)
set -a
# shellcheck disable=SC1090
while IFS= read -r line; do
  [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || continue
  eval "$line"
done < "$HOME/.config/hypr/themes/$(cat "$HOME/.config/hypr/themes/current").palette"
set +a

cat > "$OUT" <<EOF
{
  "layer": "top",
  "position": "right",
  "width": ${width},
  "height": "100%",
  "margin": "4px 4px 4px 0",
  "padding": "6px 2px",
  "spacing": 2,
  "reload_style_on_change": true,
  "modules-left": ${modules},
  "modules-center": [],
  "modules-right": [],

  "custom/launcher": {
    "format": "󰣇",
    "tooltip": false,
    "on-click": "",
    "on-click-right": ""
  },

  "custom/workspace": {
    "exec": "${ws_exec}",
    "interval": 1,
    "format": "{}",
    "tooltip": false,
    "on-click": "hyprctl dispatch workspace e+1"
  },

  "clock": {
    "format": "${clock_format}",
    "format-alt": "{:%Y-%m-%d %H:%M:%S}",
    "tooltip-format": "<tt><small>{calendar}</small></tt>",
    "interval": 30,
    "on-click": "",
    "on-click-right": ""
  },

  "cpu": {
    "format": "${cpu_fmt}",
    "interval": 2,
    "tooltip": true,
    "tooltip-format": "CPU {usage}%"
  },

  "memory": {
    "format": "${mem_fmt}",
    "interval": 3,
    "tooltip": true,
    "tooltip-format": "RAM {percentage}% — {used:GiB}G"
  },

  "pulseaudio": {
    "format": "${vol_fmt}",
    "format-muted": "󰝟",
    "format-icons": { "default": ["󰕿", "󰖀", "󰕾"] },
    "scroll-step": 5,
    "on-click": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    "on-click-right": "pavucontrol",
    "on-scroll-up": "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+",
    "on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-",
    "tooltip": true
  },

  "network": {
    "format-wifi": "${net_wifi}",
    "format-ethernet": "${net_eth}",
    "format-disconnected": "${net_disc}",
    "tooltip-format-wifi": "{essid} ({signalStrength}%)\\n{ipaddr}/{cidr}",
    "tooltip-format-ethernet": "{ifname}\\n{ipaddr}/{cidr}",
    "tooltip-format-disconnected": "disconnected",
    "on-click": "nm-connection-editor || nmtui",
    "max-length": 20
  },

  "battery": {
    "interval": 30,
    "states": { "warning": 30, "critical": 15 },
    "format": "${bat_fmt}",
    "format-charging": "󰂄",
    "format-plugged": "󰚥",
    "format-full": "󰁹",
    "format-icons": ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"],
    "tooltip-format": "{capacity}% — {timeTo}",
    "on-click": ""
  },

  "custom/notifications": {
    "format": "󰂚",
    "tooltip": true,
    "on-click": "makoctl dismiss -a",
    "on-click-right": "makoctl restore",
    "on-click-middle": "makoctl mode -t dnd || true"
  },

  "custom/settings": {
    "format": "󰒓",
    "tooltip": false,
    "on-click": "$HOME/.config/hypr/scripts/settings.sh"
  },

  "custom/session": {
    "format": "󰐥",
    "tooltip": false,
    "on-click": "$HOME/.config/hypr/scripts/session-menu.sh",
    "on-click-right": "hyprlock"
  }
}
EOF

echo "waybar config written (ws=$ws expanded=$expanded width=$width)"
