#!/bin/bash
MONITOR=$1

if [ -z "$MONITOR" ]; then
    notify-send "no arg"
    exit 1
fi

IS_DISABLED=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR\") | .disabled")

if [ "$IS_DISABLED" = "false" ]; then
    hyprctl keyword monitor "$MONITOR",disable
    notify-send "$MONITOR disabled"
else
    if [ "$MONITOR" == "DP-3" ]; then # Ultrawide
        hyprctl keyword monitor "$MONITOR",3440x1440@144,auto,1
    elif [ "$MONITOR" == "HDMI-A-1" ]; then # 4K Panel
        hyprctl keyword monitor "$MONITOR",3840x2160@60,auto,1
    else
        hyprctl keyword monitor "$MONITOR",preferred,auto,1
    fi
    notify-send "$MONITOR enabled"
fi
