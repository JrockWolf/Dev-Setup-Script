/* ================================================================
   dwm config.h — Black & Purple Theme
   Applied before compiling: cp config.h /path/to/dwm-src/config.h
   Build deps: libx11, libxft, libxinerama, XF86keysym
   ================================================================ */

#include <X11/XF86keysym.h>

/* ── Appearance ──────────────────────────────────────────────────*/
static const unsigned int borderpx  = 2;   /* border width in pixels */
static const unsigned int snap      = 32;  /* snap pixel */
static const int showbar            = 1;   /* 0 means no bar */
static const int topbar             = 1;   /* 0 means bottom bar */
static const char *fonts[]          = { "monospace:size=10" };
static const char dmenufont[]       =   "monospace:size=10";

/* Black & Purple palette */
static const char col_bg[]       = "#0a0a0a";
static const char col_bg_alt[]   = "#130020";
static const char col_fg[]       = "#e2d9f3";
static const char col_fg_muted[] = "#666688";
static const char col_purple[]   = "#9b30ff";
static const char col_purple_d[] = "#4b0082";
static const char col_inactive[] = "#1e1e2e";
static const char col_urgent[]   = "#ff4466";

static const char *colors[][3] = {
    /*                   fg             bg            border       */
    [SchemeNorm]     = { col_fg_muted,  col_bg,       col_inactive },
    [SchemeSel]      = { col_fg,        col_bg_alt,   col_purple   },
};

/* ── Tagging ─────────────────────────────────────────────────────*/
static const char *tags[] = { "1","2","3","4","5","6","7","8","9" };

static const Rule rules[] = {
    /* class           instance  title              tags  float  monitor */
    { "Pavucontrol",   NULL,     NULL,              0,    1,     -1 },
    { "lxappearance",  NULL,     NULL,              0,    1,     -1 },
};

/* ── Layouts ─────────────────────────────────────────────────────*/
static const float mfact         = 0.55; /* master area factor */
static const int   nmaster       = 1;    /* number of clients in master */
static const int   resizehints   = 1;    /* 1=respect size hints */
static const int   lockfullscreen= 1;

static const Layout layouts[] = {
    { "[]=", tile    },  /* first: tiling */
    { "[M]", monocle },  /* monocle */
    { "><>", NULL    },  /* floating */
};

/* ── Key definitions ─────────────────────────────────────────────*/
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
    { MODKEY,                       KEY, view,       {.ui = 1 << TAG} }, \
    { MODKEY|ControlMask,           KEY, toggleview, {.ui = 1 << TAG} }, \
    { MODKEY|ShiftMask,             KEY, tag,        {.ui = 1 << TAG} }, \
    { MODKEY|ControlMask|ShiftMask, KEY, toggletag,  {.ui = 1 << TAG} },

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* ── Commands ────────────────────────────────────────────────────*/
static char dmenumon[2] = "0";
static const char *dmenucmd[] = {
    "dmenu_run", "-fn", dmenufont,
    "-nb", col_bg,    "-nf", col_fg,
    "-sb", col_purple_d, "-sf", col_fg, NULL
};
static const char *termcmd[] = { "alacritty", NULL };
static const char *roficmd[] = {
    "bash", "-c",
    "rofi -show drun -theme ~/.config/rofi/launcher.rasi", NULL
};

static const Key keys[] = {
    /* modifier              key           function         argument */
    /* Apps */
    { MODKEY,                XK_Return,    spawn,           {.v = termcmd  } },
    { MODKEY,                XK_d,         spawn,           {.v = roficmd  } },

    /* Toggle bar */
    { MODKEY,                XK_b,         togglebar,       {0} },

    /* Focus stack */
    { MODKEY,                XK_j,         focusstack,      {.i = +1 } },
    { MODKEY,                XK_k,         focusstack,      {.i = -1 } },
    { MODKEY,                XK_Down,      focusstack,      {.i = +1 } },
    { MODKEY,                XK_Up,        focusstack,      {.i = -1 } },

    /* Master size */
    { MODKEY|ControlMask,    XK_h,         setmfact,        {.f = -0.05} },
    { MODKEY|ControlMask,    XK_l,         setmfact,        {.f = +0.05} },

    /* Master count */
    { MODKEY,                XK_i,         incnmaster,      {.i = +1 } },
    { MODKEY,                XK_o,         incnmaster,      {.i = -1 } },

    /* Zoom (swap to master) */
    { MODKEY|ShiftMask,      XK_Return,    zoom,            {0} },

    /* Kill client */
    { MODKEY|ShiftMask,      XK_q,         killclient,      {0} },

    /* Layouts */
    { MODKEY,                XK_t,         setlayout,       {.v = &layouts[0]} },
    { MODKEY,                XK_m,         setlayout,       {.v = &layouts[1]} },
    { MODKEY,                XK_space,     setlayout,       {0} },
    { MODKEY|ShiftMask,      XK_space,     togglefloating,  {0} },
    { MODKEY,                XK_f,         togglefullscr,   {0} },

    /* Multi-monitor */
    { MODKEY,                XK_comma,     focusmon,        {.i = -1 } },
    { MODKEY,                XK_period,    focusmon,        {.i = +1 } },
    { MODKEY|ShiftMask,      XK_comma,     tagmon,          {.i = -1 } },
    { MODKEY|ShiftMask,      XK_period,    tagmon,          {.i = +1 } },

    /* Restart / quit */
    { MODKEY|ShiftMask,      XK_r,         quit,            {1} }, /* restart */
    { MODKEY|ShiftMask,      XK_e,         quit,            {0} }, /* quit    */

    /* Volume */
    { 0, XF86XK_AudioRaiseVolume, spawn, SHCMD("pactl set-sink-volume @DEFAULT_SINK@ +5%")  },
    { 0, XF86XK_AudioLowerVolume, spawn, SHCMD("pactl set-sink-volume @DEFAULT_SINK@ -5%")  },
    { 0, XF86XK_AudioMute,        spawn, SHCMD("pactl set-sink-mute @DEFAULT_SINK@ toggle") },
    { 0, XF86XK_AudioPlay,        spawn, SHCMD("playerctl play-pause")                      },
    { 0, XF86XK_AudioNext,        spawn, SHCMD("playerctl next")                            },
    { 0, XF86XK_AudioPrev,        spawn, SHCMD("playerctl previous")                        },

    /* Brightness */
    { 0, XF86XK_MonBrightnessUp,   spawn, SHCMD("brightnessctl set +5%")  },
    { 0, XF86XK_MonBrightnessDown, spawn, SHCMD("brightnessctl set 5%-")  },

    /* Screenshots */
    { 0,          XK_Print, spawn,
        SHCMD("maim \"$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png\" && notify-send 'Screenshot saved'") },
    { MODKEY,     XK_Print, spawn,
        SHCMD("maim --window \"$(xdotool getactivewindow)\" \"$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png\"") },
    { ShiftMask,  XK_Print, spawn,
        SHCMD("maim --select \"$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png\"") },

    /* Tags */
    TAGKEYS(XK_1, 0) TAGKEYS(XK_2, 1) TAGKEYS(XK_3, 2)
    TAGKEYS(XK_4, 3) TAGKEYS(XK_5, 4) TAGKEYS(XK_6, 5)
    TAGKEYS(XK_7, 6) TAGKEYS(XK_8, 7) TAGKEYS(XK_9, 8)
};

/* ── Mouse buttons ───────────────────────────────────────────────*/
static const Button buttons[] = {
    /* click               mask    button   function         argument */
    { ClkTagBar,           0,      Button1, view,            {0} },
    { ClkTagBar,           MODKEY, Button1, tag,             {0} },
    { ClkTagBar,           0,      Button3, toggleview,      {0} },
    { ClkTagBar,           MODKEY, Button3, toggletag,       {0} },
    { ClkWinTitle,         0,      Button2, zoom,            {0} },
    { ClkClientWin,        MODKEY, Button1, movemouse,       {0} },
    { ClkClientWin,        MODKEY, Button2, togglefloating,  {0} },
    { ClkClientWin,        MODKEY, Button3, resizemouse,     {0} },
    { ClkRootWin,          0,      Button3, spawn,           {.v = dmenucmd} },
};
