pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core as C

Singleton {
    id: root

    property bool isOpen: false
    property string latestScreenshotPath: ""

    function open(filePath) {
        latestScreenshotPath = filePath
        isOpen = true
    }

    function close() {
        isOpen = false
    }

    function takeFullscreen() {
        close()
        C.ShellState.runDelayedAction("ss-full")
    }

    function takeRegion() {
        close()
        C.ShellState.runDelayedAction("ss-region")
    }

    function startRecording() {
        close()
        C.ShellState.runDelayedAction("start-region")
    }
}
