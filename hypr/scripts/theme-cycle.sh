#!/usr/bin/env bash
# theme-cycle.sh — advance to the next theme (bound to Super+Shift+T)
set -euo pipefail

HYPR="$HOME/.config/hypr"
THEMES="$HYPR/themes"
ORDER=(deep-sea midnight-violet ember mono-frost)

current=""
if [[ -f "$THEMES/current" ]]; then
  current="$(cat "$THEMES/current")"
elif [[ -L "$THEMES/current.conf" ]]; then
  current="$(basename "$(readlink "$THEMES/current.conf")" .conf)"
fi

next="${ORDER[0]}"
if [[ -n "$current" ]]; then
  for i in "${!ORDER[@]}"; do
    if [[ "${ORDER[$i]}" == "$current" ]]; then
      next="${ORDER[$(( (i + 1) % ${#ORDER[@]} ))]}"
      break
    fi
  done
fi

exec "$HYPR/scripts/apply-theme.sh" "$next"
