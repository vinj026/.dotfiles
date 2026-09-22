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

    implicitWidth: root.currentView === "wifi" ? 300 : 600
    implicitHeight: root.currentView === "wifi"
        ? (typeof wifiSurfaceView !== "undefined" ? wifiSurfaceView.implicitHeight + 20 : 250)
        : 240

    width: implicitWidth
    height: implicitHeight

    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    // Real System Hardware & State Bindings
    readonly property bool wifiEnabled: C.Network.wifiEnabled
    readonly property string wifiSsid: C.Network.ssid
    readonly property bool bluetoothEnabled: C.Bluetooth.isPowered

    readonly property real volLevel: C.Audio.volLevel / 100.0
    readonly property bool volMuted: C.Audio.volMuted

    readonly property real brightLevel: C.Brightness.level / 100.0

    property string netIp: ""
    property string netIfaceLabel: ""
    property string netRxFormatted: "0.0 B/s"
    property string netTxFormatted: "0.0 B/s"
    property var currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    Component.onCompleted: {
        C.SystemInfo.refresh();
        IdeapadService.refresh();
        RgbService.refresh();
        C.Network.refreshAll();
    }

    onActiveChanged: {
        if (active) {
            C.SystemInfo.refresh();
            IdeapadService.refresh();
            RgbService.refresh();
            C.Network.refreshAll();
            netTelemetryProc.running = true;
            bandwidthProc.running = true;
        }
    }

    function formatSpeed(bytesPerSec) {
        if (!bytesPerSec || bytesPerSec <= 0) return "0.0 B/s";
        let b = Number(bytesPerSec);
        let units = ["B/s", "K/s", "M/s", "G/s"];
        let i = Math.floor(Math.log(Math.max(1, b)) / Math.log(1024));
        i = Math.min(units.length - 1, Math.max(0, i));
        let val = b / Math.pow(1024, i);
        return val.toFixed(1) + units[i];
    }

    function getAmbientMoodIcon(dateObj) {
        let h = dateObj.getHours();
        let isNight = (h < 6 || h >= 18);
        let cond = (WeatherService.conditionText || "").toLowerCase();

        if (cond.includes("storm")) return "\uebdc";
        if (cond.includes("rain") || cond.includes("drizzle")) return "\ue814";
        if (cond.includes("snow")) return "\ueb3b";
        if (cond.includes("cloud") || cond.includes("overcast")) {
            return isNight ? "\uf174" : "\ue2c6";
        }
        return isNight ? "\uf03d" : "\ue518";
    }

    function getAmbientMoodIconColor(dateObj) {
        let h = dateObj.getHours();
        let isNight = (h < 6 || h >= 18);
        let cond = (WeatherService.conditionText || "").toLowerCase();

        if (cond.includes("storm") || cond.includes("rain") || cond.includes("snow")) return Theme.blue;
        if (cond.includes("cloud") || cond.includes("overcast")) return isNight ? Theme.blue : Theme.yellow;
        return isNight ? Theme.blue : Theme.yellow;
    }

    Process {
        id: netTelemetryProc
        command: ["bash", "-c", "ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) {if($i==\"src\") ip=$(i+1); if($i==\"dev\") dev=$(i+1)}} END {print ip; print dev}'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n");
                if (lines.length >= 1 && lines[0] !== "") root.netIp = lines[0].trim();
                if (lines.length >= 2 && lines[1] !== "") root.netIfaceLabel = lines[1].trim();
            }
        }
    }

    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real lastRxTime: 0

    Process {
        id: bandwidthProc
        command: ["bash", "-c", "awk -v iface=\"" + (root.netIfaceLabel || C.Network.wifiDevice || "wlan0") + "\" '$1 ~ iface {gsub(\":\", \"\", $1); print $2, $10}' /proc/net/dev 2>/dev/null"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(/\s+/);
                if (parts.length >= 2) {
                    let rx = parseFloat(parts[0]) || 0;
                    let tx = parseFloat(parts[1]) || 0;
                    let now = Date.now();
                    if (root.lastRxTime > 0 && now > root.lastRxTime) {
                        let dt = (now - root.lastRxTime) / 1000.0;
                        if (dt > 0.2) {
                            let rxSpeed = Math.max(0, (rx - root.lastRxBytes) / dt);
                            let txSpeed = Math.max(0, (tx - root.lastTxBytes) / dt);
                            root.netRxFormatted = root.formatSpeed(rxSpeed);
                            root.netTxFormatted = root.formatSpeed(txSpeed);
                        }
                    }
                    root.lastRxBytes = rx;
                    root.lastTxBytes = tx;
                    root.lastRxTime = now;
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: root.active && root.currentView === "main"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netTelemetryProc.running = true;
            bandwidthProc.running = true;
        }
    }

    function setVolumeFraction(val) {
        C.Audio.setVolume(val * 100);
    }

    function toggleMute() {
        C.Audio.toggleMute();
    }

    function setBrightnessFraction(val) {
        C.Brightness.setBrightness(val * 100);
    }

    function toggleWifi() {
        C.Network.toggleWifi();
    }

    function toggleBluetooth() {
        C.Bluetooth.togglePower();
    }

    // M3 Compact Horizontal Slider
    component M3HorizontalSlider: Item {
        id: hSliderRoot

        property real value: 0.0
        property bool isMuted: false
        property string icon: ""
        property string mutedIcon: ""
        property color activeColor: isMuted ? Theme.error : Theme.activeTileBg
        property color inactiveColor: Theme.surfaceContainer
        property string symbolFont: matSymbols.name

        signal moved(real val)
        signal iconClicked()

        readonly property real clampedVal: Math.max(0.0, Math.min(1.0, isMuted ? 0.0 : value))

        // Nebula Compact Geometry Tokens
        readonly property real trackHeight: 28
        readonly property real handleHeight: 40
        readonly property real handleWidth: 6
        readonly property real pressedHandleWidth: 4
        readonly property real handleGap: 4
        readonly property real trackOuterCorner: 8
        readonly property real _outer: Math.min(trackOuterCorner, trackHeight / 2)

        readonly property bool pressed: hSliderMouse.pressed
        property real _hw: pressed ? pressedHandleWidth : handleWidth
        Behavior on _hw { NumberAnimation { duration: 90 } }

        readonly property real _inset: Math.max(handleWidth, pressedHandleWidth) / 2
        readonly property real _travel: Math.max(0, width - _inset * 2)
        readonly property real _backendPos: _inset + _travel * clampedVal
        property real _dragPos: _inset
        property bool _isDraggingTrack: false

        property real _pos: _isDraggingTrack ? _dragPos : _backendPos

        Behavior on _pos {
            enabled: !hSliderRoot._isDraggingTrack
            NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
        }

        // 1. FILLED TRACK (Left section with rounded outer corners and square inner corners facing thumb)
        Item {
            id: hActive
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            width: Math.max(0, hSliderRoot._pos - hSliderRoot._hw / 2 - hSliderRoot.handleGap)
            height: hSliderRoot.trackHeight
            clip: true
            visible: width > 0

            Rectangle {
                width: parent.width + hSliderRoot._outer
                height: parent.height
                x: 0
                radius: hSliderRoot._outer
                color: hSliderRoot.activeColor
            }
        }

        // 2. THIN VERTICAL HANDLE (Divider at boundary, #d9d9d9)
        Rectangle {
            id: sliderHandle
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(hSliderRoot._pos - hSliderRoot._hw / 2)
            width: hSliderRoot._hw
            height: Math.min(hSliderRoot.handleHeight, parent.height)
            radius: width / 2
            color: "#d9d9d9"
            z: 5
        }

        // 3. UNFILLED TRACK (Right section with square inner corners facing thumb and rounded outer corners)
        Item {
            id: hInactive
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(hSliderRoot._pos + hSliderRoot._hw / 2 + hSliderRoot.handleGap)
            width: Math.max(0, parent.width - x)
            height: hSliderRoot.trackHeight
            clip: true
            visible: width > 0

            Rectangle {
                width: parent.width + hSliderRoot._outer
                height: parent.height
                x: -hSliderRoot._outer
                radius: hSliderRoot._outer
                color: hSliderRoot.inactiveColor
            }
        }

        // Slider Icon (Volume / Brightness)
        Item {
            anchors.left: parent.left
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            z: 10

            Text {
                anchors.centerIn: parent
                text: (hSliderRoot.isMuted && hSliderRoot.mutedIcon.length > 0) ? hSliderRoot.mutedIcon : hSliderRoot.icon
                font.family: hSliderRoot.symbolFont
                font.pixelSize: 15
                color: (hSliderRoot.clampedVal >= 0.15 && !hSliderRoot.isMuted) ? Theme.textOnPrimary : (hSliderRoot.isMuted ? Theme.error : Theme.textPrimary)
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
            }
        }

        // Slider Percentage Label
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: hSliderRoot.isMuted ? "Mute" : Math.round(hSliderRoot.clampedVal * 100) + "%"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: (hSliderRoot.clampedVal >= 0.88 && !hSliderRoot.isMuted) ? Theme.textOnPrimary : Theme.textPrimary
            z: 10
            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        }

        MouseArea {
            id: hSliderMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function applyAt(mouseX) {
                let p = (mouseX - hSliderRoot._inset) / Math.max(1, hSliderRoot._travel);
                p = Math.max(0.0, Math.min(1.0, p));
                hSliderRoot._dragPos = hSliderRoot._inset + hSliderRoot._travel * p;
                hSliderRoot.moved(p);
            }

            onPressed: mouse => {
                if (mouse.x < 32) {
                    hSliderRoot.iconClicked();
                } else {
                    hSliderRoot._isDraggingTrack = true;
                    applyAt(mouse.x);
                }
            }

            onReleased: {
                hSliderRoot._isDraggingTrack = false;
            }

            onCanceled: {
                hSliderRoot._isDraggingTrack = false;
            }

            onPositionChanged: mouse => {
                if (hSliderRoot._isDraggingTrack) applyAt(mouse.x);
            }

            onWheel: wheel => {
                let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                let newVal = Math.max(0.0, Math.min(1.0, hSliderRoot.clampedVal + delta));
                hSliderRoot.moved(newVal);
            }
        }
    }

    // Main Control Center Layout (Compact 600 x 240 px)
    Item {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 8
        implicitHeight: 224

        opacity: root.currentView === "main" ? 1.0 : 0.0
        scale: root.currentView === "main" ? 1.0 : 0.96
        visible: opacity > 0.01

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

        Column {
            anchors.fill: parent
            spacing: 6

            // TOP ROW: System Info (1), Weather (2), Power (3)
            Row {
                width: parent.width
                height: 48
                spacing: 6

                // 1. System Info (Top-Left, 342px)
                Item {
                    width: 342
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1; anchors.bottomMargin: -1
                        radius: 12; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                    }

                    Rectangle {
                        id: sysInfoCard
                        anchors.fill: parent
                        radius: 12
                        color: Theme.surfaceContainer
                        gradient: (Colors.activeTheme === "espresso") ? null : sysGrad
                        Gradient {
                            id: sysGrad
                            GradientStop { position: 0.0; color: Qt.tint(Theme.surfaceContainer, Qt.rgba(1, 1, 1, 0.03)) }
                            GradientStop { position: 1.0; color: Qt.darker(Theme.surfaceContainer, 1.04) }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: Theme.surfaceVariant
                                gradient: (Colors.activeTheme === "espresso") ? null : avatarGrad
                                Gradient {
                                    id: avatarGrad
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
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                    visible: !C.SystemInfo.profilePicture || C.SystemInfo.profilePicture == ""
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                width: 175

                                Row {
                                    spacing: 4
                                    Text {
                                        text: C.SystemInfo.username || "user"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: Theme.textPrimary
                                    }
                                    Text {
                                        text: "(" + (C.SystemInfo.hostname || "mango") + ")"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Normal
                                        color: Theme.textMuted
                                        anchors.baseline: parent.children[0].baseline
                                    }
                                }

                                Text {
                                    text: C.SystemInfo.uptimeLongText || "up just now"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    color: Theme.textMuted
                                }

                                Row {
                                    spacing: 3
                                    visible: root.netIp !== "" || root.netIfaceLabel !== ""

                                    Text {
                                        text: root.netIp
                                        font.family: "MesloLGS Nerd Font", "Noto Sans Mono", Theme.fontFamily
                                        font.pixelSize: 8
                                        color: Theme.textMuted
                                    }
                                    Text {
                                        text: "·"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        color: Theme.textDim
                                        visible: root.netIp !== "" && root.netIfaceLabel !== ""
                                    }
                                    Text {
                                        text: root.wifiSsid ? root.wifiSsid : root.netIfaceLabel
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                width: parent.width - 32 - 175 - 16

                                Rectangle {
                                    id: batPill
                                    anchors.right: parent.right
                                    height: 16
                                    width: batRow.implicitWidth + 8
                                    radius: 8
                                    readonly property color batColor: (Colors.activeTheme === "espresso")
                                        ? Theme.green
                                        : (C.Battery.percentage <= 20 ? Theme.error : (C.Battery.isCharging ? Theme.yellow : Theme.green))
                                    color: Qt.rgba(batColor.r, batColor.g, batColor.b, 0.16)

                                    Row {
                                        id: batRow
                                        anchors.centerIn: parent
                                        spacing: 3

                                        Text {
                                            text: C.Battery.isCharging ? "\ue3e7" : (C.Battery.percentage > 20 ? "\ue1a4" : "\ue19c")
                                            font.family: matSymbols.name
                                            font.pixelSize: 10
                                            color: batPill.batColor
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: C.Battery.percentage + "%"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            color: batPill.batColor
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                Row {
                                    anchors.right: parent.right
                                    spacing: 3
                                    Text { text: "↓"; font.pixelSize: 8; color: Theme.secondary; font.family: "MesloLGS Nerd Font" }
                                    Text { text: root.netRxFormatted; font.pixelSize: 8; font.weight: Font.DemiBold; color: Theme.textPrimary; font.family: "MesloLGS Nerd Font" }
                                    Text { text: "↑"; font.pixelSize: 8; color: Theme.tertiary; font.family: "MesloLGS Nerd Font" }
                                    Text { text: root.netTxFormatted; font.pixelSize: 8; font.weight: Font.DemiBold; color: Theme.textPrimary; font.family: "MesloLGS Nerd Font" }
                                }
                            }
                        }
                    }
                }

                // 2. Weather (Top-Middle, 194px)
                Item {
                    width: 194
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1; anchors.bottomMargin: -1
                        radius: 12; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                    }

                    Rectangle {
                        id: weatherCard
                        anchors.fill: parent
                        radius: 12
                        color: Theme.surfaceContainer
                        gradient: (Colors.activeTheme === "espresso") ? null : weatherGrad
                        Gradient {
                            id: weatherGrad
                            GradientStop { position: 0.0; color: Qt.tint(Theme.surfaceContainer, Qt.rgba(1, 1, 1, 0.03)) }
                            GradientStop { position: 1.0; color: Qt.darker(Theme.surfaceContainer, 1.04) }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: Qt.rgba(1, 1, 1, 0.04)
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: root.getAmbientMoodIcon(root.currentTime)
                                    font.family: matSymbols.name
                                    font.pixelSize: 18
                                    color: root.getAmbientMoodIconColor(root.currentTime)
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                width: parent.width - 40

                                Text {
                                    text: Math.round(WeatherService.temp) + "°C · " + (WeatherService.conditionText || "Clear")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: root.currentTime.toLocaleDateString(Qt.locale(), "ddd, d MMM")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }
                    }
                }

                // 3. Power (Top-Right, 38px)
                Item {
                    width: parent.width - 342 - 194 - 12
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1; anchors.bottomMargin: -1
                        radius: 12; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                    }

                    Rectangle {
                        id: powerCard
                        anchors.fill: parent
                        radius: 12
                        color: powerMouse.containsMouse
                            ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.20)
                            : Theme.surfaceContainer
                        scale: powerMouse.pressed ? 0.92 : (powerMouse.containsMouse ? 1.04 : 1.0)

                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\ue8ac"
                            font.family: matSymbols.name
                            font.pixelSize: 18
                            color: Theme.error
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ControlCenterService.close();
                                Quickshell.execDetached(["systemctl", "poweroff"]);
                            }
                        }
                    }
                }
            }

            // MIDDLE SECTION: Controls (Left) + Calendar (Right)
            Row {
                width: parent.width
                height: 124
                spacing: 6

                // Left Controls Block (378px)
                Column {
                    width: 378
                    height: parent.height
                    spacing: 6

                    // Row 1: 4 Quick Toggles
                    Row {
                        width: parent.width
                        height: 38
                        spacing: 6

                        // 4. Wi-Fi
                        Item {
                            width: (parent.width - 18) / 4
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 1; anchors.bottomMargin: -1
                                radius: 10; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                            }
                            Rectangle {
                                id: wifiTile
                                anchors.fill: parent
                                radius: 10
                                color: root.wifiEnabled ? Theme.wifiActive : (wifiMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                                scale: wifiMouse.pressed ? 0.95 : (wifiMouse.containsMouse ? 1.02 : 1.0)
                                gradient: (Colors.activeTheme === "espresso") ? null : wifiGrad

                                Gradient {
                                    id: wifiGrad
                                    GradientStop { position: 0.0; color: Qt.tint(wifiTile.color, Qt.rgba(1, 1, 1, root.wifiEnabled ? 0.06 : 0.03)) }
                                    GradientStop { position: 1.0; color: Qt.darker(wifiTile.color, 1.04) }
                                }
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                Behavior on scale { NumberAnimation { duration: 80 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6; anchors.rightMargin: 5
                                    spacing: 5

                                    Rectangle {
                                        width: 22; height: 22; radius: 11
                                        color: root.wifiEnabled ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: root.wifiEnabled ? "\ue63e" : "\ue648"
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
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
                                        width: parent.width - 27

                                        Text {
                                            text: "Wi-Fi"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: root.wifiEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                        }
                                        Text {
                                            text: root.wifiEnabled ? (root.wifiSsid ? root.wifiSsid : "On") : "Off"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                            color: root.wifiEnabled ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.78) : Theme.textMuted
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                    }
                                }

                                MouseArea {
                                    id: wifiMouse
                                    anchors.fill: parent
                                    anchors.leftMargin: 28
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!root.wifiEnabled) root.toggleWifi();
                                        root.currentView = "wifi";
                                        WifiService.isOpen = true;
                                    }
                                }
                            }
                        }

                        // 5. Bluetooth
                        Item {
                            width: (parent.width - 18) / 4
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 1; anchors.bottomMargin: -1
                                radius: 10; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                            }
                            Rectangle {
                                id: btTile
                                anchors.fill: parent
                                radius: 10
                                color: root.bluetoothEnabled ? Theme.bluetoothActive : (btMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                                scale: btMouse.pressed ? 0.95 : (btMouse.containsMouse ? 1.02 : 1.0)
                                gradient: (Colors.activeTheme === "espresso") ? null : btGrad

                                Gradient {
                                    id: btGrad
                                    GradientStop { position: 0.0; color: Qt.tint(btTile.color, Qt.rgba(1, 1, 1, root.bluetoothEnabled ? 0.06 : 0.03)) }
                                    GradientStop { position: 1.0; color: Qt.darker(btTile.color, 1.04) }
                                }
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                Behavior on scale { NumberAnimation { duration: 80 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6; anchors.rightMargin: 5
                                    spacing: 5

                                    Rectangle {
                                        width: 22; height: 22; radius: 11
                                        color: root.bluetoothEnabled ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: root.bluetoothEnabled ? "\ue1a7" : "\ue1a8"
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: root.bluetoothEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        width: parent.width - 27

                                        Text {
                                            text: "Bluetooth"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: root.bluetoothEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                        }
                                        Text {
                                            text: root.bluetoothEnabled ? "Active" : "Off"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                            color: root.bluetoothEnabled ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.78) : Theme.textMuted
                                            elide: Text.ElideRight
                                            width: parent.width
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

                        // 6. Focus
                        Item {
                            width: (parent.width - 18) / 4
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 1; anchors.bottomMargin: -1
                                radius: 10; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                            }
                            Rectangle {
                                id: dndTile
                                anchors.fill: parent
                                radius: 10
                                color: ControlCenterService.dndEnabled ? Theme.dndActive : (dndMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                                scale: dndMouse.pressed ? 0.95 : (dndMouse.containsMouse ? 1.02 : 1.0)
                                gradient: (Colors.activeTheme === "espresso") ? null : dndGrad
                                Gradient {
                                    id: dndGrad
                                    GradientStop { position: 0.0; color: Qt.tint(dndTile.color, Qt.rgba(1, 1, 1, ControlCenterService.dndEnabled ? 0.06 : 0.03)) }
                                    GradientStop { position: 1.0; color: Qt.darker(dndTile.color, 1.04) }
                                }
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                Behavior on scale { NumberAnimation { duration: 80 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6; anchors.rightMargin: 5
                                    spacing: 5

                                    Rectangle {
                                        width: 22; height: 22; radius: 11
                                        color: ControlCenterService.dndEnabled ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: ControlCenterService.dndEnabled ? "\ue7f6" : "\ue7f4"
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: ControlCenterService.dndEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        width: parent.width - 27

                                        Text {
                                            text: "Focus"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: ControlCenterService.dndEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                        }
                                        Text {
                                            text: ControlCenterService.dndEnabled ? "On" : "Off"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                            color: ControlCenterService.dndEnabled ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.78) : Theme.textMuted
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

                        // 7. Night Light
                        Item {
                            width: (parent.width - 18) / 4
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 1; anchors.bottomMargin: -1
                                radius: 10; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                            }
                            Rectangle {
                                id: nightTile
                                anchors.fill: parent
                                radius: 10
                                color: ControlCenterService.nightLightEnabled ? Theme.nightLightActive : (nightMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                                scale: nightMouse.pressed ? 0.95 : (nightMouse.containsMouse ? 1.02 : 1.0)
                                gradient: (Colors.activeTheme === "espresso") ? null : nightGrad
                                Gradient {
                                    id: nightGrad
                                    GradientStop { position: 0.0; color: Qt.tint(nightTile.color, Qt.rgba(1, 1, 1, ControlCenterService.nightLightEnabled ? 0.06 : 0.03)) }
                                    GradientStop { position: 1.0; color: Qt.darker(nightTile.color, 1.04) }
                                }
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                Behavior on scale { NumberAnimation { duration: 80 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6; anchors.rightMargin: 5
                                    spacing: 5

                                    Rectangle {
                                        width: 22; height: 22; radius: 11
                                        color: ControlCenterService.nightLightEnabled ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: "\uf03d"
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: ControlCenterService.nightLightEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        width: parent.width - 27

                                        Text {
                                            text: "Night"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: ControlCenterService.nightLightEnabled ? Theme.textOnPrimary : Theme.textPrimary
                                        }
                                        Text {
                                            text: ControlCenterService.nightLightEnabled ? "On" : "Off"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                            color: ControlCenterService.nightLightEnabled ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.78) : Theme.textMuted
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

                    // Row 2: Volume Slider (8) + Conservation Mode (9)
                    Row {
                        width: parent.width
                        height: 36
                        spacing: 6

                        M3HorizontalSlider {
                            width: parent.width - 90 - 6
                            height: parent.height
                            value: root.volLevel
                            isMuted: root.volMuted
                            activeColor: isMuted ? Theme.error : Theme.volumeActive
                            icon: (root.volMuted || root.volLevel === 0) ? "\ue04f" : (root.volLevel < 0.5 ? "\ue04d" : "\ue050")
                            mutedIcon: "\ue04f"
                            onMoved: val => root.setVolumeFraction(val)
                            onIconClicked: root.toggleMute()
                        }

                        Item {
                            width: 90
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 1; anchors.bottomMargin: -1
                                radius: 10; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                            }
                            Rectangle {
                                id: consTile
                                anchors.fill: parent
                                radius: 10
                                color: IdeapadService.conservationEnabled ? Theme.conservationActive : (consMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                                scale: consMouse.pressed ? 0.95 : (consMouse.containsMouse ? 1.02 : 1.0)
                                gradient: (Colors.activeTheme === "espresso") ? null : consGrad
                                Gradient {
                                    id: consGrad
                                    GradientStop { position: 0.0; color: Qt.tint(consTile.color, Qt.rgba(1, 1, 1, IdeapadService.conservationEnabled ? 0.06 : 0.03)) }
                                    GradientStop { position: 1.0; color: Qt.darker(consTile.color, 1.04) }
                                }
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                Behavior on scale { NumberAnimation { duration: 80 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6; anchors.rightMargin: 5
                                    spacing: 5

                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: IdeapadService.conservationEnabled ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18) : (Colors.activeTheme === "espresso" ? Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.14) : Qt.rgba(1, 1, 1, 0.06))
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: "\uea35"
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: IdeapadService.conservationEnabled ? Theme.textOnPrimary : (Colors.activeTheme === "espresso" ? Theme.green : Theme.textPrimary)
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        width: parent.width - 25

                                        Text {
                                            text: "Conserve"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            color: IdeapadService.conservationEnabled ? Theme.textOnPrimary : Theme.textPrimary
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
                    }

                    // Row 3: Brightness Slider (10) + Rapid Charge (11)
                    Row {
                        width: parent.width
                        height: 36
                        spacing: 6

                        M3HorizontalSlider {
                            width: parent.width - 90 - 6
                            height: parent.height
                            value: root.brightLevel
                            activeColor: Theme.brightnessActive
                            icon: "\ue518"
                            onMoved: val => root.setBrightnessFraction(val)
                            onIconClicked: {
                                if (root.brightLevel > 0.5) root.setBrightnessFraction(0.25);
                                else root.setBrightnessFraction(0.85);
                            }
                        }

                        Item {
                            width: 90
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 1; anchors.bottomMargin: -1
                                radius: 10; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                            }
                            Rectangle {
                                id: rapidTile
                                anchors.fill: parent
                                radius: 10
                                color: IdeapadService.rapidChargeEnabled ? Theme.rapidChargeActive : (rapidMouse.containsMouse ? Qt.lighter(Theme.surfaceContainer, 1.04) : Theme.surfaceContainer)
                                scale: rapidMouse.pressed ? 0.95 : (rapidMouse.containsMouse ? 1.02 : 1.0)
                                gradient: (Colors.activeTheme === "espresso") ? null : rapidGrad
                                Gradient {
                                    id: rapidGrad
                                    GradientStop { position: 0.0; color: Qt.tint(rapidTile.color, Qt.rgba(1, 1, 1, IdeapadService.rapidChargeEnabled ? 0.06 : 0.03)) }
                                    GradientStop { position: 1.0; color: Qt.darker(rapidTile.color, 1.04) }
                                }
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                Behavior on scale { NumberAnimation { duration: 80 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6; anchors.rightMargin: 5
                                    spacing: 5

                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: IdeapadService.rapidChargeEnabled ? Qt.rgba(Theme.textOnPrimary.r, Theme.textOnPrimary.g, Theme.textOnPrimary.b, 0.18) : (Colors.activeTheme === "espresso" ? Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.14) : Qt.rgba(1, 1, 1, 0.06))
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: "\uea0b"
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: IdeapadService.rapidChargeEnabled ? Theme.textOnPrimary : (Colors.activeTheme === "espresso" ? Theme.yellow : Theme.textPrimary)
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        width: parent.width - 25

                                        Text {
                                            text: "Rapid"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            color: IdeapadService.rapidChargeEnabled ? Theme.textOnPrimary : Theme.textPrimary
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
                }

                // 12. Calendar (Right Block, 200px)
                Item {
                    id: calContainer
                    width: parent.width - 378 - 6
                    height: parent.height

                    property int calYear: root.currentTime.getFullYear()
                    property int calMonth: root.currentTime.getMonth()

                    readonly property var monthNames: [
                        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
                    ]

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1; anchors.bottomMargin: -1
                        radius: 12; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                    }

                    Rectangle {
                        id: calendarCard
                        anchors.fill: parent
                        radius: 12
                        color: Theme.surfaceContainer
                        gradient: (Colors.activeTheme === "espresso") ? null : calGrad
                        Gradient {
                            id: calGrad
                            GradientStop { position: 0.0; color: Qt.tint(Theme.surfaceContainer, Qt.rgba(1, 1, 1, 0.03)) }
                            GradientStop { position: 1.0; color: Qt.darker(Theme.surfaceContainer, 1.04) }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 7
                            spacing: 4

                            Row {
                                width: parent.width
                                height: 18

                                Text {
                                    text: calContainer.monthNames[calContainer.calMonth] + " " + calContainer.calYear
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Item { width: parent.width - parent.children[0].width - 36; height: 1 }

                                Row {
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 16; height: 16; radius: 4
                                        color: prevMonthMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "\ue5cb"
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: Theme.textMuted
                                        }
                                        MouseArea {
                                            id: prevMonthMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (calContainer.calMonth === 0) {
                                                    calContainer.calMonth = 11;
                                                    calContainer.calYear--;
                                                } else {
                                                    calContainer.calMonth--;
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 16; height: 16; radius: 4
                                        color: nextMonthMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "\ue5cc"
                                            font.family: matSymbols.name
                                            font.pixelSize: 13
                                            color: Theme.textMuted
                                        }
                                        MouseArea {
                                            id: nextMonthMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (calContainer.calMonth === 11) {
                                                    calContainer.calMonth = 0;
                                                    calContainer.calYear++;
                                                } else {
                                                    calContainer.calMonth++;
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: Math.floor((parent.width - 7 * 20) / 6)

                                Repeater {
                                    model: 7
                                    Text {
                                        required property int index
                                        width: 20
                                        horizontalAlignment: Text.AlignHCenter
                                        text: ["S", "M", "T", "W", "T", "F", "S"][index]
                                        color: Theme.textMuted
                                        font.pixelSize: 8
                                        font.family: Theme.fontFamily
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Grid {
                                columns: 7
                                columnSpacing: Math.floor((parent.width - 7 * 20) / 6)
                                rowSpacing: 2

                                readonly property int firstDay: new Date(calContainer.calYear, calContainer.calMonth, 1).getDay()
                                readonly property int totalDays: new Date(calContainer.calYear, calContainer.calMonth + 1, 0).getDate()
                                readonly property int isCurrentMonth: (calContainer.calYear === root.currentTime.getFullYear() && calContainer.calMonth === root.currentTime.getMonth())

                                Repeater {
                                    model: 35

                                    Rectangle {
                                        id: dayCell
                                        required property int index
                                        width: 20; height: 14; radius: 5

                                        readonly property int dayNumber: index - parent.firstDay + 1
                                        readonly property bool isValid: dayNumber >= 1 && dayNumber <= parent.totalDays
                                        readonly property bool isToday: parent.isCurrentMonth && isValid && (dayNumber === root.currentTime.getDate())

                                        color: isToday ? Theme.primary : (dayMouse.containsMouse && isValid ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                                        Text {
                                            anchors.centerIn: parent
                                            text: dayCell.isValid ? dayCell.dayNumber : ""
                                            color: dayCell.isToday ? Theme.textOnPrimary : Theme.textPrimary
                                            font.pixelSize: 8
                                            font.family: Theme.fontFamily
                                            font.weight: dayCell.isToday ? Font.DemiBold : Font.Normal
                                        }

                                        MouseArea {
                                            id: dayMouse
                                            anchors.fill: parent
                                            hoverEnabled: dayCell.isValid
                                            cursorShape: dayCell.isValid ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // BOTTOM ROW: Keyboard RGB (13-15), Color (16), Theme (17)
            Row {
                width: parent.width
                height: 36
                spacing: 6

                // 13-15. Keyboard RGB Mode (186px)
                Item {
                    width: 186
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1; anchors.bottomMargin: -1
                        radius: 10; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                    }

                    Rectangle {
                        id: rgbModesCard
                        anchors.fill: parent
                        radius: 10
                        color: Theme.surfaceContainer
                        gradient: (Colors.activeTheme === "espresso") ? null : rgbModesGrad
                        Gradient {
                            id: rgbModesGrad
                            GradientStop { position: 0.0; color: Qt.tint(Theme.surfaceContainer, Qt.rgba(1, 1, 1, 0.03)) }
                            GradientStop { position: 1.0; color: Qt.darker(Theme.surfaceContainer, 1.04) }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4

                            Repeater {
                                model: [
                                    { id: "wave", name: "Wave", icon: "\ueb3e" },
                                    { id: "breath", name: "Breath", icon: "\uefd8" },
                                    { id: "static", name: "Static", icon: "\ue412" }
                                ]

                                Rectangle {
                                    id: rgbModeBtn
                                    required property var modelData
                                    readonly property bool isActive: RgbService.power && RgbService.mode === modelData.id

                                    width: Math.floor((parent.width - 8) / 3)
                                    height: parent.height
                                    radius: 7
                                    color: isActive ? Theme.selectionActive : (rgbBtnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
                                    scale: rgbBtnMouse.pressed ? 0.94 : (rgbBtnMouse.containsMouse ? 1.02 : 1.0)
                                    gradient: (Colors.activeTheme === "espresso") ? null : (isActive ? rgbGrad : rgbSubtleGrad)

                                    Gradient {
                                        id: rgbGrad
                                        GradientStop { position: 0.0; color: Qt.tint(Theme.selectionActive, Qt.rgba(1, 1, 1, 0.06)) }
                                        GradientStop { position: 1.0; color: Qt.darker(Theme.selectionActive, 1.04) }
                                    }

                                    Gradient {
                                        id: rgbSubtleGrad
                                        GradientStop { position: 0.0; color: Qt.tint(rgbModeBtn.color, Qt.rgba(1, 1, 1, 0.03)) }
                                        GradientStop { position: 1.0; color: Qt.darker(rgbModeBtn.color, 1.03) }
                                    }

                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                    Behavior on scale { NumberAnimation { duration: 80 } }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: rgbModeBtn.modelData.icon
                                            font.family: matSymbols.name
                                            font.pixelSize: 12
                                            color: rgbModeBtn.isActive ? Theme.textOnPrimary : Theme.textPrimary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: rgbModeBtn.modelData.name
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            font.weight: rgbModeBtn.isActive ? Font.DemiBold : Font.Normal
                                            color: rgbModeBtn.isActive ? Theme.textOnPrimary : Theme.textMuted
                                            anchors.verticalCenter: parent.verticalCenter
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
                        }
                    }
                }

                // 16. Keyboard Backlight Color (192px)
                Item {
                    width: 192
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1; anchors.bottomMargin: -1
                        radius: 10; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                    }

                    Rectangle {
                        id: rgbColorCard
                        anchors.fill: parent
                        radius: 10
                        color: Theme.surfaceContainer
                        gradient: (Colors.activeTheme === "espresso") ? null : rgbColorGrad
                        Gradient {
                            id: rgbColorGrad
                            GradientStop { position: 0.0; color: Qt.tint(Theme.surfaceContainer, Qt.rgba(1, 1, 1, 0.03)) }
                            GradientStop { position: 1.0; color: Qt.darker(Theme.surfaceContainer, 1.04) }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Repeater {
                                model: ["#ffffff", "#00d4ff", "#30d158", "#ffd60a", "#ff9500", "#ff3b30", "#bf5af2"]

                                Item {
                                    id: dotItem
                                    required property string modelData
                                    readonly property bool isActive: (RgbService.zones && RgbService.zones[0] ? RgbService.zones[0].toLowerCase() : "") === modelData.toLowerCase() && RgbService.mode === "static"

                                    width: 18
                                    height: 18

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: dotItem.isActive ? 18 : 0
                                        height: dotItem.isActive ? 18 : 0
                                        radius: 9
                                        color: Qt.rgba(colorDot.color.r, colorDot.color.g, colorDot.color.b, 0.28)
                                        visible: dotItem.isActive

                                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                    }

                                    Rectangle {
                                        id: colorDot
                                        anchors.centerIn: parent
                                        width: dotItem.isActive ? 11 : (dotMouse.containsMouse ? 11 : 9)
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

                // 17. Shell Theme Carousel (200px)
                Item {
                    width: parent.width - 186 - 192 - 12
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1; anchors.bottomMargin: -1
                        radius: 10; color: Qt.rgba(0, 0, 0, 0.16); z: -1
                    }

                    Rectangle {
                        id: themeCarouselCard
                        anchors.fill: parent
                        radius: 10
                        color: Theme.surfaceContainer
                        gradient: (Colors.activeTheme === "espresso") ? null : carouselGrad
                        Gradient {
                            id: carouselGrad
                            GradientStop { position: 0.0; color: Qt.tint(Theme.surfaceContainer, Qt.rgba(1, 1, 1, 0.03)) }
                            GradientStop { position: 1.0; color: Qt.darker(Theme.surfaceContainer, 1.04) }
                        }

                        readonly property var themes: [
                            { id: "monochrome", label: "Mono" },
                            { id: "vercel",     label: "Vercel" },
                            { id: "everblush",  label: "Everblush" },
                            { id: "wallpaper",  label: "Wall" },
                            { id: "gruvbox",    label: "Gruvbox" },
                            { id: "everforest", label: "Forest" },
                            { id: "monokai",    label: "Monokai" },
                            { id: "catppuccin", label: "Catppuccin" },
                            { id: "ayu_dark",   label: "Ayu" },
                            { id: "espresso",   label: "Espresso" }
                        ]

                        property int pageIndex: 0
                        readonly property int visibleItems: 2
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
                            anchors.margins: 4
                            spacing: 4

                            Rectangle {
                                width: 18
                                height: parent.height
                                radius: 6
                                color: leftArrowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                scale: leftArrowMouse.pressed ? 0.90 : 1.0
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                Behavior on scale { NumberAnimation { duration: 80 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\ue5cb"
                                    font.family: matSymbols.name
                                    font.pixelSize: 14
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

                            Row {
                                width: parent.width - 36 - 8
                                height: parent.height
                                spacing: 4

                                Repeater {
                                    model: themeCarouselCard.visibleItems

                                    Rectangle {
                                        id: themeBtn
                                        required property int modelData
                                        readonly property int itemIdx: themeCarouselCard.pageIndex * themeCarouselCard.visibleItems + modelData
                                        readonly property var themeItem: itemIdx < themeCarouselCard.themes.length ? themeCarouselCard.themes[itemIdx] : null
                                        readonly property bool isSelected: themeItem ? (ShellConfig.currentTheme === themeItem.id) : false

                                        width: Math.floor((parent.width - 4) / 2)
                                        height: parent.height
                                        radius: 7
                                        visible: themeItem !== null
                                        color: isSelected ? Theme.selectionActive : (themeBtnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
                                        scale: themeBtnMouse.pressed ? 0.95 : (themeBtnMouse.containsMouse ? 1.02 : 1.0)
                                        gradient: (Colors.activeTheme === "espresso") ? null : (isSelected ? themeGrad : themeSubtleGrad)

                                        Gradient {
                                            id: themeGrad
                                            GradientStop { position: 0.0; color: Qt.tint(Theme.selectionActive, Qt.rgba(1, 1, 1, 0.06)) }
                                            GradientStop { position: 1.0; color: Qt.darker(Theme.selectionActive, 1.04) }
                                        }

                                        Gradient {
                                            id: themeSubtleGrad
                                            GradientStop { position: 0.0; color: Qt.tint(themeBtn.color, Qt.rgba(1, 1, 1, 0.03)) }
                                            GradientStop { position: 1.0; color: Qt.darker(themeBtn.color, 1.03) }
                                        }

                                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                        Behavior on scale { NumberAnimation { duration: 80 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: themeBtn.themeItem ? themeBtn.themeItem.label : ""
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
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

                            Rectangle {
                                width: 18
                                height: parent.height
                                radius: 6
                                color: rightArrowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                scale: rightArrowMouse.pressed ? 0.90 : 1.0
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                Behavior on scale { NumberAnimation { duration: 80 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\ue5cc"
                                    font.family: matSymbols.name
                                    font.pixelSize: 14
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
        }
    }

    WifiView {
        id: wifiSurfaceView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
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
