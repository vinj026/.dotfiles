import QtQuick
import Quickshell
import "../../../../../theme"
import "../../../../../components"

Item {
    id: root

    property bool active: false
    property string symbolFont: ""

    // Enter-key hold forwarded from ControlCenterSurface keyboard handling
    property bool keyHold: false

    // Heat Hold state (destructive actions require a 1.2s press-and-hold)
    property string holdTarget: ""     // "reboot" | "poweroff"
    property real holdProgress: 0
    readonly property real holdSeconds: 1.2

    property bool rebootPressed: false
    property bool powerPressed: false

    implicitWidth: 348
    implicitHeight: mainCol.implicitHeight

    onActiveChanged: {
        if (!active) {
            root.keyHold = false;
            root.cancelHold();
        }
    }

    onKeyHoldChanged: root.syncHold()

    function syncHold() {
        if (root.keyHold) { root.beginHold("poweroff"); return; }
        if (root.rebootPressed) { root.beginHold("reboot"); return; }
        if (root.powerPressed) { root.beginHold("poweroff"); return; }
        root.cancelHold();
    }

    function beginHold(target) {
        if (root.holdTarget !== target) {
            root.holdTarget = target;
            root.holdProgress = 0;
        }
    }

    function cancelHold() {
        root.holdTarget = "";
        root.holdProgress = 0;
    }

    function executeHold() {
        let target = root.holdTarget;
        root.cancelHold();
        if (target === "reboot") {
            Quickshell.execDetached(["systemctl", "reboot"]);
        } else if (target === "poweroff") {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }
        ControlCenterService.close();
    }

    Timer {
        id: holdTick
        interval: 24
        repeat: true
        running: root.holdTarget !== ""
        onTriggered: {
            root.holdProgress = Math.min(1, root.holdProgress + interval / (root.holdSeconds * 1000));
            if (root.holdProgress >= 1) root.executeHold();
        }
    }

    Column {
        id: mainCol
        width: parent.width
        spacing: 8

        // ── Safe Session Actions ──
        Text {
            font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
            text: "SESSION"
            color: Theme.textMuted
        }

        Grid {
            id: safeGrid
            width: parent.width
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            readonly property real tileW: (width - 8) / 2

            Repeater {
                model: [
                    { "icon": "\ue897", "label": "Lock Session", "sub": "loginctl lock", "cmd": ["loginctl", "lock-session"] },
                    { "icon": "\ue3a6", "label": "Suspend",      "sub": "systemctl suspend", "cmd": ["systemctl", "suspend"] }
                ]

                Rectangle {
                    id: safeTile
                    width: safeGrid.tileW
                    height: 64
                    radius: Theme.shapeCornerExtraLarge
                    color: safeMouse.pressed ? Theme.primaryContainer : Theme.surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                    readonly property var sData: modelData

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            width: 36; height: 36; radius: 18
                            anchors.verticalCenter: parent.verticalCenter
                            color: safeMouse.pressed ? Theme.primary : Theme.surfaceContainerHighest
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            Text {
                                anchors.centerIn: parent
                                font.family: root.symbolFont; font.pixelSize: 18
                                text: safeTile.sData.icon
                                color: safeMouse.pressed ? Theme.onPrimary : Theme.textPrimary
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold
                                text: safeTile.sData.label
                                color: Theme.textPrimary
                            }
                            Text {
                                font.family: Theme.fontFamily; font.pixelSize: 9
                                text: safeTile.sData.sub
                                color: Theme.textMuted
                            }
                        }
                    }

                    MouseArea {
                        id: safeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ControlCenterService.close();
                            Quickshell.execDetached(safeTile.sData.cmd);
                        }
                    }
                }
            }
        }

        // ── Destructive Actions (Heat Hold) ──
        Text {
            font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
            text: "DESTRUCTIVE · HOLD " + root.holdSeconds + "S TO CONFIRM"
            color: Theme.textMuted
        }

        Grid {
            id: destGrid
            width: parent.width
            columns: 2
            columnSpacing: 8

            readonly property real tileW: (width - 8) / 2

            Repeater {
                model: [
                    { "icon": "\ue5d5", "label": "Restart",   "target": "reboot" },
                    { "icon": "\ue8ac", "label": "Power Off", "target": "poweroff" }
                ]

                Rectangle {
                    id: destTile
                    width: destGrid.tileW
                    height: 64
                    radius: Theme.shapeCornerExtraLarge
                    clip: true
                    color: {
                        if (destTile.engaged) return Theme.errorContainer;
                        return destMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh;
                    }
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                    readonly property var dData: modelData
                    readonly property bool engaged: root.holdTarget === destTile.dData.target

                    // Heat Hold fill — fills left to right while holding
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (destTile.engaged ? root.holdProgress : 0)
                        color: Theme.error
                        opacity: 0.30
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: root.symbolFont; font.pixelSize: 20
                            text: destTile.dData.icon
                            color: Theme.error
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
                            text: destTile.engaged
                                ? ("Hold " + (Math.round((1 - root.holdProgress) * 10) / 10) + "s")
                                : destTile.dData.label
                            color: destTile.engaged ? Theme.error : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                    }

                    MouseArea {
                        id: destMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: {
                            if (destTile.dData.target === "reboot") root.rebootPressed = true;
                            else root.powerPressed = true;
                            root.syncHold();
                        }
                        onReleased: {
                            root.rebootPressed = false;
                            root.powerPressed = false;
                            root.syncHold();
                        }
                        onCanceled: {
                            root.rebootPressed = false;
                            root.powerPressed = false;
                            root.syncHold();
                        }
                    }
                }
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.family: Theme.fontFamily; font.pixelSize: 10
            text: "Hold Enter to power off · Release to cancel"
            color: Theme.textDim
        }
    }
}