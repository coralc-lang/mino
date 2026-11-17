-- Input + gestures

hl.config({
  input = {
    follow_mouse = 1,
    sensitivity = 0,
    accel_profile = "flat",
    natural_scroll = false,
    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
      disable_while_typing = true,
      scroll_factor = 0.4,
    },
  },
})

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

hl.config({
  gestures = {
    workspace_swipe_distance = 300,
    workspace_swipe_forever = false,
    workspace_swipe_create_new = true,
  },
})
