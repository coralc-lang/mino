#!/usr/bin/env python3
"""Minimal GTK3 slider popup for volume or brightness."""
import gi, subprocess, sys, os
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib

kind = sys.argv[1] if len(sys.argv) > 1 else "volume"  # volume|brightness

def get_val():
    if kind == "volume":
        out = subprocess.check_output(
            ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], text=True
        ).split()
        muted = "MUTED" in out
        vol = float(out[1])
        return int(round(vol * 100)), muted
    else:
        # brightnessctl -m: device,class,current,percent,max
        out = subprocess.check_output(["brightnessctl", "-m"], text=True).strip().split(",")
        cur, mx = int(out[2]), int(out[4])
        # percent of max, min floor 1%
        pct = max(1, int(round(100 * cur / mx)))
        return pct, False

def set_val(pct):
    pct = max(1 if kind == "brightness" else 0, min(100, int(pct)))
    if kind == "volume":
        if pct == 0:
            subprocess.check_call(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "1"])
        else:
            subprocess.check_call(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"])
            subprocess.check_call(
                ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", f"{pct}%"]
            )
    else:
        # never allow 0
        pct = max(1, pct)
        subprocess.check_call(["brightnessctl", "set", f"{pct}%"])

def toggle_mute(*_):
    subprocess.check_call(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    v, m = get_val()
    scale.set_value(v)
    lbl.set_text(("muted" if m else f"{v}%"))

class SliderWin(Gtk.Window):
    def __init__(self):
        super().__init__(title=("Volume" if kind == "volume" else "Brightness"))
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_resizable(False)
        self.set_border_width(10)
        self.set_default_size(280, 92)
        self.get_style_context().add_class("mino-slider")

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(vbox)

        top = Gtk.Box(spacing=8)
        title = Gtk.Label(label=("󰕾  Volume" if kind == "volume" else "󰃠  Brightness"))
        title.set_xalign(0)
        global lbl
        v, m = get_val()
        lbl = Gtk.Label(label=("muted" if (kind=="volume" and m) else f"{v}%"))
        lbl.set_xalign(1)
        top.pack_start(title, True, True, 0)
        top.pack_end(lbl, False, False, 0)
        vbox.pack_start(top, False, False, 0)

        global scale
        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 1 if kind=="brightness" else 0, 100, 1)
        scale.set_value(v)
        scale.set_draw_value(False)
        scale.set_hexpand(True)
        scale.connect("value-changed", self.on_change)
        vbox.pack_start(scale, False, False, 0)

        if kind == "volume":
            btn = Gtk.Button(label="Mute / Unmute")
            btn.connect("clicked", toggle_mute)
            vbox.pack_start(btn, False, False, 0)

        # close on focus out / escape
        self.connect("key-press-event", self.on_key)
        self.connect("focus-out-event", lambda *_: Gtk.main_quit() or True)

    def on_key(self, _w, ev):
        if ev.keyval == 65307:  # Escape
            Gtk.main_quit()
        return False

    def on_change(self, scale):
        set_val(scale.get_value())
        v, m = get_val()
        if kind == "volume" and m:
            lbl.set_text("muted")
        else:
            lbl.set_text(f"{v}%")

# CSS
css = b"""
.mino-slider {
  background: #0f1419;
  color: #e5e9f0;
}
.mino-slider scale {
  min-height: 28px;
}
.mino-slider scale trough {
  background: #1e2530;
  border: 1px solid #2e3440;
  border-radius: 0;
  min-height: 8px;
}
.mino-slider scale highlight {
  background: #88c0d0;
  border-radius: 0;
}
.mino-slider scale slider {
  background: #e5e9f0;
  border: 2px solid #88c0d0;
  border-radius: 0;
  min-width: 14px;
  min-height: 14px;
}
.mino-slider button {
  background: #161b22;
  color: #e5e9f0;
  border: 1px solid #2e3440;
  border-radius: 0;
  padding: 6px 12px;
}
.mino-slider button:hover {
  background: #1a3040;
  border-color: #88c0d0;
  color: #88c0d0;
}
.mino-slider label {
  color: #e5e9f0;
  font-family: "JetBrains Mono Nerd Font";
  font-size: 13px;
}
"""
prov = Gtk.CssProvider()
prov.load_from_data(css)
from gi.repository import Gdk
Gtk.StyleContext.add_provider_for_screen(
    Gdk.Screen.get_default(),
    prov,
    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
)

win = SliderWin()
win.show_all()
# position near center-right (sidebar area)
win.move(1400, 300)
Gtk.main()
