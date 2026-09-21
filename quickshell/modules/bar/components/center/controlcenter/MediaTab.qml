import QtQuick
import Quickshell
import "../../../../../theme"
import "../../../../../components"

Item {
    id: root

    property bool active: false
    property string symbolFont: ""

    implicitWidth: 348
    implicitHeight: MediaService.hasMedia ? mediaContent.implicitHeight : emptyState.implicitHeight + 32

    function formatTime(ms) {
        if (!ms || ms <= 0) return "0:00";
        let s = Math.floor(ms / 1000);
        let m = Math.floor(s / 60);
        return m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
    }

    // ── Active Media Card ──
    Column {
        id: mediaContent
        visible: MediaService.hasMedia
        width: parent.width
        spacing: 12

        // Album Art + Track Info Row
        Row {
            width: parent.width
            spacing: 12
            height: 72

            // Album Art
            Rectangle {
                width: 72; height: 72
                radius: Theme.shapeCornerLarge
                color: Theme.surfaceContainerHighest
                clip: true

                Image {
                    anchors.fill: parent
                    source: MediaService.artUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: parent.children[0].status !== Image.Ready
                    font.family: root.symbolFont; font.pixelSize: 32
                    text: "\ue405"
                    color: Theme.textMuted
                }
            }

            // Track Info
            Item {
                width: parent.width - 84
                height: parent.height

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 3

                    Text {
                        width: parent.width
                        font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Bold
                        text: MediaService.title || "Unknown Track"
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    Text {
                        width: parent.width
                        font.family: Theme.fontFamily; font.pixelSize: 12
                        text: MediaService.artist || "Unknown Artist"
                        color: Theme.textMuted
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        text: (MediaService.album || "")
                        color: Theme.textDim
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }
        }

        // Progress Seek Bar
        Column {
            width: parent.width
            spacing: 4

            Rectangle {
                width: parent.width; height: 4
                radius: 2
                color: Theme.surfaceContainerHighest

                Rectangle {
                    width: (MediaService.length > 0)
                        ? parent.width * Math.max(0, Math.min(1, MediaService.position / MediaService.length))
                        : 0
                    height: parent.height; radius: 2
                    color: Theme.primary
                    Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.Linear } }
                }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (MediaService.length > 0)
                            MediaService.seekTo((mouse.x / width) * MediaService.length);
                    }
                }
            }

            Item {
                width: parent.width; height: 14
                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Medium
                    text: root.formatTime(MediaService.position); color: Theme.textMuted
                }
                Text {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Medium
                    text: root.formatTime(MediaService.length); color: Theme.textMuted
                }
            }
        }

        // Playback Controls
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8; height: 52

            // Shuffle
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 36; radius: 18; color: "transparent"
                scale: shufMouse.pressed ? 0.88 : (shufMouse.containsMouse ? 1.1 : 1.0)
                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }
                Text {
                    anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 18
                    text: "\ue043"; color: Theme.textMuted
                }
                MouseArea { id: shufMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
            }

            // Previous
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40; radius: 20
                color: prevMouse.pressed ? Theme.primaryContainer : "transparent"
                scale: prevMouse.pressed ? 0.88 : (prevMouse.containsMouse ? 1.1 : 1.0)
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }
                Text {
                    anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 26
                    text: "\ue045"; color: Theme.textPrimary
                }
                MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: MediaService.previous() }
            }

            // Play/Pause
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 52; height: 52; radius: 26
                color: Theme.primary
                scale: playMouse.pressed ? 0.90 : (playMouse.containsMouse ? 1.06 : 1.0)
                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }
                Text {
                    anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 30
                    text: MediaService.isPlaying ? "\ue034" : "\ue037"
                    color: Theme.onPrimary
                }
                MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: MediaService.togglePlay() }
            }

            // Next
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40; radius: 20
                color: nextMouse.pressed ? Theme.primaryContainer : "transparent"
                scale: nextMouse.pressed ? 0.88 : (nextMouse.containsMouse ? 1.1 : 1.0)
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }
                Text {
                    anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 26
                    text: "\ue044"; color: Theme.textPrimary
                }
                MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: MediaService.next() }
            }

            // Repeat
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 36; radius: 18; color: "transparent"
                scale: repMouse.pressed ? 0.88 : (repMouse.containsMouse ? 1.1 : 1.0)
                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }
                Text {
                    anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 18
                    text: "\ue040"; color: Theme.textMuted
                }
                MouseArea { id: repMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    // ── Empty State ──
    Column {
        id: emptyState
        visible: !MediaService.hasMedia
        anchors.centerIn: parent
        spacing: 12

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56; height: 56; radius: 28
            color: Theme.surfaceContainerHigh
            Text {
                anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 28
                text: "\ue405"; color: Theme.textMuted
            }
        }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
                text: "No Media Playing"; color: Theme.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Theme.fontFamily; font.pixelSize: 11
                text: "Play something to see controls"
                color: Theme.textMuted
            }
        }
    }
}
