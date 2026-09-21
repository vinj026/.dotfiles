pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../../../theme"

Row {
    id: root

    required property PanelWindow panel

    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Repeater {
        model: SystemTray.items

        Rectangle {
            id: trayContainer

            required property var modelData

            width: 18
            height: 18
            radius: 9
            color: "transparent"
            scale: mouseArea.pressed ? 0.90 : (mouseArea.containsMouse ? 1.18 : 1.0)

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animDurationNormal
                    easing.type: Easing.OutBack
                    easing.overshoot: Theme.springOvershootExpressive
                }
            }

            Image {
                anchors.centerIn: parent
                width: 13
                height: 13
                source: trayContainer.modelData.icon
                fillMode: Image.PreserveAspectFit
                opacity: mouseArea.containsMouse ? 1.0 : 0.85
                Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        trayContainer.modelData.activate();
                    } else if (mouse.button === Qt.RightButton) {
                        let pos = mapToItem(null, mouse.x, mouse.y);
                        trayContainer.modelData.display(root.panel, pos.x, pos.y);
                    }
                }
            }
        }
    }
}
