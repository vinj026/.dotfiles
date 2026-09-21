// RamIndicator.qml — Interactive RAM widget for status bar
import QtQuick
import qs.core as C

Item {
    id: root
    implicitWidth: contentRow.implicitWidth
    implicitHeight: C.Style.barHeight
    height: parent.height

    property bool hovered: false

    Behavior on implicitWidth {
        NumberAnimation { duration: C.Style.durNormal; easing.type: Easing.OutCubic }
    }

    Component.onCompleted: C.DeviceStats.retain()
    Component.onDestruction: C.DeviceStats.release()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: Quickshell.execDetached(["kitty", "-e", "btop"])
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: C.Style.sp.sm

        Text {
            text: "memory"
            font.family: C.Style.fontIcon
            font.variableAxes: ({ "FILL": 1 })
            font.pixelSize: C.Style.icon.sm
            color: root.hovered ? C.Colors.accent : C.Colors.text
            anchors.verticalCenter: parent.verticalCenter
            
            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
        }

        // Interactive Text Details (Toggle between Percentage and GB usage on hover)
        Text {
            text: root.hovered 
                ? C.DeviceStats.ramUsedGb.toFixed(1) + "G/" + C.DeviceStats.ramTotalGb.toFixed(0) + "G"
                : C.DeviceStats.ramPercent.toFixed(0) + "%"
            font.family: C.Style.fontMono
            font.pixelSize: C.Style.fs.sm
            color: root.hovered ? C.Colors.accent : C.Colors.text
            anchors.verticalCenter: parent.verticalCenter
            
            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
        }
    }
}
