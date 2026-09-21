import QtQuick
import Quickshell
import Quickshell.Services.SystemTray as SysTrayService
import "../../../../theme"

Row {
    id: root

    required property ShellScreen screen
    required property PanelWindow panel

    spacing: 8
    anchors.verticalCenter: parent.verticalCenter

    // System Tray
    Tray {
        panel: root.panel
    }

    // Divider between tray and status
    Rectangle {
        visible: SysTrayService.SystemTray.items.length > 0
        width: 3
        height: 3
        radius: 1.5
        color: Theme.outline
        anchors.verticalCenter: parent.verticalCenter
    }

    // System Status Cluster (WiFi, Volume)
    SystemStatus {}
}
