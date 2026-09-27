#!/usr/bin/env bash

# Map waar je wallpapers staan
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
INTERVAL=600 # 10 minuten in seconden

while true; do
    # Kies een willekeurige afbeelding
    WALL=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1)

    if [ -n "$WALL" ]; then
        # Vraag Noctalia rechtstreeks om de wallpaper aan te passen
        noctalia msg wallpaper set "$WALL"
    fi

    sleep $INTERVAL
done
