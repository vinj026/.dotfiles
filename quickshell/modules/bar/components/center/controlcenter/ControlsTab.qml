import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../../../theme"
import "../../../../../components"
import "../../../../../core" as C

Item {
    id: root

    property bool active: false
    property string symbolFont: ""

    // ── State Properties ──
    property bool wifiEnabled: true
    property string wifiSsid: ""
    property bool bluetoothEnabled: false
    
    // Bind directly to real-time services
    readonly property real volLevel: C.Audio.volLevel / 100.0
    readonly property bool volMuted: C.Audio.volMuted
    readonly property real brightLevel: C.Brightness.level / 100.0
    readonly property bool micMuted: C.Audio.micMuted
    
    property string currentSinkName: "Speakers"
    property int currentSinkId: 0
    property string powerProfile: "balanced"

    implicitWidth: 348
    implicitHeight: mainCol.implicitHeight

    // ── Hardware Queries ──
    Process {
        id: wifiProc
        command: ["bash", "-c", "echo \"$(nmcli radio wifi)|$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes:' | cut -d: -f2 | head -n1)\""]
        stdout: SplitParser { onRead: data => {
            let p = data.trim().split("|");
            root.wifiEnabled = (p[0] === "enabled");
            root.wifiSsid = p[1] || "";
        }}
    }
    Process {
        id: btProc
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'on' || echo 'off'"]
        stdout: SplitParser { onRead: data => { root.bluetoothEnabled = (data.trim() === "on"); } }
    }
    Process {
        id: sinkProc
        command: ["bash", "-c", "wpctl status | awk '/Sinks:/,/Sources:/' | grep -E '\\*\\s+[0-9]+' | head -n1"]
        stdout: SplitParser { onRead: data => {
            let m = data.trim().match(/\*\s+(\d+)\.\s+(.*)/);
            if (m) {
                root.currentSinkId = parseInt(m[1]) || 0;
                let n = m[2] || "";
                root.currentSinkName = n.toLowerCase().includes("head") ? "Headphones" : n.toLowerCase().includes("hdmi") ? "HDMI" : "Speakers";
            }
        }}
    }
    Process {
        id: powerProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser { onRead: data => { let p = data.trim(); if (p) root.powerProfile = p; } }
    }

    Timer {
        interval: 2000; repeat: true; running: root.active; triggeredOnStart: true
        onTriggered: {
            if (!wifiProc.running) wifiProc.running = true;
            if (!btProc.running) btProc.running = true;
            if (!sinkProc.running) sinkProc.running = true;
            if (!powerProc.running) powerProc.running = true;
        }
    }

    // ── Actions ──
    function toggleWifi() {
        Quickshell.execDetached(["bash", "-c", root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"]);
        root.wifiEnabled = !root.wifiEnabled;
        Qt.callLater(() => { if (!wifiProc.running) wifiProc.running = true; });
    }
    function toggleBluetooth() {
        Quickshell.execDetached(["bash", "-c", root.bluetoothEnabled ? "bluetoothctl power off" : "bluetoothctl power on"]);
        root.bluetoothEnabled = !root.bluetoothEnabled;
    }
    function toggleMute() {
        C.Audio.toggleMute();
    }
    function setVolumeFraction(f) {
        C.Audio.setVolume(f * 100);
    }
    function setBrightnessFraction(f) {
        C.Brightness.setBrightness(f * 100);
    }
    function cycleAudioSink() { Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/scripts/cycle_sink.sh"]); }
    function toggleMic() {
        C.Audio.toggleMicMute();
    }
    function setProfile(id) {
        root.powerProfile = id;
        Quickshell.execDetached(["powerprofilesctl", "set", id]);
    }

    // ── Layout ──
    Column {
        id: mainCol
        width: parent.width
        spacing: 8

        // ── Quick Toggles Grid (2×2 MD3 Tiles) ──
        Grid {
            id: toggleGrid
            width: parent.width
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            readonly property real tileW: (width - 8) / 2

            // Wi-Fi Tile
            Rectangle {
                id: wifiTile
                width: toggleGrid.tileW
                height: 72
                radius: Theme.shapeCornerExtraLarge
                color: root.wifiEnabled ? Theme.primaryContainer : Theme.surfaceContainerHigh
                scale: wifiMouse.pressed ? 0.94 : 1.0
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: root.wifiEnabled ? Theme.primary : Theme.surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Text {
                            anchors.centerIn: parent
                            font.family: root.symbolFont; font.pixelSize: 18
                            text: root.wifiEnabled ? "\ue63e" : "\ue648"
                            color: root.wifiEnabled ? Theme.onPrimary : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                    }
                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                        text: root.wifiEnabled ? (root.wifiSsid || "Wi-Fi") : "Wi-Fi Off"
                        color: root.wifiEnabled ? Theme.onPrimaryContainer : Theme.textMuted
                        elide: Text.ElideRight; width: toggleGrid.tileW - 28
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    }
                }

                MouseArea {
                    id: wifiMouse; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: root.toggleWifi()
                }
            }

            // Bluetooth Tile
            Rectangle {
                id: btTile
                width: toggleGrid.tileW
                height: 72
                radius: Theme.shapeCornerExtraLarge
                color: root.bluetoothEnabled ? Theme.secondaryContainer : Theme.surfaceContainerHigh
                scale: btMouse.pressed ? 0.94 : 1.0
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: root.bluetoothEnabled ? Theme.secondary : Theme.surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Text {
                            anchors.centerIn: parent
                            font.family: root.symbolFont; font.pixelSize: 18
                            text: "\ue1aa"
                            color: root.bluetoothEnabled ? Theme.onSecondary : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                    }
                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                        text: root.bluetoothEnabled ? "Bluetooth On" : "Bluetooth"
                        color: root.bluetoothEnabled ? Theme.onSecondaryContainer : Theme.textMuted
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    }
                }

                MouseArea {
                    id: btMouse; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: root.toggleBluetooth()
                }
            }

            // Mic Tile
            Rectangle {
                id: micTile
                width: toggleGrid.tileW
                height: 72
                radius: Theme.shapeCornerExtraLarge
                color: root.micMuted ? Theme.errorContainer : Theme.surfaceContainerHigh
                scale: micMouse.pressed ? 0.94 : 1.0
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: root.micMuted ? Theme.error : Theme.surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Text {
                            anchors.centerIn: parent
                            font.family: root.symbolFont; font.pixelSize: 18
                            text: root.micMuted ? "\ue02b" : "\ue029"
                            color: root.micMuted ? Theme.onError : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                    }
                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                        text: root.micMuted ? "Mic Muted" : "Mic On"
                        color: root.micMuted ? Theme.onErrorContainer : Theme.textMuted
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    }
                }

                MouseArea {
                    id: micMouse; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: root.toggleMic()
                }
            }

            // Audio Sink Tile
            Rectangle {
                id: sinkTile
                width: toggleGrid.tileW
                height: 72
                radius: Theme.shapeCornerExtraLarge
                color: Theme.surfaceContainerHigh
                scale: sinkMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: Theme.surfaceContainerHighest
                        Text {
                            anchors.centerIn: parent
                            font.family: root.symbolFont; font.pixelSize: 18
                            text: root.currentSinkName === "Headphones" ? "\ue310" : "\ue32d"
                            color: Theme.primary
                        }
                    }
                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                        text: root.currentSinkName
                        color: Theme.textPrimary
                        elide: Text.ElideRight; width: toggleGrid.tileW - 28
                    }
                }

                MouseArea {
                    id: sinkMouse; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: root.cycleAudioSink()
                }
            }

            // Screen Record Tile (wf-recorder + slurp via ScreenRecordService)
            Rectangle {
                id: recTile
                width: toggleGrid.tileW
                height: 72
                radius: Theme.shapeCornerExtraLarge
                color: ScreenRecordService.isRecording ? Theme.errorContainer : Theme.surfaceContainerHigh
                scale: recTileMouse.pressed ? 0.94 : 1.0
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: ScreenRecordService.isRecording ? Theme.error : Theme.surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Text {
                            anchors.centerIn: parent
                            font.family: root.symbolFont; font.pixelSize: 18
                            text: "\ue061" // fiber_manual_record
                            color: ScreenRecordService.isRecording ? Theme.textOnErrorContainer : Theme.textMuted
                        }
                    }

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                        text: ScreenRecordService.isRecording ? ("Rec " + ScreenRecordService.recordingTimeStr) : "Screen Record"
                        color: ScreenRecordService.isRecording ? Theme.error : Theme.textPrimary
                    }
                }

                MouseArea {
                    id: recTileMouse; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: ScreenRecordService.toggleRecording()
                }
            }
        }

        // ── Power Profile Segmented Control ──
        Rectangle {
            width: parent.width
            height: 36
            radius: Theme.shapeCornerFull
            color: Theme.surfaceContainerHigh

            Row {
                id: profileRow
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                readonly property var profiles: [
                    { "id": "power-saver", "name": "Quiet",    "icon": "\ue2e6" },
                    { "id": "balanced",    "name": "Balanced", "icon": "\ue3e7" },
                    { "id": "performance", "name": "Power",    "icon": "\uea0b" }
                ]

                Repeater {
                    model: profileRow.profiles.length

                    Item {
                        id: profItem
                        width: (profileRow.width - 6) / 3
                        height: profileRow.height
                        readonly property var pData: profileRow.profiles[index]
                        readonly property bool isSelected: root.powerProfile === pData.id

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.shapeCornerFull
                            color: profItem.isSelected ? Theme.primaryContainer : "transparent"
                            scale: profMouse.pressed ? 0.93 : (profMouse.containsMouse ? 1.06 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.family: root.symbolFont; font.pixelSize: 14
                                    text: profItem.pData.icon
                                    color: profItem.isSelected ? Theme.primary : Theme.textMuted
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.family: Theme.fontFamily; font.pixelSize: 11
                                    font.weight: profItem.isSelected ? Font.Bold : Font.Medium
                                    text: profItem.pData.name
                                    color: profItem.isSelected ? Theme.onPrimaryContainer : Theme.textMuted
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                }
                            }
                        }

                        MouseArea {
                            id: profMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: root.setProfile(profItem.pData.id)
                        }
                    }
                }
            }
        }

        // ── Volume Slider ──
        M3Slider {
            width: parent.width
            value: root.volLevel
            isMuted: root.volMuted
            icon: "\ue050"; mutedIcon: "\ue04f"
            symbolFont: root.symbolFont
            onMoved: val => root.setVolumeFraction(val)
            onIconClicked: root.toggleMute()
        }

        // ── Brightness Slider ──
        M3Slider {
            width: parent.width
            value: root.brightLevel
            icon: "\ue518"; mutedIcon: "\ue518"
            symbolFont: root.symbolFont
            onMoved: val => root.setBrightnessFraction(val)
        }

        // ── Power & Session (destructive actions live in the Power tab, behind Heat Hold) ──
        Rectangle {
            width: parent.width
            height: 40
            radius: Theme.shapeCornerFull
            color: powerEntryMouse.pressed ? Theme.secondaryContainer : Theme.surfaceContainerHigh
            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.symbolFont; font.pixelSize: 16
                    text: "\ue8ac"
                    color: Theme.primary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold
                    text: "Power & Session"
                    color: Theme.textPrimary
                }
            }

            MouseArea {
                id: powerEntryMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ControlCenterService.openTab("power")
            }
        }
    }
}
