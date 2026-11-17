#!/usr/bin/env bash
# screenshot.sh [region|full|window] — save to ~/Pictures/Screenshots + copy
set -euo pipefail
MODE="${1:-region}"
DIR="$HOME/Pictures/Screenshots/$(date +%Y-%m-%d)"
mkdir -p "$DIR"
FILE="$DIR/$(date +%H%M%S)-${MODE}.png"

case "$MODE" in
  region)
    geom="$(slurp || true)"
    [[ -z "${geom:-}" ]] && exit 0
    grim -g "$geom" "$FILE"
    ;;
  full)
    grim "$FILE"
    ;;
  window)
    # active window geometry via hyprctl
    read -r x y w h < <(hyprctl activewindow -j 2>/dev/null | python3 -c "import json,sys; c=json.load(sys.stdin); at=c.get('at',[0,0]); sz=c.get('size',[0,0]); print(at[0],at[1],sz[0],sz[1])" 2>/dev/null || echo "")
    if [[ -n "${x:-}" ]]; then
      grim -g "${x},${y} ${w}x${h}" "$FILE"
    else
      grim "$FILE"
    fi
    ;;
  *) echo "usage: screenshot.sh [region|full|window]" >&2; exit 1 ;;
esac

wl-copy < "$FILE" 2>/dev/null || true
notify-send -t 2500 "Screenshot" "Saved $(basename "$FILE")\n$DIR"
echo "$FILE"
