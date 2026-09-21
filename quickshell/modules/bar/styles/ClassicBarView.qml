import QtQuick
import Quickshell
import "../components/left"
import "../components/right"
import "../../../theme"

Item {
    id: root

    required property ShellScreen screen
    required property PanelWindow panel

    Rectangle {
        id: fullBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.classicBarHeight
        color: Theme.surface
        opacity: 0.94

        // Bottom subtle border
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.outline
            opacity: 0.6
        }

        // Left Content
        LeftContent {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            screen: root.screen
        }

        // Right Content
        RightContent {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            screen: root.screen
            panel: root.panel
        }
    }
}
