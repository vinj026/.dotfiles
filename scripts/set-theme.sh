#!/usr/bin/env bash

# ==============================================================================
# SET-THEME / MULTI-APP SYNC SCRIPT
# Synchronizes:
# 1. Quickshell Shell & Themes (M3 semantic tokens)
# 2. Mango Compositor Window Borders
# 3. Terminal (Kitty & Alacritty)
# 4. GTK 3 & GTK 4 / Libadwaita
# 5. Qt 5 & Qt 6 (qt6ct / qt5ct Fusion style)
# ==============================================================================

set -euo pipefail

THEME="${1:-}"
FLAG="${2:-}"

# Check for --style flag
if [ "$THEME" = "--style" ]; then
    STYLE="${2:-}"
    if [ -z "$STYLE" ]; then
        echo "Usage: set-theme --style <notch|floating|classic>" >&2
        exit 1
    fi
    STYLE="$(echo "$STYLE" | tr '[:upper:]' '[:lower:]')"
    CONFIG_JSON="$HOME/.config/quickshell/config.json"
    if [ -f "$CONFIG_JSON" ]; then
        python3 -c "
import json
path = '$CONFIG_JSON'
try:
    with open(path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {'theme': 'wallpaper'}
data['style'] = '$STYLE'
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
"
    fi
    if command -v quickshell &>/dev/null; then
        quickshell ipc call config setStyle "$STYLE" 2>/dev/null || true
    fi
    echo "Style applied: $STYLE"
    exit 0
fi

if [ -z "$THEME" ]; then
    echo "Usage: set-theme <wallpaper|monochrome|vercel|catppuccin|everforest|everblush>" >&2
    echo "       set-theme --style <notch|floating|classic>" >&2
    exit 1
fi

THEME="$(echo "$THEME" | tr '[:upper:]' '[:lower:]')"
MANGO_THEME="$HOME/.config/mango/theme.conf"
KITTY_THEME="$HOME/.config/kitty/theme.conf"
ALACRITTY_THEME="$HOME/.config/alacritty/theme.toml"
GTK3_CSS="$HOME/.config/gtk-3.0/gtk.css"
GTK4_CSS="$HOME/.config/gtk-4.0/gtk.css"
QT6_COLORS="$HOME/.config/qt6ct/colors/current.conf"
QT5_COLORS="$HOME/.config/qt5ct/colors/current.conf"
CONFIG_JSON="$HOME/.config/quickshell/config.json"

mkdir -p "$(dirname "$MANGO_THEME")" "$(dirname "$KITTY_THEME")" "$(dirname "$ALACRITTY_THEME")" \
         "$(dirname "$GTK3_CSS")" "$(dirname "$GTK4_CSS")" "$(dirname "$QT6_COLORS")" "$(dirname "$QT5_COLORS")"

write_kitty() {
    local fg="$1" bg="$2" sel_fg="$3" sel_bg="$4" cur="$5" bord="$6"
    local c0="$7" c1="$8" c2="$9" c3="${10}" c4="${11}" c5="${12}" c6="${13}" c7="${14}"
    local c8="${15}" c9="${16}" c10="${17}" c11="${18}" c12="${19}" c13="${20}" c14="${21}" c15="${22}"

    cat << KCONF > "$KITTY_THEME"
# ==============================================================================
# KITTY THEME: $THEME
# ==============================================================================
foreground              $fg
background              $bg
selection_foreground    $sel_fg
selection_background    $sel_bg
cursor                  $cur
cursor_text_color       $sel_fg

active_border_color     $bord
inactive_border_color   $c8

# Black
color0 $c0
color8 $c8

# Red
color1 $c1
color9 $c9

# Green
color2 $c2
color10 $c10

# Yellow
color3 $c3
color11 $c11

# Blue
color4 $c4
color12 $c12

# Magenta
color5 $c5
color13 $c13

# Cyan
color6 $c6
color14 $c14

# White
color7 $c7
color15 $c15
KCONF
}

write_alacritty() {
    local fg="$1" bg="$2" cur="$3" sel_fg="$4" sel_bg="$5"
    local c0="$6" c1="$7" c2="$8" c3="$9" c4="${10}" c5="${11}" c6="${12}" c7="${13}"
    local c8="${14}" c9="${15}" c10="${16}" c11="${17}" c12="${18}" c13="${19}" c14="${20}" c15="${21}"

    cat << ACONF > "$ALACRITTY_THEME"
# ==============================================================================
# ALACRITTY THEME: $THEME
# ==============================================================================
[colors.primary]
background = "$bg"
foreground = "$fg"

[colors.cursor]
text = "$sel_fg"
cursor = "$cur"

[colors.selection]
text = "$sel_fg"
background = "$sel_bg"

[colors.normal]
black   = "$c0"
red     = "$c1"
green   = "$c2"
yellow  = "$c3"
blue    = "$c4"
magenta = "$c5"
cyan    = "$c6"
white   = "$c7"

[colors.bright]
black   = "$c8"
red     = "$c9"
green   = "$c10"
yellow  = "$c11"
blue    = "$c12"
magenta = "$c13"
cyan    = "$c14"
white   = "$c15"
ACONF
}

write_gtk() {
    local primary="$1" on_primary="$2" surface="$3" on_surface="$4"
    local surface_lowest="$5" surface_container="$6" surface_variant="$7"
    local outline_variant="$8" error="$9"

    # GTK 4 / Libadwaita
    cat << G4CONF > "$GTK4_CSS"
/* GTK 4 / Libadwaita Theme: $THEME */
@define-color accent_color $primary;
@define-color accent_bg_color $primary;
@define-color accent_fg_color $on_primary;

@define-color window_bg_color $surface;
@define-color window_fg_color $on_surface;

@define-color view_bg_color $surface_lowest;
@define-color view_fg_color $on_surface;

@define-color headerbar_bg_color $surface_container;
@define-color headerbar_fg_color $on_surface;
@define-color headerbar_border_color $outline_variant;
@define-color headerbar_backdrop_color $surface_container;

@define-color card_bg_color $surface_container;
@define-color card_fg_color $on_surface;
@define-color card_border_color $outline_variant;

@define-color popover_bg_color $surface_variant;
@define-color popover_fg_color $on_surface;

@define-color dialog_bg_color $surface_variant;
@define-color dialog_fg_color $on_surface;

@define-color destructive_color $error;
@define-color destructive_bg_color $error;
@define-color destructive_fg_color $on_primary;
G4CONF

    # GTK 3
    cat << G3CONF > "$GTK3_CSS"
/* GTK 3 Theme: $THEME */
@define-color accent_color $primary;
@define-color accent_bg_color $primary;
@define-color accent_fg_color $on_primary;

@define-color window_bg_color $surface;
@define-color window_fg_color $on_surface;

@define-color view_bg_color $surface_lowest;
@define-color view_fg_color $on_surface;

@define-color headerbar_bg_color $surface_container;
@define-color headerbar_fg_color $on_surface;
@define-color headerbar_border_color $outline_variant;
@define-color headerbar_backdrop_color $surface_container;

@define-color card_bg_color $surface_container;
@define-color card_fg_color $on_surface;
@define-color card_border_color $outline_variant;

@define-color popover_bg_color $surface_variant;
@define-color popover_fg_color $on_surface;

@define-color dialog_bg_color $surface_variant;
@define-color dialog_fg_color $on_surface;

@define-color destructive_color $error;
@define-color destructive_bg_color $error;
@define-color destructive_fg_color $on_primary;

/* Legacy GTK 3 Theme Definitions */
@define-color theme_bg_color $surface;
@define-color theme_fg_color $on_surface;
@define-color theme_base_color $surface_lowest;
@define-color theme_text_color $on_surface;
@define-color theme_selected_bg_color $primary;
@define-color theme_selected_fg_color $on_primary;
@define-color insensitive_bg_color $surface_container;
@define-color insensitive_fg_color $surface_variant;
@define-color insensitive_base_color $surface;
@define-color borders $outline_variant;
@define-color error_color $error;

window {
    background-color: @theme_bg_color;
    color: @theme_fg_color;
}

headerbar {
    background-color: @headerbar_bg_color;
    color: @headerbar_fg_color;
    border-color: @headerbar_border_color;
}

button {
    background-color: @card_bg_color;
    color: @theme_fg_color;
    border-color: @borders;
}

button:hover {
    background-color: @popover_bg_color;
}

button:checked, button:active {
    background-color: @accent_bg_color;
    color: @accent_fg_color;
}

entry {
    background-color: @theme_base_color;
    color: @theme_text_color;
    border-color: @borders;
}

entry:focus {
    border-color: @accent_color;
}

scrollbar slider {
    background-color: @surface_variant;
}
G3CONF
}

write_qt() {
    local text="$1" bg_btn="$2" bg_panel="$3" bg_view="$4" border="$5" accent="$6" on_accent="$7" sec="$8" tert="$9"
    local raw_text="${text//#/}"
    local raw_btn="${bg_btn//#/}"
    local raw_panel="${bg_panel//#/}"
    local raw_view="${bg_view//#/}"
    local raw_border="${border//#/}"
    local raw_accent="${accent//#/}"
    local raw_on_accent="${on_accent//#/}"
    local raw_sec="${sec//#/}"
    local raw_tert="${tert//#/}"

    local content="[ColorScheme]
active_colors=#ff$raw_text, #ff$raw_btn, #ff$raw_panel, #ff$raw_panel, #ff$raw_border, #ff$raw_border, #ff$raw_text, #ff$raw_text, #ff$raw_text, #ff$raw_view, #ff$raw_panel, #ff000000, #ff$raw_accent, #ff$raw_on_accent, #ff$raw_sec, #ff$raw_tert, #ff$raw_view, #ff$raw_btn, #ff$raw_text, #ff$raw_border, #80$raw_accent
disabled_colors=#ff$raw_border, #ff$raw_btn, #ff$raw_panel, #ff$raw_panel, #ff$raw_border, #ff$raw_border, #ff$raw_border, #ff$raw_text, #ff$raw_border, #ff$raw_view, #ff$raw_panel, #ff000000, #ff$raw_accent, #ff$raw_border, #ff$raw_sec, #ff$raw_tert, #ff$raw_view, #ff$raw_btn, #ff$raw_text, #ff$raw_border, #80$raw_accent
inactive_colors=#ff$raw_text, #ff$raw_btn, #ff$raw_panel, #ff$raw_panel, #ff$raw_border, #ff$raw_border, #ff$raw_text, #ff$raw_text, #ff$raw_text, #ff$raw_view, #ff$raw_panel, #ff000000, #ff$raw_accent, #ff$raw_on_accent, #ff$raw_sec, #ff$raw_tert, #ff$raw_view, #ff$raw_btn, #ff$raw_text, #ff$raw_border, #80$raw_accent"

    echo "$content" > "$QT6_COLORS"
    echo "$content" > "$QT5_COLORS"
}

case "$THEME" in
    wallpaper)
        WP="$HOME/.config/mango/wallpaper/current.jpg"
        if [ ! -f "$WP" ]; then
            WP="$(ls "$HOME/.config/mango/wallpaper/"*.{jpg,png} 2>/dev/null | head -n 1)"
        fi
        if [ -n "$WP" ] && command -v matugen &>/dev/null; then
            matugen -c "$HOME/.config/matugen/config.toml" image "$WP" -m dark --source-color-index 0
        fi
        ;;
    monochrome)
        cat << 'TCONF' > "$MANGO_THEME"
# Dynamic Theme: Monochrome
rootcolor=0x0a0a0aff
bordercolor=0x404040ff
focuscolor=0xffffffff
splitcolor=0xff6b6bff
dropcolor=0xffffff55
urgentcolor=0xff6b6bff
maximizescreencolor=0xffffffff
scratchpadcolor=0xa3a3a3ff
globalcolor=0xd4d4d4ff
overlaycolor=0xa3a3a3ff
shadowscolor=0x00000088
TCONF
        write_kitty "#ffffff" "#121212" "#000000" "#ffffff" "#ffffff" "#ffffff" \
                    "#0a0a0a" "#ff6b6b" "#ffffff" "#d4d4d4" "#a3a3a3" "#737373" "#d4d4d4" "#e5e5e5" \
                    "#525252" "#ff8787" "#ffffff" "#e5e5e5" "#b5b5b5" "#8a8a8a" "#e5e5e5" "#ffffff"
        write_alacritty "#ffffff" "#121212" "#ffffff" "#000000" "#ffffff" \
                        "#0a0a0a" "#ff6b6b" "#ffffff" "#d4d4d4" "#a3a3a3" "#737373" "#d4d4d4" "#e5e5e5" \
                        "#525252" "#ff8787" "#ffffff" "#e5e5e5" "#b5b5b5" "#8a8a8a" "#e5e5e5" "#ffffff"
        write_gtk "#ffffff" "#000000" "#121212" "#ffffff" "#0a0a0a" "#1e1e1e" "#262626" "#404040" "#ff6b6b"
        write_qt "#ffffff" "#1e1e1e" "#121212" "#0a0a0a" "#404040" "#ffffff" "#000000" "#a3a3a3" "#737373"
        ;;
    vercel)
        cat << 'TCONF' > "$MANGO_THEME"
# Dynamic Theme: Vercel Dark (Official Geist Colors)
rootcolor=0x000000ff
bordercolor=0x2e2e2eff
focuscolor=0xedededff
splitcolor=0x0072f5ff
dropcolor=0xededed55
urgentcolor=0xe5484dff
maximizescreencolor=0xedededff
scratchpadcolor=0x12a594ff
globalcolor=0xedededff
overlaycolor=0x12a594ff
shadowscolor=0x000000aa
TCONF
        write_kitty "#ededed" "#000000" "#ffffff" "#3a3a42" "#ededed" "#3a3a42" \
                    "#000000" "#e5484d" "#45a557" "#ffb224" "#0072f5" "#8e4ec6" "#12a594" "#ededed" \
                    "#666666" "#ff6369" "#5bbf6e" "#ffc043" "#52a8ff" "#ab6fe5" "#20c2ae" "#ffffff"
        write_alacritty "#ededed" "#000000" "#ffffff" "#ffffff" "#3a3a42" \
                        "#000000" "#e5484d" "#45a557" "#ffb224" "#0072f5" "#8e4ec6" "#12a594" "#ededed" \
                        "#666666" "#ff6369" "#5bbf6e" "#ffc043" "#52a8ff" "#ab6fe5" "#20c2ae" "#ffffff"
        write_gtk "#ededed" "#000000" "#0a0a0a" "#3a3a42" "#ffffff" "#1a1a1a" "#1f1f1f" "#2e2e2e" "#e5484d"
        write_qt "#ededed" "#1f1f1f" "#0a0a0a" "#000000" "#2e2e2e" "#3a3a42" "#ffffff" "#0072f5" "#12a594"
        ;;
    catppuccin)
        cat << 'TCONF' > "$MANGO_THEME"
# Dynamic Theme: Catppuccin Mocha
rootcolor=0x11111bff
bordercolor=0x313244ff
focuscolor=0x89b4faff
splitcolor=0xf38ba8ff
dropcolor=0x89b4fa55
urgentcolor=0xf38ba8ff
maximizescreencolor=0x89b4faff
scratchpadcolor=0x94e2d5ff
globalcolor=0xf5c2e7ff
overlaycolor=0x94e2d5ff
shadowscolor=0x00000088
TCONF
        write_kitty "#cdd6f4" "#1e1e2e" "#11111b" "#89b4fa" "#89b4fa" "#89b4fa" \
                    "#11111b" "#f38ba8" "#a6e3a1" "#f9e2af" "#89b4fa" "#f5c2e7" "#94e2d5" "#cdd6f4" \
                    "#585b70" "#f38ba8" "#a6e3a1" "#f9e2af" "#89b4fa" "#f5c2e7" "#94e2d5" "#ffffff"
        write_alacritty "#cdd6f4" "#1e1e2e" "#89b4fa" "#11111b" "#89b4fa" \
                        "#11111b" "#f38ba8" "#a6e3a1" "#f9e2af" "#89b4fa" "#f5c2e7" "#94e2d5" "#cdd6f4" \
                        "#585b70" "#f38ba8" "#a6e3a1" "#f9e2af" "#89b4fa" "#f5c2e7" "#94e2d5" "#ffffff"
        write_gtk "#89b4fa" "#11111b" "#1e1e2e" "#cdd6f4" "#11111b" "#181825" "#313244" "#313244" "#f38ba8"
        write_qt "#cdd6f4" "#313244" "#1e1e2e" "#11111b" "#313244" "#89b4fa" "#11111b" "#f5c2e7" "#94e2d5"
        ;;
    everforest)
        cat << 'TCONF' > "$MANGO_THEME"
# Dynamic Theme: Everforest Dark
rootcolor=0x232a2eff
bordercolor=0x3a4448ff
focuscolor=0xa7c080ff
splitcolor=0xe67e80ff
dropcolor=0xa7c08055
urgentcolor=0xe67e80ff
maximizescreencolor=0xa7c080ff
scratchpadcolor=0x7fbbb3ff
globalcolor=0xdbbc7fff
overlaycolor=0x7fbbb3ff
shadowscolor=0x00000088
TCONF
        write_kitty "#d3c6aa" "#2d353b" "#232a2e" "#a7c080" "#a7c080" "#a7c080" \
                    "#232a2e" "#e67e80" "#a7c080" "#dbbc7f" "#7fbbb3" "#d699b6" "#83c092" "#d3c6aa" \
                    "#475258" "#e67e80" "#a7c080" "#dbbc7f" "#7fbbb3" "#d699b6" "#83c092" "#d3c6aa"
        write_alacritty "#d3c6aa" "#2d353b" "#a7c080" "#232a2e" "#a7c080" \
                        "#232a2e" "#e67e80" "#a7c080" "#dbbc7f" "#7fbbb3" "#d699b6" "#83c092" "#d3c6aa" \
                        "#475258" "#e67e80" "#a7c080" "#dbbc7f" "#7fbbb3" "#d699b6" "#83c092" "#d3c6aa"
        write_gtk "#a7c080" "#232a2e" "#2d353b" "#d3c6aa" "#1e2326" "#232a2e" "#343f44" "#3a4448" "#e67e80"
        write_qt "#d3c6aa" "#343f44" "#2d353b" "#1e2326" "#3a4448" "#a7c080" "#232a2e" "#dbbc7f" "#7fbbb3"
        ;;
    everblush)
        cat << 'TCONF' > "$MANGO_THEME"
# Dynamic Theme: Everblush
rootcolor=0x141b1eff
bordercolor=0x323b3eff
focuscolor=0x8ccf7eff
splitcolor=0xe57474ff
dropcolor=0x8ccf7e55
urgentcolor=0xe57474ff
maximizescreencolor=0x8ccf7eff
scratchpadcolor=0x6cbfbfff
globalcolor=0xe5c76bff
overlaycolor=0x6cbfbfff
shadowscolor=0x00000088
TCONF
        write_kitty "#dadada" "#141b1e" "#141b1e" "#8ccf7e" "#8ccf7e" "#8ccf7e" \
                    "#232a2d" "#e57474" "#8ccf7e" "#e5c76b" "#67b0e8" "#c47fd5" "#6cbfbf" "#b3b9b8" \
                    "#2d3437" "#ef7e7e" "#96d988" "#f4d67a" "#71baee" "#ce89df" "#76c9c9" "#dadada"
        write_alacritty "#dadada" "#141b1e" "#8ccf7e" "#141b1e" "#8ccf7e" \
                        "#232a2d" "#e57474" "#8ccf7e" "#e5c76b" "#67b0e8" "#c47fd5" "#6cbfbf" "#b3b9b8" \
                        "#2d3437" "#ef7e7e" "#96d988" "#f4d67a" "#71baee" "#ce89df" "#76c9c9" "#dadada"
        write_gtk "#8ccf7e" "#141b1e" "#182024" "#dadada" "#141b1e" "#232a2d" "#283236" "#323b3e" "#e57474"
        write_qt "#dadada" "#283236" "#182024" "#141b1e" "#323b3e" "#8ccf7e" "#141b1e" "#e5c76b" "#6cbfbf"
        ;;
    *)
        echo "Error: Unknown theme '$THEME'. Options: wallpaper, monochrome, vercel, catppuccin, everforest, everblush" >&2
        exit 1
        ;;
esac

# 1. Update config.json for Quickshell if called standalone from terminal
if [ "$FLAG" != "--from-qs" ] && [ -f "$CONFIG_JSON" ]; then
    python3 -c "
import json
path = '$CONFIG_JSON'
try:
    with open(path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {'style': 'notch'}
data['theme'] = '$THEME'
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
fi

# 2. Tell Quickshell via IPC if called from terminal
if [ "$FLAG" != "--from-qs" ] && command -v quickshell &>/dev/null; then
    quickshell ipc call config setTheme "$THEME" 2>/dev/null || true
fi

# 3. Reload Mango Compositor borders
if command -v mmsg &>/dev/null; then
    mmsg dispatch reload_config 2>/dev/null || true
fi

# 4. Live reload Kitty terminal instances
pkill -SIGUSR1 kitty 2>/dev/null || true

# 5. Refresh GTK theme setting
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
fi

echo "Theme applied across all apps: $THEME"
