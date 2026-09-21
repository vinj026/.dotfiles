// AppItem.qml — Single app entry in launcher
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core as C

Rectangle {
    id: root

    property var app: null
    signal activated()

    width: parent?.width ?? 300
    height: 22
    color: "transparent"
    border.width: 0
    scale: mouseArea.pressed ? 0.98 : (mouseArea.containsMouse ? 1.02 : 1.0)
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        spacing: C.Style.sp.xs

        // App icon
        IconImage {
            id: appIcon
            source: root.app?.icon ?? ""
            width:  14
            height: 14
            anchors.verticalCenter: parent.verticalCenter
        }

        // App name (1 line)
        Text {
            text: root.app?.name ?? ""
            font.family: C.Style.fontSans
            font.pixelSize: C.Style.fs.md
            font.weight: C.Style.fw.medium
            color: mouseArea.containsMouse ? C.Colors.text : C.Colors.subtext1
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: parent.width - appIcon.width - parent.spacing
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
