#!/usr/bin/env bash

# Tijdvenster waarin de tweede klik moet vallen (in milliseconden)
DOUBLE_CLICK_TIME=300
CACHE_FILE="/tmp/last_super_press"

CURRENT_TIME=$(date +%s%3N)

if [ -f "$CACHE_FILE" ]; then
    LAST_TIME=$(cat "$CACHE_FILE")
    DIFF=$((CURRENT_TIME - LAST_TIME))

    if [ $DIFF -lt $DOUBLE_CLICK_TIME ]; then
        # Binnen de tijd: voer de Lua-binding / Hyprspace toggle uit
        rm "$CACHE_FILE"
        hyprctl dispatch "plugin:overview:toggle" 2>/dev/null || hyprctl dispatch "overview:toggle"
        exit 0
    fi
fi

# Sla de huidige tijd op
echo "$CURRENT_TIME" > "$CACHE_FILE"
