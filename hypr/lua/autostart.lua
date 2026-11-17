-- Autostart — hyprpaper first (no default wallpaper flash), then services

hl.on("hyprland.start", function()
  -- wallpaper immediately (systemd unit may already be up; also direct fallback)
  hl.exec_cmd("systemctl --user start hyprpaper.service")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("systemctl --user start mako.service")
  hl.exec_cmd("systemctl --user start hypridle.service")
  hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
  -- sidebar auto-open
  hl.exec_cmd("systemctl --user start waybar.service")
  local cs = "16"
  local f = io.open(os.getenv("HOME") .. "/.config/hypr/state/cursor-size", "r")
  if f then
    local v = f:read("*l")
    f:close()
    if v and v:match("^%d+$") then cs = v end
  end
  hl.exec_cmd("hyprctl setcursor default " .. cs)
  hl.exec_cmd("xhost +SI:localuser:root")
  hl.exec_cmd("cliphist store")
end)
