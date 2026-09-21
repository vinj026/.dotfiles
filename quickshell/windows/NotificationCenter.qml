// NotificationCenter.qml — Notification History popup
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core as C

    id: root

    visible: C.ShellState.notifCenterOpen || !closeAnim.stopped
    color: "transparent"
    WlrLayershell.namespace: "quickshell:notifcenter"
    WlrLayershell.layer:     WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    implicitWidth: 320

    anchors.top:    true
    anchors.bottom: false
    anchors.left:   false
    anchors.right:  true

    readonly property bool isMinimalist: C.Style.styleMode === "minimalist"

    margins.top: root.openMargin
    margins.right: isMinimalist ? C.Style.sp.md : C.Style.sp.lg

    onVisibleChanged: {
        if (visible) {
            card.scaleFactor = 0.0
            openAnim.start()
        }
    }

    Connections {
        target: C.ShellState
        function onNotifCenterOpenChanged() {
            if (!C.ShellState.notifCenterOpen && root.visible) {
                closeAnim.start()
            }
        }
    }

    Connections {
        target: root.contentItem
        function onActiveFocusChanged() {
            if (!root.contentItem.activeFocus && C.ShellState.notifCenterOpen) {
                closeAnim.start()
            }
        }
    }

    readonly property real openMargin: isMinimalist ? (C.Style.barHeight + C.Style.sp.xs) : (C.Style.barHeight + C.Style.sp.md * 2 + C.Style.sp.sm)

    PropertyAnimation {
        id: openAnim
        target: card
        property: "scaleFactor"
        to: 1.0
        duration: C.Style.durNormal
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: closeAnim
        PropertyAnimation {
            target: card
            property: "scaleFactor"
            to: 0.0
            duration: C.Style.durFast
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: C.ShellState.notifCenterOpen = false
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: C.Colors.alpha(C.Colors.surface, C.Style.opPanel)
        border.width: 0
        radius: C.Style.r.lg

        property real scaleFactor: 0.0
        opacity: scaleFactor

        transform: Scale {
            origin.x: card.width - 24
            origin.y: -10
            xScale: card.scaleFactor
            yScale: card.scaleFactor
        }

        TapHandler {} // prevent closing when clicking inside the card

        Column {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: C.Style.sp.lg
            spacing: C.Style.sp.md

            // Header Row
            Item {
                width: parent.width
                height: 20

                Text {
                    text: "NOTIFICATION HISTORY"
                    font.family: C.Style.fontMono
                    font.pixelSize: C.Style.fs.xs
                    font.weight: C.Style.fw.bold
                    color: C.Colors.text
                    font.letterSpacing: 0.8
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                }

                // Clear All Button
                Text {
                    text: "CLEAR ALL"
                    font.family: C.Style.fontMono
                    font.pixelSize: C.Style.fs.xs
                    font.weight: C.Style.fw.bold
                    color: clearAllMouse.containsMouse ? C.Colors.red : C.Colors.subtext1
                    font.letterSpacing: 0.8
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right

                    MouseArea {
                        id: clearAllMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: C.Notifications.clearHistory()
                    }

                    Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                }
            }

            // Divider line
            Rectangle {
                width: parent.width
                height: 1
                color: C.Colors.surface
            }

            // Scrollable List of notifications
            ListView {
                id: notifList
                width: parent.width
                height: parent.height - 20 - C.Style.sp.md - 1 - C.Style.sp.md
                clip: true
                spacing: C.Style.sp.sm
                model: C.Notifications.list

                // Animations for clear list and layout shifts
                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: C.Style.durNormal
                        easing.type: Easing.OutCubic
                    }
                }

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: C.Style.durNormal
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            property: "x"
                            from: -notifList.width / 2
                            to: 0
                            duration: C.Style.durNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "opacity"
                            to: 0.0
                            duration: C.Style.durFast
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            property: "x"
                            to: notifList.width
                            duration: C.Style.durFast
                            easing.type: Easing.InCubic
                        }
                    }
                }

                delegate: Rectangle {
                    id: itemCard
                    width: notifList.width
                    height: itemCol.implicitHeight + C.Style.sp.md * 2
                    color: C.Colors.alpha(C.Colors.text, 0.05)
                    border.width: 0
                    radius: C.Style.r.sm

                    property string appNameText: ""
                    property string timeText: ""
                    property string summaryText: ""
                    property string bodyText: ""
                    property int urgencyVal: 1

                    Component.onCompleted: {
                        if (modelData) {
                            appNameText = (modelData.appName || "SYSTEM").toUpperCase();
                            timeText = modelData.time || "";
                            summaryText = modelData.summary || "";
                            bodyText = modelData.body || "";
                            urgencyVal = modelData.urgency ?? 1;
                        }
                    }

                    // Urgent highlight bar on the left
                    Rectangle {
                        id: leftBar
                        width: 3
                        height: parent.height
                        anchors.left: parent.left
                        color: {
                            if (urgencyVal === 2) return C.Colors.red;
                            if (urgencyVal === 1) return C.Colors.accent;
                            return C.Colors.subtext0;
                        }
                    }

                    Column {
                        id: itemCol
                        anchors.left: leftBar.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: C.Style.sp.md
                        spacing: C.Style.sp.xs

                        // App name + time row
                        Item {
                            width: parent.width
                            height: 14

                            Text {
                                text: appNameText
                                font.family: C.Style.fontMono
                                font.pixelSize: C.Style.fs.xs
                                font.weight: C.Style.fw.bold
                                color: C.Colors.subtext0
                                font.letterSpacing: 0.5
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: timeText
                                font.family: C.Style.fontMono
                                font.pixelSize: C.Style.fs.xs
                                color: C.Colors.subtext1
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Summary
                        Text {
                            visible: summaryText !== ""
                            text: summaryText
                            width: parent.width
                            font.family: C.Style.fontSans
                            font.pixelSize: C.Style.fs.sm
                            font.weight: C.Style.fw.bold
                            color: C.Colors.text
                            wrapMode: Text.WordWrap
                        }

                        // Body
                        Text {
                            visible: bodyText !== ""
                            text: bodyText
                            width: parent.width
                            font.family: C.Style.fontSans
                            font.pixelSize: C.Style.fs.xs
                            color: C.Colors.subtext1
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        // Empty placeholder state
        Text {
            text: "NO NOTIFICATIONS"
            font.family: C.Style.fontMono
            font.pixelSize: C.Style.fs.xs
            font.weight: C.Style.fw.bold
            font.letterSpacing: 0.8
            color: C.Colors.subtext1
            anchors.centerIn: parent

            opacity: C.Notifications.list.length === 0 ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: C.Style.durFast } }
        }
    }
