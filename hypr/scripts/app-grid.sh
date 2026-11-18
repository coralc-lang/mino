#!/usr/bin/env bash
# app-grid.sh — wofi grid launcher (Super+R)
set -euo pipefail
apps="$(grep -h '^Name=' /usr/share/applications/*.desktop 2>/dev/null | cut -d'=' -f2- | sort -u | head -60)"
[[ -z "$apps" ]] && apps="Firefox
Zed
Thunar"
choice="$(printf '%s\n' "$apps" | wofi -d -p "apps" -W 900 -w 4 2>/dev/null || true)"
[[ -z "${choice:-}" ]] && exit 0
sh -c "$choice" >/dev/null 2>&1 || true
