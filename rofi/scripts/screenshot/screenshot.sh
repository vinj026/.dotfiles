#!/usr/bin/env bash

# Tampilkan menu Rofi dengan opsi screenshot
theme_path="/home/kvn/.config/rofi/launchers/screenshot.rasi"
selected=$(echo -e "Save Active Window\nSave Area\nCopy Active Window\nCopy Area\nCopy Area with Cursor" | rofi -dmenu -p "Screenshot" -theme "$theme_path")

# Eksekusi perintah sesuai pilihan
case "$selected" in
    "Save Active Window")
        grimblast save active
        ;;
    "Save Area")
        grimblast save area
        ;;
    "Copy Active Window")
        grimblast --notify copy active
        ;;
    "Copy Area")
        grimblast --notify copy area
        ;;
    "Copy Area with Cursor")
        grimblast --cursor copysave area
        ;;
    *)
        echo "Cancelled"
        ;;
esac