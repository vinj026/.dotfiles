pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isVisible: false
    property string mode: "volume" // "volume" | "brightness"
    property real level: 0.50       // 0.0 to 1.0 (strictly capped at 1.0)
    property bool isMuted: false

    property bool initialized: false
    property real lastVolume: -1
    property var lastMuted: null
    property bool forceNextVolShow: false

    Timer {
        id: hideTimer
        interval: 1800
        repeat: false
        onTriggered: {
            root.isVisible = false;
        }
    }

    function showVolume(newLevel: real, muted: bool): void {
        root.mode = "volume";
        root.level = Math.max(0.0, Math.min(1.0, newLevel));
        root.isMuted = muted;
        root.isVisible = true;
        hideTimer.restart();
    }

    function showBrightness(newLevel: real): void {
        root.mode = "brightness";
        root.level = Math.max(0.0, Math.min(1.0, newLevel));
        root.isVisible = true;
        hideTimer.restart();
    }

    function triggerVolume(): void {
        root.forceNextVolShow = true;
        volQueryProc.running = true;
    }

    function triggerBrightness(): void {
        brightQueryProc.running = true;
    }

    function setInteractiveLevel(targetVal: real): void {
        let clamped = Math.max(0.0, Math.min(1.0, targetVal));
        root.level = clamped;
        hideTimer.restart();

        if (root.mode === "volume") {
            root.isMuted = false;
            root.lastVolume = clamped;
            root.lastMuted = false;
            Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", clamped.toFixed(2)]);
        } else {
            let pct = Math.max(5, Math.round(clamped * 100));
            Quickshell.execDetached(["brightnessctl", "set", pct + "%"]);
        }
    }

    // Volume query via wpctl
    Process {
        id: volQueryProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim();
                let match = trimmed.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/);
                if (match) {
                    let vol = parseFloat(match[1]) || 0;
                    let muted = (match[2] !== undefined && match[2].length > 0);

                    // Strictly clamp to 1.0 (100%)
                    if (vol > 1.0) {
                        vol = 1.0;
                        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "1.0"]);
                    }

                    if (root.lastVolume === -1) {
                        // First run / init
                        root.lastVolume = vol;
                        root.lastMuted = muted;
                        root.level = vol;
                        root.isMuted = muted;
                        root.initialized = true;
                        return;
                    }

                    // Only show OSD if volume or mute state actually changed!
                    let volDiff = Math.abs(vol - root.lastVolume);
                    let muteChanged = (muted !== root.lastMuted);

                    if (root.forceNextVolShow || volDiff > 0.005 || muteChanged) {
                        root.forceNextVolShow = false;
                        root.lastVolume = vol;
                        root.lastMuted = muted;
                        root.showVolume(vol, muted);
                    }
                }
            }
        }
    }

    // Real-time pactl subscribe for volume events
    Process {
        id: volWatcher
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                // Ignore sink-input (audio playback streams) and client events
                if (data.includes("sink-input") || data.includes("client")) return;
                // Only trigger if an actual change occurred on sink
                if (data.includes("change") && data.includes("sink")) {
                    volQueryProc.running = true;
                }
            }
        }
    }

    // Brightness query via brightnessctl
    Process {
        id: brightQueryProc
        command: ["bash", "-c", "brightnessctl -m"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(",");
                if (parts.length >= 4) {
                    let pctStr = parts[3].replace("%", "");
                    let pct = (parseFloat(pctStr) || 0) / 100.0;
                    pct = Math.max(0.0, Math.min(1.0, pct));
                    if (!root.initialized) {
                        root.initialized = true;
                    } else {
                        root.showBrightness(pct);
                    }
                }
            }
        }
    }

    // Sysfs Brightness File Watcher / Poller
    property real lastBrightness: -1
    Timer {
        id: brightPollTimer
        interval: 200
        repeat: true
        running: true
        onTriggered: {
            brightCheckProc.running = true;
        }
    }

    Process {
        id: brightCheckProc
        command: ["bash", "-c", "cat /sys/class/backlight/amdgpu_bl2/actual_brightness 2>/dev/null || cat /sys/class/backlight/*/actual_brightness 2>/dev/null | head -n1"]
        stdout: SplitParser {
            onRead: data => {
                let val = parseInt(data.trim());
                if (!isNaN(val)) {
                    if (root.lastBrightness === -1) {
                        root.lastBrightness = val;
                        root.initialized = true;
                    } else if (val !== root.lastBrightness) {
                        root.lastBrightness = val;
                        brightQueryProc.running = true;
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        volQueryProc.running = true;
    }
}
