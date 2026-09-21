import QtQuick
import "../../../../theme"

Item {
    id: root

    property bool isHovered: false
    property bool is24Hour: false
    property var currentDate: new Date()

    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    FontLoader {
        id: titanOneFont
        source: "file:///home/vin/.local/share/fonts/TitanOne-Regular.ttf"
    }

    readonly property string displayFont: titanOneFont.name || "Titan One"
    readonly property real fontSize: 20
    readonly property real overlap: 4.5

    // Nebula Digit Splitting
    readonly property string hourDigit1: {
        let h = root.is24Hour ? root.currentDate.getHours() : (root.currentDate.getHours() % 12);
        if (!root.is24Hour && h === 0) h = 12;
        return Math.floor(h / 10).toString();
    }
    readonly property string hourDigit2: {
        let h = root.is24Hour ? root.currentDate.getHours() : (root.currentDate.getHours() % 12);
        if (!root.is24Hour && h === 0) h = 12;
        return (h % 10).toString();
    }
    readonly property string minuteDigit1: {
        let m = root.currentDate.getMinutes();
        return Math.floor(m / 10).toString();
    }
    readonly property string minuteDigit2: {
        let m = root.currentDate.getMinutes();
        return (m % 10).toString();
    }

    anchors.verticalCenter: parent.verticalCenter
    implicitHeight: 24
    implicitWidth: contentRow.implicitWidth + (root.isHovered ? 12 : 6)

    scale: root.isHovered ? 1.05 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animDurationNormal
            easing.type: Easing.OutBack
            easing.overshoot: Theme.springOvershootSubtle
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animDurationMedium
            easing.type: Easing.OutCubic
        }
    }

    // Material 3 State Layer: subtle transparent pill on hover/press
    Rectangle {
        id: stateLayer
        anchors.fill: parent
        radius: Theme.shapeCornerSmall
        color: Theme.primary
        opacity: {
            if (mouseArea.pressed) return 0.14;
            if (root.isHovered) return 0.08;
            return 0.0;
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animDurationFast }
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        // Expandable Date (Reveals smoothly on hover, M3 At-A-Glance)
        Item {
            id: dateSection
            clip: true
            implicitHeight: dateRow.implicitHeight
            height: implicitHeight
            implicitWidth: root.isHovered ? dateRow.implicitWidth : 0
            width: implicitWidth
            opacity: root.isHovered ? 1.0 : 0.0
            anchors.verticalCenter: parent.verticalCenter

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Theme.animDurationMedium
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animDurationFast
                    easing.type: Easing.OutQuad
                }
            }

            Row {
                id: dateRow
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: ""
                    font.family: matSymbols.name
                    font.pixelSize: 12
                    color: Theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: Qt.formatDateTime(root.currentDate, "ddd, d MMM")
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    color: Theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "•"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Nebula Titan One Overlapping Stencil Cutout Digit Clock
        Row {
            id: clockRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            // Hour Digit Pair (H1 White with cutout, H2 Primary Overlapping)
            Item {
                id: hourPair
                implicitWidth: h1Text.implicitWidth + h2Text.implicitWidth - root.overlap
                implicitHeight: root.fontSize + 2
                anchors.verticalCenter: parent.verticalCenter

                // Digit 1 (Surface White)
                Text {
                    id: h1Text
                    text: root.hourDigit1
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Digit 2 Cutout Background Mask (strokes into H1)
                Text {
                    text: root.hourDigit2
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.rawSurface
                    style: Text.Outline
                    styleColor: Theme.rawSurface
                    x: h1Text.implicitWidth - root.overlap
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Digit 2 Foreground (Matugen Primary)
                Text {
                    id: h2Text
                    text: root.hourDigit2
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.primary
                    x: h1Text.implicitWidth - root.overlap
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Colon Separator
            Text {
                text: ":"
                font.pixelSize: root.fontSize
                font.family: root.displayFont
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            // Minute Digit Pair (M1 White with cutout, M2 Primary Overlapping)
            Item {
                id: minutePair
                implicitWidth: m1Text.implicitWidth + m2Text.implicitWidth - root.overlap
                implicitHeight: root.fontSize + 2
                anchors.verticalCenter: parent.verticalCenter

                // Digit 1 (Surface White)
                Text {
                    id: m1Text
                    text: root.minuteDigit1
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Digit 2 Cutout Background Mask (strokes into M1)
                Text {
                    text: root.minuteDigit2
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.rawSurface
                    style: Text.Outline
                    styleColor: Theme.rawSurface
                    x: m1Text.implicitWidth - root.overlap
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Digit 2 Foreground (Matugen Primary)
                Text {
                    id: m2Text
                    text: root.minuteDigit2
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.primary
                    x: m1Text.implicitWidth - root.overlap
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.isHovered = true
        onExited: root.isHovered = false
        onClicked: root.is24Hour = !root.is24Hour
    }
}
