-- ================================================================
--  AwesomeWM Config — Black & Purple Theme
--  Deps: awesome 4.x, rofi, alacritty, picom, feh, pactl
-- ================================================================

local awful     = require("awful")
local beautiful = require("beautiful")
local gears     = require("gears")
local naughty   = require("naughty")
local wibox     = require("wibox")
local menubar   = require("menubar")
require("awful.autofocus")

-- ── Error handling ────────────────────────────────────────────────
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title  = "Startup error!",
                     text   = awesome.startup_errors })
end
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title  = "Error!", text = tostring(err) })
        in_error = false
    end)
end

-- ── Palette ──────────────────────────────────────────────────────
local c = {
    bg       = "#0a0a0a",
    bg_alt   = "#130020",
    bg_panel = "#0f0018",
    fg       = "#e2d9f3",
    fg_dim   = "#9b7ec8",
    purple   = "#9b30ff",
    purple_d = "#4b0082",
    purple_g = "#bf5fff",
    inactive = "#1e1e2e",
    urgent   = "#ff4466",
    muted    = "#3a3050",
}

-- ── Theme ─────────────────────────────────────────────────────────
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.font                 = "monospace 10"
beautiful.bg_normal            = c.bg
beautiful.bg_focus             = c.bg_alt
beautiful.bg_urgent            = c.urgent
beautiful.bg_minimize          = c.inactive
beautiful.bg_systray           = c.bg_panel
beautiful.fg_normal            = c.fg
beautiful.fg_focus             = "#ffffff"
beautiful.fg_urgent            = "#ffffff"
beautiful.fg_minimize          = "#666688"
beautiful.border_width         = 2
beautiful.border_normal        = c.inactive
beautiful.border_focus         = c.purple
beautiful.border_marked        = c.purple_d
beautiful.wibar_bg             = c.bg_panel
beautiful.wibar_fg             = c.fg
beautiful.wibar_height         = 28
beautiful.taglist_bg_focus     = c.purple_d
beautiful.taglist_fg_focus     = c.fg
beautiful.taglist_bg_urgent    = c.urgent
beautiful.taglist_fg_urgent    = "#ffffff"
beautiful.taglist_bg_empty     = c.bg
beautiful.taglist_fg_empty     = c.muted
beautiful.taglist_bg_occupied  = c.bg
beautiful.taglist_fg_occupied  = c.fg_dim
beautiful.tasklist_bg_focus    = c.bg_alt
beautiful.tasklist_fg_focus    = c.fg
beautiful.tasklist_bg_normal   = c.bg
beautiful.tasklist_fg_normal   = c.fg_dim
beautiful.useless_gap          = 8

-- ── Variables ─────────────────────────────────────────────────────
local modkey   = "Mod4"
local terminal = "alacritty"

-- ── Layouts ───────────────────────────────────────────────────────
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.floating,
}

-- ── Wibar (top bar per screen) ────────────────────────────────────
local function make_bar(s)
    -- Workspace taglist
    s.taglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = gears.table.join(
            awful.button({},          1, function(t) t:view_only() end),
            awful.button({ modkey },  1, function(t)
                if client.focus then client.focus:move_to_tag(t) end end),
            awful.button({},          3, awful.tag.viewtoggle),
            awful.button({ modkey },  3, function(t)
                if client.focus then client.focus:toggle_tag(t) end end),
            awful.button({},          4, function(t) awful.tag.viewnext(t.screen) end),
            awful.button({},          5, function(t) awful.tag.viewprev(t.screen) end)
        ),
    }

    -- Tasklist
    s.tasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = gears.table.join(
            awful.button({}, 1, function(w)
                if w == client.focus then
                    w.minimized = true
                else
                    w:emit_signal("request::activate", "tasklist", { raise = true })
                end
            end),
            awful.button({}, 3, function()
                awful.menu.client_list({ theme = { width = 250 } })
            end)
        ),
    }

    -- Clock with purple icon
    local clock = wibox.widget.textclock(
        "<span color='" .. c.purple_g .. "'> </span>"
        .. "<span color='" .. c.purple_g .. "'>%H:%M</span>", 1)

    -- Layout indicator
    s.layoutbox = awful.widget.layoutbox(s)
    s.layoutbox:buttons(gears.table.join(
        awful.button({}, 1, function() awful.layout.inc( 1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end)
    ))

    -- Purple separator
    local function sep()
        return wibox.widget {
            widget  = wibox.widget.separator,
            color   = c.purple_d,
            forced_width = 1,
            span_ratio   = 0.6,
        }
    end

    s.wibar = awful.wibar({
        position = "top",
        screen   = s,
        height   = 28,
        bg       = c.bg_panel,
        fg       = c.fg,
    })

    s.wibar:setup {
        layout = wibox.layout.align.horizontal,
        -- Left: tags + separator
        { layout = wibox.layout.fixed.horizontal,
          s.taglist,
          sep(),
        },
        -- Center: clock
        { layout = wibox.layout.fixed.horizontal,
          clock,
        },
        -- Right: systray + layout indicator
        { layout = wibox.layout.fixed.horizontal,
          sep(),
          wibox.widget.systray(),
          wibox.widget.base.make_widget(), -- 4px spacer
          s.layoutbox,
        },
    }
end

awful.screen.connect_for_each_screen(function(s)
    awful.tag({ "1","2","3","4","5","6","7","8","9","10" },
              s, awful.layout.layouts[1])
    make_bar(s)
end)

-- ── Global keybindings ────────────────────────────────────────────
local globalkeys = gears.table.join(

    -- Focus
    awful.key({ modkey }, "h", function() awful.client.focus.bydirection("left")  end),
    awful.key({ modkey }, "j", function() awful.client.focus.bydirection("down")  end),
    awful.key({ modkey }, "k", function() awful.client.focus.bydirection("up")    end),
    awful.key({ modkey }, "l", function() awful.client.focus.bydirection("right") end),
    awful.key({ modkey }, "Left",  function() awful.client.focus.bydirection("left")  end),
    awful.key({ modkey }, "Right", function() awful.client.focus.bydirection("right") end),
    awful.key({ modkey }, "Up",    function() awful.client.focus.bydirection("up")    end),
    awful.key({ modkey }, "Down",  function() awful.client.focus.bydirection("down")  end),

    -- Swap
    awful.key({ modkey, "Shift" }, "h", function() awful.client.swap.bydirection("left")  end),
    awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.bydirection("down")  end),
    awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.bydirection("up")    end),
    awful.key({ modkey, "Shift" }, "l", function() awful.client.swap.bydirection("right") end),

    -- Terminal + launcher
    awful.key({ modkey }, "Return", function() awful.spawn(terminal) end),
    awful.key({ modkey }, "d", function()
        awful.spawn("rofi -show drun -theme " .. os.getenv("HOME") .. "/.config/rofi/launcher.rasi")
    end),
    awful.key({ modkey }, "Tab", function()
        awful.spawn("rofi -show window -theme " .. os.getenv("HOME") .. "/.config/rofi/launcher.rasi")
    end),

    -- Layout cycle
    awful.key({ modkey }, "space",         function() awful.layout.inc( 1) end),
    awful.key({ modkey, "Shift" }, "space",function() awful.layout.inc(-1) end),

    -- Master ratio
    awful.key({ modkey, "Control" }, "h", function() awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey, "Control" }, "l", function() awful.tag.incmwfact( 0.05) end),

    -- Reload / quit
    awful.key({ modkey, "Shift" }, "r", awesome.restart),
    awful.key({ modkey, "Shift" }, "e", awesome.quit),

    -- Volume
    awful.key({}, "XF86AudioRaiseVolume", function() awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%") end),
    awful.key({}, "XF86AudioLowerVolume", function() awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%") end),
    awful.key({}, "XF86AudioMute",        function() awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle") end),
    awful.key({}, "XF86AudioPlay",        function() awful.spawn("playerctl play-pause") end),
    awful.key({}, "XF86AudioNext",        function() awful.spawn("playerctl next") end),
    awful.key({}, "XF86AudioPrev",        function() awful.spawn("playerctl previous") end),

    -- Brightness
    awful.key({}, "XF86MonBrightnessUp",   function() awful.spawn("brightnessctl set +5%") end),
    awful.key({}, "XF86MonBrightnessDown", function() awful.spawn("brightnessctl set 5%-") end),

    -- Screenshots
    awful.key({}, "Print", function()
        awful.spawn.with_shell('maim "$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png" && notify-send "Screenshot saved"')
    end),
    awful.key({ modkey }, "Print", function()
        awful.spawn.with_shell('maim --window $(xdotool getactivewindow) "$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png"')
    end),
    awful.key({ "Shift" }, "Print", function()
        awful.spawn.with_shell('maim --select "$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png"')
    end)
)

-- Per-client keys
local clientkeys = gears.table.join(
    awful.key({ modkey, "Shift" }, "q",     function(w) w:kill() end),
    awful.key({ modkey },          "f",     function(w)
        w.fullscreen = not w.fullscreen
        w:raise()
    end),
    awful.key({ modkey, "Shift" }, "space", awful.client.floating.toggle),
    awful.key({ modkey },          "t",     function(w) w.ontop = not w.ontop end)
)

-- Tag keybindings
for i = 1, 10 do
    local key = tostring(i % 10)
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, key, function()
            local tag = awful.screen.focused().tags[i]
            if tag then tag:view_only() end
        end),
        awful.key({ modkey, "Shift" }, key, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:move_to_tag(tag) end
            end
        end)
    )
end

root.keys(globalkeys)

-- ── Client mouse buttons ──────────────────────────────────────────
local clientbuttons = gears.table.join(
    awful.button({},          1, function(w) w:emit_signal("request::activate", "mouse_click", { raise = true }) end),
    awful.button({ modkey },  1, function(w)
        w:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(w)
    end),
    awful.button({ modkey },  3, function(w)
        w:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(w)
    end)
)

-- ── Rules ─────────────────────────────────────────────────────────
awful.rules.rules = {
    { rule = {},
      properties = {
          border_width     = beautiful.border_width,
          border_color     = beautiful.border_normal,
          focus            = awful.client.focus.filter,
          raise            = true,
          keys             = clientkeys,
          buttons          = clientbuttons,
          screen           = awful.screen.preferred,
          placement        = awful.placement.no_overlap + awful.placement.no_offscreen,
          titlebars_enabled = false,
      }
    },
    { rule_any = { role = { "pop-up", "task_dialog" } },
      properties = { floating = true } },
    { rule = { class = "Pavucontrol"  },
      properties = { floating = true, width = 700, height = 450 } },
    { rule = { class = "lxappearance" },
      properties = { floating = true, width = 600, height = 400 } },
    { rule = { title = "Picture-in-Picture" },
      properties = { floating = true, sticky = true } },
}

-- ── Signals ───────────────────────────────────────────────────────
client.connect_signal("manage", function(w)
    if awesome.startup
        and not w.size_hints.user_position
        and not w.size_hints.program_position then
        awful.placement.no_offscreen(w)
    end
end)
client.connect_signal("focus",   function(w) w.border_color = beautiful.border_focus  end)
client.connect_signal("unfocus", function(w) w.border_color = beautiful.border_normal end)

-- ── Autostart ─────────────────────────────────────────────────────
local function run_once(cmd)
    local find = string.format("pgrep -u $USER -x '%s' > /dev/null || (%s &)", cmd:match("%S+"), cmd)
    awful.spawn.with_shell(find)
end

run_once("picom --config " .. os.getenv("HOME") .. "/.config/picom/picom.conf -b")
awful.spawn.with_shell(
    "feh --bg-scale " .. os.getenv("HOME") .. "/.config/awesome/wallpaper.jpg 2>/dev/null || true")
