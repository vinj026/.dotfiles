pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core" as Core

Singleton {
    id: root

    property string activePopup: ""
    property string targetMonitor: ""

    readonly property bool isOpen: activePopup === "battery" || activePopup === "wifi" || activePopup === "controlcenter"

    // Night Light state
    property bool nightLightEnabled: false

    // Do Not Disturb state
    property bool dndEnabled: false

    function togglePopup(name, monitor) {
        if (root.activePopup === name) {
            closePopup();
        } else {
            openPopup(name, monitor);
        }
    }

    function openPopup(name, monitor) {
        if (LauncherService.isOpen) {
            LauncherService.close();
        }
        if (typeof WallpaperSwitcherService !== "undefined" && WallpaperSwitcherService.isOpen) {
            WallpaperSwitcherService.close();
        }
        root.targetMonitor = monitor || MangoService.activeMonitor || (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        root.activePopup = name;

        if (name === "battery" || name === "controlcenter") {
            Core.Battery.refreshProfile();
            Core.Battery.refreshChargeType();
            IdeapadService.refresh();
            RgbService.refresh();
        } else if (name === "wifi") {
            Core.Network.refreshAll();
            Core.Network.rescan();
        }
    }

    function closePopup() {
        root.activePopup = "";
    }

    function toggle(monitor) {
        togglePopup("battery", monitor);
    }

    function open(monitor) {
        openPopup("battery", monitor);
    }

    function close() {
        closePopup();
    }

    function toggleNightLight() {
        root.nightLightEnabled = !root.nightLightEnabled;
        if (root.nightLightEnabled) {
            Quickshell.execDetached(["bash", "-c", "wlsunset -t 4500 -T 4501 2>/dev/null || $HOME/.local/bin/wlsunset -t 4500 -T 4501 2>/dev/null &"]);
        } else {
            Quickshell.execDetached(["bash", "-c", "pkill -x wlsunset 2>/dev/null; pkill -x gammastep 2>/dev/null"]);
        }
    }

    Process {
        id: wlsunsetCheck
        command: ["pgrep", "-x", "wlsunset"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.nightLightEnabled = (text.trim().length > 0);
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: if (!wlsunsetCheck.running) wlsunsetCheck.running = true
    }

    function toggleDnd() {
        root.dndEnabled = !root.dndEnabled;
    }
}
