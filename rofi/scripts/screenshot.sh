#!/bin/bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILENAME="screenshot-$(date +%F-%H%M%S).png"
FILEPATH="$DIR/$FILENAME"

choice=$(printf "📸 Full Screen (Save)\n📋 Full Screen (Clipboard)\n✂️  Select Area (Save)\n📋 Select Area (Clipboard)\n🪟 Window (Save)\n📋 Window (Clipboard)" |
  rofi -dmenu -theme "~/.config/rofi/screenshot.rasi" -p "Screenshot")

case "$choice" in
"📸 Full Screen (Save)")
  grim "$FILEPATH"
  notify-send "Screenshot Saved" "$FILEPATH"
  ;;
"📋 Full Screen (Clipboard)")
  grim - | wl-copy
  notify-send "Screenshot Copied" "Full Screen"
  ;;
"✂️  Select Area (Save)")
  grim -g "$(slurp)" "$FILEPATH"
  notify-send "Screenshot Saved" "$FILEPATH"
  ;;
"📋 Select Area (Clipboard)")
  grim -g "$(slurp)" - | wl-copy
  notify-send "Screenshot Copied" "Selected Area"
  ;;
"🪟 Window (Save)")
  grim -g "$(slurp -w)" "$FILEPATH"
  notify-send "Screenshot Saved" "$FILEPATH"
  ;;
"📋 Window (Clipboard)")
  grim -g "$(slurp -w)" - | wl-copy
  notify-send "Screenshot Copied" "Window"
  ;;
esac
