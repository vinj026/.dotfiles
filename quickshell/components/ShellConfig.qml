pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var availableStyles: ["notch", "floating", "classic"]
    readonly property var availableThemes: ["monochrome", "vercel", "wallpaper", "gruvbox", "everblush", "everforest", "monokai", "catppuccin", "ayu_dark", "ayu-dark"]

    property string currentStyle: "notch"
    property string currentTheme: "wallpaper"

    property var watcher: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/config.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string style: "notch"
            property string theme: "wallpaper"

            onStyleChanged: {
                if (style && root.currentStyle !== style) {
                    root.currentStyle = style;
                }
            }
            onThemeChanged: {
                if (theme && root.currentTheme !== theme) {
                    root.currentTheme = theme;
                }
            }
        }
    }

    function setStyle(newStyle) {
        if (!newStyle) return;
        newStyle = newStyle.toLowerCase().trim();
        if (availableStyles.indexOf(newStyle) === -1) {
            console.warn("Invalid style:", newStyle);
            return;
        }
        root.currentStyle = newStyle;
        save();
    }

    function setTheme(newTheme) {
        if (!newTheme) return;
        newTheme = newTheme.toLowerCase().trim();
        if (availableThemes.indexOf(newTheme) === -1) {
            console.warn("Invalid theme:", newTheme);
            return;
        }
        root.currentTheme = newTheme;
        save();
        // Apply theme directly to quickshell and sync across system
        Quickshell.execDetached(["sh", "-c", `[ -x "$HOME/.config/quickshell/scripts/apply_theme.sh" ] && "$HOME/.config/quickshell/scripts/apply_theme.sh" "${newTheme}"; [ -x "$HOME/.config/scripts/set-theme.sh" ] && "$HOME/.config/scripts/set-theme.sh" "${newTheme}" --from-qs`]);
    }

    function cycleStyle() {
        let idx = availableStyles.indexOf(root.currentStyle);
        let nextIdx = (idx + 1) % availableStyles.length;
        setStyle(availableStyles[nextIdx]);
    }

    function cycleTheme() {
        let idx = availableThemes.indexOf(root.currentTheme);
        let nextIdx = (idx + 1) % availableThemes.length;
        setTheme(availableThemes[nextIdx]);
    }

    function save() {
        let jsonStr = JSON.stringify({
            style: root.currentStyle,
            theme: root.currentTheme
        }, null, 2);

        let escaped = jsonStr.replace(/'/g, "'\\''");
        Quickshell.execDetached(["sh", "-c", `printf '%s\n' '${escaped}' > "$HOME/.config/quickshell/config.json"`]);
    }
}
