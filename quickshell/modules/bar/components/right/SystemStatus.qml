import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../theme"
import "../../../../components"

Row {
    id: root
    spacing: 8
    anchors.verticalCenter: parent.verticalCenter

    property int batteryCapacity: 100
    property bool isCharging: false
    property bool hasBattery: false

    property bool isMuted: true
    property real volumeLevel: 0.50

    property bool isWifiConnected: true
    property string wifiSsid: ""

    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    // Battery Process
    Process {
        id: batProc
        command: ["bash", "-c", "if [ -d /sys/class/power_supply/BAT1 ]; then echo \"$(cat /sys/class/power_supply/BAT1/capacity):$(cat /sys/class/power_supply/BAT1/status)\"; elif [ -d /sys/class/power_supply/BAT0 ]; then echo \"$(cat /sys/class/power_supply/BAT0/capacity):$(cat /sys/class/power_supply/BAT0/status)\"; else echo \"none\"; fi"]
        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim();
                if (trimmed && trimmed !== "none") {
                    root.hasBattery = true;
                    let parts = trimmed.split(":");
                    root.batteryCapacity = parseInt(parts[0]) || 0;
                    root.isCharging = (parts[1] === "Charging");
                } else {
                    root.hasBattery = false;
                }
            }
        }
    }

    // WiFi Process
    Process {
        id: wifiProc
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION dev | grep '^wifi:connected:' | cut -d: -f3 || echo ''"]
        stdout: SplitParser {
            onRead: data => {
                let ssid = data.trim();
                root.isWifiConnected = (ssid.length > 0);
                root.wifiSsid = ssid;
            }
        }
    }

    // Volume Status Process (Safe pipe delimiter)
    Process {
        id: volProc
        command: ["bash", "-c", "echo \"$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null || echo 'Mute: yes')|$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | head -n1 || echo '50%')\""]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("|");
                let muteStr = parts[0] || "";
                let volStr = parts[1] || "";
                root.isMuted = muteStr.includes("yes");
                let match = volStr.match(/(\d+)%/);
                if (match) {
                    root.volumeLevel = parseInt(match[1]) / 100.0;
                }
            }
        }
    }

    // Real-time Event-driven Volume Subscriptions
    Process {
        id: volSubscribe
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.includes("sink")) {
                    volProc.running = true;
                }
            }
        }
    }

    Timer {
        id: volCheckTimer
        interval: 80
        running: false
        repeat: false
        onTriggered: volProc.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batProc.running = true;
            volProc.running = true;
            wifiProc.running = true;
        }
    }

    function toggleMute(): void {
        root.isMuted = !root.isMuted;
        Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]);
        volCheckTimer.restart();
    }

    function adjustVolume(delta: real): void {
        let step = (delta > 0 ? "+5%" : "-5%");
        root.isMuted = false;
        root.volumeLevel = Math.max(0, Math.min(1.0, root.volumeLevel + (delta > 0 ? 0.05 : -0.05)));
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", step]);
        volCheckTimer.restart();
    }

    // 1. WiFi Glyph (Material Symbols Rounded)
    Item {
        width: 18
        height: 18
        anchors.verticalCenter: parent.verticalCenter
        scale: wifiMouse.containsMouse ? 1.18 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: Theme.animDurationNormal
                easing.type: Easing.OutBack
                easing.overshoot: Theme.springOvershootExpressive
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.isWifiConnected ? "" : ""
            font.family: matSymbols.name
            font.pixelSize: 17
            color: root.isWifiConnected ? Theme.textPrimary : Theme.textDim
        }

        MouseArea {
            id: wifiMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: WifiService.toggle()
        }
    }

    // 2. Volume Glyph (Material Symbols Rounded - right next to WiFi)
    Item {
        id: volItem
        width: 18
        height: 18
        anchors.verticalCenter: parent.verticalCenter
        scale: volMouse.containsMouse ? (volMouse.pressed ? 0.90 : 1.22) : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: Theme.animDurationNormal
                easing.type: Easing.OutBack
                easing.overshoot: Theme.springOvershootExpressive
            }
        }

        Text {
            id: volText
            anchors.centerIn: parent
            // volume_off (\\ue04f) when muted/zero, volume_up (\\ue050) when unmuted
            text: (root.isMuted || root.volumeLevel === 0) ? "" : ""
            font.family: matSymbols.name
            font.pixelSize: 18
            color: root.isMuted ? Theme.error : Theme.textPrimary

            Behavior on color {
                ColorAnimation { duration: Theme.animDurationFast }
            }
        }

        MouseArea {
            id: volMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMute()
            onWheel: wheel => {
                root.adjustVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05);
            }
        }
    }

    // 3. Material 3 Expressive Battery Indicator (hidden per user request)
    ExpressiveBattery {
        visible: false
        capacity: root.batteryCapacity
        isCharging: root.isCharging
        hasBattery: root.hasBattery
    }
}
