pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// --- Design tokens / Style System ---
Singleton {
    id: root

    // Load from themes/shell_style.json or fallback shell_style.json
    property var _raw: ({})

    FileView {
        id: cacheStyle
        path: Qt.resolvedUrl("../themes/shell_style.json")
        watchChanges: true
        onLoaded: updateStyle(text())
        onFileChanged: reload()
    }

    FileView {
        id: localStyle
        path: Qt.resolvedUrl("../shell_style.json")
        watchChanges: true
        onLoaded: {
            if (!cacheStyle.loaded) {
                updateStyle(text())
            }
        }
        onFileChanged: reload()
    }

    function updateStyle(jsonText) {
        try {
            let data = JSON.parse(jsonText.trim())
            if (data && Object.keys(data).length > 0) {
                root._raw = data
            }
        } catch(e) {
            console.warn("Style JSON parse error:", e)
        }
    }

    // ── SPACING (multiples of 4px base) ──────────────────────────
    readonly property var sp: ({
        "px1": 1,  "px2": 2,
        "xs":  4,  "sm":  6,
        "md":  8,  "lg":  12,
        "xl":  16, "xl2": 20,
        "xl3": 24, "xl4": 32
    })

    property string styleMode: _raw.styleMode ?? "wabi"

    // ── BORDER RADIUS ────────────────────────────────────────────
    // Always apply rounded corners for a premium feel
    readonly property var r: ({
        "none": 0,
        "xs":   3,
        "sm":   4,
        "md":   6,
        "lg":   8,
        "xl":   12,
    })

    // ── FONT ─────────────────────────────────────────────────────
    // Mono = stats, clock, numbers; Sans = labels, UI
    property string fontMono: _raw.fontMono ?? "Iosevka Nerd Font"
    property string fontSans: _raw.fontSans ?? "Iosevka Nerd Font"
    readonly property string fontIcon: "Material Icons"

    readonly property var fs: ({
        "xs":  10,
        "sm":  11,
        "md":  12,
        "lg":  13,
        "xl":  14,
        "xl2": 16,
        "xl3": 20
    })

    readonly property var fw: ({
        "thin":   Font.Thin,
        "light":  Font.Light,
        "normal": Font.Normal,
        "medium": Font.Medium,
        "semi":   Font.DemiBold,
        "bold":   Font.Bold,
        "black":  Font.Black
    })

    // ── ICON SIZES ───────────────────────────────────────────────
    readonly property var icon: ({
        "xs": 12,
        "sm": 14,
        "md": 16,
        "lg": 18,
        "xl": 20,
        "xl2": 24
    })

    // ── BAR ──────────────────────────────────────────────────────
    property int barPaddingH: _raw.barPaddingH ?? 10
    property int barPaddingV: _raw.barPaddingV ?? 4

    // ── ANIMATION ────────────────────────────────────────────────
    readonly property int durMicro:  80
    readonly property int durFast:   150
    readonly property int durNormal: 220
    readonly property int durSlow:   350

    // ── OPACITY ──────────────────────────────────────────────────
    readonly property real opHover:    0.75
    readonly property real opPressed:  0.55
    readonly property real opDisabled: 0.35
    property real opPanel:    _raw.opPanel ?? 0.85

    // ── INDICATORS TOGGLES ────────────────────────────────────────
    property bool showRam: _raw.showRam ?? true
    property bool showTemp: _raw.showTemp ?? true
    property bool showMic: _raw.showMic ?? true
    property bool showTray: _raw.showTray ?? true
}
