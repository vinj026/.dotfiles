import QtQuick
import Quickshell
import "../../../../theme"

Item {
    id: root

    property bool isHovered: false
    property bool is24Hour: false
    property var currentDate: new Date()

    function formatTime(date, is24) {
        let m = date.getMinutes();
        let mStr = (m < 10 ? "0" : "") + m;
        if (is24) {
            let h = date.getHours();
            let hStr = (h < 10 ? "0" : "") + h;
            return hStr + ":" + mStr;
        } else {
            let h = date.getHours() % 12;
            if (h === 0) h = 12;
            let hStr = (h < 10 ? "0" : "") + h;
            return hStr + ":" + mStr;
        }
    }

    function formatAmPm(date) {
        return date.getHours() >= 12 ? "PM" : "AM";
    }

    implicitHeight: 22
    implicitWidth: contentRow.implicitWidth + 16

    scale: root.isHovered ? 1.05 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animDurationNormal
            easing.type: Easing.OutBack
            easing.overshoot: Theme.springOvershootSubtle
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animDurationMedium
            easing.type: Easing.OutCubic
        }
    }

    // Material 3 State Layer
    Rectangle {
        id: stateLayer
        anchors.fill: parent
        radius: Theme.shapeCornerSmall
        color: Theme.textPrimary
        opacity: {
            if (mouseArea.pressed) return 0.12;
            if (root.isHovered) return 0.08;
            return 0.0;
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.animDurationFast }
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        // Expandable Date (Reveals smoothly on hover)
        Item {
            id: dateSection
            clip: true
            implicitHeight: dateRow.implicitHeight
            height: implicitHeight
            implicitWidth: root.isHovered ? dateRow.implicitWidth : 0
            width: implicitWidth
            opacity: root.isHovered ? 1.0 : 0.0
            anchors.verticalCenter: parent.verticalCenter

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Theme.animDurationNormal
                    easing.type: Easing.OutExpo
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animDurationFast
                    easing.type: Easing.OutQuad
                }
            }

            Row {
                id: dateRow
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: Qt.formatDateTime(root.currentDate, "ddd, d MMM")
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    color: Theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "•"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Bold Time Digits (Nebula / Material 3 primary emphasis)
        Text {
            id: timeText
            text: root.formatTime(root.currentDate, root.is24Hour)
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        // AM / PM Label (12h format)
        Text {
            visible: !root.is24Hour
            text: root.formatAmPm(root.currentDate)
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.weight: Font.DemiBold
            color: Theme.textMuted
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.isHovered = true
        onExited: root.isHovered = false
        onClicked: root.is24Hour = !root.is24Hour
    }
}
