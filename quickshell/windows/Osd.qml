// Osd.qml — OSD Window (Volume + Brightness), centered bottom
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components.osd
import qs.core as C

PanelWindow {
    id: root

    property var focusedScreen: {
        let name = mangoService.selectedMonitor
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
    }

    screen: focusedScreen
    color:  "transparent"
    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.layer:     WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    implicitWidth:  320
    implicitHeight: 64

    anchors.left:   false
    anchors.right:  false
    anchors.top:    false
    anchors.bottom: true

    margins.bottom: 48

    OsdVolume {
        id: volOsd
        anchors.centerIn: parent
    }

    OsdBrightness {
        id: brightOsd
        anchors.centerIn: parent
    }

    OsdMic {
        id: micOsd
        anchors.centerIn: parent
    }

    Connections {
        target: C.Audio
        function onTriggered() {
            brightOsd.isActive = false
            micOsd.isActive = false
        }
        function onTriggeredMic() {
            volOsd.isActive = false
            brightOsd.isActive = false
        }
    }

    Connections {
        target: C.Brightness
        function onTriggered() {
            volOsd.isActive = false
            micOsd.isActive = false
        }
    }
}
