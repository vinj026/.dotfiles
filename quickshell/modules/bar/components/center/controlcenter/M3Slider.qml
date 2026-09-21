import QtQuick
import "../../../../../theme"

Item {
    id: sliderRoot

    property real value: 0.0
    property string icon: ""
    property string mutedIcon: ""
    property bool isMuted: false
    property color activeColor: isMuted ? Theme.error : Theme.primary
    property string symbolFont: ""

    signal moved(real val)
    signal iconClicked()

    implicitWidth: 348
    implicitHeight: 44

    readonly property real clampedVal: Math.max(0.0, Math.min(1.0, isMuted ? 0.0 : value))

    // Track Background
    Rectangle {
        id: bgTrack
        anchors.fill: parent
        radius: Theme.shapeCornerMedium
        color: Theme.surfaceContainerHigh
        clip: true
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

        // Fill progress
        Rectangle {
            id: fillTrack
            x: 0; y: 0
            width: Math.max(0, bgTrack.width * sliderRoot.clampedVal)
            height: parent.height
            radius: Theme.shapeCornerMedium
            color: sliderRoot.activeColor
            Behavior on width {
                enabled: !sliderMouse.pressed
                NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
            }
            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        }
    }

    // Leading Icon
    Item {
        id: iconItem
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 28; height: 28
        z: 5

        readonly property bool isCovered: (bgTrack.width * sliderRoot.clampedVal) > 36

        Rectangle {
            anchors.fill: parent; radius: 14
            color: "transparent"
            scale: iconMouse.pressed ? 0.88 : (iconMouse.containsMouse ? 1.10 : 1.0)
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        }

        Text {
            anchors.centerIn: parent
            font.family: sliderRoot.symbolFont; font.pixelSize: 18
            text: (sliderRoot.isMuted && sliderRoot.mutedIcon) ? sliderRoot.mutedIcon : sliderRoot.icon
            color: sliderRoot.isMuted ? Theme.error : (iconItem.isCovered ? Theme.textOnPrimary : Theme.textPrimary)
            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        }

        MouseArea {
            id: iconMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: sliderRoot.iconClicked()
        }
    }

    // Trailing value
    Item {
        anchors.right: parent.right; anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height; width: valText.implicitWidth + 4
        z: 5

        readonly property bool isCovered: (bgTrack.width * sliderRoot.clampedVal) > (sliderRoot.width - 50)

        Text {
            id: valText
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
            color: sliderRoot.isMuted ? Theme.error : (parent.isCovered ? Theme.textOnPrimary : Theme.textPrimary)
            text: Math.round(sliderRoot.clampedVal * 100) + "%"
            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        }
    }

    // Balloon tooltip on drag
    Item {
        id: tooltipBubble
        x: Math.max(0, Math.min(sliderRoot.width - width, (bgTrack.width * sliderRoot.clampedVal) - width / 2))
        y: -26; width: Math.max(36, tipTxt.implicitWidth + 14); height: 22; z: 20
        opacity: sliderMouse.pressed ? 1.0 : 0.0
        scale: sliderMouse.pressed ? 1.0 : 0.6
        Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

        Rectangle {
            anchors.fill: parent; radius: 6; color: sliderRoot.activeColor
            Rectangle {
                width: 6; height: 6; rotation: 45; color: sliderRoot.activeColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom; anchors.bottomMargin: -2
            }
            Text {
                id: tipTxt; anchors.centerIn: parent
                font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
                color: Theme.textOnPrimary
                text: Math.round(sliderRoot.clampedVal * 100) + "%"
            }
        }
    }

    // Interactive area (skip the icon zone)
    MouseArea {
        id: sliderMouse
        anchors.fill: parent; anchors.leftMargin: 42
        hoverEnabled: true; cursorShape: Qt.PointingHandCursor

        function updateFromMouse(mx) {
            let actualX = mx + anchors.leftMargin;
            sliderRoot.moved(Math.max(0.0, Math.min(1.0, actualX / sliderRoot.width)));
        }

        onPressed: mouse => updateFromMouse(mouse.x)
        onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse.x); }
        onWheel: wheel => {
            let delta = wheel.angleDelta.y > 0 ? 0.04 : -0.04;
            sliderRoot.moved(Math.max(0.0, Math.min(1.0, sliderRoot.value + delta)));
        }
    }
}
