import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core as C
import "../../components"
import "../../shapes"

PanelWindow {
    id: root

    required property ShellScreen screen

    WlrLayershell.namespace: "search"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    
    // We only want to show the window on the monitor that requested it
    // Wait, grim captures everything. Better to show on the monitor grim captures, or all monitors?
    // QuickSnip captures the targetScreen, then shows on targetScreen.
    
    visible: SearchService.isOpen && (SearchService.targetMonitor === "" || SearchService.targetMonitor === root.screen.name)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    color: "transparent"
    
    // Dimmer background over the frozen screen
    Rectangle {
        anchors.fill: parent
        color: C.Colors.alpha(C.Colors.base, 0.4)
        opacity: SearchService.grimReady ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    
    // The frozen screenshot background
    Image {
        id: bgImage
        anchors.fill: parent
        z: -1
        source: SearchService.grimReady ? "file://" + SearchService.fullScreenshot : ""
        fillMode: Image.Stretch
        cache: false
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: SearchService.close()
    }
    
    RegionSelector {
        id: selector
        anchors.fill: parent
        ctsEnabled: true
        
        onRegionSelected: (x, y, w, h) => {
            SearchService.searchRegion(x, y, w, h)
        }
        
        onRightClicked: {
            SearchService.close()
        }
    }
    
    // Dimming effect using shader to highlight only the selected region
    // Actually, Quickshell supports ShaderEffect, but let's just use the drawn guides in RegionSelector for now,
    // which has an outer glow and looks very nice.
    
    // QR Code Result Panel
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - C.Style.sp.xl, 400)
        height: qrLayout.implicitHeight + C.Style.sp.xl
        radius: 16
        color: C.Colors.surface
        border.width: 1
        border.color: C.Colors.border
        visible: SearchService.qrResult !== ""
        
        ColumnLayout {
            id: qrLayout
            anchors.centerIn: parent
            width: parent.width - C.Style.sp.xl
            spacing: C.Style.sp.md
            
            Text {
                Layout.fillWidth: true
                text: "QR Code Detected"
                font.family: C.Style.fontSans
                font.pixelSize: 16
                font.weight: Font.Bold
                color: C.Colors.text
                horizontalAlignment: Text.AlignHCenter
            }
            
            Text {
                Layout.fillWidth: true
                text: SearchService.qrResult
                font.family: C.Style.fontMono
                font.pixelSize: 14
                color: C.Colors.accent
                wrapMode: Text.WrapAnywhere
                horizontalAlignment: Text.AlignHCenter
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: C.Style.sp.sm
                
                Rectangle {
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 32
                    radius: 16
                    color: ma1.pressed ? C.Colors.accentDim : (ma1.containsMouse ? C.Colors.alpha(C.Colors.accent, 0.8) : C.Colors.accent)
                    
                    Text {
                        anchors.centerIn: parent
                        text: SearchService.isQrUrl ? "Open URL" : "Copy Text"
                        font.family: C.Style.fontSans
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: C.Colors.base
                    }
                    
                    MouseArea {
                        id: ma1
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (SearchService.isQrUrl) {
                                Quickshell.execDetached(["xdg-open", SearchService.qrResult])
                            } else {
                                Quickshell.execDetached(["bash", "-c", `printf '%s' '${SearchService.qrResult.replace(/'/g, "'\\''")}' | wl-copy`])
                            }
                            SearchService.close()
                        }
                    }
                }
                
                Rectangle {
                    Layout.preferredWidth: 130
                    Layout.preferredHeight: 32
                    radius: 16
                    color: ma2.pressed ? C.Colors.surface85 : (ma2.containsMouse ? C.Colors.surface85 : "transparent")
                    border.width: 1
                    border.color: C.Colors.border
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Continue to Lens"
                        font.family: C.Style.fontSans
                        font.pixelSize: 13
                        color: C.Colors.text
                    }
                    
                    MouseArea {
                        id: ma2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            SearchService.sendToLens()
                        }
                    }
                }
            }
        }
    }
    
    // Loading Indicator
    Rectangle {
        anchors.centerIn: parent
        width: 120
        height: 48
        radius: 24
        color: C.Colors.surface
        visible: SearchService.isLoading
        
        RowLayout {
            anchors.centerIn: parent
            spacing: C.Style.sp.sm
            
            Text {
                text: "\ue8b6" // Search icon
                font.family: C.Style.fontIcon
                font.pixelSize: 18
                color: C.Colors.accent
                
                NumberAnimation on rotation {
                    from: 0; to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: SearchService.isLoading
                }
            }
            
            Text {
                text: "Searching..."
                font.family: C.Style.fontSans
                font.pixelSize: 14
                color: C.Colors.text
            }
        }
    }
}
