// MediaWidget.qml — Compact media info in bar, infinite marquee title, static artist, visible when paused
import QtQuick
import qs.core as C

Item {
    id: root

    property string screenName: ""

    visible: C.Mpris.hasPlayer && C.Mpris.title !== ""
    implicitWidth: visible ? row.implicitWidth + C.Style.sp.sm * 2 : 0
    implicitHeight: C.Style.barHeight

    Behavior on implicitWidth { NumberAnimation { duration: C.Style.durNormal; easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 0
        spacing: C.Style.sp.sm

        // Play/pause icon
        Text {
            text: C.Mpris.playIcon
            font.family: C.Style.fontIcon
            font.variableAxes: ({ "FILL": 1 })
            font.pixelSize: C.Style.icon.sm
            color: C.Colors.accent
            anchors.verticalCenter: parent.verticalCenter
        }

        // Title with Seamless Infinite Marquee
        Item {
            id: marqueeContainer
            width: Math.min(150, titleText.implicitWidth)
            height: C.Style.barHeight
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            readonly property real spacing: 40 // Space between repeated text instances
            readonly property bool shouldAnimate: titleText.implicitWidth > 150

            Item {
                id: scrollContent
                width: titleText.implicitWidth * 2 + marqueeContainer.spacing
                height: parent.height
                x: 0

                Text {
                    id: titleText
                    text: C.Mpris.title
                    font.family: C.Style.fontSans
                    font.pixelSize: C.Style.fs.md
                    font.weight: C.Style.fw.medium
                    color: C.Colors.text
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Second repeated instance of the text for seamless wrapping
                Text {
                    id: titleTextRepeat
                    text: titleText.text
                    font: titleText.font
                    color: titleText.color
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: titleText.right
                    anchors.leftMargin: marqueeContainer.spacing
                    visible: marqueeContainer.shouldAnimate
                }

                NumberAnimation {
                    id: marqueeAnim
                    target: scrollContent
                    property: "x"
                    running: marqueeContainer.shouldAnimate
                    loops: Animation.Infinite
                    from: 0
                    to: -(titleText.implicitWidth + marqueeContainer.spacing)
                    duration: (titleText.implicitWidth + marqueeContainer.spacing) * 35 // Constant speed
                    easing.type: Easing.Linear

                    onRunningChanged: {
                        if (!running) {
                            scrollContent.x = 0;
                        }
                    }
                }

                Connections {
                    target: titleText
                    function onTextChanged() {
                        if (marqueeAnim.running) {
                            marqueeAnim.restart();
                        } else {
                            scrollContent.x = 0;
                        }
                    }
                }
            }
        }

        // Separator dot
        Text {
            visible: C.Mpris.artist !== ""
            text: "·"
            font.family: C.Style.fontMono
            font.pixelSize: C.Style.fs.sm
            color: C.Colors.subtext0
            anchors.verticalCenter: parent.verticalCenter
        }

        // Artist (Static)
        Text {
            visible: C.Mpris.artist !== ""
            text: C.Mpris.artist
            font.family: C.Style.fontSans
            font.pixelSize: C.Style.fs.sm
            color: C.Colors.subtext1
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                let globalPos = mapToItem(null, 0, 0)
                C.ShellState.toggleMediaPopup(root.screenName !== "" ? root.screenName : C.ShellState.fallbackScreen(), globalPos.x, root.width)
            } else {
                C.Mpris.next()
            }
        }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) C.Mpris.previous()
            else C.Mpris.next()
        }
    }
}
