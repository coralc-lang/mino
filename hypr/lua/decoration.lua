-- Decoration — sharp corners, subtle glass

local T = MINO_THEME or {}

hl.config({
  decoration = {
    rounding = 0,
    active_opacity = 0.92,
    inactive_opacity = 0.82,
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
})
