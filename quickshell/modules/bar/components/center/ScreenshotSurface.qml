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
    implicitHeight: 30

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: C.Style.sp.xs

        // If recording, show only the Stop button
        Repeater {
            model: ScreenRecordService.isRecording ? [
                { name: "Stop Recording", icon: "\ue04b", fn: () => ScreenRecordService.stopRecording(), isStop: true }
            ] : [
                { name: "Fullscreen", icon: "\ue5d0", fn: () => ScreenshotService.takeFullscreen(), isStop: false },
                { name: "Region",     icon: "\ue3e2", fn: () => ScreenshotService.takeRegion(), isStop: false },
                { name: "Record",     icon: "\ue04b", fn: () => ScreenshotService.startRecording(), isStop: false },
                { name: "Lens",       icon: "\ue8b6", fn: () => ScreenshotService.openLens(), isStop: false },
                { name: "Color",      icon: "\ue3b8", fn: () => ScreenshotService.openColorPicker(), isStop: false }
            ]

            delegate: Rectangle {
                Layout.preferredWidth: row.implicitWidth + C.Style.sp.md
                Layout.preferredHeight: 26
                radius: 13
                color: modelData.isStop 
                    ? (ma.pressed ? C.Colors.alpha(C.Colors.red, 0.8) : (ma.containsMouse ? C.Colors.red : C.Colors.alpha(C.Colors.red, 0.9)))
                    : (ma.pressed ? C.Colors.alpha(C.Colors.text, 0.12) : (ma.containsMouse ? C.Colors.alpha(C.Colors.text, 0.06) : "transparent"))
                border.width: 0

                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: modelData.icon
                        font.family: C.Style.fontIcon
                        font.pixelSize: 14
                        color: modelData.isStop ? C.Colors.base : C.Colors.text
                    }
                    Text {
                        text: modelData.name + (modelData.isStop ? " (" + ScreenRecordService.recordingTimeStr + ")" : "")
                        font.family: C.Style.fontSans
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: modelData.isStop ? C.Colors.base : C.Colors.text
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        modelData.fn()
                        if (modelData.isStop) ScreenshotService.close()
                    }
                }
            }
        }
    }
}
