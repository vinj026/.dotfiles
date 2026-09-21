#!/usr/bin/env bash

# ==============================================================================
# MANGO AUTOSTART SCRIPT (MODULAR VERSION)
# ==============================================================================
# This script launches essential services and applications when MangoWM starts

# ------------------------------------------------------------------------------
# 0. Session Environment Sync (D-Bus & systemd user session)
# ------------------------------------------------------------------------------
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME QT_WAYLAND_DISABLE_WINDOWDECORATION GTK_THEME XCURSOR_THEME XCURSOR_SIZE 2>/dev/null || true
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME QT_WAYLAND_DISABLE_WINDOWDECORATION GTK_THEME 2>/dev/null || true

# ------------------------------------------------------------------------------
# 1. Wallpaper Daemon & Persistent Theme Restoration
# ------------------------------------------------------------------------------
if command -v awww-daemon &>/dev/null; then
    echo "Starting wallpaper daemon..."
    pkill -x awww-daemon 2>/dev/null
    rm -f "${XDG_RUNTIME_DIR:-/run/user/$UID}"/*awww*.sock 2>/dev/null
    awww-daemon &
    
    # Restore wallpaper image and persistent theme
    (
        sleep 0.8
        WP=""
        if [ -L "$HOME/.config/mango/wallpaper/current.jpg" ] && [ -f "$HOME/.config/mango/wallpaper/current.jpg" ]; then
            RESOLVED="$(readlink -f "$HOME/.config/mango/wallpaper/current.jpg" 2>/dev/null || true)"
            if [ -n "$RESOLVED" ] && [ -f "$RESOLVED" ] && [ "$RESOLVED" != "$HOME/.config/mango/wallpaper/current.jpg" ]; then
                WP="$RESOLVED"
            fi
        elif [ -f "$HOME/.config/mango/wallpaper/current.jpg" ]; then
            WP="$HOME/.config/mango/wallpaper/current.jpg"
        fi
        if [ -z "$WP" ] || [ ! -f "$WP" ]; then
            WP="$(find "$HOME/.config/mango/wallpaper" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) ! -name "current.jpg" 2>/dev/null | head -n 1)"
        fi
        if [ -n "$WP" ] && command -v awww &>/dev/null; then
            echo "Restoring wallpaper display: $WP"
            awww img "$WP" --transition-type grow --transition-pos center --transition-fps 165 --transition-duration 2 --resize crop || true
        fi

        # Restore saved theme across all apps without resetting to default
        CONFIG_JSON="$HOME/.config/quickshell/config.json"
        SAVED_THEME="wallpaper"
        if [ -f "$CONFIG_JSON" ]; then
            SAVED_THEME=$(python3 -c "
import json
try:
    with open('$CONFIG_JSON') as f:
        print(json.load(f).get('theme', 'wallpaper'))
except:
    print('wallpaper')
" 2>/dev/null || echo "wallpaper")
        fi

        echo "Restoring persistent theme: $SAVED_THEME"
        if [ -x "$HOME/.config/scripts/set-theme.sh" ]; then
            "$HOME/.config/scripts/set-theme.sh" "$SAVED_THEME"
        elif [ -x "$HOME/.dotfiles/scripts/set-theme.sh" ]; then
            "$HOME/.dotfiles/scripts/set-theme.sh" "$SAVED_THEME"
        fi
    ) &
fi

# ------------------------------------------------------------------------------
# 2. Desktop Shell (Quickshell)
# ------------------------------------------------------------------------------
if command -v quickshell &>/dev/null; then
    echo "Starting Quickshell desktop shell..."
    pkill -x quickshell 2>/dev/null
    sleep 0.2
    quickshell -d &
else
    echo "Warning: Quickshell not found"
fi

# ------------------------------------------------------------------------------
# 3. Clipboard History (cliphist)
# ------------------------------------------------------------------------------
if command -v cliphist &>/dev/null && command -v wl-paste &>/dev/null; then
    echo "Starting clipboard history service..."
    pkill -f "wl-paste.*cliphist" 2>/dev/null
    nohup wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
    nohup wl-paste --type image --watch cliphist store >/dev/null 2>&1 &
else
    echo "Warning: cliphist or wl-paste not found"
fi

# ------------------------------------------------------------------------------
# 4. XDG Desktop Portal WLR
# ------------------------------------------------------------------------------
if [ -x /usr/lib/xdg-desktop-portal-wlr ]; then
    echo "Starting XDG Desktop Portal WLR..."
    /usr/lib/xdg-desktop-portal-wlr &
else
    echo "Warning: xdg-desktop-portal-wlr not found"
fi

# ------------------------------------------------------------------------------
# 5. Additional Services (Uncomment to enable)
# ------------------------------------------------------------------------------

# Notification Daemon
# if command -v mako &>/dev/null; then
#     echo "Starting notification daemon..."
#     pkill -x mako 2>/dev/null
#     mako &
# fi

# Screenshot Service
# if command -v flameshot &>/dev/null; then
#     echo "Starting screenshot service..."
#     flameshot &
# fi

# Network Manager Applet
# if command -v nm-applet &>/dev/null; then
#     echo "Starting network manager applet..."
#     nm-applet &
# fi

# Bluetooth Applet
# if command -v blueman-applet &>/dev/null; then
#     echo "Starting bluetooth applet..."
#     blueman-applet &
# fi

# Audio Control
# if command -v pavucontrol &>/dev/null; then
#     echo "Audio control available via pavucontrol"
# fi

# ------------------------------------------------------------------------------
# 6. Custom User Applications
# ------------------------------------------------------------------------------

# Add your custom autostart applications here
# Example:
# if command -v discord &>/dev/null; then
#     discord &
# fi

echo "MangoWM autostart completed!"