import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../theme"
import "../../../../components"

Item {
    id: root
    implicitHeight: 14
    implicitWidth: batteryBody.width + (root.isCharging ? (boltCanvas.width + 4.5) : (terminalNub.width + 2.0))
    width: implicitWidth
    height: implicitHeight
    visible: root.hasBattery

    // Reactive Properties
    property int capacity: 0
    property bool isCharging: false
    property bool hasBattery: true

    readonly property int safeCapacity: Math.max(0, Math.min(100, root.capacity))
    readonly property bool isLow: safeCapacity <= 20

    // Palette strictly matching reference screenshot & user preferences
    readonly property color greenColor: "#6fdd86" // User's requested charging color
    readonly property color redColor: Theme.error
    readonly property color normalFillColor: Theme.textPrimary
    readonly property color darkTextColor: Theme.bgBase
    readonly property color trackColor: Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.38)

    readonly property color fillColor: {
        if (root.isCharging) return root.greenColor;
        if (root.isLow) return root.redColor;
        return root.normalFillColor;
    }

    // Direct battery query process
    Process {
        id: batProc
        command: ["bash", "-c", "if [ -d /sys/class/power_supply/BAT1 ]; then echo \"$(cat /sys/class/power_supply/BAT1/capacity):$(cat /sys/class/power_supply/BAT1/status)\"; elif [ -d /sys/class/power_supply/BAT0 ]; then echo \"$(cat /sys/class/power_supply/BAT0/capacity):$(cat /sys/class/power_supply/BAT0/status)\"; else echo \"none\"; fi"]
        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim();
                if (trimmed && trimmed !== "none") {
                    root.hasBattery = true;
                    let parts = trimmed.split(":");
                    root.capacity = parseInt(parts[0]) || 0;
                    root.isCharging = (parts[1] === "Charging");
                } else {
                    root.hasBattery = false;
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batProc.running = true;
        }
    }

    scale: batMouse.containsMouse ? (batMouse.pressed ? 0.94 : 1.08) : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animDurationNormal
            easing.type: Easing.OutBack
            easing.overshoot: Theme.springOvershootExpressive
        }
    }

    // Animated fill fraction with Material 3 Expressive spring
    property real fillFraction: root.safeCapacity / 100.0
    Behavior on fillFraction {
        NumberAnimation {
            duration: Theme.animDurationLong
            easing.type: Easing.OutBack
            easing.overshoot: Theme.springOvershootSubtle
        }
    }

    onFillFractionChanged: batteryCanvas.requestPaint()
    onFillColorChanged: batteryCanvas.requestPaint()
    onTrackColorChanged: batteryCanvas.requestPaint()

    // Battery Body Canvas (Shortened: 24px x 14px, radius 3.5px)
    Item {
        id: batteryBody
        width: root.safeCapacity >= 100 ? 28 : 24
        height: 14
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Behavior on width {
            NumberAnimation {
                duration: Theme.animDurationFast
                easing.type: Easing.OutQuad
            }
        }

        onWidthChanged: batteryCanvas.requestPaint()

        Canvas {
            id: batteryCanvas
            anchors.fill: parent

            function drawPillPath(ctx, w, h, r) {
                ctx.beginPath();
                ctx.moveTo(r, 0);
                ctx.lineTo(w - r, 0);
                ctx.arcTo(w, 0, w, r, r);
                ctx.lineTo(w, h - r);
                ctx.arcTo(w, h, w - r, h, r);
                ctx.lineTo(r, h);
                ctx.arcTo(0, h, 0, h - r, r);
                ctx.lineTo(0, r);
                ctx.arcTo(0, 0, r, 0, r);
                ctx.closePath();
            }

            onPaint: {
                let ctx = getContext("2d");
                ctx.reset();

                let w = width;
                let h = height;
                let r = 3.5;

                // 1. Draw rounded outer track
                drawPillPath(ctx, w, h, r);
                ctx.fillStyle = root.trackColor;
                ctx.fill();

                // 2. Clip strictly to the rounded pill
                ctx.save();
                drawPillPath(ctx, w, h, r);
                ctx.clip();

                // 3. Draw fill layer with vertical divider cut
                let fillW = Math.max(0, Math.min(w, w * root.fillFraction));
                if (fillW > 0) {
                    ctx.fillStyle = root.fillColor;
                    ctx.fillRect(0, 0, fillW, h);
                }

                ctx.restore();
            }
        }

        // Crisp Numerals centered within the pill
        Text {
            id: capacityLabel
            text: root.safeCapacity
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -0.5
            font.family: Theme.fontFamily
            font.pixelSize: root.safeCapacity >= 100 ? 9.0 : 11.0
            font.weight: Font.Bold
            color: root.darkTextColor
            z: 2
        }
    }

    // Terminal Nub (Visible when not charging)
    Rectangle {
        id: terminalNub
        visible: !root.isCharging
        anchors.left: batteryBody.right
        anchors.leftMargin: 1.5
        anchors.verticalCenter: batteryBody.verticalCenter
        width: 1.8
        height: 5.5
        radius: 0.9
        color: root.trackColor
    }

    // Vector Charging Lightning Bolt (Visible when charging)
    Canvas {
        id: boltCanvas
        visible: root.isCharging
        anchors.left: batteryBody.right
        anchors.leftMargin: 3.5
        anchors.verticalCenter: batteryBody.verticalCenter
        width: 7
        height: 12

        onPaint: {
            let ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "#ffffff";
            ctx.beginPath();
            ctx.moveTo(4.5, 0);
            ctx.lineTo(0.5, 6.0);
            ctx.lineTo(3.8, 6.0);
            ctx.lineTo(2.0, 12.0);
            ctx.lineTo(7.0, 5.0);
            ctx.lineTo(3.8, 5.0);
            ctx.closePath();
            ctx.fill();
        }

        SequentialAnimation on opacity {
            running: root.isCharging
            loops: Animation.Infinite
            NumberAnimation { to: 0.50; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
        }
    }

    MouseArea {
        id: batMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            batProc.running = true;
            ControlCenterService.toggle(Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        }
    }
}
