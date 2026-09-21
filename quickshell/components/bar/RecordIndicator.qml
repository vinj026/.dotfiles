// RecordIndicator.qml — Dynamic screen recording indicator widget with pulse animation and controls
import QtQuick
import QtQuick.Layouts
import qs.core as C

Item {
    id: root

    visible: C.ShellState.isRecording
    implicitWidth: visible ? container.implicitWidth : 0
    implicitHeight: parent.height
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: C.Style.durNormal; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: container
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: contentRow.implicitWidth + C.Style.sp.lg * 2
        height: C.Style.barHeight - 6
        radius: C.Style.r.xs // Match wabi-sabi or rounded 'minimalist' style
        color: C.Colors.alpha(C.Colors.overlay0, 0.92)
        border.width: 0

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: C.Style.sp.md
            height: parent.height

            // Red Pulsing Dot container
            Item {
                width: 16
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter

                // Solid red dot
                Rectangle {
                    id: solidDot
                    anchors.centerIn: parent
                    width: 8; height: 8
                    radius: 4
                    color: C.Colors.red

                    // Pulsing outer ring
                    Rectangle {
                        anchors.centerIn: parent
                        width: 8; height: 8
                        radius: 4
                        color: C.Colors.red
                        opacity: 0.0
                        z: -1

                        PropertyAnimation on scale {
                            from: 1.0; to: 2.8
                            duration: 1200
                            loops: Animation.Infinite
                            running: C.ShellState.isRecording && !C.ShellState.isRecordingPaused
                        }
                        PropertyAnimation on opacity {
                            from: 0.6; to: 0.0
                            duration: 1200
                            loops: Animation.Infinite
                            running: C.ShellState.isRecording && !C.ShellState.isRecordingPaused
                        }
                    }
                }
            }

            // Recording Timer Text
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (C.ShellState.isRecordingPaused) return "PAUSED"
                    let min = Math.floor(C.ShellState.recordingTime / 60)
                    let sec = C.ShellState.recordingTime % 60
                    return (min < 10 ? "0" : "") + min + ":" + (sec < 10 ? "0" : "") + sec
                }
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.sm
                font.weight: C.Style.fw.bold
                color: C.Colors.text
            }

            // Controls Separator
            Rectangle {
                width: 1
                height: 12
                color: C.Colors.alpha(C.Colors.border, 0.4)
                anchors.verticalCenter: parent.verticalCenter
            }

            // Pause/Resume Button
            Item {
                width: 20; height: 20
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: C.ShellState.isRecordingPaused ? "play_arrow" : "pause"
                    font.family: C.Style.fontIcon
                    font.pixelSize: C.Style.icon.md
                    color: pauseMouse.containsMouse ? C.Colors.accent : C.Colors.subtext1
                    Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                }

                MouseArea {
                    id: pauseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: C.ShellState.togglePauseRecording()
                }
            }

            // Stop Button
            Item {
                width: 20; height: 20
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "stop"
                    font.family: C.Style.fontIcon
                    font.pixelSize: C.Style.icon.md
                    color: stopMouse.containsMouse ? C.Colors.red : C.Colors.subtext1
                    Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                }

                MouseArea {
                    id: stopMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: C.ShellState.stopRecording()
                }
            }
        }
    }
}
