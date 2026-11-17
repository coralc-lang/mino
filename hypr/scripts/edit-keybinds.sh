#!/usr/bin/env bash
# edit-keybinds.sh — view / edit keybinds in binds.lua
set -euo pipefail
BINDS="$HOME/.config/hypr/lua/binds.lua"
WS="$HOME/.config/hypr/lua/workspaces.lua"

choice="$(printf '%s\n' \
  "View keybinds" \
  "Edit binds.lua" \
  "Edit workspaces.lua" \
  "Reload config" \
  | rofi -dmenu -i -p "keybinds" -theme mino)"
[[ -z "${choice:-}" ]] && exit 0

case "$choice" in
  "View keybinds")
    # pretty-print binds from lua files
    {
      echo "════════ mino keybinds ═══════"
      echo
      grep -E 'hl\.bind\(|hl\.dsp' "$BINDS" "$WS" 2>/dev/null \
        | sed 's/.*hl\.bind(//;s/)).*//' \
        | sed 's/^/  /' \
        | head -80
      echo
      echo "Press Enter to close"
      read -r
    } | foot -e sh -c 'cat; read' >/dev/null 2>&1 &
    # fallback without foot pipe issues
    if ! pgrep -f 'mino keybinds' >/dev/null 2>&1; then
      tmp="$(mktemp)"
      {
        echo "════════ mino keybinds ═══════"
        grep -h 'hl.bind(' "$BINDS" "$WS" 2>/dev/null | sed 's/^hl.bind(/  /;s/)).*/,/' | head -100
      } > "$tmp"
      foot -e sh -c "less -R '$tmp' 2>/dev/null || cat '$tmp'; echo; read" >/dev/null 2>&1 &
    fi
    ;;
  "Edit binds.lua")
    foot -e sh -c "\$EDITOR '$BINDS' 2>/dev/null || nano '$BINDS'" >/dev/null 2>&1 &
    ;;
  "Edit workspaces.lua")
    foot -e sh -c "\$EDITOR '$WS' 2>/dev/null || nano '$WS'" >/dev/null 2>&1 &
    ;;
  "Reload config")
    hyprctl reload >/dev/null 2>&1
    notify-send -t 1200 mino "Config reloaded"
    ;;
esac
