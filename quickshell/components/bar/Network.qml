// Network.qml — WiFi icon + SSID on hover
import QtQuick
import qs.core as C

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: C.Style.barHeight

    property bool hovered: false

    Behavior on implicitWidth {
        NumberAnimation {
            duration: C.Style.durNormal
            easing.type: Easing.OutCubic
        }
    }

    Row {
        id: row
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: C.Style.sp.sm

        Text {
            text: C.Network.connected ? "network_wifi" : "wifi_off"
            font.family: C.Style.fontIcon
            font.variableAxes: ({ "FILL": 1 })
            font.pixelSize: C.Style.icon.sm
            color: C.Network.connected
                ? (root.hovered ? C.Colors.accent : C.Colors.text)
                : C.Colors.red
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
        }

        Text {
            visible: root.hovered && C.Network.connected && C.Network.ssid !== ""
            text: C.Network.ssid
            font.family: C.Style.fontMono
            font.pixelSize: C.Style.fs.sm
            color: C.Colors.subtext1
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.hovered ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: C.Style.durFast
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: C.ShellState.toggleWifiPicker()
    }
}
