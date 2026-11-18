#!/usr/bin/env python3
"""mino-ui: icon-grid launcher and card-based settings. GTK4, no libadwaita.

  mino-ui.py launcher      # Super+R
  mino-ui.py settings

Hyprland app-ids: mino.launcher, mino.settings (float + center those).
"""
import json, os, re, subprocess, sys
import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, Gdk, Gio, GLib

HERE = os.path.dirname(os.path.realpath(__file__))
CONF = os.path.expanduser("~/.config/mino")
FAVS = ["firefox", "zeditor", "zed", "thunar", "foot", "godot"]
ACCENTS = {
    "Violet": ("#8b7cf6", "#5ad4e6"), "Ocean": ("#4f9cf7", "#5ad4e6"),
    "Mint": ("#4fd1a1", "#7bdff2"), "Amber": ("#f5b86b", "#f2677a"),
    "Rose": ("#f27aa8", "#8b7cf6"), "Slate": ("#9aa7c7", "#5ad4e6"),
}
# Edit to match your real binds. Shown on the Keybinds page.
KEYBINDS = [
    ("App launcher", ["Super", "R"]),
    ("Terminal", ["Super", "Enter"]),
    ("Close window", ["Super", "Q"]),
    ("Toggle floating", ["Super", "V"]),
    ("Fullscreen", ["Super", "F"]),
    ("Switch workspace", ["Super", "1-5"]),
    ("Move to workspace", ["Super", "Shift", "1-5"]),
    ("Settings", ["Super", "S"]),
]


# ── helpers ───────────────────────────────────────────────────────────
def sh(cmd, timeout=3):
    try:
        return subprocess.run(cmd, shell=True, capture_output=True, text=True,
                              timeout=timeout).stdout.strip()
    except Exception:
        return ""


def fire(cmd):
    subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)


def icon(names, size=20):
    theme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default())
    names = [names] if isinstance(names, str) else names
    pick = next((n for n in names if theme.has_icon(n)), names[-1])
    img = Gtk.Image.new_from_icon_name(pick)
    img.set_pixel_size(size)
    return img


_provider = Gtk.CssProvider()


def load_css(accent=None):
    css = open(os.path.join(HERE, "mino.css")).read()
    if accent:
        css = re.sub(r"(@define-color accent )#[0-9a-fA-F]{6};", rf"\g<1>{accent[0]};", css)
        css = re.sub(r"(@define-color accent2)\s+#[0-9a-fA-F]{6};", rf"\g<1> {accent[1]};", css)
    _provider.load_from_string(css)


def saved_accent():
    try:
        return ACCENTS.get(open(os.path.join(CONF, "accent")).read().strip())
    except Exception:
        return None


def setup_css():
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(), _provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    load_css(saved_accent())


def add_escape(win):
    kc = Gtk.EventControllerKey()
    kc.connect("key-pressed", lambda c, k, *a: (win.close(), True)[1] if k == Gdk.KEY_Escape else False)
    win.add_controller(kc)


# ── launcher ──────────────────────────────────────────────────────────
class AppTile(Gtk.FlowBoxChild):
    def __init__(self, info):
        super().__init__()
        self.info = info
        self.name = info.get_name()
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.add_css_class("app")
        gicon = info.get_icon()
        img = Gtk.Image.new_from_gicon(gicon) if gicon else Gtk.Image.new_from_icon_name("application-x-executable")
        img.set_pixel_size(52)
        lbl = Gtk.Label(label=self.name, ellipsize=3, max_width_chars=13)
        lbl.add_css_class("app-name")
        box.append(img)
        box.append(lbl)
        self.set_child(box)


class DemoInfo:
    def __init__(self, name, ico):
        self.n, self.i = name, ico
    def get_name(self): return self.n
    def get_icon(self): return Gio.ThemedIcon.new(self.i)
    def get_id(self): return self.n.lower() + ".desktop"
    def launch(self, *a): pass


def list_apps():
    if os.environ.get("MINO_DEMO"):
        demo = [("Firefox", "web-browser"), ("Zed", "text-editor"), ("Files", "system-file-manager"),
                ("Foot", "utilities-terminal"), ("Godot", "applications-games"), ("Settings", "preferences-system"),
                ("Calculator", "accessories-calculator"), ("Image Viewer", "image-x-generic"),
                ("Music", "multimedia-audio-player"), ("Video", "multimedia-video-player"),
                ("Mixer", "audio-volume-high"), ("Disks", "drive-harddisk"),
                ("Calendar", "x-office-calendar"), ("Camera", "camera-photo"),
                ("Archive", "package-x-generic"), ("Fonts", "preferences-desktop-font"),
                ("Network", "network-wired"), ("Bluetooth", "bluetooth")]
        return [DemoInfo(n, i) for n, i in demo]
    seen, out = set(), []
    for a in Gio.AppInfo.get_all():
        if a.should_show() and a.get_id() not in seen:
            seen.add(a.get_id())
            out.append(a)
    return out


class Launcher(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, default_width=820, default_height=600, decorated=False)
        self.add_css_class("mino")
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        for side in ("top", "bottom", "start", "end"):
            getattr(outer, f"set_margin_{side}")(26)

        self.entry = Gtk.SearchEntry(placeholder_text="Search applications")
        self.entry.add_css_class("search")
        self.entry.set_key_capture_widget(self)
        self.entry.connect("search-changed", lambda *_: self.refilter())
        self.entry.connect("activate", lambda *_: self.launch_first())
        down = Gtk.EventControllerKey()
        down.connect("key-pressed", self.on_entry_key)
        self.entry.add_controller(down)

        self.flow = Gtk.FlowBox(valign=Gtk.Align.START, homogeneous=True, min_children_per_line=3,
                                max_children_per_line=6, column_spacing=4, row_spacing=4,
                                selection_mode=Gtk.SelectionMode.SINGLE, activate_on_single_click=True)
        self.flow.set_filter_func(self.visible)
        self.flow.connect("child-activated", lambda f, c: self.launch(c.info))

        def rank(a):
            ident = (a.get_id() or "").lower()
            for i, f in enumerate(FAVS):
                if f in ident:
                    return (0, i)
            return (1, a.get_name().lower())
        for a in sorted(list_apps(), key=rank):
            self.flow.append(AppTile(a))

        sc = Gtk.ScrolledWindow(child=self.flow, vexpand=True, hscrollbar_policy=Gtk.PolicyType.NEVER)
        hint = Gtk.Label(label="↵ launch   ·   ↓ browse   ·   esc close", xalign=0.5)
        hint.add_css_class("hint")
        for w in (self.entry, sc, hint):
            outer.append(w)
        self.set_child(outer)
        add_escape(self)
        self.refilter()

        self.ready = False
        GLib.timeout_add(500, self.arm)
        self.connect("notify::is-active", lambda *_: self.close() if self.ready and not self.is_active() else None)

    def arm(self):
        self.ready = True
        return False

    def visible(self, child):
        q = self.entry.get_text().strip().lower()
        return not q or q in child.name.lower()

    def first_visible(self):
        i = 0
        while (c := self.flow.get_child_at_index(i)):
            if self.visible(c):
                return c
            i += 1

    def refilter(self):
        self.flow.invalidate_filter()
        c = self.first_visible()
        if c:
            self.flow.select_child(c)

    def on_entry_key(self, ctrl, key, *a):
        if key == Gdk.KEY_Down:
            c = self.first_visible()
            if c:
                c.grab_focus()
            return True
        return False

    def launch_first(self):
        c = self.first_visible()
        if c:
            self.launch(c.info)

    def launch(self, info):
        try:
            info.launch([], None)
        except Exception:
            pass
        GLib.timeout_add(120, lambda: self.close() or False)


# ── settings widgets ──────────────────────────────────────────────────
def badge(ico):
    b = Gtk.Box(halign=Gtk.Align.START, valign=Gtk.Align.CENTER, hexpand=False)
    b.add_css_class("badge")
    i = icon(ico, 20)
    i.set_halign(Gtk.Align.CENTER); i.set_valign(Gtk.Align.CENTER)
    i.set_hexpand(True); i.set_vexpand(True)
    b.append(i)
    return b


def label(text, css, xalign=0.0):
    l = Gtk.Label(label=text, xalign=xalign, halign=Gtk.Align.START if xalign == 0.0 else Gtk.Align.CENTER)
    l.add_css_class(css)
    return l


class Toggle(Gtk.Button):
    def __init__(self, ico, title, get, set_):
        super().__init__()
        self.add_css_class("tile")
        self.set_, self.on = set_, bool(get())
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        self.sub = label("", "tile-sub")
        box.append(badge(ico))
        col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        col.append(label(title, "tile-title"))
        col.append(self.sub)
        box.append(col)
        self.set_child(box)
        self.connect("clicked", self.flip)
        self.paint()

    def paint(self):
        (self.add_css_class if self.on else self.remove_css_class)("on")
        self.sub.set_text("On" if self.on else "Off")

    def flip(self, *_):
        self.on = not self.on
        self.set_(self.on)
        self.paint()


class Action(Gtk.Button):
    def __init__(self, ico, title, sub, cmd, danger=False):
        super().__init__()
        self.add_css_class("action")
        if danger:
            self.add_css_class("danger")
        row = Gtk.Box(spacing=14)
        row.append(badge(ico))
        col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2, valign=Gtk.Align.CENTER)
        col.append(label(title, "tile-title"))
        col.append(label(sub, "tile-sub"))
        row.append(col)
        self.set_child(row)
        self.connect("clicked", lambda *_: fire(cmd))


class Slider(Gtk.Box):
    def __init__(self, ico, title, value, apply):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        self.add_css_class("card")
        self.apply, self.timer = apply, None
        top = Gtk.Box(spacing=12)
        top.append(badge(ico))
        t = label(title, "tile-title")
        t.set_hexpand(True); t.set_valign(Gtk.Align.CENTER)
        self.val = label(f"{int(value)}%", "value")
        top.append(t); top.append(self.val)
        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.scale.set_draw_value(False)
        self.scale.set_value(value)
        self.scale.connect("value-changed", self.changed)
        self.append(top); self.append(self.scale)

    def changed(self, s):
        v = int(s.get_value())
        self.val.set_text(f"{v}%")
        if self.timer:
            GLib.source_remove(self.timer)
        self.timer = GLib.timeout_add(120, self.fire, v)

    def fire(self, v):
        self.timer = None
        self.apply(v)
        return False


def grid(widgets, cols):
    g = Gtk.Grid(column_spacing=12, row_spacing=12, column_homogeneous=True)
    for i, w in enumerate(widgets):
        g.attach(w, i % cols, i // cols, 1, 1)
    return g


def page(title, sub, *blocks):
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
    for side in ("top", "bottom"):
        getattr(box, f"set_margin_{side}")(30)
    box.set_margin_start(34); box.set_margin_end(34)
    box.append(label(title, "page-title"))
    box.append(label(sub, "page-sub"))
    for b in blocks:
        box.append(label(b, "section") if isinstance(b, str) else b)
    return Gtk.ScrolledWindow(child=box, hscrollbar_policy=Gtk.PolicyType.NEVER, vexpand=True, hexpand=True)


# ── system state ──────────────────────────────────────────────────────
def hypr_opt(name):
    try:
        return json.loads(sh(f"hyprctl getoption {name} -j")).get("int", 1)
    except Exception:
        return 1


def get_vol(target="@DEFAULT_AUDIO_SINK@"):
    m = re.search(r"([\d.]+)", sh(f"wpctl get-volume {target}"))
    return round(float(m.group(1)) * 100) if m else 50


def get_bright():
    p = sh("brightnessctl -m").split(",")
    try:
        return int(p[3].strip("%"))
    except Exception:
        return 70


def proc_toggle(name, cmd):
    def setter(on):
        fire(cmd) if on else fire(f"pkill -x {name}")
    return setter


# ── settings window ───────────────────────────────────────────────────
class Settings(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, default_width=980, default_height=660, decorated=False)
        self.add_css_class("mino")
        root = Gtk.Box()
        side = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        side.add_css_class("sidebar")
        side.set_size_request(230, -1)
        side.append(label("mino", "brand"))
        side.append(label("settings", "brand-sub"))

        self.stack = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE, transition_duration=160,
                               hexpand=True, vexpand=True)
        self.navs = {}
        pages = [
            ("quick", "Quick settings", "view-grid-symbolic", self.p_quick()),
            ("look", "Appearance", "applications-graphics-symbolic", self.p_look()),
            ("sound", "Sound & display", "audio-volume-high-symbolic", self.p_sound()),
            ("net", "Network", "network-wireless-symbolic", self.p_net()),
            ("sys", "System", "system-shutdown-symbolic", self.p_sys()),
            ("keys", "Keybinds", "input-keyboard-symbolic", self.p_keys()),
        ]
        for key, name, ico, widget in pages:
            self.stack.add_named(widget, key)
            b = Gtk.Button()
            b.add_css_class("nav")
            row = Gtk.Box(spacing=12)
            row.append(icon(ico, 18)); row.append(Gtk.Label(label=name))
            b.set_child(row)
            b.connect("clicked", lambda _b, k=key: self.show(k))
            side.append(b)
            self.navs[key] = b
        spacer = Gtk.Box(vexpand=True)
        side.append(spacer)
        close = Gtk.Button(halign=Gtk.Align.START)
        close.add_css_class("nav")
        row = Gtk.Box(spacing=12)
        row.append(icon("window-close-symbolic", 18)); row.append(Gtk.Label(label="Close"))
        close.set_child(row)
        close.connect("clicked", lambda *_: self.close())
        side.append(close)

        root.append(side); root.append(self.stack)
        self.set_child(root)
        add_escape(self)
        self.show("quick")

    def show(self, key):
        self.stack.set_visible_child_name(key)
        for k, b in self.navs.items():
            (b.add_css_class if k == key else b.remove_css_class)("active")

    def p_quick(self):
        wifi = Toggle(["network-wireless-symbolic", "network-wireless"], "Wi-Fi",
                      lambda: sh("nmcli radio wifi") == "enabled",
                      lambda on: fire(f"nmcli radio wifi {'on' if on else 'off'}"))
        bt = Toggle(["bluetooth-active-symbolic", "bluetooth-symbolic"], "Bluetooth",
                    lambda: "Soft blocked: no" in sh("rfkill list bluetooth"),
                    lambda on: fire(f"rfkill {'unblock' if on else 'block'} bluetooth"))
        night = Toggle(["night-light-symbolic", "weather-clear-night-symbolic"], "Night light",
                       lambda: bool(sh("pgrep -x hyprsunset")), proc_toggle("hyprsunset", "hyprsunset -t 4200"))
        anim = Toggle(["media-playlist-shuffle-symbolic", "view-refresh-symbolic"], "Animations",
                      lambda: hypr_opt("animations:enabled"),
                      lambda on: fire(f"hyprctl keyword animations:enabled {int(on)}"))
        idle = Toggle(["system-lock-screen-symbolic", "changes-prevent-symbolic"], "Idle lock",
                      lambda: bool(sh("pgrep -x hypridle")), proc_toggle("hypridle", "hypridle"))
        blur = Toggle(["image-filter-symbolic", "applications-graphics-symbolic"], "Blur",
                      lambda: hypr_opt("decoration:blur:enabled"),
                      lambda on: fire(f"hyprctl keyword decoration:blur:enabled {int(on)}"))
        return page("Quick settings", "The things you flip most.",
                    "TOGGLES", grid([wifi, bt, night, anim, idle, blur], 3),
                    "LEVELS", grid([
                        Slider("audio-volume-high-symbolic", "Volume", get_vol(),
                               lambda v: fire(f"wpctl set-volume @DEFAULT_AUDIO_SINK@ {v}%")),
                        Slider("display-brightness-symbolic", "Brightness", get_bright(),
                               lambda v: fire(f"brightnessctl set {max(v,1)}%"))], 2))

    def p_look(self):
        current = saved_accent()
        row = Gtk.Box(spacing=12)
        self.swatches = {}
        for name, pair in ACCENTS.items():
            b = Gtk.Button(tooltip_text=name)
            b.add_css_class("swatch"); b.add_css_class(f"sw-{name}")
            if pair == current or (current is None and name == "Violet"):
                b.add_css_class("sel")
            b.connect("clicked", lambda _b, n=name: self.pick(n))
            self.swatches[name] = b
            row.append(b)
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        card.add_css_class("card")
        card.append(label("Accent colour", "tile-title"))
        card.append(row)
        return page("Appearance", "Colour, spacing and shape.",
                    "ACCENT", card,
                    "SHAPE", grid([
                        Slider("view-grid-symbolic", "Window gaps", 12,
                               lambda v: fire(f"hyprctl keyword general:gaps_out {v//2}")),
                        Slider("applications-graphics-symbolic", "Corner rounding", 28,
                               lambda v: fire(f"hyprctl keyword decoration:rounding {v//2}"))], 2),
                    "PANEL", grid([
                        Action("view-refresh-symbolic", "Reload bar", "Restart waybar", "pkill waybar; waybar"),
                        Action("preferences-desktop-wallpaper-symbolic", "Wallpaper", "Choose a new one",
                               "waypaper")], 2))

    def pick(self, name):
        os.makedirs(CONF, exist_ok=True)
        open(os.path.join(CONF, "accent"), "w").write(name)
        load_css(ACCENTS[name])
        for n, b in self.swatches.items():
            (b.add_css_class if n == name else b.remove_css_class)("sel")

    def p_sound(self):
        return page("Sound & display", "Levels and where they go.",
                    "SOUND", grid([
                        Slider("audio-volume-high-symbolic", "Output volume", get_vol(),
                               lambda v: fire(f"wpctl set-volume @DEFAULT_AUDIO_SINK@ {v}%")),
                        Slider("audio-input-microphone-symbolic", "Microphone", get_vol("@DEFAULT_AUDIO_SOURCE@"),
                               lambda v: fire(f"wpctl set-volume @DEFAULT_AUDIO_SOURCE@ {v}%"))], 2),
                    "DISPLAY", grid([
                        Slider("display-brightness-symbolic", "Brightness", get_bright(),
                               lambda v: fire(f"brightnessctl set {max(v,1)}%"))], 2),
                    "TOOLS", grid([
                        Action("audio-card-symbolic", "Audio mixer", "Per-app volume and devices", "pavucontrol"),
                        Action("video-display-symbolic", "Display layout", "Resolution, scale, position",
                               "nwg-displays")], 2))

    def p_net(self):
        return page("Network", "Connections and devices.",
                    "RADIOS", grid([
                        Toggle(["network-wireless-symbolic"], "Wi-Fi", lambda: sh("nmcli radio wifi") == "enabled",
                               lambda on: fire(f"nmcli radio wifi {'on' if on else 'off'}")),
                        Toggle(["bluetooth-active-symbolic", "bluetooth-symbolic"], "Bluetooth",
                               lambda: "Soft blocked: no" in sh("rfkill list bluetooth"),
                               lambda on: fire(f"rfkill {'unblock' if on else 'block'} bluetooth"))], 3),
                    "MANAGE", grid([
                        Action("network-wired-symbolic", "Connections", "Wi-Fi, VPN, ethernet",
                               "nm-connection-editor"),
                        Action("bluetooth-symbolic", "Bluetooth devices", "Pair and manage",
                               "blueman-manager")], 2))

    def p_sys(self):
        return page("System", "Session and power.",
                    "SESSION", grid([
                        Action("system-lock-screen-symbolic", "Lock", "Lock the screen now", "hyprlock"),
                        Action("system-log-out-symbolic", "Log out", "End this session", "hyprctl dispatch exit"),
                        Action("media-playback-pause-symbolic", "Suspend", "Sleep to RAM", "systemctl suspend")], 3),
                    "POWER", grid([
                        Action("view-refresh-symbolic", "Restart", "Reboot the machine", "systemctl reboot", True),
                        Action("system-shutdown-symbolic", "Shut down", "Power off", "systemctl poweroff", True)], 3))

    def p_keys(self):
        rows = []
        for name, keys in KEYBINDS:
            r = Gtk.Box(spacing=8)
            r.add_css_class("card")
            n = label(name, "tile-title"); n.set_hexpand(True)
            r.append(n)
            for k in keys:
                kc = Gtk.Label(label=k); kc.add_css_class("key"); r.append(kc)
            rows.append(r)
        return page("Keybinds", "What your keyboard does.", "SHORTCUTS", grid(rows, 2))


# ── entry ─────────────────────────────────────────────────────────────
class MinoApp(Gtk.Application):
    def __init__(self, mode):
        super().__init__(application_id=f"mino.{mode}", flags=Gio.ApplicationFlags.NON_UNIQUE)
        self.mode = mode

    def do_activate(self):
        setup_css()
        (Launcher if self.mode == "launcher" else Settings)(self).present()


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "launcher"
    sys.exit(MinoApp(mode).run([sys.argv[0]]))
