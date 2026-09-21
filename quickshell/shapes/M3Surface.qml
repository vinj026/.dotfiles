import QtQuick
import QtQuick.Shapes
import "../theme"

// ────────────────────────────────────────────────────────────────────────────
// M3Surface — Material 3 docked surface shape.
// A full-bleed rounded-bottom "surface that grows from the top edge":
//   * square top corners (flush against the screen edge, y = 0)
//   * rounded bottom corners following the surface's shape token
// Used by the Dynamic Island so the rest pill and the expanded launcher /
// control-center surfaces are ONE continuously-morphing element.
// ────────────────────────────────────────────────────────────────────────────
Item {
    id: root
    anchors.fill: parent

    property real bottomRadius: 14
    property color color: Theme.surface

    Behavior on bottomRadius {
        NumberAnimation {
            duration: 350
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.16, 1, 0.3, 1, 1, 1]
        }
    }

    function buildPath() {
        const w = root.width;
        const h = root.height;
        const r = Math.max(0, Math.min(root.bottomRadius, h / 2, w / 2));
        const K = 0.55228475; // Cubic Bézier quarter-circle constant

        let p = "M 0 0 ";
        // Top edge (flush, square corners)
        p += "L " + w + " 0 ";
        // Right vertical wall down to bottom fillet
        p += "L " + w + " " + (h - r) + " ";
        // Bottom-right convex fillet: (w, h-r) -> (w-r, h)
        p += "C " + w + " " + (h - r + K * r) + ", "
                  + (w - r + K * r) + " " + h + ", "
                  + (w - r) + " " + h + " ";
        // Bottom edge (leftwards)
        p += "L " + r + " " + h + " ";
        // Bottom-left convex fillet: (r, h) -> (0, h-r)
        p += "C " + (r - K * r) + " " + h + ", "
                  + "0 " + (h - r + K * r) + ", "
                  + "0 " + (h - r) + " ";
        // Left vertical wall back up
        p += "L 0 0 Z";
        return p;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        smooth: true
        antialiasing: true

        layer.enabled: true
        layer.samples: 8
        layer.smooth: true

        ShapePath {
            fillColor: root.color
            strokeColor: root.color
            strokeWidth: 1.0
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            PathSvg {
                path: root.buildPath()
            }
        }
    }
}