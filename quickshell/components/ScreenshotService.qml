pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core as C

Singleton {
    id: root

    property bool isOpen: false

    function toggle() {
        isOpen = !isOpen
    }

    function open() {
        isOpen = true
    }

    function close() {
        isOpen = false
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
