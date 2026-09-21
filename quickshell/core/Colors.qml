pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// --- Singleton Color Palette ---
// Dark terminal aesthetic: Catppuccin Mocha base, more saturated accent
Singleton {
    id: root

    // Load dari colors.json
    property var _raw: ({})

    // Main cache colors file (Matugen dynamic colors)
    FileView {
        id: cacheColors
        path: Qt.resolvedUrl("../themes/colors.json")
        watchChanges: true
        onLoaded: updateColors(text())
        onFileChanged: reload()
    }

    // Local colors file (fallback)
    FileView {
        id: localColors
        path: Qt.resolvedUrl("../colors.json")
        watchChanges: true
        onLoaded: {
            if (!cacheColors.loaded) {
                updateColors(text())
            }
        }
        onFileChanged: reload()
    }

    function updateColors(jsonText) {
        try {
            if (data && Object.keys(data).length > 0) {
                root._raw = data
            }
        } catch(e) {
            console.warn("colors parse error:", e)
        }
    }

    // --- Base surfaces ---
    readonly property color base:     _raw.base    ?? _raw.bg ?? "#0d0e11"
    readonly property color surface:  _raw.surface ?? _raw.bg_light ?? "#141519"
    readonly property color overlay0: _raw.overlay0 ?? _raw.bg_light ?? "#1c1d22"
    readonly property color overlay1: _raw.overlay1 ?? _raw.bg_light ?? "#22232a"

    // --- Borders ---
    readonly property color border: alpha(_raw.border ?? _raw.bg_light ?? "#2a2b33", 0.3)
    readonly property color muted:  _raw.muted  ?? _raw.bg_light ?? "#3a3b45"

    // --- Text ---
    readonly property color text:     _raw.text     ?? "#cdd6f4"
    readonly property color subtext1: _raw.subtext1 ?? _raw.fg_light ?? "#7f849c"
    readonly property color subtext0: _raw.subtext0 ?? _raw.fg_light ?? "#6c7086"

    // --- Accent ---
    readonly property color accent:    _raw.accent    ?? "#89b4fa"
    readonly property color accentDim: _raw.accentDim ?? _raw.secondary ?? "#5a7fc4"

    // --- Semantic ---
    readonly property color green:  _raw.green  ?? "#a6e3a1"
    readonly property color teal:   _raw.teal   ?? _raw.secondary ?? "#94e2d5"
    readonly property color cyan:   _raw.cyan   ?? "#89dceb"
    readonly property color yellow: _raw.yellow ?? "#f9e2af"
    readonly property color peach:  _raw.peach  ?? "#fab387"
    readonly property color red:    _raw.red    ?? _raw.error ?? "#f38ba8"
    readonly property color maroon: _raw.maroon ?? "#eba0ac"
    readonly property color mauve:  _raw.mauve  ?? _raw.tertiary ?? "#cba6f7"

    // --- Alpha variants ---
    readonly property color surface85: Qt.rgba(surface.r, surface.g, surface.b, 0.88)
    readonly property color overlay85: Qt.rgba(overlay0.r, overlay0.g, overlay0.b, 0.90)
    readonly property color base70:    Qt.rgba(base.r, base.g, base.b, 0.70)

    // Helper: tint dengan alpha
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function mix(c1, c2, t) {
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            c1.a + (c2.a - c1.a) * t
        )
    }
}
