pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core as C

Singleton {
    id: root

    property bool isOpen: false
    property string targetMonitor: ""

    function toggle(screenName) {
        if (screenName !== undefined) {
            targetMonitor = screenName;
        } else {
            targetMonitor = "";
        }
        isOpen = !isOpen;
    }

    function open(screenName) {
        if (screenName !== undefined) {
            targetMonitor = screenName;
        } else {
            targetMonitor = "";
        }
        isOpen = true;
    }

    function close() {
        isOpen = false;
        targetMonitor = "";
    }

    function takeFullscreen() {
        close()
        Quickshell.execDetached(["/home/vin/.local/bin/screenshot.sh", "full-save"])
    }

    function takeRegion() {
        close()
        Quickshell.execDetached(["/home/vin/.local/bin/screenshot.sh", "region-save"])
    }

    function startRecording() {
        close()
        C.ShellState.runDelayedAction("start-region")
    }

    function openLens() {
        close()
        Quickshell.execDetached(["/home/vin/.local/bin/screenshot.sh", "lens"])
    }

    function openColorPicker() {
        close()
        Quickshell.execDetached(["/home/vin/.local/bin/screenshot.sh", "color"])
    }
}
