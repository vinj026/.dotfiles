import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core as C
import "../../../../components"
import "../../../shapes"
import "../../../theme"

Item {
    id: root

    property bool active: false
    
    // Explicit dimensions so NotchBarView can bind to them!
    implicitWidth: layout.implicitWidth + C.Style.sp.xl * 2
    implicitHeight: layout.implicitHeight + C.Style.sp.md * 2

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: C.Style.sp.sm

        Repeater {
            model: [
                { name: "Fullscreen", icon: "\ue5d0", fn: () => ScreenshotService.takeFullscreen() },
                { name: "Region",     icon: "\ue3e2", fn: () => ScreenshotService.takeRegion() },
                { name: "Record",     icon: "\ue04b", fn: () => ScreenshotService.startRecording() },
                { name: "Lens",       icon: "\ue8b6", fn: () => ScreenshotService.openLens() },
                { name: "Color",      icon: "\ue3b8", fn: () => ScreenshotService.openColorPicker() }
            ]

            delegate: Rectangle {
                Layout.preferredWidth: row.implicitWidth + C.Style.sp.lg
                Layout.preferredHeight: 32
                radius: 16
                color: ma.pressed
                    ? C.Colors.alpha(C.Colors.text, 0.12)
                    : ma.containsMouse
                        ? C.Colors.alpha(C.Colors.text, 0.06)
                        : "transparent"
                border.width: 0

                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: C.Style.sp.xs

                    Text {
                        text: modelData.icon
                        font.family: C.Style.fontIcon
                        font.pixelSize: 16
                        color: C.Colors.text
                    }
                    Text {
                        text: modelData.name
                        font.family: C.Style.fontSans
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: C.Colors.text
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.fn()
                }
            }
        }
    }
}
