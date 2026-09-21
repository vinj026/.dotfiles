pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../../theme"
import "../../../../components"
import "../../../../core" as C
import "./controlcenter"

Item {
    id: root

    property bool active: false
    focus: active

    property string currentView: WifiService.isOpen ? "wifi" : "main"

    Connections {
        target: WifiService
        function onIsOpenChanged() {
            if (WifiService.isOpen) {
                root.currentView = "wifi";
            } else if (root.currentView === "wifi") {
                root.currentView = "main";
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true;
            if (root.currentView === "wifi") {
                root.currentView = "main";
                WifiService.close();
            } else {
                ControlCenterService.close();
            }
        }
    }

    implicitWidth: root.currentView === "wifi" ? 320 : 410
    implicitHeight: (root.currentView === "wifi"
        ? (typeof wifiSurfaceView !== "undefined" ? wifiSurfaceView.implicitHeight : 262)
        : (typeof mainLayout !== "undefined" ? mainLayout.implicitHeight : 262)) + 24

    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    // ────────────────────────────────────────────────────────────
    // Hardware & Status Probing
    // ────────────────────────────────────────────────────────────
    property bool wifiEnabled: true
    property string wifiSsid: ""
    property bool bluetoothEnabled: false

    property real volLevel: 0.50
    property bool volMuted: false

    property real brightLevel: 0.50

    property string netIp: "127.0.0.1"
    property string netIfaceLabel: "LAN"
    property string netRxFormatted: "0.0 B"
    property string netTxFormatted: "0.0 B"
    property var currentTime: new Date()
    property bool powerMenuHovered: false

    Timer {
        id: powerCloseTimer
        interval: 250
        repeat: false
        onTriggered: {
            root.powerMenuHovered = false;
        }
    }

    function formatBytes(bytes) {
        let b = Number(bytes) || 0;
        if (b <= 0) return "0.0 B";
        let units = ["B", "KB", "MB", "GB", "TB"];
        let i = Math.floor(Math.log(b) / Math.log(1024));
        i = Math.min(units.length - 1, Math.max(0, i));
        let val = b / Math.pow(1024, i);
        return val.toFixed(1) + " " + units[i];
    }

    function getAmbientMoodIcon(dateObj) {
        let h = dateObj.getHours();
        let isNight = (h < 6 || h >= 18);
        let cond = (WeatherService.conditionText || "").toLowerCase();

        if (cond.includes("storm")) return "\uebdc"; // thunderstorm
        if (cond.includes("rain") || cond.includes("drizzle")) return "\ue814"; // rainy
        if (cond.includes("snow")) return "\ueb3b"; // snowy
        if (cond.includes("cloud") || cond.includes("overcast")) {
            return isNight ? "\uf174" : "\ue2c6"; // partly_cloudy_night / partly_cloudy_day
        }

        // Clear sky / default by time:
        return isNight ? "\uf03d" : "\ue518"; // moon (nightlight) vs sun (light_mode)
    }

    function getAmbientMoodIconColor(dateObj) {
        let h = dateObj.getHours();
        let isNight = (h < 6 || h >= 18);
        let cond = (WeatherService.conditionText || "").toLowerCase();

        if (cond.includes("storm") || cond.includes("rain") || cond.includes("snow")) return "#74c0fc";
        if (cond.includes("cloud") || cond.includes("overcast")) return isNight ? "#a5d8ff" : "#ffd43b";
        return isNight ? "#a5d8ff" : "#fcc419";
    }

    function formatAestheticDate(dateObj) {
        const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        const months = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ];

        let dayName = days[dateObj.getDay()];
        let dateNum = dateObj.getDate();
        let monthName = months[dateObj.getMonth()];

        let h = dateObj.getHours();
        let isNight = (h < 6 || h >= 18);

        let period = "Night";
        if (h >= 5 && h < 12) period = "Morning";
        else if (h >= 12 && h < 17) period = "Afternoon";
        else if (h >= 17 && h < 21) period = "Evening";

        let cond = (WeatherService.conditionText || "").toLowerCase();
        let t = Math.round(WeatherService.temp);

        let mood = "";
        if (cond.includes("storm")) mood = "Stormy";
        else if (cond.includes("rain") || cond.includes("drizzle")) mood = "Rainy";
        else if (cond.includes("snow")) mood = "Snowy";
        else if (cond.includes("overcast")) mood = "Overcast";
        else if (cond.includes("cloud")) mood = "Cloudy";
        else if (cond.includes("clear") || cond.includes("sun")) {
            mood = isNight ? "Clear" : (h >= 11 && h < 16 && t >= 28 ? "Sunny" : "Clear");
        } else {
            // Contextual fallback based on time and temp
            if (isNight) {
                mood = (t < 18) ? "Cool" : (t < 23) ? "Quiet" : "Peaceful";
            } else {
                mood = (t >= 31) ? "Warm" : (t >= 25) ? "Sunny" : (t < 18) ? "Crisp" : "Pleasant";
            }
        }

        let tempStr = (WeatherService.isLoaded || WeatherService.temp) ? `${t}° · ` : "";
        return `${mood} ${period} · ${tempStr}<i>${dayName}</i>, <i>${monthName}</i> ${dateNum}`;
    }

    // Network IP and Bandwidth Telemetry Check
    Process {
        id: netTelemetryProc
        command: ["bash", "-c", "route_info=$(ip route get 1.1.1.1 2>/dev/null || ip route show default 2>/dev/null | head -n1)\n" +
                  "dev=$(echo \"$route_info\" | grep -oP \"dev \\K\\S+\")\n" +
                  "ip=$(echo \"$route_info\" | grep -oP \"src \\K\\S+\")\n" +
                  "if [ -z \"$ip\" ] && [ -n \"$dev\" ]; then\n" +
                  "    ip=$(ip -4 addr show \"$dev\" 2>/dev/null | grep -oP \"inet \\K\\S+\" | cut -d/ -f1 | head -n1)\n" +
                  "fi\n" +
                  "[ -z \"$dev\" ] && dev=\"lo\"\n" +
                  "[ -z \"$ip\" ] && ip=\"127.0.0.1\"\n" +
                  "type_label=\"LAN\"\n" +
                  "if [[ \"$dev\" == wl* ]]; then type_label=\"WiFi\"\n" +
                  "elif [[ \"$dev\" == tun* ]] || [[ \"$dev\" == wg* ]] || [[ \"$dev\" == *vpn* ]]; then type_label=\"VPN\"\n" +
                  "elif [[ \"$dev\" == en* ]] || [[ \"$dev\" == eth* ]]; then type_label=\"Ethernet\"\n" +
                  "fi\n" +
                  "read rx_b tx_b <<< $(awk -v d=\"$dev:\" '$1==d {print $2, $10}' /proc/net/dev 2>/dev/null)\n" +
                  "echo \"$ip|$dev $type_label|${rx_b:-0}|${tx_b:-0}\"\n"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("|");
                if (parts.length >= 4) {
                    root.netIp = parts[0] || "127.0.0.1";
                    root.netIfaceLabel = parts[1] || "LAN";
                    root.netRxFormatted = root.formatBytes(parts[2]);
                    root.netTxFormatted = root.formatBytes(parts[3]);
                }
            }
        }
    }

    // Wi-Fi Status Check
    Process {
        id: wifiQueryProc
        command: ["bash", "-c", "echo \"$(nmcli radio wifi)|$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes:' | cut -d: -f2 | head -n1)\""]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("|");
                root.wifiEnabled = (parts[0] === "enabled");
                root.wifiSsid = parts[1] || "";
            }
        }
    }

    // Bluetooth Status Check
    Process {
        id: btQueryProc
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'on' || echo 'off'"]
        stdout: SplitParser {
            onRead: data => {
                root.bluetoothEnabled = (data.trim() === "on");
            }
        }
    }

    // Volume Status Check
    Process {
        id: volQueryProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim();
                let match = trimmed.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/);
                if (match) {
                    root.volLevel = Math.max(0.0, Math.min(1.0, parseFloat(match[1]) || 0));
                    root.volMuted = (match[2] !== undefined && match[2].length > 0);
                }
            }
        }
    }

    // Brightness Status Check
    Process {
        id: brightQueryProc
        command: ["bash", "-c", "brightnessctl -m | head -n1"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(",");
                if (parts.length >= 4) {
                    let pctStr = parts[3].replace("%", "");
                    root.brightLevel = Math.max(0.05, Math.min(1.0, (parseFloat(pctStr) || 0) / 100.0));
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 1500
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            root.currentTime = new Date();
            wifiQueryProc.running = true;
            btQueryProc.running = true;
            volQueryProc.running = true;
            brightQueryProc.running = true;
            netTelemetryProc.running = true;
            C.SystemInfo.refresh();
        }
    }

    Component.onCompleted: {
        root.currentTime = new Date();
        wifiQueryProc.running = true;
        btQueryProc.running = true;
        volQueryProc.running = true;
        brightQueryProc.running = true;
        netTelemetryProc.running = true;
        C.SystemInfo.refresh();
        IdeapadService.refresh();
        RgbService.refresh();
        C.Battery.refreshProfile();
    }

    onActiveChanged: {
        if (root.active) {
            root.currentView = WifiService.isOpen ? "wifi" : "main";
            root.currentTime = new Date();
            wifiQueryProc.running = true;
            btQueryProc.running = true;
            volQueryProc.running = true;
            brightQueryProc.running = true;
            netTelemetryProc.running = true;
            C.SystemInfo.refresh();
            IdeapadService.refresh();
            RgbService.refresh();
            C.Battery.refreshProfile();
        } else {
            powerCloseTimer.stop();
            root.powerMenuHovered = false;
            root.currentView = "main";
            WifiService.close();
        }
    }

    // ────────────────────────────────────────────────────────────
    // Action Helpers
    // ────────────────────────────────────────────────────────────
    function toggleWifi() {
        let newState = !root.wifiEnabled;
        root.wifiEnabled = newState;
        Quickshell.execDetached(["nmcli", "radio", "wifi", newState ? "on" : "off"]);
        wifiCheckTimer.restart();
    }

    function toggleBluetooth() {
        let newState = !root.bluetoothEnabled;
        root.bluetoothEnabled = newState;
        Quickshell.execDetached(["bluetoothctl", "power", newState ? "on" : "off"]);
        btCheckTimer.restart();
    }

    function setVolumeFraction(val) {
        let clamped = Math.max(0.0, Math.min(1.0, val));
        root.volLevel = clamped;
        root.volMuted = false;
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", clamped.toFixed(2)]);
    }

    function toggleMute() {
        root.volMuted = !root.volMuted;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
        volQueryProc.running = true;
    }

    function setBrightnessFraction(val) {
        let clamped = Math.max(0.05, Math.min(1.0, val));
        root.brightLevel = clamped;
        let pct = Math.round(clamped * 100);
        Quickshell.execDetached(["brightnessctl", "set", pct + "%"]);
    }

    Timer { id: wifiCheckTimer; interval: 800; onTriggered: wifiQueryProc.running = true }
    Timer { id: btCheckTimer; interval: 800; onTriggered: btQueryProc.running = true }
    // ════════════════════════════════════════════════════════════
    // M3 Vertical Expressive Slider Component (Volume & Brightness)
    // ════════════════════════════════════════════════════════════
    component M3VerticalSlider: Item {
        id: vSliderRoot

        property real value: 0.0
        property bool isMuted: false
        property string icon: ""
        property string mutedIcon: ""
        property color activeColor: isMuted ? Theme.error : Theme.activeTileBg
        property color inactiveColor: Theme.surfaceContainer
        property string symbolFont: matSymbols.name

        signal moved(real val)
        signal iconClicked()

        implicitWidth: 54
        implicitHeight: 130

        readonly property real clampedVal: Math.max(0.0, Math.min(1.0, isMuted ? 0.0 : value))

        // Ambient drop shadow beneath slider
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 1
            anchors.bottomMargin: -1
            radius: 14
            color: Qt.rgba(0, 0, 0, 0.18)
            z: -1
        }

        // Background container pill (tactile recessed track)
        Rectangle {
            id: vTrack
            anchors.fill: parent
            radius: 14
            color: vSliderRoot.inactiveColor
            clip: true

            // Smooth rounded fluid level capsule (raised tactile pill)
            Rectangle {
                id: fillPill
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.round(parent.height * vSliderRoot.clampedVal)
                radius: 14
                color: vSliderRoot.activeColor
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.tint(vSliderRoot.activeColor, Qt.rgba(1, 1, 1, 0.06)) }
                    GradientStop { position: 1.0; color: Qt.darker(vSliderRoot.activeColor, 1.04) }
                }

                Behavior on height {
                    enabled: !vSliderMouse.pressed
                    NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                }
            }

            // Top readout: percentage or Muted
            Text {
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                text: vSliderRoot.isMuted ? "Mute" : Math.round(vSliderRoot.clampedVal * 100) + "%"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: (vSliderRoot.clampedVal >= 0.85 && !vSliderRoot.isMuted) ? Theme.textOnPrimary : Theme.textPrimary
                z: 10

                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
            }

            // Bottom icon: volume / brightness
            Item {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: 28
                height: 28
                z: 10

                Text {
                    anchors.centerIn: parent
                    text: (vSliderRoot.isMuted && vSliderRoot.mutedIcon.length > 0) ? vSliderRoot.mutedIcon : vSliderRoot.icon
                    font.family: vSliderRoot.symbolFont
                    font.pixelSize: 20
                    color: (vSliderRoot.clampedVal >= 0.25 && !vSliderRoot.isMuted)
                        ? Theme.textOnPrimary
                        : (vSliderRoot.isMuted ? Theme.error : Theme.textPrimary)

                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                }
            }
        }

        // Mouse handling for drag, click and wheel
        MouseArea {
            id: vSliderMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function updateVal(mouseY) {
                let fraction = 1.0 - (mouseY / height);
                let clamped = Math.max(0.0, Math.min(1.0, fraction));
                vSliderRoot.moved(clamped);
            }

            onPressed: mouse => {
                if (mouse.y > height - 42) {
                    vSliderRoot.iconClicked();
                } else {
                    updateVal(mouse.y);
                }
            }
            onPositionChanged: mouse => {
                if (pressed) updateVal(mouse.y);
            }
            onWheel: wheel => {
                let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                let newVal = Math.max(0.0, Math.min(1.0, vSliderRoot.value + delta));
                vSliderRoot.moved(newVal);
            }
        }
    }



    // ────────────────────────────────────────────────────────────
    // Material 3 Expressive Layout
    // ────────────────────────────────────────────────────────────
    Column {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 12
        spacing: 10

        opacity: root.currentView === "main" ? 1.0 : 0.0
        scale: root.currentView === "main" ? 1.0 : 0.96
        visible: opacity > 0.01

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

        // ════════════════════════════════════════════════════════════
        // 1. M3 Telemetry Card (Profile, Battery, Network IP & Action Strip)
        // ════════════════════════════════════════════════════════════
        Item {
            width: parent.width
            height: teleCol.implicitHeight + 20

            // Ambient drop shadow beneath card
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 1
                anchors.bottomMargin: -1
                radius: 16
                color: Qt.rgba(0, 0, 0, 0.18)
                z: -1
            }

            Rectangle {
                id: telemetryCard
                anchors.fill: parent
                radius: 16
                color: Theme.surfaceContainer
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.tint(Theme.surfaceContainer, Qt.rgba(1, 1, 1, 0.03)) }
                    GradientStop { position: 1.0; color: Qt.darker(Theme.surfaceContainer, 1.04) }
                }

                Column {
                    id: teleCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 10

                    // ── Profile, System Telemetry & Network Row ──
                    Item {
                        width: parent.width
                        height: 56

                        // Profile Avatar + System Column (Username, Uptime, IP/WiFi)
                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            // Profile Avatar Squircle
                            Rectangle {
                                width: 42
                                height: 42
                                radius: 12
                                color: Theme.surfaceVariant
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.tint(Theme.surfaceVariant, Qt.rgba(1, 1, 1, 0.04)) }
                                    GradientStop { position: 1.0; color: Qt.darker(Theme.surfaceVariant, 1.03) }
                                }
                                clip: true
                                anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.fill: parent
                                source: C.SystemInfo.profilePicture
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: (C.SystemInfo.username ? C.SystemInfo.username.charAt(0).toUpperCase() : "U")
                                font.family: Theme.fontFamily
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                                visible: !C.SystemInfo.profilePicture || C.SystemInfo.profilePicture == ""
                            }
                        }

                        // Username, Uptime & WiFi/IP in ONE Unified Column
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            // Line 1: Username & Hostname
                            Row {
                                spacing: 5
                                Text {
                                    text: C.SystemInfo.username || "user"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                }
                                Text {
                                    text: "(" + (C.SystemInfo.hostname || "mango") + ")"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Normal
                                    color: Theme.textMuted
                                    anchors.baseline: parent.children[0].baseline
                                }
                            }

                            // Line 2: Uptime
                            Text {
                                text: C.SystemInfo.uptimeLongText || "up just now"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }

                            // Line 3: IP & WiFi
                            Row {
                                spacing: 5
                                visible: root.netIp !== "" || root.netIfaceLabel !== ""

                                Text {
                                    text: root.netIp
                                    font.family: "MesloLGS Nerd Font", "Noto Sans Mono", Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }

                                Text {
                                    text: "·"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textDim
                                    visible: root.netIp !== "" && root.netIfaceLabel !== ""
                                }

                                Text {
                                    text: root.netIfaceLabel
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }
                        }
                    }

                    // Battery & Bandwidth Stats (Right)
                    Column {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        // Battery Chip Pill
                        Rectangle {
                            id: batChip
                            anchors.right: parent.right
                            height: 20
                            width: batRow.implicitWidth + 12
                            radius: 10
                            color: C.Battery.percentage <= 20
                                ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16)
                                : Qt.rgba(105/255, 219/255, 124/255, 0.14)

                            Row {
                                id: batRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: C.Battery.isCharging ? "" : (C.Battery.percentage > 20 ? "" : "")
                                    font.family: matSymbols.name
                                    font.pixelSize: 13
                                    color: C.Battery.percentage <= 20 ? Theme.error : "#69db7c"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: C.Battery.percentage + "%"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: C.Battery.percentage <= 20 ? Theme.error : "#69db7c"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        // Download Speed (RX)
                        Row {
                            anchors.right: parent.right
                            spacing: 4

                            Text {
                                text: "↓"
                                font.family: "MesloLGS Nerd Font", "Noto Sans Mono"
                                font.pixelSize: 10
                                color: Theme.secondary
                            }
                            Text {
                                text: root.netRxFormatted
                                font.family: "MesloLGS Nerd Font", "Noto Sans Mono"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                            }
                        }

                        // Upload Speed (TX) below Download
                        Row {
                            anchors.right: parent.right
                            spacing: 4

                            Text {
                                text: "↑"
                                font.family: "MesloLGS Nerd Font", "Noto Sans Mono"
                                font.pixelSize: 10
                                color: Theme.tertiary
                            }
                            Text {
                                text: root.netTxFormatted
                                font.family: "MesloLGS Nerd Font", "Noto Sans Mono"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                            }
                        }
                    }
                }

                // ── ROW 2: Bottom Action Strip ──
                Rectangle {
                    id: actionStrip
                    width: parent.width
                    height: 36
                    radius: 12
                    color: Qt.rgba(0, 0, 0, 0.20)

                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        // Right Quick Action (Power Button)
                        Rectangle {
                            id: powerBtn
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            height: 28
                            radius: 8
                            color: (root.powerMenuHovered || powerBtnMouse.containsMouse)
                                ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16)
                                : Qt.rgba(1, 1, 1, 0.08)
                            scale: powerBtnMouse.pressed ? 0.90 : (powerBtnMouse.containsMouse ? 1.08 : 1.0)
                            opacity: powerBtnMouse.containsMouse ? 1.0 : 0.85
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on opacity { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            Text {
                                anchors.centerIn: parent
                                text: "\ue8ac" // power_settings_new
                                font.family: matSymbols.name
                                font.pixelSize: 14
                                color: (root.powerMenuHovered || powerBtnMouse.containsMouse) ? Theme.error : Theme.textPrimary
                            }
                            MouseArea {
                                id: powerBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    powerCloseTimer.stop();
                                    root.powerMenuHovered = true;
                                }
                                onExited: {
                                    powerCloseTimer.restart();
                                }
                                onClicked: {
                                    root.powerMenuHovered = !root.powerMenuHovered;
                                }
                            }
                        }

                        // ── DEFAULT STATE: Date-Time & Weather (Centered & Symmetrical) ──
                        Item {
                            id: defaultInfoArea
                            anchors.left: parent.left
                            anchors.right: powerBtn.left
                            anchors.rightMargin: 6
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            opacity: !root.powerMenuHovered ? 1.0 : 0.0
                            scale: !root.powerMenuHovered ? 1.0 : 0.96
                            visible: opacity > 0.01

                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                height: parent.height

                                Text {
                                    text: root.getAmbientMoodIcon(root.currentTime)
                                    font.family: matSymbols.name
                                    font.pixelSize: 14
                                    color: root.getAmbientMoodIconColor(root.currentTime)
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: root.formatAestheticDate(root.currentTime)
                                    textFormat: Text.StyledText
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Theme.textPrimary
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // ── POWER HOVER STATE: Sleep | Logout | Restart | Shutdown ──
                        Item {
                            id: powerOptionsArea
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.right: powerBtn.left
                            anchors.rightMargin: 6
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            opacity: root.powerMenuHovered ? 1.0 : 0.0
                            scale: root.powerMenuHovered ? 1.0 : 0.96
                            visible: opacity > 0.01

                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5

                                // Sleep
                                Rectangle {
                                    height: 26
                                    width: sleepRow.implicitWidth + 14
                                    radius: 8
                                    color: sleepMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                    scale: sleepMouse.pressed ? 0.92 : (sleepMouse.containsMouse ? 1.05 : 1.0)
                                    opacity: sleepMouse.containsMouse ? 1.0 : 0.85
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                    Behavior on opacity { NumberAnimation { duration: 80 } }
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                    Row {
                                        id: sleepRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "\ue51c" // dark_mode / moon
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: Theme.secondary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "Sleep"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            color: Theme.secondary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: sleepMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: { powerCloseTimer.stop(); root.powerMenuHovered = true; }
                                        onExited: { powerCloseTimer.restart(); }
                                        onClicked: {
                                            ControlCenterService.close();
                                            Quickshell.execDetached(["systemctl", "suspend"]);
                                        }
                                    }
                                }

                                // Logout
                                Rectangle {
                                    height: 26
                                    width: logoutRow.implicitWidth + 14
                                    radius: 8
                                    color: logoutMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                    scale: logoutMouse.pressed ? 0.92 : (logoutMouse.containsMouse ? 1.05 : 1.0)
                                    opacity: logoutMouse.containsMouse ? 1.0 : 0.85
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                    Behavior on opacity { NumberAnimation { duration: 80 } }
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                    Row {
                                        id: logoutRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "\ue9ba" // logout
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "Logout"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            color: Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: logoutMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: { powerCloseTimer.stop(); root.powerMenuHovered = true; }
                                        onExited: { powerCloseTimer.restart(); }
                                        onClicked: {
                                            ControlCenterService.close();
                                            Quickshell.execDetached(["bash", "-c", "loginctl terminate-user $USER || pkill -TERM mango"]);
                                        }
                                    }
                                }

                                // Restart
                                Rectangle {
                                    height: 26
                                    width: restartRow.implicitWidth + 14
                                    radius: 8
                                    color: restartMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                    scale: restartMouse.pressed ? 0.92 : (restartMouse.containsMouse ? 1.05 : 1.0)
                                    opacity: restartMouse.containsMouse ? 1.0 : 0.85
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                    Behavior on opacity { NumberAnimation { duration: 80 } }
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                    Row {
                                        id: restartRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "\uf053" // restart_alt
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: Theme.tertiary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "Restart"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            color: Theme.tertiary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: restartMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: { powerCloseTimer.stop(); root.powerMenuHovered = true; }
                                        onExited: { powerCloseTimer.restart(); }
                                        onClicked: {
                                            ControlCenterService.close();
                                            Quickshell.execDetached(["systemctl", "reboot"]);
                                        }
                                    }
                                }

                                // Shutdown
                                Rectangle {
                                    height: 26
                                    width: shutdownRow.implicitWidth + 14
                                    radius: 8
                                    color: shutdownMouse.containsMouse
                                        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16)
                                        : "transparent"
                                    scale: shutdownMouse.pressed ? 0.92 : (shutdownMouse.containsMouse ? 1.05 : 1.0)
                                    opacity: shutdownMouse.containsMouse ? 1.0 : 0.85
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                    Behavior on opacity { NumberAnimation { duration: 80 } }
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                    Row {
                                        id: shutdownRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "\ue8ac" // power_settings_new
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: Theme.error
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "Shutdown"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            color: Theme.error
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: shutdownMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: { powerCloseTimer.stop(); root.powerMenuHovered = true; }
                                        onExited: { powerCloseTimer.restart(); }
                                        onClicked: {
                                            ControlCenterService.close();
                                            Quickshell.execDetached(["systemctl", "poweroff"]);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

        // ════════════════════════════════════════════════════════════
        // 2. M3 Expressive Controls: Quick Settings + Sliders (Side-by-Side)
        // ════════════════════════════════════════════════════════════
        Row {
            width: parent.width
            height: 130
            spacing: 10

            // ── Left: Quick Settings 2x2 Grid ──
            Grid {
                columns: 2
                spacing: 10
                width: 260

                // Tile 1: Wi-Fi / Internet
                Item {
                    width: (parent.width - 8) / 2
                    height: 60

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: -1
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.18)
                        z: -1
                    }

                    Rectangle {
                        id: wifiTile
                        anchors.fill: parent
                        radius: 14
                        color: root.wifiEnabled ? Theme.activeTileBg : (wifiMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                        scale: wifiMouse.pressed ? 0.95 : (wifiMouse.containsMouse ? 1.02 : 1.0)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.tint(wifiTile.color, Qt.rgba(1, 1, 1, root.wifiEnabled ? 0.06 : 0.03)) }
                            GradientStop { position: 1.0; color: Qt.darker(wifiTile.color, 1.04) }
                        }

                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Rectangle {
                                id: wifiIconCircle
                                width: 32
                                height: 32
                                radius: 16
                                color: root.wifiEnabled
                                    ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18)
                                    : Qt.rgba(1, 1, 1, 0.06)
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: root.wifiEnabled ? "\ue63e" : "\ue648"
                                    font.family: matSymbols.name
                                    font.pixelSize: 18
                                    color: root.wifiEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleWifi()
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                width: parent.width - 32 - 8 - 18

                                Text {
                                    text: "Internet"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: root.wifiEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                }

                                Text {
                                    text: root.wifiEnabled ? (root.wifiSsid ? root.wifiSsid : "Connected") : "Off"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Normal
                                    color: root.wifiEnabled
                                        ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.78)
                                        : Theme.textMuted
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\ue5cc" // chevron_right
                                font.family: matSymbols.name
                                font.pixelSize: 16
                                color: root.wifiEnabled
                                    ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.6)
                                    : Theme.textDim
                            }
                        }

                        MouseArea {
                            id: wifiMouse
                            anchors.fill: parent
                            anchors.leftMargin: 36
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.wifiEnabled) {
                                    root.toggleWifi();
                                }
                                root.currentView = "wifi";
                                WifiService.isOpen = true;
                                C.Network.refreshAll();
                                C.Network.rescan();
                            }
                        }
                    }
                }

                // Tile 2: Bluetooth
                Item {
                    width: (parent.width - 8) / 2
                    height: 60

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: -1
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.18)
                        z: -1
                    }

                    Rectangle {
                        id: btTile
                        anchors.fill: parent
                        radius: 14
                        color: root.bluetoothEnabled ? Theme.activeTileBg : (btMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                        scale: btMouse.pressed ? 0.95 : (btMouse.containsMouse ? 1.02 : 1.0)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.tint(btTile.color, Qt.rgba(1, 1, 1, root.bluetoothEnabled ? 0.06 : 0.03)) }
                            GradientStop { position: 1.0; color: Qt.darker(btTile.color, 1.04) }
                        }

                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Rectangle {
                                id: btIconCircle
                                width: 32
                                height: 32
                                radius: 16
                                color: root.bluetoothEnabled
                                    ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18)
                                    : Qt.rgba(1, 1, 1, 0.06)
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: root.bluetoothEnabled ? "" : ""
                                    font.family: matSymbols.name
                                    font.pixelSize: 18
                                    color: root.bluetoothEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                width: parent.width - 40

                                Text {
                                    text: "Bluetooth"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: root.bluetoothEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                }

                                Text {
                                    text: root.bluetoothEnabled ? "Active" : "Off"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Normal
                                    color: root.bluetoothEnabled
                                        ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.78)
                                        : Theme.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: btMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleBluetooth()
                        }
                    }
                }

                // Tile 3: Do Not Disturb
                Item {
                    width: (parent.width - 8) / 2
                    height: 60

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: -1
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.18)
                        z: -1
                    }

                    Rectangle {
                        id: dndTile
                        anchors.fill: parent
                        radius: 14
                        color: ControlCenterService.dndEnabled ? Theme.activeTileBg : (dndMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                        scale: dndMouse.pressed ? 0.95 : (dndMouse.containsMouse ? 1.02 : 1.0)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.tint(dndTile.color, Qt.rgba(1, 1, 1, ControlCenterService.dndEnabled ? 0.06 : 0.03)) }
                            GradientStop { position: 1.0; color: Qt.darker(dndTile.color, 1.04) }
                        }

                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Rectangle {
                                id: dndIconCircle
                                width: 32
                                height: 32
                                radius: 16
                                color: ControlCenterService.dndEnabled
                                    ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18)
                                    : Qt.rgba(1, 1, 1, 0.06)
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: ControlCenterService.dndEnabled ? "" : ""
                                    font.family: matSymbols.name
                                    font.pixelSize: 18
                                    color: ControlCenterService.dndEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                width: parent.width - 40

                                Text {
                                    text: "Focus"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: ControlCenterService.dndEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                }

                                Text {
                                    text: ControlCenterService.dndEnabled ? "On" : "Off"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Normal
                                    color: ControlCenterService.dndEnabled
                                        ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.78)
                                        : Theme.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: dndMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ControlCenterService.toggleDnd()
                        }
                    }
                }

                // Tile 4: Night Light
                Item {
                    width: (parent.width - 8) / 2
                    height: 60

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: -1
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.18)
                        z: -1
                    }

                    Rectangle {
                        id: nightTile
                        anchors.fill: parent
                        radius: 14
                        color: ControlCenterService.nightLightEnabled ? Theme.activeTileBg : (nightMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                        scale: nightMouse.pressed ? 0.95 : (nightMouse.containsMouse ? 1.02 : 1.0)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.tint(nightTile.color, Qt.rgba(1, 1, 1, ControlCenterService.nightLightEnabled ? 0.06 : 0.03)) }
                            GradientStop { position: 1.0; color: Qt.darker(nightTile.color, 1.04) }
                        }

                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Rectangle {
                                id: nightIconCircle
                                width: 32
                                height: 32
                                radius: 16
                                color: ControlCenterService.nightLightEnabled
                                    ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18)
                                    : Qt.rgba(1, 1, 1, 0.06)
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf03d" // nightlight (crescent moon)
                                    font.family: matSymbols.name
                                    font.pixelSize: 18
                                    color: ControlCenterService.nightLightEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                width: parent.width - 40

                                Text {
                                    text: "Night Light"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: ControlCenterService.nightLightEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                }

                                Text {
                                    text: ControlCenterService.nightLightEnabled ? "On" : "Off"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Normal
                                    color: ControlCenterService.nightLightEnabled
                                        ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.78)
                                        : Theme.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: nightMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ControlCenterService.toggleNightLight()
                        }
                    }
                }
            }

            // ── Right: Vertical Sliders (Left: Volume, Right: Brightness) ──
            Row {
                width: parent.width - 260 - 10
                height: 130
                spacing: 8

                // Volume M3 Vertical Slider (Left)
                M3VerticalSlider {
                    width: (parent.width - 8) / 2
                    height: 130
                    value: root.volLevel
                    isMuted: root.volMuted
                    icon: (root.volMuted || root.volLevel === 0) ? "" : (root.volLevel < 0.5 ? "" : "")
                    mutedIcon: ""
                    onMoved: val => root.setVolumeFraction(val)
                    onIconClicked: root.toggleMute()
                }

                // Brightness M3 Vertical Slider (Right)
                M3VerticalSlider {
                    width: (parent.width - 8) / 2
                    height: 130
                    value: root.brightLevel
                    icon: "" // light_mode
                    onMoved: val => root.setBrightnessFraction(val)
                    onIconClicked: {
                        if (root.brightLevel > 0.5) root.setBrightnessFraction(0.25);
                        else root.setBrightnessFraction(0.85);
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════════
        // 3. Charging Modes (Conserve 60% & Rapid Charge)
        // ════════════════════════════════════════════════════════════
        Row {
            width: parent.width
            spacing: 10

            // Left: Conserve 60% Tile
            Item {
                width: (parent.width - 10) / 2
                height: 52

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 1
                    anchors.bottomMargin: -1
                    radius: 14
                    color: Qt.rgba(0, 0, 0, 0.18)
                    z: -1
                }

                Rectangle {
                    id: consTile
                    anchors.fill: parent
                    radius: 14
                    color: IdeapadService.conservationEnabled ? Theme.activeTileBg : (consMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                    scale: consMouse.pressed ? 0.95 : (consMouse.containsMouse ? 1.02 : 1.0)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.tint(consTile.color, Qt.rgba(1, 1, 1, IdeapadService.conservationEnabled ? 0.06 : 0.03)) }
                        GradientStop { position: 1.0; color: Qt.darker(consTile.color, 1.04) }
                    }

                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                            id: consIconCircle
                            width: 32
                            height: 32
                            radius: 16
                            color: IdeapadService.conservationEnabled
                                ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18)
                                : Qt.rgba(1, 1, 1, 0.06)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "\uea35" // eco / leaf
                                font.family: matSymbols.name
                                font.pixelSize: 17
                                color: IdeapadService.conservationEnabled ? Theme.textOnPrimary : Theme.textPrimary
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            width: parent.width - 40

                            Text {
                                text: "Conserve 60%"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: IdeapadService.conservationEnabled ? Theme.textOnPrimary : Theme.textPrimary
                            }

                            Text {
                                text: "Limit battery to 60%"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.Normal
                                color: IdeapadService.conservationEnabled
                                    ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.78)
                                    : Theme.textMuted
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    MouseArea {
                        id: consMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: IdeapadService.toggleConservation()
                    }
                }
            }

            // Right: Rapid Charge Tile
            Item {
                width: (parent.width - 10) / 2
                height: 52

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 1
                    anchors.bottomMargin: -1
                    radius: 14
                    color: Qt.rgba(0, 0, 0, 0.18)
                    z: -1
                }

                Rectangle {
                    id: rapidTile
                    anchors.fill: parent
                    radius: 14
                    color: IdeapadService.rapidChargeEnabled ? Theme.activeTileBg : (rapidMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                    scale: rapidMouse.pressed ? 0.95 : (rapidMouse.containsMouse ? 1.02 : 1.0)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.tint(rapidTile.color, Qt.rgba(1, 1, 1, IdeapadService.rapidChargeEnabled ? 0.06 : 0.03)) }
                        GradientStop { position: 1.0; color: Qt.darker(rapidTile.color, 1.04) }
                    }

                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                            id: rapidIconCircle
                            width: 32
                            height: 32
                            radius: 16
                            color: IdeapadService.rapidChargeEnabled
                                ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18)
                                : Qt.rgba(1, 1, 1, 0.06)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "\uea0b" // bolt
                                font.family: matSymbols.name
                                font.pixelSize: 17
                                color: IdeapadService.rapidChargeEnabled ? Theme.textOnPrimary : Theme.textPrimary
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            width: parent.width - 40

                            Text {
                                text: "Rapid Charge"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: IdeapadService.rapidChargeEnabled ? Theme.textOnPrimary : Theme.textPrimary
                            }

                            Text {
                                text: "Fast charging mode"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.Normal
                                color: IdeapadService.rapidChargeEnabled
                                    ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.78)
                                    : Theme.textMuted
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    MouseArea {
                        id: rapidMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: IdeapadService.toggleRapidCharge()
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════════
        // 4. System Power Profiles (Segmented Control)
        // ════════════════════════════════════════════════════════════
        Rectangle {
            id: profContainer
            width: parent.width
            height: 34
            radius: 12
            color: Qt.rgba(0, 0, 0, 0.22)

            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: [
                        { id: "performance", label: "Performance", icon: "\ue26b" },
                        { id: "balanced", label: "Balanced", icon: "\uea35" },
                        { id: "power-saver", label: "Saver", icon: "\ue9e0" }
                    ]

                    Item {
                        id: profItem
                        required property var modelData
                        readonly property bool isSelected: C.Battery.activeProfile === modelData.id

                        width: Math.floor((parent.width - 6) / 3)
                        height: parent.height

                        // Active button drop shadow
                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 1
                            anchors.bottomMargin: -1
                            radius: 9
                            visible: profItem.isSelected
                            color: Qt.rgba(0, 0, 0, 0.20)
                            z: -1
                        }

                        Rectangle {
                            id: profBtn
                            anchors.fill: parent
                            radius: 9
                            color: profItem.isSelected ? Theme.activeTileBg : (profMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                            scale: profMouse.pressed ? 0.96 : (profMouse.containsMouse ? 1.01 : 1.0)
                            gradient: profItem.isSelected ? profGrad : null

                            Gradient {
                                id: profGrad
                                GradientStop { position: 0.0; color: Qt.tint(Theme.activeTileBg, Qt.rgba(1, 1, 1, 0.06)) }
                                GradientStop { position: 1.0; color: Qt.darker(Theme.activeTileBg, 1.04) }
                            }

                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: profItem.modelData.icon
                                    font.family: matSymbols.name
                                    font.pixelSize: 13
                                    color: profItem.isSelected ? Theme.textOnPrimary : Theme.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: profItem.modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: profItem.isSelected ? Font.DemiBold : Font.Normal
                                    color: profItem.isSelected ? Theme.textOnPrimary : Theme.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: profMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: C.Battery.setProfile(profItem.modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════════
        // 5. Keyboard RGB Lighting & Color Palette
        // ════════════════════════════════════════════════════════════
        Item {
            width: parent.width
            height: rgbCol.implicitHeight + 16

            // Ambient drop shadow beneath RGB card
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 1
                anchors.bottomMargin: -1
                radius: 16
                color: Qt.rgba(0, 0, 0, 0.18)
                z: -1
            }

            Rectangle {
                id: rgbCard
                anchors.fill: parent
                radius: 16
                color: Theme.surfaceContainer
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.tint(Theme.surfaceContainer, Qt.rgba(1, 1, 1, 0.03)) }
                    GradientStop { position: 1.0; color: Qt.darker(Theme.surfaceContainer, 1.04) }
                }

                Column {
                    id: rgbCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 8

                    // Row 1: 5 Squircle Mode Buttons (Wave, Smooth, Breath, Static, Brightness)
                    Row {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: [
                                { id: "wave", name: "Wave", icon: "\ueb3e" },
                                { id: "smooth", name: "Smooth", icon: "\ue3f3" },
                                { id: "breath", name: "Breath", icon: "\uefd8" },
                                { id: "static", name: "Static", icon: "\ue412" }
                            ]

                            Rectangle {
                                id: rgbModeBtn
                                required property var modelData
                                readonly property bool isActive: RgbService.power && RgbService.mode === modelData.id

                                width: Math.floor((parent.width - 24) / 5)
                                height: 44
                                radius: 10
                                color: isActive ? Theme.activeTileBg : (rgbBtnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
                                scale: rgbBtnMouse.pressed ? 0.94 : (rgbBtnMouse.containsMouse ? 1.03 : 1.0)
                                gradient: isActive ? rgbGrad : rgbSubtleGrad

                                Gradient {
                                    id: rgbGrad
                                    GradientStop { position: 0.0; color: Qt.tint(Theme.activeTileBg, Qt.rgba(1, 1, 1, 0.06)) }
                                    GradientStop { position: 1.0; color: Qt.darker(Theme.activeTileBg, 1.04) }
                                }

                                Gradient {
                                    id: rgbSubtleGrad
                                    GradientStop { position: 0.0; color: Qt.tint(rgbModeBtn.color, Qt.rgba(1, 1, 1, 0.03)) }
                                    GradientStop { position: 1.0; color: Qt.darker(rgbModeBtn.color, 1.03) }
                                }

                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: rgbModeBtn.modelData.icon
                                        font.family: matSymbols.name
                                        font.pixelSize: 14
                                        color: rgbModeBtn.isActive ? Theme.textOnPrimary : Theme.textPrimary
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: rgbModeBtn.modelData.name
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.weight: rgbModeBtn.isActive ? Font.DemiBold : Font.Normal
                                        color: rgbModeBtn.isActive ? Theme.textOnPrimary : Theme.textMuted
                                    }
                                }

                                MouseArea {
                                    id: rgbBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: RgbService.setMode(rgbModeBtn.modelData.id)
                                }
                            }
                        }

                        // 5th Button: Keyboard Brightness Toggle (Low / High)
                        Rectangle {
                            id: kbdBBtn
                            width: Math.floor((parent.width - 24) / 5)
                            height: 44
                            radius: 10
                            color: kbdBMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                            scale: kbdBMouse.pressed ? 0.94 : (kbdBMouse.containsMouse ? 1.03 : 1.0)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.tint(kbdBBtn.color, Qt.rgba(1, 1, 1, 0.03)) }
                                GradientStop { position: 1.0; color: Qt.darker(kbdBBtn.color, 1.03) }
                            }

                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "\ue1d8" // bar_chart / brightness
                                    font.family: matSymbols.name
                                    font.pixelSize: 14
                                    color: Theme.textPrimary
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: RgbService.brightness.toLowerCase()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Normal
                                    color: Theme.textMuted
                                }
                            }

                            MouseArea {
                                id: kbdBMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (RgbService.brightness === "high") RgbService.setBrightness("low");
                                    else RgbService.setBrightness("high");
                                }
                            }
                        }
                    }

                    // Row 2: Minimalist Color Palette
                    Item {
                        width: parent.width
                        height: 22

                        Row {
                            anchors.centerIn: parent
                            spacing: 12

                            Repeater {
                                model: ["#ffffff", "#00d4ff", "#30d158", "#ffd60a", "#ff9500", "#ff3b30", "#bf5af2"]

                                Item {
                                    id: dotItem
                                    required property string modelData
                                    readonly property bool isActive: (RgbService.zones && RgbService.zones[0] ? RgbService.zones[0].toLowerCase() : "") === modelData.toLowerCase() && RgbService.mode === "static"

                                    width: 22
                                    height: 22

                                    // Active subtle halo disc (no border!)
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: dotItem.isActive ? 22 : 0
                                        height: dotItem.isActive ? 22 : 0
                                        radius: 11
                                        color: Qt.rgba(colorDot.color.r, colorDot.color.g, colorDot.color.b, 0.28)
                                        visible: dotItem.isActive

                                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                    }

                                    Rectangle {
                                        id: colorDot
                                        anchors.centerIn: parent
                                        width: dotItem.isActive ? 12 : (dotMouse.containsMouse ? 12 : 10)
                                        height: width
                                        radius: width / 2
                                        color: dotItem.modelData
                                        scale: dotMouse.pressed ? 0.90 : 1.0
                                        opacity: dotItem.isActive ? 1.0 : (dotMouse.containsMouse ? 0.95 : 0.65)

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on opacity { NumberAnimation { duration: 120 } }
                                        Behavior on scale { NumberAnimation { duration: 80 } }
                                    }

                                    MouseArea {
                                        id: dotMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: RgbService.setColor(dotItem.modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════════
        // 6. Theme Selector Carousel (Wireframe)
        // ════════════════════════════════════════════════════════════
        Item {
            width: parent.width
            height: 46

            // Ambient drop shadow beneath Carousel
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 1
                anchors.bottomMargin: -1
                radius: 16
                color: Qt.rgba(0, 0, 0, 0.18)
                z: -1
            }

            Rectangle {
                id: themeCarouselCard
                anchors.fill: parent
                radius: 16
                color: Theme.surfaceContainer
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.tint(Theme.surfaceContainer, Qt.rgba(1, 1, 1, 0.03)) }
                    GradientStop { position: 1.0; color: Qt.darker(Theme.surfaceContainer, 1.04) }
                }

                readonly property var themes: [
                    { id: "monochrome", label: "Monochrome" },
                    { id: "vercel",     label: "Vercel" },
                    { id: "everblush",  label: "Everblush" },
                    { id: "wallpaper",  label: "Wallpaper" },
                    { id: "gruvbox",    label: "Gruvbox" },
                    { id: "everforest", label: "Everforest" },
                    { id: "monokai",    label: "Monokai" },
                    { id: "catppuccin", label: "Catppuccin" },
                    { id: "ayu_dark",   label: "Ayu Dark" }
                ]

                property int pageIndex: 0
                readonly property int visibleItems: 3
                readonly property int maxPage: Math.ceil(themes.length / visibleItems) - 1

                function syncPageIndex() {
                    for (let i = 0; i < themes.length; i++) {
                        if (themes[i].id === ShellConfig.currentTheme) {
                            pageIndex = Math.floor(i / visibleItems);
                            break;
                        }
                    }
                }

                Component.onCompleted: syncPageIndex()

                Connections {
                    target: ShellConfig
                    function onCurrentThemeChanged() {
                        themeCarouselCard.syncPageIndex();
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    // Left Arrow Button
                    Rectangle {
                        width: 30
                        height: parent.height
                        radius: 10
                        color: leftArrowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        scale: leftArrowMouse.pressed ? 0.90 : 1.0
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\ue5cb" // chevron_left
                            font.family: matSymbols.name
                            font.pixelSize: 18
                            color: leftArrowMouse.containsMouse ? Theme.primary : Theme.textMuted
                        }

                        MouseArea {
                            id: leftArrowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (themeCarouselCard.pageIndex > 0) {
                                    themeCarouselCard.pageIndex--;
                                } else {
                                    themeCarouselCard.pageIndex = themeCarouselCard.maxPage;
                                }
                            }
                        }
                    }

                    // 3 Theme Buttons
                    Row {
                        width: parent.width - 60 - 12
                        height: parent.height
                        spacing: 6

                        Repeater {
                            model: themeCarouselCard.visibleItems

                            Rectangle {
                                id: themeBtn
                                required property int modelData
                                readonly property int itemIdx: themeCarouselCard.pageIndex * themeCarouselCard.visibleItems + modelData
                                readonly property var themeItem: itemIdx < themeCarouselCard.themes.length ? themeCarouselCard.themes[itemIdx] : null
                                readonly property bool isSelected: themeItem ? (ShellConfig.currentTheme === themeItem.id) : false

                                width: Math.floor((parent.width - 12) / 3)
                                height: parent.height
                                radius: 10
                                visible: themeItem !== null
                                color: isSelected ? Theme.activeTileBg : (themeBtnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
                                scale: themeBtnMouse.pressed ? 0.95 : (themeBtnMouse.containsMouse ? 1.02 : 1.0)
                                gradient: isSelected ? themeGrad : themeSubtleGrad

                                Gradient {
                                    id: themeGrad
                                    GradientStop { position: 0.0; color: Qt.tint(Theme.activeTileBg, Qt.rgba(1, 1, 1, 0.06)) }
                                    GradientStop { position: 1.0; color: Qt.darker(Theme.activeTileBg, 1.04) }
                                }

                                Gradient {
                                    id: themeSubtleGrad
                                    GradientStop { position: 0.0; color: Qt.tint(themeBtn.color, Qt.rgba(1, 1, 1, 0.03)) }
                                    GradientStop { position: 1.0; color: Qt.darker(themeBtn.color, 1.03) }
                                }

                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                            Text {
                                anchors.centerIn: parent
                                text: themeBtn.themeItem ? themeBtn.themeItem.label : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: themeBtn.isSelected ? Font.DemiBold : Font.Normal
                                color: themeBtn.isSelected ? Theme.textOnPrimary : Theme.textPrimary
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: themeBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (themeBtn.themeItem) {
                                        ShellConfig.setTheme(themeBtn.themeItem.id);
                                    }
                                }
                            }
                        }
                    }
                }

                // Right Arrow Button
                Rectangle {
                    width: 30
                    height: parent.height
                    radius: 10
                    color: rightArrowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    scale: rightArrowMouse.pressed ? 0.90 : 1.0
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\ue5cc" // chevron_right
                        font.family: matSymbols.name
                        font.pixelSize: 18
                        color: rightArrowMouse.containsMouse ? Theme.primary : Theme.textMuted
                    }

                    MouseArea {
                        id: rightArrowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (themeCarouselCard.pageIndex < themeCarouselCard.maxPage) {
                                themeCarouselCard.pageIndex++;
                            } else {
                                themeCarouselCard.pageIndex = 0;
                            }
                        }
                    }
                }
            }
        }
    }
    }

    // ────────────────────────────────────────────────────────────
    // Wi-Fi Details View (Replaces Control Center with exact same size & style)
    // ────────────────────────────────────────────────────────────
    WifiView {
        id: wifiSurfaceView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        opacity: root.currentView === "wifi" ? 1.0 : 0.0
        scale: root.currentView === "wifi" ? 1.0 : 0.96
        visible: opacity > 0.01

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

        onBackClicked: {
            root.currentView = "main";
            WifiService.close();
        }
    }
}

