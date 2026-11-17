#!/usr/bin/env bash
# toggle-waybar.sh — show/hide the on-demand side panel (Super+N)
set -euo pipefail

if pgrep -x waybar >/dev/null 2>&1; then
  systemctl --user stop waybar.service 2>/dev/null || pkill -x waybar || true
  # also kill any orphan
  pkill -x waybar 2>/dev/null || true
else
  # regenerate CSS vars are already in place; just start
  systemctl --user start waybar.service 2>/dev/null || {
    # fallback if unit not enabled/started
    waybar >/dev/null 2>&1 &
  }
fi
