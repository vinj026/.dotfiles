// NotifIndicator.qml — Bell icon in bar, click to toggle notif center
import QtQuick
import qs.core as C

Item {
    id: root
    implicitWidth: C.Style.icon.sm
    implicitHeight: C.Style.barHeight

    property bool hovered: false

    Text {
        anchors.centerIn: parent
        text: C.Notifications.pendingCount > 0 ? "notifications_active" : "notifications"
        font.family: C.Style.fontIcon
        font.variableAxes: ({ "FILL": 1 })
        font.pixelSize: C.Style.icon.sm
        color: C.Notifications.pendingCount > 0
            ? C.Colors.accent
            : C.Colors.text

        Behavior on color { ColorAnimation { duration: C.Style.durFast } }
    }

    // Badge count
    Rectangle {
        visible: C.Notifications.pendingCount > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.rightMargin: 2
        width: badgeText.implicitWidth + 4
        height: 12
        radius: 6
        color: C.Colors.red

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: Math.min(C.Notifications.pendingCount, 9).toString() +
                  (C.Notifications.pendingCount > 9 ? "+" : "")
            font.family: C.Style.fontMono
            font.pixelSize: C.Style.fs.sm
            font.weight: C.Style.fw.bold
            color: C.Colors.base
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: C.ShellState.toggleNotifCenter()
    }
}
