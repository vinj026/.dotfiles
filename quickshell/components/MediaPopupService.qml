pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    property bool isOpen: false
    property string targetMonitor: ""

    function open(monitor): void {
        if (ControlCenterService.isOpen) {
            ControlCenterService.close();
        }
        if (LauncherService.isOpen) {
            LauncherService.close();
        }
        if (typeof WallpaperSwitcherService !== "undefined" && WallpaperSwitcherService.isOpen) {
            WallpaperSwitcherService.close();
        }
        root.targetMonitor = monitor || MangoService.activeMonitor || (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        root.isOpen = true;
    }

    function close(): void {
        root.isOpen = false;
    }

    function toggle(monitor): void {
        if (root.isOpen) {
            close();
        } else {
            open(monitor);
        }
    }
}
