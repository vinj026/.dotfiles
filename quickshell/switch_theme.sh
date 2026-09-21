#!/usr/bin/env bash
# switch_theme.sh — Switch quickshell styles between 'wabi' and 'minimalist' (leaving colors to Matugen)

THEME_DIR="$HOME/.config/quickshell/themes"

if [ "$1" = "wabi" ]; then
    echo "Switching to Wabi layout style..."
    if [ -f "$THEME_DIR/shell_style_wabi.json" ]; then
        cp "$THEME_DIR/shell_style_wabi.json" "$THEME_DIR/shell_style.json"
        echo "Successfully switched to Wabi style! (Colors still follow Matugen)"
    else
        echo "Error: Wabi style file not found in $THEME_DIR."
        exit 1
    fi
elif [ "$1" = "minimalist" ]; then
    echo "Switching to Minimalist layout style..."
    if [ -f "$THEME_DIR/shell_style_minimalist.json" ]; then
        cp "$THEME_DIR/shell_style_minimalist.json" "$THEME_DIR/shell_style.json"
        echo "Successfully switched to Minimalist style! (Colors still follow Matugen)"
    else
        echo "Error: Minimalist preset file not found in $THEME_DIR."
        exit 1
    fi
else
    echo "Usage: $0 [wabi|minimalist]"
    exit 1
fi
