// Tray.qml — System tray icons
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.core as C

Item {
    id: root

    implicitWidth: trayRow.implicitWidth
    implicitHeight: C.Style.barHeight

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: C.Style.sp.xs

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem

                required property SystemTrayItem modelData
                implicitWidth:  C.Style.icon.sm
                implicitHeight: C.Style.barHeight

                opacity: trayMouse.containsMouse ? 1.0 : 0.7
                Behavior on opacity { NumberAnimation { duration: C.Style.durFast } }

                Image {
                    source: trayItem.modelData.icon
                    anchors.centerIn: parent
                    width:  C.Style.icon.sm
                    height: C.Style.icon.sm
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            trayItem.modelData.activate()
                        else
                            trayItem.modelData.secondaryActivate()
                    }
                }
            }
        }
    }
}
