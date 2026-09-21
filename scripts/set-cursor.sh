#!/usr/bin/env bash

# ==============================================================================
# SET-CURSOR SCRIPT
# Synchronizes cursor theme across:
# 1. MangoWM visuals & environment
# 2. GTK 3 & GTK 4
# 3. Default X11 / Wayland icon index
# 4. GSettings
# ==============================================================================

set -euo pipefail

THEME="${1:-}"
SIZE="${2:-24}"

if [ -z "$THEME" ]; then
    echo "Usage: $0 <theme-name> [size]" >&2
    echo "Available Google Cursor themes:" >&2
    echo "  - GoogleDot-Black" >&2
    echo "  - GoogleDot-White" >&2
    echo "  - GoogleDot-Blue" >&2
    echo "  - GoogleDot-Red" >&2
    exit 1
fi

# 1. Update MangoWM modules/visuals.conf
VISUALS_CONF="$HOME/.config/mango/modules/visuals.conf"
if [ -f "$VISUALS_CONF" ]; then
    sed -i -E "s/^cursor_theme=.*/cursor_theme=$THEME/" "$VISUALS_CONF"
    sed -i -E "s/^cursor_size=.*/cursor_size=$SIZE/" "$VISUALS_CONF"
fi

# 2. Update MangoWM modules/environment.conf
ENV_CONF="$HOME/.config/mango/modules/environment.conf"
if [ -f "$ENV_CONF" ]; then
    sed -i -E "s/^env=XCURSOR_THEME,.*/env=XCURSOR_THEME,$THEME/" "$ENV_CONF"
    sed -i -E "s/^env=XCURSOR_SIZE,.*/env=XCURSOR_SIZE,$SIZE/" "$ENV_CONF"
fi

# 3. Update ~/.icons/default/index.theme
mkdir -p "$HOME/.icons/default"
cat << EOF > "$HOME/.icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$THEME
EOF

# 4. Update GTK 3 settings.ini
GTK3_CONF="$HOME/.config/gtk-3.0/settings.ini"
if [ -f "$GTK3_CONF" ]; then
    sed -i -E "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$THEME/" "$GTK3_CONF"
    sed -i -E "s/^gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$SIZE/" "$GTK3_CONF"
fi

# 5. Update GTK 4 settings.ini
mkdir -p "$HOME/.config/gtk-4.0"
cat << EOF > "$HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-cursor-theme-name=$THEME
gtk-cursor-theme-size=$SIZE
EOF

# 6. GSettings
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface cursor-theme "$THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$SIZE" 2>/dev/null || true
fi

# 7. Reload MangoWM compositor
if command -v mmsg &>/dev/null; then
    mmsg dispatch reload_config 2>/dev/null || true
fi

echo "Cursor theme successfully updated to: $THEME (size: $SIZE)"
