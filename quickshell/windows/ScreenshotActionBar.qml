// ScreenshotActionBar.qml - Floating action bar for screenshots
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

    screen: focusedScreen
    implicitWidth: panelContent.width + C.Style.sp.md * 2
    implicitHeight: panelContent.height + C.Style.sp.md * 2

    anchors {
        bottom: true
        left: false
        right: false
        top: false
    }

    margins {
        bottom: 40
    }

    WlrLayershell.keyboardFocus: WlrLayershell.OnDemand
    WlrLayershell.namespace: "quickshell:screenshotbar"
    WlrLayershell.layer: WlrLayer.Overlay

    onVisibleChanged: {
        if (!visible && ScreenshotService.isOpen) {
            ScreenshotService.close()
        }
    }

    Rectangle {
        id: panelContent
        anchors.centerIn: parent
        width: layout.implicitWidth + 32
        height: layout.implicitHeight + 16

        radius: 100 // Pill shape
        color: Qt.rgba(C.Theme.surfaceContainer.r, C.Theme.surfaceContainer.g, C.Theme.surfaceContainer.b, 0.85)

        border.width: 0

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: 8

            // Image Preview (thumbnail)
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 8
                color: "transparent"
                clip: true
                border.width: 0

                Image {
                    anchors.fill: parent
                    source: ScreenshotService.latestScreenshotPath !== "" ? "file://" + ScreenshotService.latestScreenshotPath : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }
            }

            // Separator
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                color: Qt.rgba(C.Theme.textPrimary.r, C.Theme.textPrimary.g, C.Theme.textPrimary.b, 0.1)
                border.width: 0
            }

            // Buttons
            Repeater {
                model: [
                    { name: "Fullscreen", icon: "\ue5d0", fn: () => ScreenshotService.takeFullscreen() },
                    { name: "Region", icon: "\ue3e2", fn: () => ScreenshotService.takeRegion() },
                    { name: "Record", icon: "\ue04b", fn: () => ScreenshotService.startRecording() },
                    { name: "Lens", icon: "\ue8b6", fn: () => { 
                        Quickshell.execDetached(["notify-send", "-u", "critical", "Google Lens", "Image path copied to clipboard. Paste it in the browser to upload. Be aware of sending sensitive data to Google!"]);
                        Quickshell.execDetached(["wl-copy", ScreenshotService.latestScreenshotPath]);
                        Quickshell.execDetached(["xdg-open", "https://lens.google.com/"]);
                        ScreenshotService.close();
                    }},
                    { name: "Color", icon: "\ue3b8", fn: () => {
                        Quickshell.execDetached(["notify-send", "Color Picker", "Picking a color from the captured image requires an interactive viewer or external tool which is not currently available."]);
                        ScreenshotService.close();
                    }}
                ]

                delegate: Rectangle {
                    id: btnRect
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: btnMouse.pressed ? Qt.rgba(C.Theme.textPrimary.r, C.Theme.textPrimary.g, C.Theme.textPrimary.b, 0.1) : (btnMouse.containsMouse ? Qt.rgba(C.Theme.textPrimary.r, C.Theme.textPrimary.g, C.Theme.textPrimary.b, 0.05) : "transparent")
                    border.width: 0

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.family: "Material Icons"
                        font.pixelSize: 20
                        color: C.Theme.textPrimary
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

            // Close button
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: closeMouse.pressed ? Qt.rgba(C.Theme.error.r, C.Theme.error.g, C.Theme.error.b, 0.2) : (closeMouse.containsMouse ? Qt.rgba(C.Theme.error.r, C.Theme.error.g, C.Theme.error.b, 0.1) : "transparent")
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    text: "\ue5cd"
                    font.family: "Material Icons"
                    font.pixelSize: 20
                    color: C.Theme.error
                }
                
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: ScreenshotService.close()
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
