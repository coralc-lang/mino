-- Window / layer / workspace rules

-- Never let apps force fullscreen on open (maximize is allowed)
hl.window_rule({
  name = "suppress-fullscreen",
  match = { class = ".*" },
  suppress_event = "fullscreen",
})

-- Floats (dialogs / small popups — these get blur via decoration.blur.popups)
hl.window_rule({ name = "float-pavucontrol", match = { class = "^pavucontrol$" }, float = true })
hl.window_rule({ name = "float-nm-conn", match = { class = "^nm-connection-editor$" }, float = true })
hl.window_rule({ name = "float-blueman", match = { class = "^blueman-manager$" }, float = true })
hl.window_rule({ name = "float-calc", match = { class = "^org.gnome.Calculator$" }, float = true })
hl.window_rule({
  name = "float-nautilus-copy",
  match = { class = "^org.gnome.Nautilus$", title = "^(Copying|Moving)" },
  float = true,
})
hl.window_rule({ name = "float-hyprpicker", match = { class = "^hyprpicker$" }, float = true })
hl.window_rule({ name = "float-imv", match = { class = "^imv$" }, float = true })
hl.window_rule({
  name = "float-pip",
  match = { class = "^firefox$", title = "^(Picture-in-Picture)$" },
  float = true,
})

-- Mino UI windows (launcher / settings from the mockup)
hl.window_rule({ name = "float-mino-launcher", match = { class = "^mino\\.launcher$" }, float = true, center = true })
hl.window_rule({ name = "float-mino-settings", match = { class = "^mino\\.settings$" }, float = true, center = true })

-- Opacity exceptions (opaque = no blur through these)
hl.window_rule({ name = "opaque-firefox", match = { class = "^firefox$" }, opaque = true })
hl.window_rule({ name = "opaque-kitty", match = { class = "^kitty$" }, opaque = true })
hl.window_rule({ name = "opaque-nautilus", match = { class = "^org.gnome.Nautilus$" }, opaque = true })
hl.window_rule({ name = "opaque-zed", match = { class = "^zed$" }, opaque = true })
hl.window_rule({ name = "opaque-pulsar", match = { class = "^Pulsar$" }, opaque = true })

-- Idle inhibit while fullscreen
hl.window_rule({
  name = "idle-inhibit-fs",
  match = { fullscreen = true },
  idle_inhibit = "fullscreen",
})

-- Fix XWayland drag ghosts
hl.layer_rule({ match = { namespace = "^widgets$" }, blur = false })

-- NO blur on waybar (layer blur looked wrong on the side panel)
-- Keep mako blur only (notifications over content)
hl.layer_rule({ match = { namespace = "^mako$" }, blur = true, ignore_alpha = 0.3 })

-- Workspace 1 default on laptop panel
hl.workspace_rule({
  workspace = "1",
  monitor = "eDP-1",
  default = true,
})
