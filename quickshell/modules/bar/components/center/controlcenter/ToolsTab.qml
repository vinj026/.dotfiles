import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../../../theme"
import "../../../../../components"

Item {
    id: root

    property bool active: false
    property string symbolFont: ""

    // Clipboard history (backed by ClipboardService singleton)
    readonly property var clipItems: ClipboardService.filteredItems

    // Pomodoro Timer
    property int timerSeconds: 25 * 60
    property bool timerRunning: false

    implicitWidth: 348
    implicitHeight: mainCol.implicitHeight

    // ── Timer Logic ──
    Timer {
        id: pomoTimer; interval: 1000; repeat: true; running: root.timerRunning
        onTriggered: {
            if (root.timerSeconds > 0) {
                root.timerSeconds--;
            } else {
                root.timerRunning = false;
                Quickshell.execDetached(["notify-send", "Focus Timer", "Time is up! Take a 5-minute break."]);
            }
        }
    }

    function toggleTimer() { root.timerRunning = !root.timerRunning; }
    function resetTimer() { root.timerRunning = false; root.timerSeconds = 25 * 60; }
    function formatTimer(s) {
        let m = Math.floor(s / 60); let sec = s % 60;
        return (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    // ── Screen Recorder (via ScreenRecordService) ──
    function startRecording(mode) {
        ScreenRecordService.startRecording(mode);
    }
    function stopRecording() {
        ScreenRecordService.stopRecording();
    }

    Column {
        id: mainCol
        width: parent.width
        spacing: 8

        // ── Screenshot Quick Actions ──
        Row {
            id: ssRow
            width: parent.width; spacing: 8; height: 52

            readonly property var ssActions: [
                { "icon": "\ue3b0", "label": "Region",  "cmd": ["bash", "-c", "grimblast copy area"] },
                { "icon": "\uef3d", "label": "Window",  "cmd": ["bash", "-c", "grimblast copy active"] },
                { "icon": "\ue86b", "label": "Screen",  "cmd": ["bash", "-c", "grimblast copy screen"] }
            ]

            Repeater {
                model: ssRow.ssActions.length

                Rectangle {
                    id: ssBtn
                    width: (ssRow.width - 16) / 3; height: 52
                    radius: Theme.shapeCornerLarge
                    color: ssMouse.pressed ? Theme.secondaryContainer : Theme.surfaceContainerHigh
                    scale: ssMouse.pressed ? 0.93 : (ssMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }

                    readonly property var sData: ssRow.ssActions[index]

                    Column {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: root.symbolFont; font.pixelSize: 20
                            text: ssBtn.sData.icon
                            color: ssMouse.pressed ? Theme.onSecondaryContainer : Theme.textPrimary
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Medium
                            text: ssBtn.sData.label
                            color: ssMouse.pressed ? Theme.onSecondaryContainer : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                    }

                    MouseArea {
                        id: ssMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { ControlCenterService.close(); Quickshell.execDetached(ssBtn.sData.cmd); }
                    }
                }
            }
        }

        // ── Focus Timer Card ──
        Rectangle {
            width: parent.width; height: 60
            radius: Theme.shapeCornerExtraLarge
            color: root.timerRunning ? Qt.rgba(Theme.primaryContainer.r, Theme.primaryContainer.g, Theme.primaryContainer.b, 0.5) : Theme.surfaceContainerHigh
            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

            Item {
                anchors.fill: parent; anchors.margins: 14

                // Left: icon + info
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: root.timerRunning ? Theme.primary : Theme.surfaceContainerHighest
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Text {
                            anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 17
                            text: "\uef1c"
                            color: root.timerRunning ? Theme.onPrimary : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Text {
                            font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Medium
                            text: "Focus Timer"
                            color: root.timerRunning ? Theme.onPrimaryContainer : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                        Text {
                            font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.Bold
                            text: root.formatTimer(root.timerSeconds)
                            color: root.timerRunning ? Theme.primary : Theme.textPrimary
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                    }
                }

                // Right: controls
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: root.timerRunning ? Theme.primary : Theme.surfaceContainerHighest
                        scale: tPlayMouse.pressed ? 0.90 : 1.0
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro } }
                        Text {
                            anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 16
                            text: root.timerRunning ? "\ue034" : "\ue037"
                            color: root.timerRunning ? Theme.onPrimary : Theme.textPrimary
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                        MouseArea { id: tPlayMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleTimer() }
                    }

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: Theme.surfaceContainerHighest
                        scale: tResetMouse.pressed ? 0.90 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro } }
                        Text {
                            anchors.centerIn: parent; font.family: root.symbolFont; font.pixelSize: 16
                            text: "\ue5d5"; color: Theme.textMuted
                        }
                        MouseArea { id: tResetMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.resetTimer() }
                    }
                }
            }
        }

        // ── Screen Recorder ──
        Rectangle {
            width: parent.width
            implicitHeight: recSection.implicitHeight + 20
            radius: Theme.shapeCornerExtraLarge
            color: Theme.surfaceContainerHigh

            Column {
                id: recSection
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: 12
                spacing: 6

                // Header
                Item {
                    width: parent.width; height: 24

                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: root.symbolFont; font.pixelSize: 14
                            text: "\ue837" // radio_button_checked
                            color: ScreenRecordService.isRecording ? Theme.error : Theme.primary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold
                            text: "Screen Recorder"; color: Theme.textPrimary
                        }
                    }

                    Text {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
                        text: ScreenRecordService.isRecording ? ScreenRecordService.recordingTimeStr : ""
                        color: Theme.error
                    }
                }

                // Mode buttons (hidden while recording)
                Row {
                    width: parent.width; spacing: 8
                    visible: !ScreenRecordService.isRecording

                    Rectangle {
                        width: (parent.width - 8) / 2; height: 36
                        radius: Theme.shapeCornerFull
                        color: recRegionMouse.pressed ? Theme.primaryContainer : Theme.surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                            text: "Region"; color: Theme.textPrimary
                        }
                        MouseArea {
                            id: recRegionMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: root.startRecording("region")
                        }
                    }

                    Rectangle {
                        width: (parent.width - 8) / 2; height: 36
                        radius: Theme.shapeCornerFull
                        color: recFullMouse.pressed ? Theme.primaryContainer : Theme.surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                            text: "Fullscreen"; color: Theme.textPrimary
                        }
                        MouseArea {
                            id: recFullMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: root.startRecording("fullscreen")
                        }
                    }
                }

                // Active recording strip
                Rectangle {
                    width: parent.width; height: 36
                    radius: Theme.shapeCornerFull
                    visible: ScreenRecordService.isRecording
                    color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.14)

                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            width: 8; height: 8; radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.error

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: ScreenRecordService.isRecording
                                NumberAnimation { from: 1.0; to: 0.25; duration: 560; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 0.25; to: 1.0; duration: 560; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                            text: "REC " + ScreenRecordService.recordingTimeStr + (ScreenRecordService.recordAudio ? " · mic" : "")
                            color: Theme.error
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right; anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 60; height: 24; radius: 12
                        color: recStopMouse.pressed ? Theme.error : Theme.errorContainer
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
                            text: "Stop"; color: Theme.textOnErrorContainer
                        }
                        MouseArea {
                            id: recStopMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: root.stopRecording()
                        }
                    }
                }

                // Mic audio toggle
                Row {
                    width: parent.width; height: 24
                    spacing: 10

                    Rectangle {
                        width: 90; height: 24; radius: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: ScreenRecordService.recordAudio ? Theme.secondaryContainer : Theme.surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
                            text: ScreenRecordService.recordAudio ? "Mic On" : "Mic Off"
                            color: ScreenRecordService.recordAudio ? Theme.onSecondaryContainer : Theme.textMuted
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: ScreenRecordService.recordAudio = !ScreenRecordService.recordAudio
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily; font.pixelSize: 10
                        text: "Capture microphone audio"
                        color: Theme.textDim
                    }
                }
            }
        }

        // ── Clipboard History ──
        Rectangle {
            width: parent.width
            implicitHeight: clipSection.implicitHeight + 20
            radius: Theme.shapeCornerExtraLarge
            color: Theme.surfaceContainerHigh

            Column {
                id: clipSection
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: 12
                spacing: 4

                // Header
                Item {
                    width: parent.width; height: 24

                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: root.symbolFont; font.pixelSize: 14
                            text: "\ue14d"; color: Theme.primary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold
                            text: "Clipboard"; color: Theme.textPrimary
                        }
                    }

                    Text {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily; font.pixelSize: 10
                        text: "Clear all"; color: Theme.textMuted
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor; onClicked: ClipboardService.clearAll()
                        }
                    }
                }

                // Search field
                Rectangle {
                    width: parent.width; height: 28
                    radius: 14
                    color: Theme.surfaceContainerHighest

                    TextInput {
                        id: clipSearch
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        color: Theme.textPrimary
                        clip: true
                        selectByMouse: true
                        selectionColor: Theme.primary
                        onTextChanged: ClipboardService.searchQuery = text

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 11
                            text: "Search clipboard…"; color: Theme.textDim
                            visible: !clipSearch.text && !clipSearch.activeFocus
                        }
                    }
                }

                // Items
                Repeater {
                    model: root.clipItems.length

                    Rectangle {
                        id: clipCard
                        width: parent.width; height: 30
                        color: itemMouse.pressed ? Theme.primaryContainer : "transparent"
                        scale: itemMouse.pressed ? 0.98 : (itemMouse.containsMouse ? 1.015 : 1.0)
                        opacity: itemMouse.containsMouse ? 1.0 : 0.85
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                        readonly property var cData: root.clipItems[index]
                        readonly property bool isCopied: ClipboardService.lastCopiedId === cData.id

                        Row {
                            anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: root.symbolFont; font.pixelSize: 13
                                text: clipCard.isCopied ? "\ue876" : "\ue24d"
                                color: clipCard.isCopied ? Theme.primary : Theme.textMuted
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 30
                                font.family: Theme.fontFamily; font.pixelSize: 11
                                text: clipCard.isCopied ? "Copied!" : clipCard.cData.text
                                color: clipCard.isCopied ? Theme.primary : Theme.textPrimary
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }
                        }

                        MouseArea {
                            id: itemMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: ClipboardService.copyItem(clipCard.cData.id)
                        }
                    }
                }

                // Empty clipboard state
                Text {
                    visible: root.clipItems.length === 0
                    width: parent.width; font.family: Theme.fontFamily; font.pixelSize: 11
                    text: "Clipboard is empty"; color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
