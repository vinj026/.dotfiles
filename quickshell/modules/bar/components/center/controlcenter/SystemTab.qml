import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../../../theme"

Item {
    id: root

    property bool active: false
    property string symbolFont: ""

    // Telemetry values
    property int cpuPct: 0
    property int cpuTemp: 45
    property int ramPct: 0
    property string ramStr: "0.0/0.0 GB"
    property int swapPct: 0
    property string rxSpeed: "0 B/s"
    property string txSpeed: "0 B/s"
    property int batPct: 100
    property real batW: 0.0
    property string batStatus: "Discharging"

    implicitWidth: 348
    implicitHeight: mainCol.implicitHeight

    Process {
        id: statProc
        command: ["python3", "/home/vin/.config/quickshell/scripts/system_stats.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let d = JSON.parse(data.trim());
                    root.cpuPct    = d.cpu_pct    || 0;
                    root.cpuTemp   = d.temp       || 45;
                    root.ramPct    = d.ram_pct    || 0;
                    root.ramStr    = d.ram_str    || "";
                    root.swapPct   = d.swap_pct   || 0;
                    root.rxSpeed   = d.rx_str     || "0 B/s";
                    root.txSpeed   = d.tx_str     || "0 B/s";
                    root.batPct    = d.bat_pct    || 100;
                    root.batW      = d.bat_w      || 0.0;
                    root.batStatus = d.bat_status || "Discharging";
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 2500; repeat: true; running: root.active; triggeredOnStart: true
        onTriggered: { if (!statProc.running) statProc.running = true; }
    }

    // ── Helper: gauge color by percent ──
    function gaugeColor(pct) {
        return pct > 85 ? Theme.error : pct > 60 ? Theme.tertiary : Theme.primary;
    }

    Column {
        id: mainCol
        width: parent.width
        spacing: 8

        // ── CPU + RAM Row ──
        Row {
            width: parent.width
            spacing: 8

            // CPU Card
            Rectangle {
                width: (parent.width - 8) / 2; height: 80
                radius: Theme.shapeCornerExtraLarge
                color: Theme.surfaceContainerHigh

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Row {
                        width: parent.width
                        Text {
                            font.family: root.symbolFont; font.pixelSize: 14
                            text: "\ue322"; color: root.gaugeColor(root.cpuPct)
                        }
                        Item { width: parent.width - cpuLbl.implicitWidth - 18; height: 1 }
                        Text {
                            id: cpuLbl
                            font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Font.Medium
                            text: root.cpuTemp + "°C"; color: Theme.textMuted
                        }
                    }

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 20; font.weight: Font.Bold
                        text: root.cpuPct + "%"; color: Theme.textPrimary
                    }

                    Rectangle {
                        width: parent.width; height: 4; radius: 2
                        color: Theme.surfaceContainerHighest
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, root.cpuPct / 100))
                            height: parent.height; radius: 2
                            color: root.gaugeColor(root.cpuPct)
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                        }
                    }
                }
            }

            // RAM Card
            Rectangle {
                width: (parent.width - 8) / 2; height: 80
                radius: Theme.shapeCornerExtraLarge
                color: Theme.surfaceContainerHigh

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Row {
                        width: parent.width
                        Text {
                            font.family: root.symbolFont; font.pixelSize: 14
                            text: "\ue322"; color: root.gaugeColor(root.ramPct)
                        }
                        Item { width: parent.width - ramLbl.implicitWidth - 18; height: 1 }
                        Text {
                            id: ramLbl
                            font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Font.Medium
                            text: root.ramStr; color: Theme.textMuted
                            elide: Text.ElideRight; width: 70
                        }
                    }

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 20; font.weight: Font.Bold
                        text: root.ramPct + "%"; color: Theme.textPrimary
                    }

                    Rectangle {
                        width: parent.width; height: 4; radius: 2
                        color: Theme.surfaceContainerHighest
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, root.ramPct / 100))
                            height: parent.height; radius: 2
                            color: root.gaugeColor(root.ramPct)
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                        }
                    }
                }
            }
        }

        // ── Network Row ──
        Rectangle {
            width: parent.width; height: 52
            radius: Theme.shapeCornerExtraLarge
            color: Theme.surfaceContainerHigh

            Row {
                anchors.fill: parent; anchors.margins: 14
                spacing: 0

                // Download
                Row {
                    width: parent.width / 2; spacing: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 16; text: "\ue5db"; color: Theme.primary }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 1
                        Text { font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Font.Medium; text: "DOWN"; color: Theme.textMuted }
                        Text { font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold; text: root.rxSpeed; color: Theme.textPrimary }
                    }
                }

                // Upload
                Row {
                    width: parent.width / 2; spacing: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: Qt.rgba(Theme.tertiary.r, Theme.tertiary.g, Theme.tertiary.b, 0.12)
                        anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 16; text: "\ue5d8"; color: Theme.tertiary }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 1
                        Text { font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Font.Medium; text: "UP"; color: Theme.textMuted }
                        Text { font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold; text: root.txSpeed; color: Theme.textPrimary }
                    }
                }
            }
        }

        // ── Battery Row ──
        Rectangle {
            width: parent.width; height: 52
            radius: Theme.shapeCornerExtraLarge
            color: Theme.surfaceContainerHigh

            Item {
                anchors.fill: parent; anchors.margins: 14

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: Theme.primaryContainer
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 16
                            text: (root.batStatus === "Charging") ? "\ue1a3" : "\ue1a4"
                            color: Theme.onPrimaryContainer
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 1
                        Text {
                            font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold
                            text: "Battery · " + root.batPct + "%"; color: Theme.textPrimary
                        }
                        Text {
                            font.family: Theme.fontFamily; font.pixelSize: 10
                            text: root.batStatus + (root.batW > 0 ? " · " + root.batW + "W" : "")
                            color: Theme.textMuted
                        }
                    }
                }

                // Battery bar
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 72; height: 4; radius: 2
                    color: Theme.surfaceContainerHighest
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.batPct / 100))
                        height: parent.height; radius: 2
                        color: root.batPct < 20 ? Theme.error : Theme.primary
                    }
                }
            }
        }
    }
}
