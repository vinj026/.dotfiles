pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    // Reference to Semantic Colors
    property color bgBase: Colors.bgBase
    property color rawSurface: Colors.rawSurface
    property color surface: Colors.surface
    property color surfaceVariant: Colors.surfaceVariant
    property color surfaceContainer: Colors.surfaceContainer
    property color activeTileBg: Colors.activeTileBg
    property color primary: Colors.primary
    property color textOnPrimary: Colors.textOnPrimary
    property color primaryContainer: Colors.primaryContainer
    property color secondary: Colors.secondary
    property color tertiary: Colors.tertiary
    property color textPrimary: Colors.textPrimary
    property color textMuted: Colors.textMuted
    property color textDim: Colors.textDim
    property color outline: Colors.outline
    property color error: Colors.error
    property color workspaceOccupied: Colors.workspaceOccupied
    property color workspaceInactive: Colors.workspaceInactive

    // Material 3 Shape Scale Tokens
    property int shapeCornerNone: 0
    property int shapeCornerExtraSmall: 4
    property int shapeCornerSmall: 8
    property int shapeCornerMedium: 12
    property int shapeCornerLarge: 16
    property int shapeCornerExtraLarge: 24
    property int shapeCornerFull: 999

    // Bar Style Dimensions
    // 1. Dynamic Island Notch (Concept 2: Material 3 Seamless Dynamic Notch)
    property int notchHeight: 30
    property int notchCutoutDepth: 6
    property int notchCutoutWidth: 160
    property int notchTransitionRadius: 16
    property int notchBottomRadius: 14
    property int notchTopRadius: 13
    property int notchSideRadius: 14
    property int notchPopupCornerRadius: 12
    property real notchBgOpacity: 0.95

    property int leftNotchMinWidth: 180
    property int leftNotchMaxWidth: 380

    property int rightNotchMinWidth: 75
    property int rightNotchMaxWidth: 200

    // 2. Floating Bar
    property int floatingBarHeight: 32
    property int floatingBarTopMargin: 8
    property int floatingBarHorizontalMargin: 16

    // 3. Classic Bar
    property int classicBarHeight: 28

    property int appNameMaxWidth: 180

    // Typography
    property string fontFamily: "Inter"
    property string fontJp: "Zen Kaku Gothic New"
    property string iconFontFamily: "Material Symbols Rounded"

    // Ukishima Official Motion Tokens (amanhex/ukishima)
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]
    property int durationMorph: 420
    property int durationGlide: 260
    property int durationStandard: 300
    property int durationFast: 140
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeMorph: Easing.BezierSpline

    // Material 3 / vast-shell Official Bézier Spline Curves
    readonly property var curveEmphasized: [0.05, 0, 0.13, 0.06, 0.16, 0.4, 0.20833, 0.82, 0.25, 1, 1, 1]
    readonly property var curveEmphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var curveEmphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var curveExpressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var curveExpressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var curveExpressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var curveStandard: [0.2, 0, 0, 1, 1, 1]
    readonly property var curveStandardAccel: [0.3, 0, 1, 1, 1, 1]
    readonly property var curveStandardDecel: [0, 0, 0, 1, 1, 1]

    // Durations matching vast-shell / M3 specs
    property int durationEmphasized: 500
    property int durationEmphasizedDecel: 400
    property int durationEmphasizedAccel: 200
    property int durationExpressiveDefaultSpatial: 500
    property int durationExpressiveFastSpatial: 350
    property int durationExpressiveEffects: 200

    // Material 3 Expressive Animation Tokens
    property int animDurationMicro: 120
    property int animDurationFast: 180
    property int animDurationNormal: 300
    property int animDurationMedium: 350
    property int animDurationLong: 500

    property real springOvershootSubtle: 1.15
    property real springOvershootExpressive: 1.35

    // Material 3 Battery Palette (Matching Reference Design)
    property color batteryGreenFill: "#69db7c"
    property color batteryGreenBase: "#40c057"
    property color batteryGreenText: "#1b5e20"

    property color batteryWarnFill: "#ffd43b"
    property color batteryWarnBase: "#f76707"
    property color batteryWarnText: "#7f1d1d"

    property color batteryCritFill: "#ff8787"
    property color batteryCritBase: "#c92a2a"
    property color batteryCritText: "#491212"

    function scaleFor(screen, damping): real {
        if (!screen) return 1.0
        return 1.0
    }
}
