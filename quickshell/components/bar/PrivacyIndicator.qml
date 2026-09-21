// PrivacyIndicator.qml — Android-style privacy indicator (Green dot, expands to a beautiful green pill on hover)
import QtQuick
import qs.core as C

Item {
    id: root

    readonly property bool camActive: C.Audio.camActive
    readonly property bool micActive: C.Audio.micActive && !C.Audio.micMuted
    readonly property bool anyActive: camActive || micActive
    readonly property bool testMode: C.Style._raw.testPrivacy === true
    
    readonly property bool isCamActive: camActive || testMode
    readonly property bool isMicActive: micActive || testMode
    readonly property bool isAnyActive: isCamActive || isMicActive

    visible: isAnyActive
    
    // Dynamic dimensions
    readonly property bool isExpanded: hoverArea.containsMouse
    
    implicitWidth: visible ? (isExpanded ? (iconsRow.implicitWidth + 16) : 8) : 0
    implicitHeight: C.Style.barHeight

    Behavior on implicitWidth {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // The Pill Container
    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right // Lock to the right side
        // Animate dimensions and colors
        width: root.isExpanded ? (iconsRow.implicitWidth + 16) : 8
        height: root.isExpanded ? 20 : 8
        radius: height / 2
        
        // Soft light green background when expanded, solid warning green when collapsed
        color: root.isExpanded ? C.Colors.alpha(C.Colors.green, 0.3) : C.Colors.green
        
        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 200 } }

        // Pulsing opacity animation (only when collapsed)
        SequentialAnimation {
            id: pulseAnim
            loops: Animation.Infinite
            running: root.visible && !root.isExpanded
            
            NumberAnimation { target: pill; property: "opacity"; from: 1.0; to: 0.4; duration: 900; easing.type: Easing.InOutSine }
            
            onStopped: pill.opacity = 1.0
        }

        // Icons Row (shown inside the pill when expanded)
        Row {
            id: iconsRow
            anchors.centerIn: parent
            spacing: 6
            opacity: root.isExpanded ? 1.0 : 0.0
            scale: root.isExpanded ? 1.0 : 0.6
            clip: true

            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

            Text {
                visible: root.isCamActive
                text: "videocam"
                font.family: C.Style.fontIcon
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: "#064E3B" // Dark green
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: root.isMicActive
                text: "mic"
                font.family: C.Style.fontIcon
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: "#064E3B" // Dark green
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
