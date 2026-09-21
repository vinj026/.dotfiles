// StartButton.qml — Launcher/Control Center toggle button on the left of the bar
import QtQuick
import qs.core as C

Item {
    id: root

    property string screenName: ""
    readonly property bool isActiveHere: C.ShellState.isControlCenterOpen(screenName)

    width: C.Style.barHeight
    height: parent.height

    Text {
        anchors.centerIn: parent
        text: "apps"
        font.family: C.Style.fontIcon
        font.variableAxes: ({ "FILL": 1 })
        font.pixelSize: C.Style.icon.sm
        color: isActiveHere ? C.Colors.accent : C.Colors.text

        Behavior on color { ColorAnimation { duration: C.Style.durFast } }

        // Slight scale animation on hover/click
        scale: clickArea.containsPress ? 0.90 : clickArea.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: C.Style.durMicro } }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: C.ShellState.toggleControlCenter(root.screenName)
    }
}
