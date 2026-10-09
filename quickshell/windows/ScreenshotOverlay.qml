// ScreenshotOverlay.qml — On-demand floating screenshot overlay
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core as C
import "../components"

PanelWindow {
    id: root

    visible: ScreenshotService.isOpen
    color: "transparent"

    implicitWidth: panelContent.width + C.Style.sp.xl * 2
    implicitHeight: panelContent.height + C.Style.sp.xl * 2

    anchors {
        top: true
        bottom: false
        left: false
        right: false
    }

    margins {
        top: 120
    }

    WlrLayershell.keyboardFocus: ScreenshotService.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:screenshotoverlay"
    WlrLayershell.layer: WlrLayer.Overlay

    onVisibleChanged: {
        if (!visible && ScreenshotService.isOpen)
            ScreenshotService.close()
    }

    // Escape to dismiss
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ScreenshotService.close()
    }

    Rectangle {
        id: panelContent
        anchors.centerIn: parent
        width: layout.implicitWidth + C.Style.sp.xl4
        height: layout.implicitHeight + C.Style.sp.xl

        radius: height / 2
        color: C.Colors.overlay85
        border.width: 0

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
                    Layout.preferredWidth: row.implicitWidth + C.Style.sp.xl
                    Layout.preferredHeight: 36
                    radius: 18
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
                            font.pixelSize: 18
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
}
