-- General layout / gaps / borders (theme colors via MINO_THEME)

local T = MINO_THEME or {}

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 6,
    border_size = 1,
    col = {
      active_border = MINO_RGBA(T.accent or "88c0d0"),
      inactive_border = MINO_RGBA(T.border_dim or "2e3440"),
    },
    resize_on_border = true,
    extend_border_grab_area = 8,
    layout = "dwindle",
    allow_tearing = false,
  },
  dwindle = {
    preserve_split = true,
    smart_split = false,
    smart_resizing = true,
    default_split_ratio = 1.0,
  },
  master = {
    new_status = "inherit",
  },
})
