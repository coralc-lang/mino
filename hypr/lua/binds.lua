-- Keybinds — user spec
-- Super+Q close | Super+Return term | Super+C zed | Super+V cliphist
-- Super+Shift+V emoji | Super+R launcher | Super+N sidebar | Super+Shift+T theme
-- Super+F fullscreen | Super+M maximize | Super+L lock
-- Super+Shift+S / PrtSc screenshot | float + swap needed

local HOME = os.getenv("HOME") or "/home/cerie"
local SCRIPTS = HOME .. "/.config/hypr/scripts"

local terminal = "foot"
local editor = "zeditor"
local fileManager = "thunar"  -- thunar preferred; nautilus fallback via shell
local browser = "firefox"
local menu = "rofi -show drun -theme mino"

-- Apps
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + C", hl.dsp.exec_cmd(editor))
hl.bind("SUPER + E", hl.dsp.exec_cmd("command -v thunar >/dev/null && thunar || nautilus"))
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + G", hl.dsp.exec_cmd("godot"))
hl.bind("SUPER + R", hl.dsp.exec_cmd(menu))
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd(terminal .. " -e btop"))
hl.bind("SUPER + ALT + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("hyprpicker -a -n"))

-- Window management
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
hl.bind("SUPER + M", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + Tab", hl.dsp.window.cycle_next())
hl.bind("SUPER + SHIFT + Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
end)
hl.bind("SUPER + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.swap({ direction = "left" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.swap({ direction = "up" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.swap({ direction = "down" }))

-- Focus
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + ALT + J", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + semicolon", hl.dsp.focus({ direction = "right" }))

-- Move windows
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- Clipboard / emoji / float (Super+V is clipboard per spec)
hl.bind("SUPER + V", hl.dsp.exec_cmd(
  'cliphist list | wofi --dmenu | cliphist decode | wl-copy'
))
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("rofimoji -a copy"))

-- Theme / panel / lock / settings
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd(SCRIPTS .. "/theme-cycle.sh"))
hl.bind("SUPER + N", hl.dsp.exec_cmd(SCRIPTS .. "/toggle-waybar.sh"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd(SCRIPTS .. "/wallpaper-picker.sh"))
hl.bind("SUPER + SHIFT + comma", hl.dsp.exec_cmd(SCRIPTS .. "/settings.sh"))
hl.bind("SUPER + I", hl.dsp.exec_cmd(SCRIPTS .. "/settings.sh"))

-- Session
hl.bind("SUPER + SHIFT + Escape", hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("loginctl lock-session"))

-- Screenshots
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(
  'grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot" "Region copied"'
))
hl.bind("Print", hl.dsp.exec_cmd(
  'grim - | wl-copy && notify-send "Screenshot" "Fullscreen copied"'
))
hl.bind("SUPER + Print", hl.dsp.exec_cmd(
  'grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot" "Region copied"'
))

-- Media / brightness (locked = works on lockscreen)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Mouse
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
