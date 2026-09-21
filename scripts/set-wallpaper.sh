#!/usr/bin/env bash

# ==============================================================================
# SET-WALLPAPER & DYNAMIC MATUGEN THEME
# Integrates Wallpaper with Matugen Material You colors for:
# - Quickshell (colors.json)
# - Mango Compositor (theme.conf)
# - Terminal (Kitty theme.conf & Alacritty theme.toml)
# - GTK 3 & GTK 4 / Libadwaita (gtk.css)
# - Qt 5 & Qt 6 (qt6ct / qt5ct colors)
# ==============================================================================

set -euo pipefail

WALLPAPER="${1:-}"

if [ -z "$WALLPAPER" ]; then
    if [ -L "$HOME/.config/mango/wallpaper/current.jpg" ] && [ -f "$HOME/.config/mango/wallpaper/current.jpg" ]; then
        RESOLVED="$(readlink -f "$HOME/.config/mango/wallpaper/current.jpg" 2>/dev/null || true)"
        if [ -n "$RESOLVED" ] && [ -f "$RESOLVED" ] && [ "$RESOLVED" != "$HOME/.config/mango/wallpaper/current.jpg" ]; then
            WALLPAPER="$RESOLVED"
        fi
    fi
    if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
        WALLPAPER="$(find "$HOME/.config/mango/wallpaper" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) ! -name "current.jpg" 2>/dev/null | head -n 1)"
    fi
fi

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    echo "Error: No valid wallpaper found in '$HOME/.config/mango/wallpaper/'" >&2
    exit 1
fi

# 1. Determine active theme from config.json
CONFIG_JSON="$HOME/.config/quickshell/config.json"
CURRENT_THEME="wallpaper"
if [ -f "$CONFIG_JSON" ]; then
    CURRENT_THEME=$(python3 -c "
import json
try:
    with open('$CONFIG_JSON') as f:
        print(json.load(f).get('theme', 'wallpaper'))
except:
    print('wallpaper')
" 2>/dev/null || echo "wallpaper")
fi

# 2. Extract colors using Matugen ONLY if theme is "wallpaper"
if [ "$CURRENT_THEME" = "wallpaper" ]; then
    mkdir -p "$HOME/.cache/matugen"
    if command -v matugen &>/dev/null; then
        matugen -c "$HOME/.config/matugen/config.toml" image "$WALLPAPER" -m dark --source-color-index 0
    fi
    if command -v mmsg &>/dev/null; then
        mmsg dispatch reload_config 2>/dev/null || true
    fi
    pkill -SIGUSR1 kitty 2>/dev/null || true
fi

# 3. Set wallpaper via awww with smooth 165fps grow transition
if command -v awww &>/dev/null; then
    awww img "$WALLPAPER" \
        --transition-type grow \
        --transition-pos center \
        --transition-fps 165 \
        --transition-duration 2 \
        --resize crop
fi

# 4. Update current wallpaper symlink
if [ "$WALLPAPER" != "$HOME/.config/mango/wallpaper/current.jpg" ] && [ "$WALLPAPER" != "$HOME/.dotfiles/mango/wallpaper/current.jpg" ]; then
    ln -sfn "$WALLPAPER" "$HOME/.config/mango/wallpaper/current.jpg"
    if [ -d "$HOME/.dotfiles/mango/wallpaper" ]; then
        ln -sfn "$WALLPAPER" "$HOME/.dotfiles/mango/wallpaper/current.jpg"
    fi
fi

echo "Wallpaper applied: $WALLPAPER (active theme preserved: $CURRENT_THEME)"
