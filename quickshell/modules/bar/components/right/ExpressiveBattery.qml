import QtQuick
import Quickshell
import "../../../../theme"

Item {
    id: root

    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    property int capacity: 100
    property bool isCharging: false
    property bool hasBattery: true

    readonly property int safeCapacity: Math.max(0, Math.min(100, capacity))
    readonly property bool isLow: safeCapacity <= 20

    // Dynamic Matugen semantic color tokens
    readonly property color baseColor: {
        if (root.isLow) return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.3);
        return Theme.primaryContainer;
    }

    readonly property color fillColor: {
        if (root.isLow) return Theme.error;
        return Theme.primary;
    }

    readonly property color textColor: {
        if (root.isLow) return "#410002";
        return Theme.textOnPrimary;
    }

    // Authentic compact Android 16 status bar icon dimensions (reduced length)
    implicitWidth: batteryBody.width + terminalNub.width - 0.4
    implicitHeight: batteryBody.height
    anchors.verticalCenter: parent.verticalCenter

    // Material 3 Expressive spring hover feedback
    scale: mouseArea.containsMouse ? 1.18 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animDurationNormal
            easing.type: Easing.OutBack
            easing.overshoot: Theme.springOvershootExpressive
        }
    }

    // Terminal Nub (Positive contact on right)
    Rectangle {
        id: terminalNub
        anchors.left: batteryBody.right
        anchors.leftMargin: -0.4
        anchors.verticalCenter: batteryBody.verticalCenter
        width: 1.8
        height: 4.8
        radius: 0.9
        color: root.safeCapacity >= 100 ? root.fillColor : root.baseColor
        z: 0

        Behavior on color {
            ColorAnimation { duration: Theme.animDurationNormal }
        }
    }

    // Main Battery Body (Compact Pill Container, reduced width = 22px)
    Rectangle {
        id: batteryBody
        width: 22
        height: 12
        radius: 3.2
        color: root.baseColor
        clip: true
        z: 1

        Behavior on color {
            ColorAnimation { duration: Theme.animDurationNormal }
        }

        // Fluid Level Fill Layer (Rounded Cap)
        Rectangle {
            id: fillLayer
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, Math.min(parent.width, parent.width * (root.safeCapacity / 100.0)))
            radius: batteryBody.radius
            color: root.fillColor

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animDurationLong
                    easing.type: Easing.OutBack
                    easing.overshoot: Theme.springOvershootSubtle
                }
            }

            Behavior on color {
                ColorAnimation { duration: Theme.animDurationNormal }
            }

            // Material 3 Expressive breathing pulse when charging
            SequentialAnimation on opacity {
                running: root.isCharging
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.72
                    duration: 850
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1.0
                    duration: 850
                    easing.type: Easing.InOutSine
                }
            }
        }

        // Centered Percentage Digits (Matugen dynamic typography inside icon)
        Row {
            id: labelRow
            anchors.centerIn: parent
            spacing: 0.5
            z: 2

            Text {
                visible: root.isCharging
                text: ""
                font.family: matSymbols.name
                font.pixelSize: 8
                font.weight: Font.Bold
                color: root.textColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.safeCapacity
                font.family: "Noto Sans Black"
                font.styleName: "Black"
                font.pixelSize: root.safeCapacity >= 100 ? 8 : 9
                font.weight: Font.Black
                font.bold: true
                color: root.textColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
