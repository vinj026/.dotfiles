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
        id: capsuleBar
        anchors.top: parent.top
        anchors.topMargin: Theme.floatingBarTopMargin
        anchors.left: parent.left
        anchors.leftMargin: Theme.floatingBarHorizontalMargin
        anchors.right: parent.right
        anchors.rightMargin: Theme.floatingBarHorizontalMargin
        height: Theme.floatingBarHeight
        radius: Theme.shapeCornerLarge
        color: Theme.surface
        opacity: 1.0
        border.color: "transparent"
        border.width: 0
        antialiasing: false
        smooth: false

        // Left Content
        LeftContent {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            screen: root.screen
        }

        // Right Content
        RightContent {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            screen: root.screen
            panel: root.panel
        }
    }
}
