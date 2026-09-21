// OsdBrightness.qml — Brightness OSD, segmented bar style
import QtQuick
import qs.core as C

Item {
    id: root
    implicitWidth: 320
    implicitHeight: 64

    property bool isActive: false
    visible: card.scale > 0.01

    Connections {
        target: C.Brightness
        function onTriggered() {
            root.isActive = true
            dismissTimer.restart()
        }
    }

    Timer {
        id: dismissTimer
        interval: 1800
        onTriggered: root.isActive = false
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: C.Colors.alpha(C.Colors.base, C.Style.opPanel)
        opacity: 1.0
        border.width: 0
        radius: C.Style.r.lg
        transformOrigin: Item.Bottom

        scale: root.isActive ? 1.0 : 0.0
        Behavior on scale {
            NumberAnimation {
                duration: root.isActive ? C.Style.durNormal : C.Style.durFast
                easing.type: root.isActive ? Easing.OutBack : Easing.InCubic
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: C.Style.sp.lg
            spacing: C.Style.sp.sm

            // Icon + Label row
            Row {
                spacing: C.Style.sp.sm

                Text {
                    text: C.Brightness.icon
                    font.family: C.Style.fontIcon
                    font.variableAxes: ({ "FILL": 1 })
                    font.pixelSize: C.Style.icon.md
                    color: C.Colors.text
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Brightness: " + C.Brightness.level + "%"
                    font.family: C.Style.fontMono
                    font.pixelSize: C.Style.fs.md
                    color: C.Colors.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Segmented progress bar
            Row {
                spacing: 3
                width: parent.width

                Repeater {
                    model: 20
                    delegate: Rectangle {
                        width: (parent.width - 19 * 3) / 20
                        height: 10
                        color: (index < Math.round(C.Brightness.level / 5))
                            ? C.Colors.text
                            : C.Colors.muted

                        Behavior on color {
                            ColorAnimation { duration: C.Style.durFast }
                        }
                    }
                }
            }
        }

        // Bottom separator line removed
    }
}
