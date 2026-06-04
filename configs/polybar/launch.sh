#!/usr/bin/env bash
# ================================================================
#  Polybar launch script
#  Called by i3 exec_always so polybar restarts on i3 reload/restart
# ================================================================

# Kill any existing polybar instances gracefully
pkill -x polybar 2>/dev/null

# Wait until all bars have closed
while pgrep -x polybar > /dev/null; do sleep 0.1; done

# Launch bar on each connected monitor
if command -v xrandr &>/dev/null; then
    for monitor in $(xrandr --query | awk '/\bconnected\b/ {print $1}'); do
        MONITOR="$monitor" polybar --reload main &
    done
else
    # Fallback: single monitor
    polybar --reload main &
fi
