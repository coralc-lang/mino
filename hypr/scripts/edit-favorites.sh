#!/usr/bin/env bash
set -euo pipefail
FAV="$HOME/.config/hypr/state/favorites"
mkdir -p "$(dirname "$FAV")"
[[ -f "$FAV" ]] || printf '%s\n' firefox zeditor thunar foot > "$FAV"
# open in editor with list
foot -e sh -c "printf 'Edit favorites (one app/command per line):\\n'; \$EDITOR '$FAV' 2>/dev/null || nano '$FAV'" >/dev/null 2>&1 &
notify-send -t 2000 mino "Editing favorites"
