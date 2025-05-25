#!/usr/bin/env bash

theme_path="$HOME/.config/rofi/launchers/screenshot.rasi"
selected=$(echo -e " Screenshot Window\nScreenshot a Monitor\nScreenshot a Region" | rofi -dmenu -p "Screenshot" -theme "$theme_path")

case "$selected" in
    "Screenshot Window")
        hyprshot -m window
        ;;
    "Screenshot a Monitor")
        hyprshot -m output  
        ;;
    "Screenshot a Region")
        hyprshot -m region
        ;;
    *)
        echo "Cancelled"
        ;;
esac
