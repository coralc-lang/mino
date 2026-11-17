#!/usr/bin/env python3
"""GTK3 wallpaper grid picker with thumbnails."""
import gi, os, subprocess, sys, glob
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib

DIR = os.path.expanduser("~/Pictures/wallpapers")
HYPR = os.path.expanduser("~/.config/hypr")
THUMB = os.path.expanduser("~/.cache/mino/wall-thumbs")
os.makedirs(THUMB, exist_ok=True)

def ensure_hypr_env():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    base = f"/run/user/{os.getuid()}/hypr"
    if not sig or not os.path.exists(f"{base}/{sig}/.socket.sock"):
        cands = []
        if os.path.isdir(base):
            for d in os.listdir(base):
                if os.path.exists(f"{base}/{d}/.socket.sock"):
                    cands.append(d)
        # newest by mtime
        if cands:
            cands.sort(key=lambda d: os.path.getmtime(f"{base}/{d}"), reverse=True)
            os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = cands[0]
    if not os.environ.get("WAYLAND_DISPLAY"):
        sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
        # find hypr pid
        try:
            out = subprocess.check_output(["hyprctl", "instances"], text=True)
            import re
            m = re.search(r"pid:\s*(\d+)", out)
            if m:
                pid = m.group(1)
                with open(f"/proc/{pid}/environ", "rb") as f:
                    env = f.read().split(b"\0")
                for e in env:
                    if e.startswith(b"WAYLAND_DISPLAY="):
                        os.environ["WAYLAND_DISPLAY"] = e.split(b"=",1)[1].decode()
        except Exception:
            pass

def apply_wallpaper(path: str):
    ensure_hypr_env()
    try:
        subprocess.run(["hyprctl", "hyprpaper", "wallpaper", f",{path}"],
                       check=False, capture_output=True, timeout=3)
    except Exception:
        pass

    cur = "deep-sea"
    try:
        cur = open(os.path.join(HYPR, "themes/current")).read().strip() or "deep-sea"
    except Exception:
        pass
    for rel in (f"themes/{cur}.lua", f"themes/{cur}.conf",
                "themes/current.lua", "themes/current.conf"):
        p = os.path.join(HYPR, rel)
        if os.path.islink(p):
            p = os.path.realpath(p)
        if not os.path.isfile(p):
            continue
        try:
            t = open(p).read()
            if p.endswith(".lua"):
                import re
                t = re.sub(r'wallpaper\s*=\s*"[^"]*"', f'wallpaper = "{path}"', t, count=1)
            else:
                t = re.sub(r'^\$wallpaper\s*=.*$', f"$wallpaper   = {path}", t, count=1, flags=re.M)
            open(p, "w").write(t)
        except Exception:
            pass

    hp = os.path.join(HYPR, "hyprpaper.conf")
    open(hp, "w").write(
        "wallpaper {\n    monitor =\n    path = %s\n    fit_mode = cover\n}\n\nsplash = false\nipc = on\n" % path
    )
    hl = os.path.join(HYPR, "hyprlock.conf")
    if os.path.isfile(hl):
        try:
            lines = open(hl).read().splitlines()
            out = []
            for ln in lines:
                if ln.strip().startswith("path = "):
                    out.append(f"    path = {path}")
                else:
                    out.append(ln)
            open(hl, "w").write("\n".join(out) + "\n")
        except Exception:
            pass
    try:
        subprocess.run(["notify-send", "-t", "2000", "mino", f"Wallpaper: {os.path.basename(path)}"],
                       check=False)
    except Exception:
        pass

def make_thumb(path: str) -> str:
    base = os.path.basename(path)
    out = os.path.join(THUMB, base + ".png")
    if os.path.isfile(out) and os.path.getmtime(out) >= os.path.getmtime(path):
        return out
    try:
        subprocess.run(
            ["magick", path, "-thumbnail", "240x140^", "-gravity", "center",
             "-extent", "240x140", "-quality", "80", out],
            check=False, capture_output=True, timeout=5,
        )
    except Exception:
        try:
            subprocess.run(
                ["convert", path, "-thumbnail", "240x140^", "-gravity", "center",
                 "-extent", "240x140", out],
                check=False, capture_output=True, timeout=5,
            )
        except Exception:
            return path
    return out if os.path.isfile(out) else path

class Picker(Gtk.Window):
    def __init__(self):
        super().__init__(title="Wallpapers")
        self.set_default_size(780, 480)
        self.set_border_width(12)
        self.get_style_context().add_class("mino-pick")

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(vbox)

        header = Gtk.Label(label="_pick a wallpaper_")
        header.set_xalign(0)
        header.get_style_context().add_class("hdr")
        vbox.pack_start(header, False, False, 0)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        vbox.pack_start(scrolled, True, True, 0)

        flow = Gtk.FlowBox()
        flow.set_max_children_per_row(4)
        flow.set_selection_mode(Gtk.SelectionMode.SINGLE)
        flow.set_homogeneous(True)
        scrolled.add(flow)

        files = sorted(
            f for f in glob.glob(os.path.join(DIR, "*"))
            if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp"))
        )
        if not files:
            lbl = Gtk.Label(label=f"No images in {DIR}")
            flow.add(lbl)

        for f in files:
            thumb = make_thumb(f)
            try:
                pix = GdkPixbuf.Pixbuf.new_from_file_at_size(thumb, 220, 130)
            except Exception:
                continue
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            img = Gtk.Image.new_from_pixbuf(pix)
            box.pack_start(img, False, False, 0)
            name = Gtk.Label(label=os.path.basename(f))
            name.set_ellipsize(3)  # END
            name.get_style_context().add_class("cap")
            box.pack_start(name, False, False, 0)
            box._wall_path = f
            box.show_all()
            flow.add(box)

        flow.connect("child-activated", self.on_activate)

        btn_box = Gtk.Box(spacing=8)
        cancel = Gtk.Button(label="Cancel")
        cancel.connect("clicked", lambda *_: Gtk.main_quit())
        apply_btn = Gtk.Button(label="Set wallpaper")
        apply_btn.get_style_context().add_class("suggested")
        apply_btn.connect("clicked", self.on_apply_btn)
        btn_box.pack_end(apply_btn, False, False, 0)
        btn_box.pack_end(cancel, False, False, 0)
        vbox.pack_start(btn_box, False, False, 0)

        self.flow = flow
        self.connect("key-press-event", self.on_key)

    def selected_path(self):
        rows = self.flow.get_selected_children()
        if not rows:
            return None
        return self._find_path(rows[0])

    @staticmethod
    def _find_path(widget):
        if widget is None:
            return None
        if hasattr(widget, "_wall_path"):
            return widget._wall_path
        if isinstance(widget, Gtk.Container):
            for ch in widget.get_children():
                found = Picker._find_path(ch)
                if found:
                    return found
        return None

    def on_activate(self, flow, child):
        path = self._find_path(child)
        if path:
            apply_wallpaper(path)
            Gtk.main_quit()

    def on_apply_btn(self, *_):
        path = self.selected_path()
        if path:
            apply_wallpaper(path)
        Gtk.main_quit()

    def on_key(self, _w, ev):
        if ev.keyval == 65307:
            Gtk.main_quit()
        elif ev.keyval in (65293, 65421):  # Return
            self.on_apply_btn()
        return False

css = b"""
.mino-pick { background: #0f1419; color: #e5e9f0; }
.mino-pick .hdr {
  font-family: "JetBrains Mono Nerd Font";
  font-size: 16px;
  font-weight: 700;
  color: #88c0d0;
  padding: 4px 2px;
}
.mino-pick .cap {
  font-family: "JetBrains Mono Nerd Font";
  font-size: 11px;
  color: #8b949e;
}
.mino-pick flowbox { background: transparent; }
.mino-pick flowbox child {
  background: #161b22;
  border: 1px solid #2e3440;
  border-radius: 0;
  padding: 6px;
  margin: 4px;
}
.mino-pick flowbox child:selected {
  border-color: #88c0d0;
  background: #1a3040;
}
.mino-pick button {
  background: #161b22;
  color: #e5e9f0;
  border: 1px solid #2e3440;
  border-radius: 0;
  padding: 8px 16px;
  font-family: "JetBrains Mono Nerd Font";
}
.mino-pick button:hover { border-color: #88c0d0; color: #88c0d0; }
.mino-pick button.suggested {
  background: #88c0d0;
  color: #0f1419;
  border-color: #88c0d0;
  font-weight: 700;
}
.mino-pick button.suggested:hover { background: #a0d0dc; color: #0f1419; }
.mino-pick scrolledwindow { background: transparent; border: none; }
"""
prov = Gtk.CssProvider()
prov.load_from_data(css)
from gi.repository import Gdk as _Gdk
Gtk.StyleContext.add_provider_for_screen(
    _Gdk.Screen.get_default(), prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)

ensure_hypr_env()
win = Picker()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
