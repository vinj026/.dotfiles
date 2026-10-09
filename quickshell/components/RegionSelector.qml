import QtQuick
import Quickshell
import qs.core as C

Item {
    id: root

    property real mouseX: 0
    property real mouseY: 0
    readonly property bool pressed: mouseArea.pressed
    
    property real selectionX: 0
    property real selectionY: 0
    property real selectionWidth: 0
    property real selectionHeight: 0
    
    property real targetX: 0
    property real targetY: 0
    property real targetWidth: 0
    property real targetHeight: 0
    
    property point startPos
    property var path: []
    property point lastPathPoint: Qt.point(-1, -1)
    
    property bool ctsEnabled: true
    property bool animate: true

    signal regionSelected(real x, real y, real w, real h)
    signal rightClicked()

    anchors.fill: parent

    onSelectionXChanged: guides.requestPaint()
    onSelectionYChanged: guides.requestPaint()
    onSelectionWidthChanged: guides.requestPaint()
    onSelectionHeightChanged: guides.requestPaint()
    onMouseXChanged: guides.requestPaint()
    onMouseYChanged: guides.requestPaint()
    onPressedChanged: guides.requestPaint()

    Behavior on selectionX { enabled: root.animate; NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
    Behavior on selectionY { enabled: root.animate; NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
    Behavior on selectionWidth { enabled: root.animate; NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
    Behavior on selectionHeight { enabled: root.animate; NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

    onTargetXChanged: selectionX = targetX
    onTargetYChanged: selectionY = targetY
    onTargetWidthChanged: selectionWidth = targetWidth
    onTargetHeightChanged: selectionHeight = targetHeight

    Canvas {
        id: guides
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (mouseArea.pressed && root.ctsEnabled && root.path.length > 0) {
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                
                ctx.strokeStyle = C.Colors.alpha(C.Colors.accent, 0.4);
                ctx.lineWidth = 14;
                ctx.beginPath();
                ctx.moveTo(root.path[0].x, root.path[0].y);
                for (var i = 1; i < root.path.length; i++) {
                    ctx.lineTo(root.path[i].x, root.path[i].y);
                }
                ctx.stroke();
                
                ctx.strokeStyle = C.Colors.accent;
                ctx.lineWidth = 5;
                ctx.beginPath();
                ctx.moveTo(root.path[0].x, root.path[0].y);
                for (var j = 1; j < root.path.length; j++) {
                    ctx.lineTo(root.path[j].x, root.path[j].y);
                }
                ctx.stroke();
            } else if (mouseArea.pressed && !root.ctsEnabled) {
                ctx.fillStyle = C.Colors.alpha(C.Colors.base, 0.4);
                ctx.fillRect(root.selectionX, root.selectionY, root.selectionWidth, root.selectionHeight);
                
                ctx.strokeStyle = C.Colors.accent;
                ctx.lineWidth = 2;
                ctx.setLineDash([]);
                ctx.beginPath();
                ctx.rect(root.selectionX, root.selectionY, root.selectionWidth, root.selectionHeight);
                ctx.stroke();
            } else if (!mouseArea.pressed) {
                ctx.strokeStyle = C.Colors.alpha(C.Colors.text, 0.6);
                ctx.lineWidth = 1;
                ctx.setLineDash([4, 4]);
                ctx.beginPath();
                ctx.moveTo(root.mouseX, 0);
                ctx.lineTo(root.mouseX, height);
                ctx.moveTo(0, root.mouseY);
                ctx.lineTo(width, root.mouseY);
                ctx.stroke();
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.CrossCursor

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
                return;
            }
            root.animate = false;
            root.startPos = Qt.point(mouse.x, mouse.y);
            root.path = [Qt.point(mouse.x, mouse.y)];
            root.lastPathPoint = Qt.point(mouse.x, mouse.y);
            
            root.targetX = mouse.x;
            root.targetY = mouse.y;
            root.targetWidth = 0;
            root.targetHeight = 0;
            root.selectionX = mouse.x;
            root.selectionY = mouse.y;
            root.selectionWidth = 0;
            root.selectionHeight = 0;
        }

        onPositionChanged: (mouse) => {
            root.mouseX = mouse.x;
            root.mouseY = mouse.y;

            if (!pressed) return;

            const boundedX = Math.max(0, Math.min(mouse.x, width));
            const boundedY = Math.max(0, Math.min(mouse.y, height));

            if (root.ctsEnabled) {
                const dx = boundedX - root.lastPathPoint.x;
                const dy = boundedY - root.lastPathPoint.y;
                if (dx * dx + dy * dy > 100) {
                    root.animate = true;
                    root.path.push(Qt.point(boundedX, boundedY));
                    root.lastPathPoint = Qt.point(boundedX, boundedY);
                    
                    const minX = Math.min(root.selectionX, boundedX);
                    const minY = Math.min(root.selectionY, boundedY);
                    const maxX = Math.max(root.selectionX + root.selectionWidth, boundedX);
                    const maxY = Math.max(root.selectionY + root.selectionHeight, boundedY);
                    
                    root.targetX = minX;
                    root.targetY = minY;
                    root.targetWidth = maxX - minX;
                    root.targetHeight = maxY - minY;
                }
            } else {
                root.animate = true;
                root.targetX = Math.min(root.startPos.x, boundedX);
                root.targetY = Math.min(root.startPos.y, boundedY);
                root.targetWidth = Math.abs(boundedX - root.startPos.x);
                root.targetHeight = Math.abs(boundedY - root.startPos.y);
            }
        }

        onReleased: (mouse) => {
            if (mouse.button === Qt.RightButton) return;
            if (root.selectionWidth > 10 && root.selectionHeight > 10) {
                root.regionSelected(root.selectionX, root.selectionY, root.selectionWidth, root.selectionHeight);
            }
            root.path = [];
            guides.requestPaint();
        }
    }
}
