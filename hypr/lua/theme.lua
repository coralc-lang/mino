-- Active theme colors — symlink themes/current.lua managed by apply-theme.sh
local ok, theme = pcall(require, "themes.current")
if not ok or type(theme) ~= "table" then
  theme = {
    name = "deep-sea",
    accent = "88c0d0",
    accent_dim = "88c0d099",
    bg = "0f1419",
    fg = "e5e9f0",
    border_dim = "2e3440",
    shadow = "88c0d01a",
    surface = "161b22",
    surface_hi = "1e2530",
    on_surface = "c8d0dc",
    on_surface_variant = "8b949e",
    error = "ff7b72",
    success = "7ee787",
    warning = "e3b341",
    wallpaper = "/home/cerie/Pictures/wallpapers/digital-art-dark-cosmic-night-sky.jpg",
  }
end

_G.MINO_THEME = theme

local function rgba(hex, alpha)
  hex = tostring(hex or "ffffffff"):gsub("#", "")
  if #hex == 6 then hex = hex .. "ff" end
  if alpha then
    local a = math.floor((tonumber(alpha, 16) or 255))
    hex = hex:sub(1, 6) .. string.format("%02x", a)
  end
  return "rgba(" .. hex .. ")"
end

_G.MINO_RGBA = rgba

return theme
