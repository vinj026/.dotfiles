import QtQuick
import Quickshell
import "../../../../theme"

Item {
    id: root

    required property ShellScreen screen

    implicitWidth: workspaces.implicitWidth
    implicitHeight: workspaces.implicitHeight
    anchors.verticalCenter: parent.verticalCenter

    Workspaces {
        id: workspaces
        screen: root.screen
        anchors.verticalCenter: parent.verticalCenter
    }
}
