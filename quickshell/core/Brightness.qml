pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Brightness singleton — brightnessctl + IPC trigger
Singleton {
    id: root

    property int level: 0
    property int _max: 65535

    signal triggered()

    // IPC handler — called from keybind via: qs ipc call brightness trigger
    IpcHandler {
        target: "brightness"
        function trigger() {
            refreshQuery.running = true
        }
    }

    // Read max brightness once on startup
    Process {
        id: maxQuery
        command: ["sh", "-c", "cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -n1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim())
                if (!isNaN(val) && val > 0) root._max = val
            }
        }
    }

    // Refresh brightness value
    Process {
        id: refreshQuery
        command: ["sh", "-c", "cat /sys/class/backlight/*/brightness 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim())
                if (!isNaN(val)) {
                    let newLevel = Math.round((val / root._max) * 100)
                    if (newLevel !== root.level) {
                        root.level = newLevel
                        root.triggered()
                    }
                }
            }
        }
    }

    // Poll on startup
    Component.onCompleted: refreshQuery.running = true

    // Short delay timer: refresh brightness after our own brightnessctl calls
    Timer {
        id: refreshDelay
        interval: 50
        repeat: false
        onTriggered: refreshQuery.running = true
    }

    // Event-driven brightness monitoring via udev (replaces slow 1s polling loop)
    Process {
        id: udevMonitor
        command: ["stdbuf", "-oL", "udevadm", "monitor", "-k", "-s", "backlight"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.includes("change") && data.includes("backlight")) {
                    refreshQuery.running = true
                }
            }
        }
    }

    function addBrightness(delta) {
        Quickshell.execDetached(["brightnessctl", "set", (delta > 0 ? "+" : "") + Math.abs(delta) + "%"])
        refreshDelay.restart()
    }

    function setBrightness(pct) {
        let clamped = Math.max(1, Math.min(100, Math.round(pct)))
        root.level = clamped
        Quickshell.execDetached(["brightnessctl", "set", clamped + "%"])
        refreshDelay.restart()
    }

    readonly property string icon: {
        if (level < 30) return "brightness_low"
        if (level < 70) return "brightness_medium"
        return "brightness_high"
    }
}
