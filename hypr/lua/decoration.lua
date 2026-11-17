-- Decoration — sharp corners; transparency from state/transparency

local T = MINO_THEME or {}

local trans = 1
do
  local f = io.open(os.getenv("HOME") .. "/.config/hypr/state/transparency", "r")
  if f then
    local v = f:read("*l")
    f:close()
    if v and v:match("^%d+$") then trans = tonumber(v) end
  end
end

-- transparency=1 → glassy; transparency=0 → solid
local active_op = (trans == 1) and 0.92 or 1.0
local inactive_op = (trans == 1) and 0.80 or 1.0

hl.config({
  decoration = {
    rounding = 0,
    active_opacity = active_op,
    inactive_opacity = inactive_op,
    fullscreen_opacity = 1.0,
    dim_inactive = false,
    dim_strength = 0.1,
    dim_special = 0.3,
    shadow = {
      enabled = true,
      range = 12,
      render_power = 3,
      color = MINO_RGBA(T.shadow or "88c0d01a"),
      offset = { 0, 2 },
    },
    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      vibrancy = 0.15,
      vibrancy_darkness = 0.4,
      special = true,
      popups = true,
      new_optimizations = true,
      ignore_opacity = false,
    },
  },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },
})
