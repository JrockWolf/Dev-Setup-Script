# ================================================================
#  Qtile Config — Black & Purple Theme
#  Deps: qtile, rofi, alacritty, picom, feh, pactl, xdotool, maim
# ================================================================

import os
import subprocess
from libqtile import bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy

# ── Palette ──────────────────────────────────────────────────────
BG        = "#0a0a0a"
BG_ALT    = "#130020"
BG_PANEL  = "#0f0018"
FG        = "#e2d9f3"
FG_DIM    = "#9b7ec8"
PURPLE    = "#9b30ff"
PURPLE_D  = "#4b0082"
PURPLE_G  = "#bf5fff"
PURPLE_S  = "#c084fc"
INACTIVE  = "#1e1e2e"
URGENT    = "#ff4466"
OK        = "#50fa7b"
MUTED     = "#3a3050"

# ── Modifier ─────────────────────────────────────────────────────
mod = "mod4"

# ── Keybindings ──────────────────────────────────────────────────
keys = [
    # Focus
    Key([mod], "h",     lazy.layout.left(),  desc="Focus left"),
    Key([mod], "j",     lazy.layout.down(),  desc="Focus down"),
    Key([mod], "k",     lazy.layout.up(),    desc="Focus up"),
    Key([mod], "l",     lazy.layout.right(), desc="Focus right"),
    Key([mod], "Left",  lazy.layout.left()),
    Key([mod], "Down",  lazy.layout.down()),
    Key([mod], "Up",    lazy.layout.up()),
    Key([mod], "Right", lazy.layout.right()),

    # Move
    Key([mod, "shift"], "h",     lazy.layout.shuffle_left()),
    Key([mod, "shift"], "j",     lazy.layout.shuffle_down()),
    Key([mod, "shift"], "k",     lazy.layout.shuffle_up()),
    Key([mod, "shift"], "l",     lazy.layout.shuffle_right()),
    Key([mod, "shift"], "Left",  lazy.layout.shuffle_left()),
    Key([mod, "shift"], "Down",  lazy.layout.shuffle_down()),
    Key([mod, "shift"], "Up",    lazy.layout.shuffle_up()),
    Key([mod, "shift"], "Right", lazy.layout.shuffle_right()),

    # Resize
    Key([mod, "control"], "h", lazy.layout.grow_left()),
    Key([mod, "control"], "j", lazy.layout.grow_down()),
    Key([mod, "control"], "k", lazy.layout.grow_up()),
    Key([mod, "control"], "l", lazy.layout.grow_right()),
    Key([mod, "control"], "n", lazy.layout.normalize()),

    # Layout
    Key([mod], "space",          lazy.next_layout()),
    Key([mod], "f",              lazy.window.toggle_fullscreen()),
    Key([mod, "shift"], "space", lazy.window.toggle_floating()),
    Key([mod], "m",              lazy.layout.maximize()),

    # Apps
    Key([mod], "Return", lazy.spawn("alacritty")),
    Key([mod], "d",      lazy.spawn(
        f"rofi -show drun -theme {os.environ['HOME']}/.config/rofi/launcher.rasi")),
    Key([mod], "Tab",    lazy.spawn(
        f"rofi -show window -theme {os.environ['HOME']}/.config/rofi/launcher.rasi")),

    # Kill
    Key([mod, "shift"], "q", lazy.window.kill()),

    # Reload / quit
    Key([mod, "shift"], "r", lazy.reload_config()),
    Key([mod, "shift"], "e", lazy.shutdown()),

    # Volume
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%")),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%")),
    Key([], "XF86AudioMute",        lazy.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")),
    Key([], "XF86AudioMicMute",     lazy.spawn("pactl set-source-mute @DEFAULT_SOURCE@ toggle")),
    Key([], "XF86AudioPlay",        lazy.spawn("playerctl play-pause")),
    Key([], "XF86AudioNext",        lazy.spawn("playerctl next")),
    Key([], "XF86AudioPrev",        lazy.spawn("playerctl previous")),

    # Brightness
    Key([], "XF86MonBrightnessUp",   lazy.spawn("brightnessctl set +5%")),
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 5%-")),

    # Screenshots
    Key([], "Print", lazy.spawn(
        'bash -c "maim \\"$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png\\" && notify-send \\"Screenshot saved\\""')),
    Key([mod], "Print", lazy.spawn(
        'bash -c "maim --window $(xdotool getactivewindow) \\"$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png\\""')),
    Key(["shift"], "Print", lazy.spawn(
        'bash -c "maim --select \\"$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png\\""')),
]

# ── Mouse ─────────────────────────────────────────────────────────
mouse = [
    Drag([mod],  "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod],  "Button3", lazy.window.set_size_floating(),     start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

# ── Groups (workspaces) ───────────────────────────────────────────
groups = [Group(str(i)) for i in range(1, 11)]

for i, g in enumerate(groups):
    key = str((i + 1) % 10)
    keys.extend([
        Key([mod],          key, lazy.group[g.name].toscreen()),
        Key([mod, "shift"], key, lazy.window.togroup(g.name, switch_group=True)),
    ])

# ── Layouts ───────────────────────────────────────────────────────
_lkw = dict(
    border_width  = 2,
    border_focus  = PURPLE,
    border_normal = INACTIVE,
    margin        = 8,
)

layouts = [
    layout.Columns(**_lkw),
    layout.MonadTall(**_lkw),
    layout.MonadWide(**_lkw),
    layout.Max(),
    layout.Floating(border_focus=PURPLE, border_normal=INACTIVE, border_width=2),
]

# ── Widget helpers ────────────────────────────────────────────────
widget_defaults = dict(
    font       = "monospace",
    fontsize   = 12,
    padding    = 4,
    foreground = FG,
    background = BG_PANEL,
)
extension_defaults = widget_defaults.copy()


def _sep():
    return widget.TextBox(text=" | ", foreground=PURPLE_D, padding=0)


def _icon(ch):
    return widget.TextBox(text=ch, foreground=PURPLE_G, padding=2)


# ── Screens ───────────────────────────────────────────────────────
screens = [
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    background              = BG_PANEL,
                    foreground              = FG,
                    active                  = FG,
                    inactive                = MUTED,
                    highlight_method        = "block",
                    block_highlight_text_color = FG,
                    this_current_screen_border = PURPLE_D,
                    this_screen_border      = PURPLE_D,
                    urgent_alert_method     = "block",
                    urgent_border           = URGENT,
                    rounded                 = False,
                    padding                 = 6,
                    margin_x                = 0,
                    font                    = "monospace",
                    fontsize                = 12,
                    borderwidth             = 2,
                    use_mouse_wheel         = False,
                ),
                _sep(),
                widget.WindowName(foreground=FG_DIM, max_chars=50),
                widget.Spacer(),
                _icon(" "),
                widget.Clock(format="%H:%M", foreground=PURPLE_G, fontsize=13),
                widget.Spacer(length=6),
                _sep(),
                _icon(" "), widget.CPU(format="{load_percent:2.0f}%", foreground=FG, update_interval=2),
                _sep(),
                _icon(" "), widget.Memory(format="{MemPercent:2.0f}%", foreground=FG, update_interval=3),
                _sep(),
                _icon(" "), widget.Volume(foreground=FG),
                _sep(),
                widget.Battery(
                    format         = "{char} {percent:2.0%}",
                    charge_char    = "",
                    discharge_char = "",
                    full_char      = "",
                    unknown_char   = "",
                    foreground     = FG,
                    low_foreground = URGENT,
                    low_percentage = 0.2,
                    update_interval = 30,
                ),
                _sep(),
                widget.Systray(background=BG_PANEL, padding=4),
                widget.Spacer(length=4),
                widget.CurrentLayoutIcon(scale=0.7),
            ],
            28,
            background   = BG_PANEL,
            border_width = [0, 0, 2, 0],
            border_color = [BG_PANEL, BG_PANEL, PURPLE_D, BG_PANEL],
        ),
    ),
]

# ── Floating rules ────────────────────────────────────────────────
floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="Pavucontrol"),
        Match(wm_class="lxappearance"),
        Match(title="Picture-in-Picture"),
    ],
    border_focus  = PURPLE,
    border_normal = INACTIVE,
    border_width  = 2,
)

# ── General settings ──────────────────────────────────────────────
dgroups_key_binder         = None
dgroups_app_rules          = []
follow_mouse_focus         = True
bring_front_click          = False
cursor_warp                = False
auto_fullscreen            = True
focus_on_window_activation = "smart"
reconfigure_screens        = True
auto_minimize              = True
wl_input_rules             = None
wmname                     = "LG3D"

# ── Autostart ─────────────────────────────────────────────────────
@hook.subscribe.startup_once
def autostart():
    home = os.environ["HOME"]
    subprocess.Popen([
        "bash", "-c",
        f"pgrep -x picom > /dev/null || picom --config {home}/.config/picom/picom.conf -b ; "
        f"feh --bg-scale {home}/.config/qtile/wallpaper.jpg 2>/dev/null || true",
    ])
