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
        command: ["cat", "/sys/class/backlight/amdgpu_bl2/max_brightness"]
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
        command: ["cat", "/sys/class/backlight/amdgpu_bl2/brightness"]
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

    // Slow background poll every 5s as fallback
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: refreshQuery.running = true
    }

    function addBrightness(delta) {
        Quickshell.execDetached(["brightnessctl", "set", (delta > 0 ? "+" : "") + Math.abs(delta) + "%"])
    }

    function setBrightness(pct) {
        let clamped = Math.max(1, Math.min(100, Math.round(pct)))
        root.level = clamped
        Quickshell.execDetached(["brightnessctl", "set", clamped + "%"])
    }

    readonly property string icon: {
        if (level < 30) return "brightness_low"
        if (level < 70) return "brightness_medium"
        return "brightness_high"
    }
}
