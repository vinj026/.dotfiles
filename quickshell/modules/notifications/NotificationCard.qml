pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../theme"
import "../../components"

Rectangle {
    id: card

    required property var notif
    property bool dismissing: false

    // Initial state: already off-screen and transparent to prevent 1-frame flashes
    x: width + 40
    opacity: 0
    scale: 0.94

    width: 336
    implicitHeight: mainCol.implicitHeight + 20
    height: implicitHeight
    radius: 10
    color: Theme.surfaceContainer
    border.width: 0
    border.color: "transparent"
    antialiasing: false
    smooth: false
    clip: true

    Behavior on color {
        ColorAnimation { duration: 180 }
    }

    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    function resolveIcon(iconStr): string {
        if (!iconStr || typeof iconStr !== "string") return "";
        if (iconStr.startsWith("/") || iconStr.startsWith("file://")) {
            return iconStr.startsWith("file://") ? iconStr : "file://" + iconStr;
        }
        if (iconStr.startsWith("image://icon/")) {
            let name = iconStr.substring("image://icon/".length);
            if (Quickshell.hasThemeIcon(name)) {
                return iconStr;
            }
            return "";
        }
        return Quickshell.iconPath(iconStr, true) || "";
    }

    readonly property string headerIconSource: {
        if (!card.notif) return "";
        let resolved = resolveIcon(card.notif.appIcon);
        if (resolved !== "") return resolved;
        if (card.notif.image && typeof card.notif.image === "string" && card.notif.image.startsWith("image://icon/")) {
            return resolveIcon(card.notif.image);
        }
        return "";
    }

    readonly property string bodyImageSource: {
        if (!card.notif || !card.notif.image) return "";
        return resolveIcon(card.notif.image);
    }

    function dismissCard() {
        if (dismissing) return;
        dismissing = true;
        pauseTimer();
        exitAnim.start();
    }

    // High-precision countdown timer with hover pause & resume
    property real timerDuration: Math.max(1000, (card.notif && card.notif.expireTimeout > 0) ? card.notif.expireTimeout : 5000)
    property real timerStartTime: 0
    property real timerRemaining: timerDuration

    function pauseTimer() {
        if (dismissTimer.running) {
            timerRemaining = Math.max(0, timerRemaining - (Date.now() - timerStartTime));
            dismissTimer.stop();
        }
    }

    function resumeTimer() {
        if (!dismissTimer.running && timerRemaining > 0 && !card.dismissing) {
            dismissTimer.interval = timerRemaining;
            timerStartTime = Date.now();
            dismissTimer.start();
        }
    }

    Timer {
        id: dismissTimer
        interval: card.timerDuration
        repeat: false
        onTriggered: card.dismissCard()
    }

    Connections {
        target: card.notif
        function onClosed() {
            card.dismissCard();
        }
    }

    Component.onCompleted: {
        timerStartTime = Date.now();
        dismissTimer.start();
        enterAnim.start();
    }

    // 1. Enter Animation: Emphasized Bézier Spline from vast-shell / Material 3
    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target: card
            property: "x"
            from: card.width + 40
            to: 0
            duration: Theme.durationEmphasized
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveEmphasized
        }
        NumberAnimation {
            target: card
            property: "opacity"
            from: 0
            to: 1.0
            duration: Theme.durationEmphasizedDecel
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveEmphasizedDecel
        }
        NumberAnimation {
            target: card
            property: "scale"
            from: 0.94
            to: 1.0
            duration: Theme.durationEmphasized
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveExpressiveDefaultSpatial
        }
    }

    // 2. Exit Animation: Emphasized Acceleration Bézier Spline
    // Slide off to the right horizontally and fade out; ListView will glide remaining cards up!
    ParallelAnimation {
        id: exitAnim
        NumberAnimation {
            target: card
            property: "x"
            to: card.width + 40
            duration: Theme.durationEmphasizedAccel
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveEmphasizedAccel
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0
            duration: Theme.durationEmphasizedAccel
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveEmphasizedAccel
        }
        NumberAnimation {
            target: card
            property: "scale"
            to: 0.94
            duration: Theme.durationEmphasizedAccel
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveEmphasizedAccel
        }
        onFinished: {
            NotificationService.removeNotification(card.notif);
        }
    }

    // 3. Swipe-to-Dismiss Fling Animation
    ParallelAnimation {
        id: flingAnim
        NumberAnimation {
            target: card
            property: "x"
            to: card.width + 50
            duration: 180
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveStandardAccel
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0
            duration: 160
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveStandardAccel
        }
        onFinished: {
            NotificationService.removeNotification(card.notif);
        }
    }

    // 4. Swipe Spring-Back Animation: Expressive Spatial Bézier Curve
    ParallelAnimation {
        id: springBackAnim
        NumberAnimation {
            target: card
            property: "x"
            to: 0
            duration: Theme.durationExpressiveDefaultSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveExpressiveFastSpatial
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 1.0
            duration: Theme.durationExpressiveDefaultSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveExpressiveFastSpatial
        }
    }

    // Notification Content Layout (Compact spacing & margins)
    Column {
        id: mainCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 10
            bottomMargin: 10
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 6

        // 1. Header Row (App Icon, App Name, Spacer, Close Button)
        Row {
            width: parent.width
            height: 20
            spacing: 7

            // App Icon
            Item {
                width: 16
                height: 16
                anchors.verticalCenter: parent.verticalCenter
                visible: card.headerIconSource !== ""

                Image {
                    anchors.fill: parent
                    source: card.headerIconSource
                    fillMode: Image.PreserveAspectFit
                    sourceSize: Qt.size(32, 32)
                }
            }

            // App Name
            Text {
                text: card.notif ? (card.notif.appName || "Notification") : "Notification"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.textDim
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 180)
            }

            // Spacer
            Item {
                width: parent.width - (parent.children[0].visible ? 23 : 0) - (card.notif ? Math.min(parent.children[1].implicitWidth, 180) : 70) - 26
                height: 1
            }

            // Material 3 Close Button (Compact Tonal, ZERO BORDER)
            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: "transparent"
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 13
                    color: closeMouseArea.containsMouse ? Theme.textPrimary : Theme.textDim

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    rotation: closeMouseArea.containsMouse ? 90 : 0
                    scale: closeMouseArea.pressed ? 0.85 : (closeMouseArea.containsMouse ? 1.15 : 1.0)

                    Behavior on rotation {
                        NumberAnimation {
                            duration: Theme.durationExpressiveFastSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.curveExpressiveFastSpatial
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.durationExpressiveEffects
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.curveExpressiveFastSpatial
                        }
                    }
                }

                MouseArea {
                    id: closeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.dismissCard()
                }
            }
        }

        // 2. Content Row (Optional thumbnail/icon + compact text)
        Row {
            width: parent.width
            spacing: 10

            // Notification Rich Image / Large Icon
            Item {
                id: imageContainer
                property bool hasImage: card.bodyImageSource !== "" && notifImg.status === Image.Ready
                visible: hasImage
                width: visible ? 38 : 0
                height: 38

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    clip: true
                    color: Theme.surfaceVariant
                    border.width: 0

                    Image {
                        id: notifImg
                        anchors.fill: parent
                        source: card.bodyImageSource
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(76, 76)
                    }
                }
            }

            // Text Column (Summary & Body)
            Column {
                width: imageContainer.visible ? parent.width - 48 : parent.width
                spacing: 2

                Text {
                    id: summaryText
                    width: parent.width
                    text: card.notif ? card.notif.summary : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    visible: text.length > 0
                }

                Text {
                    id: bodyText
                    width: parent.width
                    text: card.notif ? card.notif.body : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    lineHeight: 1.2
                    color: Theme.textMuted
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    visible: text.length > 0
                }
            }
        }

        // 3. Actions Row (Material 3 Compact Tonal Buttons, ZERO BORDER)
        Flow {
            id: actionsFlow
            width: parent.width
            spacing: 6
            visible: card.notif && card.notif.actions && card.notif.actions.length > 0

            Repeater {
                model: (card.notif && card.notif.actions) ? card.notif.actions : []

                delegate: Rectangle {
                    id: actionBtn
                    required property var modelData

                    // Skip "default" action since clicking the card activates default
                    visible: modelData && modelData.id !== "default" && modelData.text && modelData.text.length > 0
                    height: visible ? 26 : 0
                    width: visible ? (actionText.implicitWidth + 20) : 0
                    radius: 13
                    color: Theme.surfaceVariant
                    border.width: 0

                    scale: actionMouseArea.pressed ? 0.94 : (actionMouseArea.containsMouse ? 1.05 : 1.0)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.durationExpressiveEffects
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.curveExpressiveFastSpatial
                        }
                    }

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: actionBtn.modelData ? actionBtn.modelData.text : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                        opacity: actionMouseArea.containsMouse ? 1.0 : 0.8
                        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                    }

                    MouseArea {
                        id: actionMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (actionBtn.modelData && actionBtn.modelData.invoke) {
                                actionBtn.modelData.invoke();
                            }
                            card.dismissCard();
                        }
                    }
                }
            }
        }
    }

    // Card Body MouseArea: Drag-to-swipe, click default action, hover-to-pause
    MouseArea {
        id: cardMouseArea
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        cursorShape: Qt.PointingHandCursor

        drag.target: card
        drag.axis: Drag.XAxis
        drag.minimumX: 0
        drag.maximumX: 380

        onEntered: card.pauseTimer()
        onExited: {
            if (!card.dismissing && !cardMouseArea.drag.active) {
                card.resumeTimer();
            }
        }

        onPositionChanged: {
            if (drag.active) {
                card.opacity = Math.max(0.2, 1.0 - (card.x / 240));
            }
        }

        onReleased: {
            if (card.x > 75) {
                card.dismissing = true;
                card.pauseTimer();
                flingAnim.start();
            } else if (card.x > 0) {
                springBackAnim.start();
                if (!containsMouse) card.resumeTimer();
            }
        }

        onClicked: {
            if (card.x < 8) {
                if (card.notif && card.notif.actions) {
                    for (let i = 0; i < card.notif.actions.length; i++) {
                        if (card.notif.actions[i].id === "default") {
                            if (card.notif.actions[i].invoke) card.notif.actions[i].invoke();
                            break;
                        }
                    }
                }
                card.dismissCard();
            }
        }
    }
}
