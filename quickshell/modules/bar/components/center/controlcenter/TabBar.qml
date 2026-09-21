import QtQuick
import "../../../../../theme"

Item {
    id: root

    property int currentTab: 0
    property string symbolFont: ""

    signal tabSelected(int index)

    implicitWidth: 348
    implicitHeight: 40

    readonly property var tabItems: [
        { "name": "Deck",     "icon": "\ue8b8" },
        { "name": "Media",    "icon": "\ue405" },
        { "name": "Calendar", "icon": "\ue878" },
        { "name": "System",   "icon": "\ue871" },
        { "name": "Tools",    "icon": "\ue869" },
        { "name": "Power",    "icon": "\ue8ac" },
        { "name": "Style",    "icon": "\ue40e" }
    ]

    // M3 Expressive segmented chips: the selected chip grows to reveal its
    // label while the rest stay compact icon-only. No sliding pill needed —
    // the tonal fill IS the indicator.
    readonly property real expandedW: 92
    readonly property real compactW: (width - 4 - expandedW - 2 * (tabItems.length - 1)) / (tabItems.length - 1)

    Row {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 2

        Repeater {
            model: root.tabItems.length

            Rectangle {
                id: chip
                width: chip.isSelected ? root.expandedW : root.compactW
                height: parent.height
                radius: Theme.shapeCornerFull
                clip: true
                color: chip.isSelected ? Theme.secondaryContainer : "transparent"
                scale: tabMouse.pressed ? 0.92 : (tabMouse.containsMouse ? 1.06 : 1.0)

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.16, 1, 0.3, 1, 1, 1]
                    }
                }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                readonly property bool isSelected: root.currentTab === index
                readonly property var itemData: root.tabItems[index]

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: root.symbolFont
                        font.pixelSize: 14
                        text: chip.itemData.icon
                        color: chip.isSelected ? Theme.onSecondaryContainer : (tabMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: chip.isSelected ? 1.0 : 0.0
                        visible: opacity > 0.01
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        text: chip.itemData.name
                        color: Theme.onSecondaryContainer

                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    }
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.currentTab = index; root.tabSelected(index); }
                }
            }
        }
    }

    WheelHandler {
        target: null
        onWheel: event => {
            if (event.angleDelta.y < 0) {
                root.currentTab = (root.currentTab + 1) % root.tabItems.length;
                root.tabSelected(root.currentTab);
            } else if (event.angleDelta.y > 0) {
                root.currentTab = (root.currentTab - 1 + root.tabItems.length) % root.tabItems.length;
                root.tabSelected(root.currentTab);
            }
        }
    }
}
