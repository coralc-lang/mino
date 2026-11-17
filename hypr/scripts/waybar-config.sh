#!/usr/bin/env bash
# waybar-config.sh — regenerate waybar/config.jsonc from state flags
set -euo pipefail

STATE="$HOME/.config/hypr/state"
OUT="$HOME/.config/waybar/config.jsonc"
mkdir -p "$(dirname "$OUT")" "$STATE"

read_state() { [[ -f "$STATE/$1" ]] && cat "$STATE/$1" || echo "${2:-0}"; }

ws="$(read_state show-workspaces 0)"
expanded="$(read_state waybar-expanded 1)"

mods=('"custom/launcher"')
if [[ "$ws" == "1" ]]; then
  mods+=('"workspaces"')
fi
mods+=('"clock"' '"custom/spacer"' '"pulseaudio"' '"network"' '"battery"' '"custom/notifications"' '"custom/settings"' '"custom/session"')
modules="[$(IFS=,; echo "${mods[*]}")]"

if [[ "$expanded" == "1" ]]; then
  width=200
  clock_format='{:%H:%M}'
  clock_alt='{:%Y-%m-%d %H:%M:%S}'
  net_wifi='󰤨 {essid}'
  net_eth='󰈀 {ifname}'
  net_disc='󰤮 offline'
  vol_fmt='{icon} {volume}%'
  bat_fmt='{icon} {capacity}%'
else
  width=48
  clock_format='{:%H\n%M}'
  clock_alt='{:%Y-%m-%d %H:%M:%S}'
  net_wifi='󰤨'
  net_eth='󰈀'
  net_disc='󰤮'
  vol_fmt='{icon}'
  bat_fmt='{icon}'
fi

cat > "$OUT" <<EOF
{
  "layer": "top",
  "position": "right",
  "width": ${width},
  "height": "100%",
  "margin": "6px 6px 6px 0",
  "padding": "8px 4px",
  "spacing": 6,
  "reload_style_on_change": true,
  "modules-left": ${modules},
  "modules-center": [],
  "modules-right": [],

  "custom/launcher": {
    "format": "󰣇",
    "tooltip": false,
    "on-click": "hyprlauncher",
    "on-click-right": "kitty -e btop"
  },

  "workspaces": {
    "format": "{name}",
    "format-icons": {
      "urgent": "󰌕",
      "active": "●",
      "default": "○"
    },
    "sort-by-number": true,
    "on-click": "activate",
    "tooltip": false
  },

  "clock": {
    "format": "${clock_format}",
    "format-alt": "${clock_alt}",
    "tooltip-format": "<tt><small>{calendar}</small></tt>",
    "interval": 30,
    "on-click": "notify-send \\"$(date '+%A, %B %d %Y')\\"",
    "on-click-right": "gnome-calendar || kalender || true"
  },

  "custom/spacer": {
    "format": " ",
    "tooltip": false
  },

  "pulseaudio": {
    "format": "${vol_fmt}",
    "format-muted": "󰝟 muted",
    "format-icons": {
      "default": ["󰕿", "󰖀", "󰕾"]
    },
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
    "max-length": 24
  },

  "battery": {
    "interval": 30,
    "states": {
      "warning": 30,
      "critical": 15
    },
    "format": "${bat_fmt}",
    "format-charging": "󰂄 {capacity}%",
    "format-plugged": "󰚥 {capacity}%",
    "format-full": "󰁹 {capacity}%",
    "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"],
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
    "on-click": "wlogout || hyprctl dispatch exit",
    "on-click-right": "hyprlock"
  }
}
EOF

echo "waybar config written (ws=$ws expanded=$expanded width=$width)"
