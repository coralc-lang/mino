#!/usr/bin/env bash
# mino installer — symlinks configs into ~/.config (no sudo for files)
# For packages: run install.sh --packages (prints sudo command; does not run it)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME="${HOME:-/home/$USER}"
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"

info() { printf '\033[36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33m  !\033[0m %s\n' "$*"; }

link() {
  # link <src-rel> <dst-abs>
  local src="$REPO/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    local bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$bak"
    warn "backed up existing → $bak"
  fi
  ln -sfn "$src" "$dst"
  ok "$dst → $1"
}

if [[ "${1:-}" == "--packages" ]]; then
  cat <<'PKG'
Run these yourself (no sudo from installer):

  # full system upgrade — fixes kitty (libcrypto.so.4 / openssl 4)
  sudo pacman -Syu

  # rice dependencies
  sudo pacman -S --needed \
    thunar thunar-volman thunar-archive-plugin tumbler gvfs \
    jq grim slurp wl-clipboard cliphist \
    network-manager-applet nm-connection-editor pavucontrol \
    rofimoji wlogout \
    noto-fonts-emoji

  # optional extras
  sudo pacman -S --needed hyprshot wf-recorder swappy foot

  # AUR (if you use yay)
  yay -S --needed bemoji
PKG
  exit 0
fi

info "linking mino configs"
link hypr/hyprland.lua          "$XDG/hypr/hyprland.lua"
link hypr/lua                   "$XDG/hypr/lua"
link hypr/scripts               "$XDG/hypr/scripts"
link hypr/themes                "$XDG/hypr/themes"
link hypr/hypridle.conf         "$XDG/hypr/hypridle.conf"
link hypr/hyprpaper.conf        "$XDG/hypr/hyprpaper.conf"
link hypr/xdph.conf             "$XDG/hypr/xdph.conf"
# generated at runtime — do not link hyprlock/hyprlauncher/mako
mkdir -p "$XDG/hypr/state" "$XDG/hypr/generated"
[[ -f "$XDG/hypr/state/cursor-size" ]] || echo 24 > "$XDG/hypr/state/cursor-size"
[[ -f "$XDG/hypr/state/show-workspaces" ]] || echo 0 > "$XDG/hypr/state/show-workspaces"
[[ -f "$XDG/hypr/state/waybar-expanded" ]] || echo 1 > "$XDG/hypr/state/waybar-expanded"
[[ -f "$XDG/hypr/state/animations" ]] || echo 1 > "$XDG/hypr/state/animations"
[[ -f "$XDG/hypr/state/idle" ]] || echo 1 > "$XDG/hypr/state/idle"
ok "hypr state defaults"

link waybar/config.jsonc        "$XDG/waybar/config.jsonc"
link waybar/style.css           "$XDG/waybar/style.css"
link foot/foot.ini              "$XDG/foot/foot.ini"
link kitty/kitty.conf           "$XDG/kitty/kitty.conf"
link gtk-3.0/settings.ini       "$XDG/gtk-3.0/settings.ini"
link wlogout                    "$XDG/wlogout"
link mimeapps.list              "$XDG/mimeapps.list"
link thunar/thunarrc            "$HOME/.config/Thunar/thunarrc"

info "wallpapers (must exist)"
WALL="$HOME/Pictures/wallpapers"
mkdir -p "$WALL"
while IFS= read -r f; do
  [[ -f "$WALL/$f" ]] && ok "wallpaper $f" || warn "missing wallpaper: $WALL/$f"
done < "$REPO/wallpapers/MANIFEST.txt"

info "systemd user services"
if command -v systemctl >/dev/null; then
  systemctl --user enable --now hyprpaper.service 2>/dev/null && ok "hyprpaper" || warn "hyprpaper enable failed"
  systemctl --user enable --now hypridle.service 2>/dev/null && ok "hypridle" || warn "hypridle enable failed"
  systemctl --user enable --now mako.service 2>/dev/null && ok "mako" || warn "mako enable failed"
  systemctl --user disable --now waybar.service 2>/dev/null || true
  ok "waybar disabled (Super+N on-demand)"
fi

info "initial theme"
"$XDG/hypr/scripts/apply-theme.sh" deep-sea || warn "apply-theme failed (start a Hyprland session first)"
"$XDG/hypr/scripts/waybar-config.sh" || true

info "SDDM theme (needs root — run manually)"
cat <<SDDM
  sudo cp -a "$REPO/sddm/mino" /usr/share/sddm/themes/
  sudo sed -i 's/^Current=.*/Current=mino/' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null || true
SDDM

info "packages (needs root — run manually)"
echo "  $0 --packages"

info "done — restart Hyprland to load hyprland.lua"
