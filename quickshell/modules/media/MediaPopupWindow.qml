pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../components"
import "../../core" as Core

PanelWindow {
    id: root



    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    readonly property bool isTargetScreen: (MediaPopupService.targetMonitor === "" && screen === Quickshell.screens[0]) || (MediaPopupService.targetMonitor === screen.name)
    readonly property bool active: MediaPopupService.isOpen && isTargetScreen && ShellConfig.currentStyle !== "notch"

    onActiveChanged: console.log("[MEDIA WINDOW]", "screen:", screen.name, "target:", MediaPopupService.targetMonitor, "isOpen:", MediaPopupService.isOpen, "active:", active)

    visible: active || card.opacity > 0.01

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.namespace: "media-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // Close on ESC key
    Item {
        focus: root.active
        Keys.onEscapePressed: MediaPopupService.close()
    }

    // Dismiss backdrop
    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: MediaPopupService.close()
    }

    // Track change pulse effect for Ukishima Play/Pause Seal
    property real sealPulse: 0
    SequentialAnimation {
        id: pulseAnim
        NumberAnimation { target: root; property: "sealPulse"; to: 1.0; duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        NumberAnimation { target: root; property: "sealPulse"; to: 0.0; duration: 240; easing.type: Easing.OutCubic }
    }

    Connections {
        target: MediaService
        function onTitleChanged() {
            if (MediaService.isPlaying) pulseAnim.restart();
        }
    }

    // ════════════════════════════════════════════════════════════════
    // Ukishima Floating Media Card
    // ════════════════════════════════════════════════════════════════
    Rectangle {
        id: card
        width: 410
        height: rightSection.height + 24
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.active ? 38 : 14

        opacity: root.active ? 1.0 : 0.0
        scale: root.active ? 1.0 : 0.96

        Behavior on y {
            NumberAnimation {
                duration: root.active ? Theme.durationGlide : 90
                easing.type: root.active ? Theme.easeMorph : Easing.InQuad
                easing.bezierCurve: Theme.morphCurve
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.active ? 130 : 80
                easing.type: Easing.OutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.active ? Theme.durationGlide : 90
                easing.type: root.active ? Theme.easeMorph : Easing.InQuad
                easing.bezierCurve: Theme.morphCurve
            }
        }

        radius: 14
        color: Theme.surface
        border.width: 0
        border.color: "transparent"
        antialiasing: false
        smooth: false

        // Consume clicks inside card
        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            onClicked: {}
        }

        // Inner Content Container: disappears in 60ms on close to eliminate ghosting
        Item {
            id: cardContent
            anchors.fill: parent
            opacity: root.active ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: root.active ? 160 : 60
                    easing.type: Easing.OutQuad
                }
            }

            // ────────────────────────────────────────────────────────────
            // 1. LEFT COLUMN: Rounded Cover Art (matches right section height)
            // ────────────────────────────────────────────────────────────
            Item {
                id: coverContainer
                width: rightSection.height
                height: rightSection.height
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: coverBg
                    anchors.fill: parent
                    radius: 14
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.8)
                    border.width: 0

                    // Fallback 3-bar animated equalizer
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        visible: coverImg.status !== Image.Ready && MediaService.isPlaying

                        Repeater {
                            model: 3
                            Rectangle {
                                id: barRect
                                required property int index
                                width: 4
                                height: 6 + Math.random() * 12
                                radius: 2
                                color: Theme.primary

                                SequentialAnimation on height {
                                    loops: Animation.Infinite
                                    running: MediaService.isPlaying
                                    NumberAnimation {
                                        to: 6 + Math.random() * 16
                                        duration: 250 + barRect.index * 50
                                        easing.type: Easing.InOutQuad
                                    }
                                    NumberAnimation {
                                        to: 6
                                        duration: 250 + barRect.index * 50
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                        }
                    }

                    // Fallback icon when not playing/loading
                    Text {
                        anchors.centerIn: parent
                        font.family: matSymbols.name
                        font.pixelSize: 24
                        text: "\uE405"
                        color: Theme.textDim
                        visible: coverImg.status !== Image.Ready && !MediaService.isPlaying
                    }
                }

                // Real Album Art
                Image {
                    id: coverImg
                    anchors.fill: parent
                    source: MediaService.artUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 152
                    sourceSize.height: 152
                    visible: false
                }

                Rectangle {
                    id: coverMask
                    anchors.fill: parent
                    radius: 14
                    border.width: 0
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: coverImg
                    maskSource: coverMask
                    cached: true
                    visible: coverImg.status === Image.Ready
                }
            }

            // ────────────────────────────────────────────────────────────
            // 2. RIGHT COLUMN: Header, Track Info, Soundwave Bar Seekbar & Controls
            // ────────────────────────────────────────────────────────────
            Item {
                id: rightSection
                anchors.left: coverContainer.right
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: seekbarRow.y + seekbarRow.height

                // Track Info
                Column {
                    id: trackInfoCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: controlsRow.left
                    anchors.rightMargin: 12
                    spacing: 4

                    Text {
                        id: titleText
                        width: parent.width
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: MediaService.title || "No Media"
                        elide: Text.ElideRight
                    }

                    Text {
                        id: artistText
                        width: parent.width
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.textDim
                        text: MediaService.subline || (MediaService.artist || "Unknown Artist")
                        elide: Text.ElideRight
                    }
                }

                // Transport Controls
                Row {
                    id: controlsRow
                    anchors.verticalCenter: trackInfoCol.verticalCenter
                    anchors.verticalCenterOffset: 4
                    anchors.right: parent.right
                    spacing: 12

                    // Previous
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        border.width: 0
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        scale: prevMouse.pressed ? 0.88 : (prevMouse.containsMouse ? 1.08 : 1.0)
                        Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }

                        Text {
                            anchors.centerIn: parent
                            font.family: matSymbols.name
                            font.pixelSize: 14
                            text: "\uE045" // skip_previous
                            color: Theme.textPrimary
                            opacity: prevMouse.containsMouse ? 1.0 : 0.75
                            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MediaService.previous()
                        }
                    }

                    // Play/Pause
                    Item {
                        width: 32
                        height: 26
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            id: playCircleBtn
                            anchors.fill: parent
                            radius: 6
                            border.width: 0
                            color: MediaService.isLive ? "#ff453a" : Theme.primary
                            scale: (playBtnMouse.pressed ? 0.90 : (playBtnMouse.containsMouse ? 1.06 : 1.0)) * (1.0 + 0.08 * root.sealPulse)
                            Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }

                            Text {
                                anchors.centerIn: parent
                                font.family: matSymbols.name
                                font.pixelSize: 15
                                text: MediaService.isPlaying ? "\uE034" : "\uE037"
                                color: "#141416"
                            }

                            MouseArea {
                                id: playBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MediaService.togglePlay()
                            }
                        }
                    }

                    // Next
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        border.width: 0
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        scale: nextMouse.pressed ? 0.88 : (nextMouse.containsMouse ? 1.08 : 1.0)
                        Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }

                        Text {
                            anchors.centerIn: parent
                            font.family: matSymbols.name
                            font.pixelSize: 14
                            text: "\uE044" // skip_next
                            color: Theme.textPrimary
                            opacity: nextMouse.containsMouse ? 1.0 : 0.75
                            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MediaService.next()
                        }
                    }
                }

                // C. Progress Bar
                Item {
                    id: seekbarRow
                    anchors.top: trackInfoCol.bottom
                    anchors.topMargin: 12
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 14

                    Text {
                        id: posText
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: Theme.textDim
                        text: MediaService.formatTime(MediaService.position)
                    }

                    Text {
                        id: lenText
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: MediaService.isLive ? Font.Bold : Font.Normal
                        color: MediaService.isLive ? "#ff453a" : Theme.textDim
                        text: MediaService.isLive ? "LIVE" : MediaService.formatTime(MediaService.length)
                    }

                    // Audio Waveform Visualizer Canvas
                    Canvas {
                        id: stroke
                        clip: true
                        anchors.left: posText.right
                        anchors.leftMargin: 8
                        anchors.right: lenText.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        height: 14

                        property real targetF: {
                            if (MediaService.isLive && (!MediaService.hasLength || MediaService.length <= 0)) {
                                return 0.52;
                            }
                            return MediaService.progress;
                        }
                        property real lastFrac: 0
                        property real drawF: targetF

                        Behavior on drawF {
                            enabled: Math.abs(MediaService.progress - stroke.lastFrac) < 0.05
                            NumberAnimation { duration: 400; easing.type: Easing.Linear }
                        }
                        onTargetFChanged: Qt.callLater(() => { stroke.lastFrac = MediaService.progress; })

                        property real animPhase: 0
                        NumberAnimation on animPhase {
                            from: 0
                            to: Math.PI * 2
                            duration: 1400
                            loops: Animation.Infinite
                            running: root.active && MediaService.isPlaying
                        }

                        onAnimPhaseChanged: requestPaint()
                        onDrawFChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onVisibleChanged: if (visible) requestPaint()

                        readonly property var soundwavePattern: [
                            0.20, 0.28, 0.38, 0.55, 0.78, 0.95, 0.72, 1.00, 0.82, 0.60,
                            0.75, 0.92, 0.85, 0.62, 0.50, 0.38, 0.55, 0.80, 0.96, 1.00,
                            0.82, 0.68, 0.52, 0.62, 0.85, 0.72, 0.52, 0.38, 0.32, 0.45,
                            0.62, 0.52, 0.40, 0.32, 0.28, 0.22, 0.28, 0.32, 0.25, 0.20,
                            0.18, 0.15
                        ]

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            if (width <= 0 || height <= 0) return;

                            const total = soundwavePattern.length;
                            const barW = 2.2;
                            const spacing = (width - total * barW) / (total - 1);
                            const centerY = height / 2;
                            const maxH = 11;

                            for (let i = 0; i < total; i++) {
                                const u = i / (total - 1);
                                const isPlayed = u <= drawF;

                                let rawH = soundwavePattern[i];
                                let dynamicH = rawH;
                                if (MediaService.isPlaying) {
                                    dynamicH = rawH * (0.80 + 0.20 * Math.sin(animPhase + i * 0.45));
                                }
                                const h = Math.max(3.0, Math.min(maxH, dynamicH * maxH));
                                const x = i * (barW + spacing) + barW / 2;

                                ctx.lineWidth = barW;
                                ctx.lineCap = "round";

                                if (isPlayed) {
                                    ctx.strokeStyle = MediaService.isLive ? "#ff453a" : Theme.primary;
                                    ctx.shadowColor = MediaService.isLive ? Qt.rgba(1.0, 0.27, 0.23, 0.45) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.45);
                                    ctx.shadowBlur = 4;
                                } else {
                                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.16);
                                    ctx.shadowColor = "transparent";
                                    ctx.shadowBlur = 0;
                                }

                                const bottomY = height - barW / 2 - 1;
                                ctx.beginPath();
                                ctx.moveTo(x, bottomY);
                                ctx.lineTo(x, bottomY - h);
                                ctx.stroke();
                            }
                        }

                        MouseArea {
                            id: seekArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            function fracAt(mx) {
                                return Math.max(0, Math.min(1, (mx - 4) / stroke.width));
                            }
                            onPressed: (e) => {
                                MediaService.seekRatio(fracAt(e.x));
                            }
                            onPositionChanged: (e) => {
                                if (pressed) MediaService.seekRatio(fracAt(e.x));
                            }
                        }
                    }
                }
            }
        }
    }
}

