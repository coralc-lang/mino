#!/usr/bin/env bash
# volume-menu.sh — click volume icon → slider-like menu
set -euo pipefail
get_vol() { wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "%d", $2*100}'; }
get_mute() { wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED && echo 1 || echo 0; }
vol="$(get_vol)"
mute="$(get_mute)"
if [[ "$mute" == "1" ]]; then vol_label="muted"; else vol_label="${vol}%"; fi

choice="$(printf '%s\n' \
  "Volume: ${vol_label}" \
  "+ 5%" \
  "- 5%" \
  "+ 10%" \
  "- 10%" \
  "Mute toggle" \
  "Open mixer (pavucontrol)" \
  | rofi -dmenu -i -p "volume" -theme mino)"

case "$choice" in
  "+ 5%")  wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  "- 5%")  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  "+ 10%") wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 10%+ ;;
  "- 10%") wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%- ;;
  "Mute toggle") wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  "Open mixer"*) pavucontrol >/dev/null 2>&1 & ;;
esac
