-- Autostart — systemd owns long-running services; one-shots only here

hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("systemctl --user start mako.service")
  hl.exec_cmd("systemctl --user start hyprpaper.service")
  hl.exec_cmd("systemctl --user start hypridle.service")
  hl.exec_cmd("hyprctl setcursor default 24")
  hl.exec_cmd("xhost +SI:localuser:root")
  hl.exec_cmd("cliphist store")
end)
