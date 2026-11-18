#!/usr/bin/env bash
# mino — uninstall user config artifacts
set -euo pipefail
D="$HOME/.config/hypr"
W="$HOME/.config/waybar"
O="$HOME/.config/gtk-3.0"
G="$HOME/.config/gtk-4.0"
R="$HOME/.config/rofi"
S="$HOME/.config/hypr/scripts"
STATE="$HOME/.config/hypr/state"

rm -rf "$S" "$D/lua" "$D/hyprland.lua" "$D/hyprland.conf" "$D/hyprlock.conf" \
       "$D/hyprpaper.conf" "$D/hypridle.conf" "$D/hypr-polkit-agent.conf" \
       "$D/xdph.conf" "$D/hypr-launcher.conf" "$D/hypr-theme-rice-plan.md" \
       "$D/theming" 2>/dev/null || true
rm -rf "$D/themes" "$D/state" "$D/generated" "$D/conf.d" 2>/dev/null || true
rm -rf "$D/.claude" 2>/dev/null || true

rm -rf "$W" 2>/dev/null || true
rm -f "$O/gtk.css" "$O/settings.ini" 2>/dev/null || true
rm -f "$G/gtk.css" 2>/dev/null || true
rm -f "$R/config.rasi" "$R/mino.rasi" 2>/dev/null || true
rm -rf "$R/themes" 2>/dev/null || true

# foot
rm -f "$HOME/.config/foot/foot.ini" 2>/dev/null || true

# thunar
rm -f "$HOME/.config/Thunar/thunarrc" 2>/dev/null || true
rm -f "$HOME/.config/thunar/thunarrc" 2>/dev/null || true

# kitty
rm -f "$HOME/.config/kitty/kitty.conf" 2>/dev/null || true

# mako
rm -f "$HOME/.config/mako/config" 2>/dev/null || true

# state
rm -f "$HOME/.config/mako" "$STATE" -r 2>/dev/null || true

echo "mino uninstall: user config cleaned."
echo "Remaining compositor references: source lines in hyprland.conf/conf.d"
echo "If a hyprland.conf remains, review it."
