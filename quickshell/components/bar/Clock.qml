// Clock.qml — Monospace date + time display on a single line
import QtQuick
import Quickshell
import qs.core as C

Item {
    id: root
    implicitWidth: timeText.implicitWidth
    implicitHeight: C.Style.barHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: timeText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 2
        text: Qt.formatDateTime(clock.date, "HH:mm")
        font.family: C.Style.fontMono
        font.pixelSize: C.Style.fs.sm
        font.weight: C.Style.fw.bold
        color: C.Colors.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: C.ShellState.toggleNotifCenter()
    }
}
