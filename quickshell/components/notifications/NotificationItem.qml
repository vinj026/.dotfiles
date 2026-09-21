// NotificationItem.qml — Single notification toast card
import QtQuick
import Quickshell.Services.Notifications
import qs.core as C

Rectangle {
    id: root

    property var notifData: ({})
    signal dismissed()

    property real scaleFactor: 0.0
    opacity: scaleFactor

    transform: Scale {
        origin.x: root.width - 24
        origin.y: -(root.y + (root.ListView.view ? root.ListView.view.y : 42) - 15)
        xScale: root.scaleFactor
        yScale: root.scaleFactor
    }

    width: 340
    height: contentCol.implicitHeight + C.Style.sp.lg * 2
    radius: C.Style.r.md
    color: C.Colors.surface85
    border.width: 0
    clip: true

    property string appNameText: ""
    property string timeText: ""
    property string summaryText: ""
    property string bodyText: ""
    property int urgencyVal: 1

    Component.onCompleted: {
        enterAnim.start();
        if (notifData) {
            appNameText = (notifData.appName || "SYSTEM").toUpperCase();
            timeText = notifData.time || "";
            summaryText = notifData.summary || "";
            bodyText = notifData.body || "";
            urgencyVal = notifData.urgency ?? 1;
        }
    }

    NumberAnimation on scaleFactor {
        id: enterAnim
        from: 0.0
        to: 1.0
        duration: C.Style.durNormal
        easing.type: Easing.OutCubic
    }

    // Left urgency accent bar
    Rectangle {
        id: urgencyBar
        width: 3
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: 0
        color: {
            if (urgencyVal === 2) return C.Colors.red
            if (urgencyVal === 1) return C.Colors.accent
            return C.Colors.subtext0
        }
    }

    Column {
        id: contentCol
        anchors.left: urgencyBar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: C.Style.sp.lg
        spacing: C.Style.sp.sm

        // App name + close button
        Item {
            width: parent.width
            height: 18

            Text {
                id: appIcon
                text: "⬡"
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.sm
                color: C.Colors.accent
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
            }

            Text {
                id: appNameTextLabel
                text: appNameText
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.xs
                font.weight: C.Style.fw.bold
                color: C.Colors.subtext0
                font.letterSpacing: 0.8
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: appIcon.right
                anchors.leftMargin: C.Style.sp.sm
            }

            Text {
                id: timeTextLabel
                text: timeText
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.xs
                color: C.Colors.subtext0
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: dismissBtn.left
                anchors.rightMargin: C.Style.sp.sm
            }

            Text {
                id: dismissBtn
                text: "×"
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.xl
                color: hoverDismiss.containsMouse ? C.Colors.red : C.Colors.subtext0
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right

                MouseArea {
                    id: hoverDismiss
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissed()
                }

                Behavior on color { ColorAnimation { duration: C.Style.durFast } }
            }
        }

        // Summary
        Text {
            visible: summaryText !== ""
            text: summaryText
            width: parent.width
            font.family: C.Style.fontSans
            font.pixelSize: C.Style.fs.lg
            font.weight: C.Style.fw.semi
            color: C.Colors.text
            wrapMode: Text.WordWrap
        }

        // Body
        Text {
            visible: bodyText !== ""
            text: bodyText
            width: parent.width
            font.family: C.Style.fontSans
            font.pixelSize: C.Style.fs.md
            color: C.Colors.subtext1
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }
    }
}
