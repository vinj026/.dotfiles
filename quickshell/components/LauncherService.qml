pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    property bool isOpen: false
    property string targetMonitor: ""

    readonly property real launcherWidth: 250
    readonly property real launcherHeight: 182

    function toggle() {
        if (root.isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        if (ControlCenterService.isOpen) {
            ControlCenterService.close();
        }
        if (MediaPopupService.isOpen) {
            MediaPopupService.close();
        }
        if (typeof WallpaperSwitcherService !== "undefined" && WallpaperSwitcherService.isOpen) {
            WallpaperSwitcherService.close();
        }
        root.targetMonitor = MangoService.activeMonitor || (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
    }
}
