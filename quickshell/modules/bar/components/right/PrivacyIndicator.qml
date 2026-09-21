import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../theme"

Item {
    id: root

    property bool micActive: false
    property bool camActive: false
    readonly property bool hasActive: micActive || camActive
    readonly property bool bothActive: micActive && camActive

    // Alternating state: true = icon phase, false = pulse dot phase
    property bool showingIcon: true

    implicitHeight: 20
    implicitWidth: capsule.width
    height: implicitHeight
    width: implicitWidth
    visible: width > 0

    // Material Symbols Rounded Font
    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    readonly property string iconFontFamily: matSymbols.name.length > 0 ? matSymbols.name : "Material Symbols Rounded"

    // Process to check status of mic and camera using PipeWire/WirePlumber
    Process {
        id: checkProc
        command: ["/bin/bash", "/home/vin/.config/quickshell/scripts/check_privacy.sh"]
        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim();
                root.micActive = trimmed.includes("mic");
                root.camActive = trimmed.includes("cam");
            }
        }
    }

    // Periodic check every 800ms
    Timer {
        id: pollTimer
        interval: 800
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkProc.running) {
                checkProc.running = true;
            }
        }
    }

    // Unified Green Palette
    readonly property color greenColor: "#22c55e"
    readonly property color containerColor: Qt.rgba(0.13, 0.77, 0.37, 0.22)

    // Alternating Cycle Controller: Camera / Mic Icons <---> Pulse Dot
    SequentialAnimation {
        id: alternateAnim
        running: root.hasActive
        loops: Animation.Infinite

        // 1. Tampilkan Ikon Mic/Cam dulu selama 2.2 detik agar user langsung tahu statusnya
        ScriptAction { script: root.showingIcon = true }
        PauseAnimation { duration: 2200 }

        // 2. Bergantian tampilkan Pulse Dot selama 2 detik
        ScriptAction { script: root.showingIcon = false }
        PauseAnimation { duration: 2000 }
    }

    onHasActiveChanged: {
        if (root.hasActive) {
            root.showingIcon = true;
            alternateAnim.restart();
        } else {
            root.showingIcon = false;
        }
    }

    // Single Unified Borderless Green Capsule
    Rectangle {
        id: capsule
        anchors.centerIn: parent
        height: 20
        radius: 10
        clip: true
        color: root.containerColor
        border.width: 0

        // Adaptive symmetric width with smooth transition
        width: root.hasActive ? Math.round(Math.max(28, iconRow.width + 16)) : 0
        opacity: root.hasActive ? 1.0 : 0.0

        Behavior on width {
            NumberAnimation {
                duration: Theme.animDurationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animDurationFast
                easing.type: Easing.OutQuad
            }
        }

        // =====================================================================
        // FASE A: Pulse Dot (Aktif saat showingIcon == false)
        // =====================================================================
        Item {
            id: pulseBox
            anchors.centerIn: parent
            width: 16
            height: 16
            opacity: (!root.showingIcon && root.hasActive) ? 1.0 : 0.0
            scale: (!root.showingIcon && root.hasActive) ? 1.0 : 0.75

            Behavior on opacity {
                NumberAnimation { duration: 280; easing.type: Easing.InOutQuad }
            }
            Behavior on scale {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }

            // Outer expanding ripple ring
            Rectangle {
                id: pulseRing
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: "transparent"
                border.width: 1
                border.color: root.greenColor

                SequentialAnimation {
                    running: root.hasActive && !root.showingIcon
                    loops: Animation.Infinite
                    ParallelAnimation {
                        NumberAnimation {
                            target: pulseRing
                            property: "scale"
                            from: 1.0
                            to: 1.9
                            duration: 1800
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: pulseRing
                            property: "opacity"
                            from: 0.75
                            to: 0.0
                            duration: 1800
                            easing.type: Easing.OutQuad
                        }
                    }
                    PauseAnimation { duration: 250 }
                }
            }

            // Inner solid breathing dot
            Rectangle {
                id: innerDot
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                color: root.greenColor

                SequentialAnimation {
                    running: root.hasActive && !root.showingIcon
                    loops: Animation.Infinite
                    NumberAnimation {
                        target: innerDot
                        property: "scale"
                        to: 1.25
                        duration: 900
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: innerDot
                        property: "scale"
                        to: 1.0
                        duration: 900
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }

        // =====================================================================
        // FASE B: Ikon Camera & Mic (Aktif saat showingIcon == true)
        // =====================================================================
        Row {
            id: iconRow
            anchors.centerIn: parent
            height: 16
            spacing: 6
            opacity: (root.showingIcon && root.hasActive) ? 1.0 : 0.0
            scale: (root.showingIcon && root.hasActive) ? 1.0 : 0.75

            Behavior on opacity {
                NumberAnimation { duration: 280; easing.type: Easing.InOutQuad }
            }
            Behavior on scale {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }

            // 1. Camera Icon Box
            Item {
                visible: root.camActive
                width: 14
                height: 16
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: root.iconFontFamily
                    font.pixelSize: 14
                    color: root.greenColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // 2. Microphone Icon Box
            Item {
                visible: root.micActive
                width: 14
                height: 16
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: root.iconFontFamily
                    font.pixelSize: 14
                    color: root.greenColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
