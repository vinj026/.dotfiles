pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    property bool isOpen: false
    property string targetMonitor: ""

    // Night Light state
    property bool nightLightEnabled: false

    // Do Not Disturb state
    property bool dndEnabled: false

    function toggle(monitor) {
        if (root.isOpen) {
            close();
        } else {
            open(monitor);
        }
    }

    function open(monitor) {
        if (LauncherService.isOpen) {
            LauncherService.close();
        }
        if (MediaPopupService.isOpen) {
            MediaPopupService.close();
        }
        if (typeof WallpaperSwitcherService !== "undefined" && WallpaperSwitcherService.isOpen) {
            WallpaperSwitcherService.close();
        }
        root.targetMonitor = monitor || MangoService.activeMonitor || (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
    }

    function toggleNightLight() {
        root.nightLightEnabled = !root.nightLightEnabled;
        if (root.nightLightEnabled) {
            Quickshell.execDetached(["bash", "-c", "wlsunset -t 4500 2>/dev/null || gammastep -O 4500 2>/dev/null || hyprsunset --temperature 4500 2>/dev/null &"]);
        } else {
            Quickshell.execDetached(["bash", "-c", "pkill wlsunset 2>/dev/null; pkill gammastep 2>/dev/null; pkill hyprsunset 2>/dev/null"]);
        }
    }

    function toggleDnd() {
        root.dndEnabled = !root.dndEnabled;
    }
}
