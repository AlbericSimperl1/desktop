#!/bin/bash
# ~/scripts/rofi-toggle.sh

if pgrep -x "rofi" > /dev/null; then
    pkill -x "rofi"
else
    rofi -show drun -theme ~/.config/rofi/config.rasi &
fi
