// MainBar.qml — Floating top bar, sharp corners
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components.bar
import qs.core as C

PanelWindow {
    id: root

    property ShellScreen modelData
    readonly property bool isMinimalist: C.Style.styleMode === "minimalist"

    screen:         modelData
    implicitHeight: isMinimalist ? C.Style.barHeight : (C.Style.barHeight + C.Style.sp.md * 2)
    color:          "transparent"
    exclusiveZone:  implicitHeight

    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer:     WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.top:   true
    anchors.left:  true
    anchors.right: true

    // Background bar — adapts to minimalist/floating style
    Rectangle {
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        anchors.leftMargin: isMinimalist ? 0 : C.Style.sp.lg
        anchors.rightMargin:isMinimalist ? 0 : C.Style.sp.lg
        anchors.topMargin:  isMinimalist ? 0 : C.Style.sp.md
        height: C.Style.barHeight
        radius: isMinimalist ? 0 : C.Style.r.md
        color:  isMinimalist ? C.Colors.base : C.Colors.surface85

        // Bottom border for minimalist style
        Rectangle {
            visible: isMinimalist
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            color: C.Colors.border
            height: 1
        }
    }

    // ── LEFT ─────────────────────────────────────────────────────
    RowLayout {
        id: leftSection
        anchors.left:       parent.left
        anchors.leftMargin: isMinimalist ? C.Style.sp.lg : (C.Style.sp.lg + C.Style.sp.lg)
        anchors.top:        parent.top
        anchors.topMargin:  isMinimalist ? 0 : C.Style.sp.md
        height: C.Style.barHeight
        spacing: C.Style.sp.md

        StartButton {
            screenName: root.modelData?.name ?? ""
            Layout.alignment: Qt.AlignVCenter
        }

        Workspaces {
            currentOutput: root.modelData?.name ?? ""
            Layout.alignment: Qt.AlignVCenter
        }

        MediaWidget {
            screenName: root.modelData?.name ?? ""
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // ── CENTER: Pomodoro Timer (Visible only when active) ──────────
    Item {
        id: centerSection
        width: timeText.implicitWidth
        height: C.Style.barHeight
        anchors.centerIn: parent
        visible: C.ShellState.pomoActive || pomoScaleXAnim.running || pomoOpacityAnim.running

        opacity: C.ShellState.pomoActive ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { id: pomoOpacityAnim; duration: C.Style.durFast } }

        transform: Scale {
            id: pomoScale
            origin.x: centerSection.width / 2
            origin.y: centerSection.height / 2
            xScale: C.ShellState.pomoActive ? 1.0 : 0.8
            yScale: C.ShellState.pomoActive ? 1.0 : 0.8
            Behavior on xScale {
                NumberAnimation {
                    id: pomoScaleXAnim
                    duration: C.Style.durFast
                    easing.type: C.ShellState.pomoActive ? Easing.OutCubic : Easing.InCubic
                }
            }
            Behavior on yScale {
                NumberAnimation {
                    id: pomoScaleYAnim
                    duration: C.Style.durFast
                    easing.type: C.ShellState.pomoActive ? Easing.OutCubic : Easing.InCubic
                }
            }
        }

        Text {
            id: timeText
            anchors.centerIn: parent
            text: {
                let status = C.ShellState.pomoRunning ? C.ShellState.pomoMode.toLowerCase() : "paused"
                return "pomo: " + status + " [" + (C.ShellState.pomoMinutes < 10 ? "0" : "") + C.ShellState.pomoMinutes + ":" + (C.ShellState.pomoSeconds < 10 ? "0" : "") + C.ShellState.pomoSeconds + "]"
            }
            font.family: C.Style.fontMono
            font.pixelSize: C.Style.fs.sm
            font.weight: C.Style.fw.bold
            color: !C.ShellState.pomoRunning ? C.Colors.subtext1 : (C.ShellState.pomoMode === "Focus" ? C.Colors.accent : C.Colors.peach)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    C.ShellState.pomoRunning = !C.ShellState.pomoRunning
                    if (C.ShellState.pomoRunning) C.ShellState.pomoActive = true
                } else if (mouse.button === Qt.RightButton) {
                    C.ShellState.pomoRunning = false
                    C.ShellState.pomoActive = false
                    C.ShellState.pomoMode = "Focus"
                    C.ShellState.pomoMinutes = 25
                    C.ShellState.pomoSeconds = 0
                }
            }
        }
    }

    // ── RIGHT ────────────────────────────────────────────────────
    RowLayout {
        id: rightSection
        anchors.right:       parent.right
        anchors.rightMargin: isMinimalist ? C.Style.sp.lg : (C.Style.sp.lg + C.Style.sp.lg)
        anchors.top:         parent.top
        anchors.topMargin:   isMinimalist ? 0 : C.Style.sp.md
        height: C.Style.barHeight
        spacing: C.Style.sp.xl

        RecordIndicator {
            Layout.alignment: Qt.AlignVCenter
        }

        Tray {
            visible: C.Style.showTray
            Layout.alignment: Qt.AlignVCenter
        }

        RamIndicator {
            visible: C.Style.showRam
            Layout.alignment: Qt.AlignVCenter
        }

        TempIndicator {
            visible: C.Style.showTemp
            Layout.alignment: Qt.AlignVCenter
        }

        Network {
            Layout.alignment: Qt.AlignVCenter
        }

        MicIndicator {
            visible: C.Style.showMic
            Layout.alignment: Qt.AlignVCenter
        }

        Volume {
            Layout.alignment: Qt.AlignVCenter
        }

        Battery {
            Layout.alignment: Qt.AlignVCenter
        }

        Clock {
            Layout.alignment: Qt.AlignVCenter
        }

        NotifIndicator {
            Layout.alignment: Qt.AlignVCenter
        }

        PrivacyIndicator {
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
