-- Environment

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("XCURSOR_THEME", "default")

local cursor_size = "16"
do
  local f = io.open(os.getenv("HOME") .. "/.config/hypr/state/cursor-size", "r")
  if f then
    local v = f:read("*l")
    f:close()
    if v and v:match("^%d+$") then cursor_size = v end
  end
end
hl.env("XCURSOR_SIZE", cursor_size)
hl.env("HYPRCURSOR_SIZE", cursor_size)

hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
end)
