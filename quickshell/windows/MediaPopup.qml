// MediaPopup.qml — Media player popup dropdown, aligned under the media widget
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core as C

PopupWindow {
    id: root

    property ShellScreen modelData
    property PanelWindow barWindow
    readonly property bool isMinimalist: C.Style.styleMode === "minimalist"

    visible: root.isOpen || opacityAnim.running
    color: "transparent"

    anchor.window: barWindow
    grabFocus: true

    anchor.rect.x: Math.min(root.screen.width - width - C.Style.sp.lg, Math.max(C.Style.sp.lg, C.ShellState.mediaPopupX + (C.ShellState.mediaPopupWidth - width) / 2))
    anchor.rect.y: isMinimalist ? (C.Style.barHeight + C.Style.sp.xs) : (C.Style.sp.md + C.Style.barHeight + C.Style.sp.xs)

    width: 320
    height: panelContent.implicitHeight + C.Style.sp.md * 2

    onVisibleChanged: {
        if (!visible && C.ShellState.isMediaPopupOpen(root.modelData?.name ?? "")) {
            C.ShellState.closeMediaPopup()
        }
    }

    Item {
        id: clipWrapper
        anchors.fill: parent
        clip: true

        Rectangle {
            id: panel
            anchors.fill: parent
            color: C.Colors.alpha(C.Colors.base, C.Style.opPanel)
            radius: C.Style.r.lg

            // No border overlay
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 0
                visible: false
                radius: C.Style.r.lg
                z: 999
            }

            // Consume taps inside the panel so it doesn't dismiss
            TapHandler {}

            // Slide down + fade animation
            opacity: root.isOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { id: opacityAnim; duration: C.Style.durFast } }

            // Inner Content
            ColumnLayout {
                id: panelContent
                width: parent.width - C.Style.sp.md * 2
                anchors.top: parent.top
                anchors.topMargin: C.Style.sp.md
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: C.Style.sp.md

                // ── COVER ART & TRACK DETAILS ─────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: C.Style.sp.md

                    // Album Cover Art (72x72)
                    Rectangle {
                        width: 72
                        height: 72
                        color: C.Colors.surface
                        border.width: 1
                        border.color: C.Colors.border

                        Image {
                            id: coverImage
                            anchors.fill: parent
                            source: C.Mpris.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            visible: source !== "" && status === Image.Ready
                        }

                        // Fallback Music Note Icon
                        Text {
                            visible: !coverImage.visible
                            anchors.centerIn: parent
                            text: "music_note"
                            font.family: C.Style.fontIcon
                            font.variableAxes: ({ "FILL": 1 })
                            font.pixelSize: 36
                            color: C.Colors.subtext0
                        }
                    }

                    // Metadata Labels
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: C.Style.sp.px2

                        Text {
                            Layout.fillWidth: true
                            text: C.Mpris.title !== "" ? C.Mpris.title : "No Active Media"
                            font.family: C.Style.fontSans
                            font.pixelSize: C.Style.fs.sm
                            font.weight: C.Style.fw.bold
                            color: C.Colors.accent
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: C.Mpris.artist !== "" ? C.Mpris.artist : "Unknown Artist"
                            font.family: C.Style.fontSans
                            font.pixelSize: C.Style.fs.xs
                            color: C.Colors.subtext1
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }

                // Separator line
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: C.Colors.alpha(C.Colors.border, 0.35)
                }

                // ── PLAYER VOLUME SLIDER ──────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: C.Style.sp.sm
                    visible: C.Mpris.player !== null

                    // Volume Icon
                    Text {
                        property real vol: C.Mpris.player?.volume ?? 0.0
                        text: {
                            if (vol === 0.0) return "volume_off"
                            if (vol < 0.33) return "volume_mute"
                            if (vol < 0.66) return "volume_down"
                            return "volume_up"
                        }
                        font.family: C.Style.fontIcon
                        font.pixelSize: C.Style.icon.sm
                        color: C.Colors.accent
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Segmented Volume Bar
                    Item {
                        id: sliderContainer
                        Layout.fillWidth: true
                        height: 10
                        Layout.alignment: Qt.AlignVCenter

                        Row {
                            id: segRow
                            anchors.fill: parent
                            spacing: 2

                            Repeater {
                                model: 15
                                delegate: Rectangle {
                                    required property int index
                                    width: (segRow.width - 14 * 2) / 15
                                    height: parent.height
                                    color: index < Math.round((C.Mpris.player?.volume ?? 0.0) * 15)
                                        ? C.Colors.accent
                                        : C.Colors.muted
                                    Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                                }
                            }
                        }

                        // Thumb Indicator
                        Rectangle {
                            x: Math.min(
                                parent.width - width,
                                Math.max(0, (C.Mpris.player?.volume ?? 0.0) * parent.width - width / 2)
                            )
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 14
                            color: C.Colors.text
                        }

                        // Drag/Click Handler
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (C.Mpris.player) {
                                    C.Mpris.player.volume = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                }
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed && C.Mpris.player) {
                                    C.Mpris.player.volume = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                }
                            }
                        }
                    }

                    // Volume Percentage Text
                    Text {
                        text: Math.round((C.Mpris.player?.volume ?? 0.0) * 100) + "%"
                        font.family: C.Style.fontMono
                        font.pixelSize: C.Style.fs.xs
                        color: C.Colors.subtext1
                        Layout.preferredWidth: 28
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // Separator line (only visible when volume slider is visible)
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: C.Colors.alpha(C.Colors.border, 0.35)
                    visible: C.Mpris.player !== null
                }

                // ── PLAYBACK CONTROLS (Terminal Style) ────────────────
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: C.Style.sp.lg

                    // Prev Button
                    ControlButton {
                        label: "prev"
                        onClicked: C.Mpris.previous()
                    }

                    // Play/Pause Button
                    ControlButton {
                        label: C.Mpris.isPlaying ? "pause" : "resume"
                        onClicked: C.Mpris.playPause()
                    }

                    // Next Button
                    ControlButton {
                        label: "next"
                        onClicked: C.Mpris.next()
                    }
                }
            }
        }
    }

    // Reuseable playback control button
    component ControlButton: Text {
        id: btn
        property string label: ""
        signal clicked()

        text: btn.label
        font.family: C.Style.fontMono
        font.pixelSize: C.Style.fs.sm
        font.weight: C.Style.fw.bold
        color: mArea.containsMouse ? C.Colors.accent : C.Colors.mix(C.Colors.border, C.Colors.text, 0.3)

        Behavior on color { ColorAnimation { duration: C.Style.durFast } }

        MouseArea {
            id: mArea
            anchors.fill: parent
            anchors.margins: -C.Style.sp.xs
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
