import QtQuick
import QtQuick.Shapes
import "../theme"

Item {
    id: root

    property real centerWidth: 260
    property real centerHeight: Theme.notchHeight
    property real centerLeft: (width - centerWidth) / 2

    // Apple-style True Rounded Notch (Quarter-Circle Fillets & Vertical Walls)
    property real topRadius: 12
    property real bottomRadius: 14
    property color color: Theme.surface
    property bool isReady: false

    readonly property real w: width

    Behavior on centerLeft {
        enabled: root.isReady && root.width > 0
        NumberAnimation {
            duration: 380
            easing.type: Easing.OutBack
            easing.overshoot: 1.28
        }
    }

    Behavior on centerWidth {
        enabled: root.isReady && root.width > 0
        NumberAnimation {
            duration: 380
            easing.type: Easing.OutBack
            easing.overshoot: 1.28
        }
    }

    Behavior on centerHeight {
        NumberAnimation {
            duration: Theme.durationEmphasizedDecel
            easing.type: Easing.OutCubic
        }
    }

    function buildBarPath() {
        const w = root.w;
        const cW = root.centerWidth;
        const cH = root.centerHeight;
        const rTop = root.topRadius;
        const rBot = root.bottomRadius;
        const K = 0.55228475; // Cubic Bézier quarter-circle constant

        // Position center notch using centerLeft
        const cX = root.centerLeft;

        let p = "M " + (cX - rTop) + " 0 ";

        // 1. Top-left concave fillet: (cX - rTop, 0) -> (cX, rTop)
        p += "C " + (cX - rTop + K * rTop) + " 0, "
                  + cX + " " + (rTop - K * rTop) + ", "
                  + cX + " " + rTop + " ";

        // 2. Left vertical wall down to bottom fillet: (cX, rTop) -> (cX, cH - rBot)
        if (cH > (rTop + rBot)) {
            p += "L " + cX + " " + (cH - rBot) + " ";
        }

        // 3. Bottom-left convex fillet: (cX, cH - rBot) -> (cX + rBot, cH)
        p += "C " + cX + " " + (cH - rBot + K * rBot) + ", "
                  + (cX + rBot - K * rBot) + " " + cH + ", "
                  + (cX + rBot) + " " + cH + " ";

        // 4. Flat bottom floor: (cX + rBot, cH) -> (cX + cW - rBot, cH)
        p += "L " + (cX + cW - rBot) + " " + cH + " ";

        // 5. Bottom-right convex fillet: (cX + cW - rBot, cH) -> (cX + cW, cH - rBot)
        p += "C " + (cX + cW - rBot + K * rBot) + " " + cH + ", "
                  + (cX + cW) + " " + (cH - rBot + K * rBot) + ", "
                  + (cX + cW) + " " + (cH - rBot) + " ";

        // 6. Right vertical wall up to top fillet: (cX + cW, cH - rBot) -> (cX + cW, rTop)
        if (cH > (rTop + rBot)) {
            p += "L " + (cX + cW) + " " + rTop + " ";
        }

        // 7. Top-right concave fillet: (cX + cW, rTop) -> (cX + cW + rTop, 0)
        p += "C " + (cX + cW) + " " + (rTop - K * rTop) + ", "
                  + (cX + cW + rTop - K * rTop) + " 0, "
                  + (cX + cW + rTop) + " 0 ";

        // 8. Close along top bezel
        p += "L " + (cX - rTop) + " 0 Z";
        return p;
    }

    Shape {
        id: barShape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0

            PathSvg {
                path: root.buildBarPath()
            }
        }
    }
}
