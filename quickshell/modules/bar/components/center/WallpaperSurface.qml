pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../../../theme"
import "../../../../components"

Item {
    id: root

    property bool active: false
    focus: active

    onActiveChanged: {
        if (active) {
            root.forceActiveFocus();
        }
    }

    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    implicitWidth: 440
    implicitHeight: 180

    // ────────────────────────────────────────────────────────────
    // Keyboard Controls: WASD, Arrows, H/L, Enter, Esc
    // ────────────────────────────────────────────────────────────
    Keys.onPressed: event => {
        switch (event.key) {
            case Qt.Key_A:
            case Qt.Key_Left:
            case Qt.Key_H:
                WallpaperSwitcherService.prev();
                event.accepted = true;
                break;
            case Qt.Key_D:
            case Qt.Key_Right:
            case Qt.Key_L:
                WallpaperSwitcherService.next();
                event.accepted = true;
                break;
            case Qt.Key_W:
            case Qt.Key_Up:
            case Qt.Key_K:
                WallpaperSwitcherService.prev();
                event.accepted = true;
                break;
            case Qt.Key_S:
            case Qt.Key_Down:
            case Qt.Key_J:
                WallpaperSwitcherService.next();
                event.accepted = true;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
            case Qt.Key_Escape:
                WallpaperSwitcherService.close();
                event.accepted = true;
                break;
        }
    }

    readonly property var list: WallpaperSwitcherService.wallpapers
    readonly property int total: list ? list.length : 0
    readonly property int cur: WallpaperSwitcherService.currentIndex

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // ────────────────────────────────────────────────────────────
        // 1. Header (Icon + Title + Counter + Close)
        // ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 8

            Text {
                font.family: matSymbols.name
                font.pixelSize: 15
                text: "\uE3F4" // wallpaper
                color: Colors.primary
            }

            Text {
                text: "Wallpaper Switcher"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Colors.textPrimary
            }

            Item { Layout.fillWidth: true }

            // Counter Pill
            Rectangle {
                radius: 999
                color: Colors.surfaceVariant
                border.width: 0
                implicitWidth: countText.implicitWidth + 12
                implicitHeight: 18

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.total > 0 ? ((root.cur + 1) + " / " + root.total) : "0 / 0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: Colors.textMuted
                }
            }

            // Close Button
            Rectangle {
                width: 20
                height: 20
                color: "transparent"
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    font.family: matSymbols.name
                    font.pixelSize: 15
                    text: "\uE5CD" // close
                    color: closeArea.containsMouse ? Colors.textPrimary : Colors.textMuted

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WallpaperSwitcherService.close()
                }
            }
        }

        // ────────────────────────────────────────────────────────────
        // 2. Animated Sliding Carousel Viewport
        // ────────────────────────────────────────────────────────────
        Item {
            id: carouselArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            readonly property real cardWidth: 196
            readonly property real cardHeight: 110
            readonly property real cardSpacing: 14
            readonly property real step: cardWidth + cardSpacing

            // Sliding track containing all wallpaper cards
            Item {
                id: track
                height: carouselArea.cardHeight
                anchors.verticalCenter: parent.verticalCenter
                // Center the card at root.cur exactly in the viewport
                x: (carouselArea.width / 2) - (root.cur * carouselArea.step + carouselArea.cardWidth / 2)

                Behavior on x {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                Repeater {
                    model: root.list

                    Item {
                        id: cardItem
                        required property int index
                        required property var modelData

                        x: index * carouselArea.step
                        width: carouselArea.cardWidth
                        height: carouselArea.cardHeight
                        anchors.verticalCenter: parent.verticalCenter

                        readonly property bool isCur: cardItem.index === root.cur
                        readonly property int dist: Math.abs(cardItem.index - root.cur)
                        readonly property bool isAdjacent: cardItem.dist === 1

                        z: isCur ? 10 : (5 - Math.min(cardItem.dist, 4))
                        scale: isCur ? (cardArea.containsMouse ? 1.03 : 1.0) : (isAdjacent ? 0.82 : 0.65)
                        opacity: isCur ? 1.0 : (isAdjacent ? (cardArea.containsMouse ? 0.65 : 0.42) : 0.0)

                        Behavior on scale {
                            NumberAnimation {
                                duration: 240
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 240
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: cardItem.isCur ? 12 : 10
                            color: Colors.surfaceContainer
                            border.width: 0

                            Behavior on radius { NumberAnimation { duration: 200 } }

                            Image {
                                id: cardImg
                                anchors.fill: parent
                                source: cardItem.modelData ? ("file://" + cardItem.modelData.path) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 320
                                sourceSize.height: 180
                                visible: false
                            }

                            Rectangle {
                                id: cardMask
                                anchors.fill: parent
                                radius: cardItem.isCur ? 12 : 10
                                border.width: 0
                                visible: false

                                Behavior on radius { NumberAnimation { duration: 200 } }
                            }

                            OpacityMask {
                                anchors.fill: parent
                                source: cardImg
                                maskSource: cardMask
                                cached: true
                            }

                            // Info Gradient Overlay (shown prominently on current card)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 32
                                radius: cardItem.isCur ? 12 : 10
                                opacity: cardItem.isCur ? 1.0 : 0.0
                                visible: opacity > 0.01

                                Behavior on opacity { NumberAnimation { duration: 200 } }

                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.82) }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 6

                                    Text {
                                        Layout.fillWidth: true
                                        text: cardItem.modelData ? cardItem.modelData.title : ""
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: "#ffffff"
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        visible: cardItem.modelData ? cardItem.modelData.isCurrent : false
                                        radius: 999
                                        color: Colors.primary
                                        border.width: 0
                                        implicitWidth: activeBadgeText.implicitWidth + 8
                                        implicitHeight: 16

                                        Text {
                                            id: activeBadgeText
                                            anchors.centerIn: parent
                                            text: "ACTIVE"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                            font.weight: Font.Bold
                                            color: Colors.textOnPrimary
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: cardArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (cardItem.isCur) {
                                    WallpaperSwitcherService.close();
                                } else {
                                    WallpaperSwitcherService.selectIndex(cardItem.index);
                                }
                            }
                        }
                    }
                }
            }

            // ── Floating Chevrons (Prev / Next) ──
            Rectangle {
                width: 26
                height: 26
                radius: 13
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                z: 20
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.85)
                border.width: 0
                opacity: prevChevronArea.containsMouse ? 1.0 : 0.75
                scale: prevChevronArea.containsMouse ? 1.08 : 1.0

                Behavior on opacity { NumberAnimation { duration: 100 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    font.family: matSymbols.name
                    font.pixelSize: 16
                    text: "\uE5CB" // chevron_left
                    color: Colors.textPrimary
                }

                MouseArea {
                    id: prevChevronArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WallpaperSwitcherService.prev()
                }
            }

            Rectangle {
                width: 26
                height: 26
                radius: 13
                x: parent.width - width - 6
                anchors.verticalCenter: parent.verticalCenter
                z: 20
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.85)
                border.width: 0
                opacity: nextChevronArea.containsMouse ? 1.0 : 0.75
                scale: nextChevronArea.containsMouse ? 1.08 : 1.0

                Behavior on opacity { NumberAnimation { duration: 100 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    font.family: matSymbols.name
                    font.pixelSize: 16
                    text: "\uE5CC" // chevron_right
                    color: Colors.textPrimary
                }

                MouseArea {
                    id: nextChevronArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WallpaperSwitcherService.next()
                }
            }
        }

        // ────────────────────────────────────────────────────────────
        // 3. Footer (WASD Hints + Close Button)
        // ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 8

            Text {
                text: "A / D or ← → to switch • Enter / Esc to finish"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Colors.textDim
            }

            Item { Layout.fillWidth: true }

            // Done / Close Button
            Rectangle {
                height: 22
                implicitWidth: doneLabelRow.implicitWidth + 14
                radius: 999
                color: Colors.primary
                border.width: 0
                opacity: doneBtnArea.containsMouse ? 0.9 : 1.0
                scale: doneBtnArea.containsMouse ? 1.02 : 1.0

                Behavior on opacity { NumberAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 120 } }

                RowLayout {
                    id: doneLabelRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        font.family: matSymbols.name
                        font.pixelSize: 13
                        text: "\uE876" // check
                        color: Colors.textOnPrimary
                    }

                    Text {
                        text: "Done"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Colors.textOnPrimary
                    }
                }

                MouseArea {
                    id: doneBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WallpaperSwitcherService.close()
                }
            }
        }
    }
}
