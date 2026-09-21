// Volume.qml — Material icon + percentage, scroll to adjust
import QtQuick
import qs.core as C

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: C.Style.barHeight

    property bool hovered: false

    Row {
        id: row
        anchors.centerIn: parent
        spacing: C.Style.sp.sm

        Text {
            id: iconText
            text: C.Audio.volMuted ? "volume_off" : (C.Audio.volLevel < 33 ? "volume_mute" : (C.Audio.volLevel < 66 ? "volume_down" : "volume_up"))
            font.family: C.Style.fontIcon
            font.variableAxes: ({ "FILL": 1 })
            font.pixelSize: C.Audio.volMuted ? C.Style.icon.sm : C.Style.icon.xl
            color: C.Audio.volMuted ? C.Colors.red : (root.hovered ? C.Colors.accent : C.Colors.text)
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
        }

        Text {
            id: valText
            text: C.Audio.volLevel + "%"
            font.family: C.Style.fontMono
            font.pixelSize: C.Style.fs.sm
            color: C.Audio.volMuted ? C.Colors.red : (root.hovered ? C.Colors.accent : C.Colors.text)
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hovered || C.Audio.volMuted

            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: C.Audio.toggleMute()
        onWheel: (wheel) => {
            let delta = wheel.angleDelta.y > 0 ? 0.02 : -0.02
            C.Audio.addVolume(delta)
        }
        cursorShape: Qt.PointingHandCursor
    }
}
