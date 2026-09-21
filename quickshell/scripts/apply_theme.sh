#!/bin/bash
THEME=$1
COLORS_FILE="$HOME/.cache/matugen/colors.json"

if [ "$THEME" == "wallpaper" ]; then
    WALLPAPER=$(swww query | grep -o 'image: .*' | cut -d ' ' -f 2 | head -n 1)
    if [ -n "$WALLPAPER" ]; then
        matugen image "$WALLPAPER"
    fi
    exit 0
fi

cat << 'PYEOF' > /tmp/gen_theme.py
import json
import sys
import os

theme = sys.argv[1]
colors_file = os.path.expanduser("~/.cache/matugen/colors.json")

palettes = {
    "monochrome": {
        "primary": "#dadada", "bgBase": "#141414", "surface": "#191919",
        "surfaceVariant": "#323232", "surfaceContainer": "#252525",
        "textPrimary": "#e7e7e7", "textMuted": "#9e9e9e", "textDim": "#6a6a6a",
        "outline": "#484848", "textOnPrimary": "#161616", "primaryContainer": "#353535",
        "secondary": "#b8b8b8", "tertiary": "#c4c4c4", "error": "#e32626"
    },
    "vercel": {
        "primary": "#3a3a42", "bgBase": "#000000", "surface": "#0a0a0a",
        "surfaceVariant": "#1f1f1f", "surfaceContainer": "#1a1a1a",
        "textPrimary": "#ededed", "textMuted": "#a1a1aa", "textDim": "#71717a",
        "outline": "#2e2e2e", "textOnPrimary": "#ffffff", "primaryContainer": "#252528",
        "secondary": "#0072f5", "tertiary": "#12a594", "error": "#e5484d"
    },
    "gruvbox": {
        "primary": "#d79921", "bgBase": "#1d2021", "surface": "#282828",
        "surfaceVariant": "#504945", "surfaceContainer": "#3c3836",
        "textPrimary": "#ebdbb2", "textMuted": "#bdae93", "textDim": "#7c6f64",
        "outline": "#665c54", "textOnPrimary": "#282828", "primaryContainer": "#b57614",
        "secondary": "#fabd2f", "tertiary": "#b8bb26", "error": "#cc241d"
    },
    "everblush": {
        "primary": "#8ccf7e", "bgBase": "#141b1e", "surface": "#182024",
        "surfaceVariant": "#283236", "surfaceContainer": "#232a2d",
        "textPrimary": "#dadada", "textMuted": "#808d93", "textDim": "#5c676c",
        "outline": "#323b3e", "textOnPrimary": "#141b1e", "primaryContainer": "#283b32",
        "secondary": "#e5c76b", "tertiary": "#6cbfbf", "error": "#e57474"
    },
    "everforest": {
        "primary": "#a7c080", "bgBase": "#232a2e", "surface": "#2d353b",
        "surfaceVariant": "#4a555b", "surfaceContainer": "#343f44",
        "textPrimary": "#d3c6aa", "textMuted": "#9da9a0", "textDim": "#859289",
        "outline": "#5c6a72", "textOnPrimary": "#232a2e", "primaryContainer": "#7f9f7f",
        "secondary": "#dbbc7f", "tertiary": "#7fbbb3", "error": "#e67e80"
    },
    "monokai": {
        "primary": "#a6e22e", "bgBase": "#272822", "surface": "#3e3d32",
        "surfaceVariant": "#49483e", "surfaceContainer": "#3e3d32",
        "textPrimary": "#f8f8f2", "textMuted": "#75715e", "textDim": "#75715e",
        "outline": "#49483e", "textOnPrimary": "#272822", "primaryContainer": "#f92672",
        "secondary": "#f92672", "tertiary": "#66d9ef", "error": "#f92672"
    },
    "catppuccin": {
        "primary": "#cba6f7", "bgBase": "#11111b", "surface": "#1e1e2e",
        "surfaceVariant": "#45475a", "surfaceContainer": "#313244",
        "textPrimary": "#cdd6f4", "textMuted": "#a6adc8", "textDim": "#7f849c",
        "outline": "#585b70", "textOnPrimary": "#1e1e2e", "primaryContainer": "#b4befe",
        "secondary": "#f38ba8", "tertiary": "#89b4fa", "error": "#f38ba8"
    },
    "ayu_dark": {
        "primary": "#ffb454", "bgBase": "#0b0e14", "surface": "#0f141c",
        "surfaceVariant": "#242936", "surfaceContainer": "#1b212c",
        "textPrimary": "#e6e1cf", "textMuted": "#bfbdb6", "textDim": "#707a8c",
        "outline": "#3d424d", "textOnPrimary": "#0b0e14", "primaryContainer": "#e6b450",
        "secondary": "#39bae6", "tertiary": "#aad94c", "error": "#f07178"
    },
    "ayu-dark": {
        "primary": "#ffb454", "bgBase": "#0b0e14", "surface": "#0f141c",
        "surfaceVariant": "#242936", "surfaceContainer": "#1b212c",
        "textPrimary": "#e6e1cf", "textMuted": "#bfbdb6", "textDim": "#707a8c",
        "outline": "#3d424d", "textOnPrimary": "#0b0e14", "primaryContainer": "#e6b450",
        "secondary": "#39bae6", "tertiary": "#aad94c", "error": "#f07178"
    }
}

p = palettes.get(theme, palettes["monochrome"])

for k, v in p.items():
    if v.lower() == "#ffffff":
        p[k] = "#ededed"

os.makedirs(os.path.dirname(colors_file), exist_ok=True)
with open(colors_file, 'w') as f:
    json.dump(p, f, indent=2)

PYEOF

python3 /tmp/gen_theme.py "$THEME"
