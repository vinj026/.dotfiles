// ScreenshotOverlay.qml - On-demand floating screenshot overlay
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core as C
import "../components"

PanelWindow {
    id: root
    visible: ScreenshotService.isOpen
    color: "transparent"

    implicitWidth: panelContent.implicitWidth + C.Style.sp.md * 2
    implicitHeight: panelContent.implicitHeight + C.Style.sp.md * 2

    // Center or Top-Center positioning
    anchors {
        top: true
        bottom: false
        left: false
        right: false
    }

    margins {
        top: 120
    }

    // Must be overlay, and request keyboard focus to catch Escape
    WlrLayershell.keyboardFocus: ScreenshotService.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:screenshotoverlay"
    WlrLayershell.layer: WlrLayer.Overlay

    onVisibleChanged: {
        if (!visible && ScreenshotService.isOpen) {
            ScreenshotService.close()
        }
    }

    // Dismiss on Escape
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            ScreenshotService.close()
        }
    }

    Rectangle {
        id: panelContent
        anchors.centerIn: parent
        width: layout.implicitWidth + 32
        height: layout.implicitHeight + 16

        radius: 100 // Pill shape
        color: Qt.rgba(C.Theme.surfaceContainer.r, C.Theme.surfaceContainer.g, C.Theme.surfaceContainer.b, 0.90)

        // Strict anti-slop: no borders
        border.width: 0

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: 12

            Repeater {
                model: [
                    { name: "Fullscreen", icon: "\ue5d0", fn: () => ScreenshotService.takeFullscreen() },
                    { name: "Region",     icon: "\ue3e2", fn: () => ScreenshotService.takeRegion() },
                    { name: "Record",     icon: "\ue04b", fn: () => ScreenshotService.startRecording() },
                    { name: "Lens",       icon: "\ue8b6", fn: () => ScreenshotService.openLens() },
                    { name: "Color",      icon: "\ue3b8", fn: () => ScreenshotService.openColorPicker() }
                ]

                delegate: Rectangle {
                    id: btnRect
                    Layout.preferredWidth: contentLayout.implicitWidth + 24
                    Layout.preferredHeight: 36
                    radius: 18
                    color: btnMouse.pressed ? Qt.rgba(C.Theme.textPrimary.r, C.Theme.textPrimary.g, C.Theme.textPrimary.b, 0.1) : (btnMouse.containsMouse ? Qt.rgba(C.Theme.textPrimary.r, C.Theme.textPrimary.g, C.Theme.textPrimary.b, 0.05) : "transparent")
                    border.width: 0

                    RowLayout {
                        id: contentLayout
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: modelData.icon
                            font.family: "Material Icons"
                            font.pixelSize: 18
                            color: C.Theme.textPrimary
                        }
                        Text {
                            text: modelData.name
                            font.family: C.Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: C.Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: modelData.fn()
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }
}
