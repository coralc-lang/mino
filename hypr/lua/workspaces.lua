-- Workspaces — Super+number focus; Super+Shift+number move window; Super+Alt+Shift+arrows adjacent move

for i = 1, 9 do
  local key = tostring(i)
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Move focused window to adjacent workspace
hl.bind("SUPER + ALT + SHIFT + left", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace -1"))
hl.bind("SUPER + ALT + SHIFT + right", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace +1"))
hl.bind("SUPER + ALT + SHIFT + up", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace -1"))
hl.bind("SUPER + ALT + SHIFT + down", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace +1"))

hl.bind("SUPER + grave", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }))
