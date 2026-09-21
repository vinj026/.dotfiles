// qmllint disable unresolved-type
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../components"

Singleton {
    id: root

    // File watcher for dynamic Matugen wallpaper theme
    property var watcher: FileView {
        path: Quickshell.env("HOME") + "/.cache/matugen/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()

        JsonAdapter {
            id: matugenAdapter

            property color bgBase: "#0c0e13"
            property color surface: "#1e1f25"
            property color surfaceVariant: "#44464f"
            property color surfaceContainer: "#282a2f"

            property color primary: "#afc6ff"
            property color textOnPrimary: "#142f60"
            property color primaryContainer: "#2e4578"
            property color secondary: "#bfc6dc"
            property color tertiary: "#dfbbde"

            property color textPrimary: "#e2e2e9"
            property color textMuted: "#c5c6d0"
            property color textDim: "#8f9099"
            property color outline: "#44464f"
            property color error: "#ffb4ab"
        }
    }

    readonly property string activeTheme: ShellConfig.currentTheme

    function withAlpha(c, a) {
        let col = Qt.darker(c, 1.0);
        return Qt.rgba(col.r, col.g, col.b, a);
    }

    // Semantic Material 3 Token Properties
    readonly property color bgBase: {
        switch (activeTheme) {
            case "monochrome": return "#141414"; // ChillPill bgD
            case "vercel":     return "#000000"; // Vercel pitch black
            case "catppuccin": return "#11111b";
            case "everblush":  return "#141b1e";
            case "everforest": return "#232a2e";
            case "gruvbox":    return "#1d2021";
            case "monokai":    return "#1e1f1c";
            case "ayu_dark":
            case "ayu-dark":   return "#0b0e14";
            case "wallpaper":
            default: return matugenAdapter.bgBase;
        }
    }

    readonly property color rawSurface: {
        switch (activeTheme) {
            case "monochrome": return "#191919"; // ChillPill bgD1
            case "vercel":     return "#0a0a0a"; // Vercel obsidian surface
            case "catppuccin": return "#1e1e2e";
            case "everblush":  return "#182024";
            case "everforest": return "#2d353b";
            case "gruvbox":    return "#282828";
            case "monokai":    return "#272822";
            case "ayu_dark":
            case "ayu-dark":   return "#0f141c";
            case "wallpaper":
            default: return matugenAdapter.surface;
        }
    }
    // Frosted glass base surface (subtle transparency, allowing compositor blur through)
    readonly property color surface: withAlpha(rawSurface, activeTheme === "vercel" ? 0.65 : 0.82)

    readonly property color rawSurfaceVariant: {
        switch (activeTheme) {
            case "monochrome": return "#323232"; // ChillPill bg5
            case "vercel":     return "#1f1f1f"; // Geist gray-200
            case "catppuccin": return "#313244";
            case "everblush":  return "#283236";
            case "everforest": return "#475258";
            case "gruvbox":    return "#504945";
            case "monokai":    return "#49483e";
            case "ayu_dark":
            case "ayu-dark":   return "#242936";
            case "wallpaper":
            default: return matugenAdapter.surfaceVariant;
        }
    }
    readonly property color surfaceVariant: withAlpha(rawSurfaceVariant, activeTheme === "vercel" ? 0.55 : 0.70)

    readonly property color rawSurfaceContainer: {
        switch (activeTheme) {
            case "monochrome": return "#252525"; // ChillPill bg3
            case "vercel":     return "#1a1a1a"; // Geist gray-100
            case "catppuccin": return "#181825";
            case "everblush":  return "#232a2d";
            case "everforest": return "#343f44";
            case "gruvbox":    return "#3c3836";
            case "monokai":    return "#3e3d32";
            case "ayu_dark":
            case "ayu-dark":   return "#1b212c";
            case "wallpaper":
            default: return matugenAdapter.surfaceContainer;
        }
    }
    readonly property color surfaceContainer: withAlpha(rawSurfaceContainer, activeTheme === "vercel" ? 0.45 : 0.65)

    readonly property color activeTileBg: {
        switch (activeTheme) {
            case "vercel":
            case "monochrome":
                return Qt.rgba(1, 1, 1, 0.20); // Frosted luminous white glass for active buttons
            default:
                return primary;
        }
    }

    readonly property color primary: {
        switch (activeTheme) {
            case "monochrome": return "#dadada"; // ChillPill fg (soft light gray)
            case "vercel":     return "#ededed"; // Geist gray-1000 high-contrast white
            case "catppuccin": return "#89b4fa";
            case "everblush":  return "#8ccf7e";
            case "everforest": return "#a7c080";
            case "gruvbox":    return "#fabd2f";
            case "monokai":    return "#a6e22e";
            case "ayu_dark":
            case "ayu-dark":   return "#ffb454";
            case "wallpaper":
            default: return matugenAdapter.primary;
        }
    }

    readonly property color textOnPrimary: {
        switch (activeTheme) {
            case "monochrome": return "#161616"; // ChillPill bg
            case "vercel":     return "#ffffff"; // Crisp pure white text/icon on frosted glass
            case "catppuccin": return "#11111b";
            case "everblush":  return "#141b1e";
            case "everforest": return "#232a2e";
            case "gruvbox":    return "#282828";
            case "monokai":    return "#272822";
            case "ayu_dark":
            case "ayu-dark":   return "#0b0e14";
            case "wallpaper":
            default: return matugenAdapter.textOnPrimary;
        }
    }

    readonly property color primaryContainer: {
        switch (activeTheme) {
            case "monochrome": return "#353535"; // ChillPill focusBgL / bg6
            case "vercel":     return "#262626";
            case "catppuccin": return "#45475a";
            case "everblush":  return "#283b32";
            case "everforest": return "#3a463e";
            case "gruvbox":    return "#b57614";
            case "monokai":    return "#75715e";
            case "ayu_dark":
            case "ayu-dark":   return "#e6b450";
            case "wallpaper":
            default: return matugenAdapter.primaryContainer;
        }
    }

    readonly property color secondary: {
        switch (activeTheme) {
            case "monochrome": return "#b8b8b8"; // ChillPill accent (brightened for high readability)
            case "vercel":     return "#0070f3"; // Vercel electric blue accent
            case "catppuccin": return "#f5c2e7";
            case "everblush":  return "#e5c76b";
            case "everforest": return "#dbbc7f";
            case "gruvbox":    return "#d79921";
            case "monokai":    return "#f92672";
            case "ayu_dark":
            case "ayu-dark":   return "#39bae6";
            case "wallpaper":
            default: return matugenAdapter.secondary;
        }
    }

    readonly property color tertiary: {
        switch (activeTheme) {
            case "monochrome": return "#c4c4c4"; // ChillPill fg3
            case "vercel":     return "#12a594"; // Geist teal-700
            case "catppuccin": return "#94e2d5";
            case "everblush":  return "#6cbfbf";
            case "everforest": return "#7fbbb3";
            case "gruvbox":    return "#b8bb26";
            case "monokai":    return "#66d9ef";
            case "ayu_dark":
            case "ayu-dark":   return "#aad94c";
            case "wallpaper":
            default: return matugenAdapter.tertiary;
        }
    }

    readonly property color textPrimary: {
        switch (activeTheme) {
            case "monochrome": return "#e7e7e7"; // ChillPill fg1 (warm light gray close to white)
            case "vercel":     return "#ededed"; // Geist gray-1000
            case "catppuccin": return "#cdd6f4";
            case "everblush":  return "#dadada";
            case "everforest": return "#d3c6aa";
            case "gruvbox":    return "#ebdbb2";
            case "monokai":    return "#f8f8f2";
            case "ayu_dark":
            case "ayu-dark":   return "#e6e1cf";
            case "wallpaper":
            default: return matugenAdapter.textPrimary;
        }
    }

    readonly property color textMuted: {
        switch (activeTheme) {
            case "monochrome": return "#9e9e9e"; // ChillPill fg4
            case "vercel":     return "#8f8f8f"; // Geist gray-700
            case "catppuccin": return "#a6adc8";
            case "everblush":  return "#808d93";
            case "everforest": return "#9da9a0";
            case "gruvbox":    return "#bdae93";
            case "monokai":    return "#cfcfc2";
            case "ayu_dark":
            case "ayu-dark":   return "#bfbdb6";
            case "wallpaper":
            default: return matugenAdapter.textMuted;
        }
    }

    readonly property color textDim: {
        switch (activeTheme) {
            case "monochrome": return "#6a6a6a"; // ChillPill fg6
            case "vercel":     return "#666666"; // Geist gray-500
            case "catppuccin": return "#6c7086";
            case "everblush":  return "#5c676c";
            case "everforest": return "#7a8478";
            case "gruvbox":    return "#7c6f64";
            case "monokai":    return "#75715e";
            case "ayu_dark":
            case "ayu-dark":   return "#707a8c";
            case "wallpaper":
            default: return matugenAdapter.textDim;
        }
    }

    readonly property color outline: {
        switch (activeTheme) {
            case "monochrome": return "#484848"; // ChillPill borderBg1 / fg7
            case "vercel":     return "#2e2e2e"; // Geist gray-400
            case "catppuccin": return "#585b70";
            case "everblush":  return "#323b3e";
            case "everforest": return "#4f5b58";
            case "gruvbox":    return "#665c54";
            case "monokai":    return "#49483e";
            case "ayu_dark":
            case "ayu-dark":   return "#3d424d";
            case "wallpaper":
            default: return matugenAdapter.outline;
        }
    }

    readonly property color error: {
        switch (activeTheme) {
            case "monochrome": return "#e32626"; // ChillPill deleting
            case "vercel":     return "#e5484d"; // Geist red-700
            case "catppuccin": return "#f38ba8";
            case "everblush":  return "#e57474";
            case "everforest": return "#e67e80";
            case "gruvbox":    return "#cc241d";
            case "monokai":    return "#f92672";
            case "ayu_dark":
            case "ayu-dark":   return "#f07178";
            case "wallpaper":
            default: return matugenAdapter.error;
        }
    }

    // Workspaces semantic indicators
    readonly property color workspaceOccupied: {
        switch (activeTheme) {
            case "monochrome": return "#b8b8b8"; // Crisp light silver for occupied inactive workspace
            case "vercel":     return "#0070f3"; // Electric blue
            default:           return secondary;
        }
    }

    readonly property color workspaceInactive: {
        switch (activeTheme) {
            case "monochrome": return "#727272"; // Clearly visible balanced neutral gray on dark surface
            case "vercel":     return "#525252";
            case "catppuccin": return "#6c7086";
            case "everblush":  return "#5c676c";
            case "everforest": return "#6e7874";
            case "gruvbox":    return "#7c6f64";
            case "monokai":    return "#68675b";
            case "ayu_dark":
            case "ayu-dark":   return "#555f73";
            case "wallpaper":
            default: return textDim;
        }
    }
}
