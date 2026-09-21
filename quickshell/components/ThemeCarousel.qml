import QtQuick
import QtQuick.Layouts
import qs.core as C
import Quickshell

Item {
    id: root
    width: parent.width
    height: 40

    property var themes: [
        { name: "Wallpaper", id: "wallpaper" },
        { name: "Monochrome", id: "monochrome" },
        { name: "Everblush", id: "everblush" },
        { name: "Gruvbox", id: "gruvbox" },
        { name: "Everforest", id: "everforest" },
        { name: "Monokai", id: "monokai" },
        { name: "Catppuccin", id: "catppuccin" }
    ]
    property int currentIndex: 0

    Row {
        anchors.fill: parent
        anchors.margins: C.Style.sp.xs
        spacing: 4

        // Left Arrow
        Item {
            width: 24
            height: parent.height
            Text {
                anchors.centerIn: parent
                text: "chevron_left"
                font.family: C.Style.fontIcon
                font.pixelSize: C.Style.icon.md
                color: leftArrowHover.containsMouse ? C.Colors.accent : C.Colors.subtext1
                Behavior on color { ColorAnimation { duration: C.Style.durFast } }
            }
            MouseArea {
                id: leftArrowHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.currentIndex > 0) {
                        root.currentIndex--
                    } else {
                        root.currentIndex = root.themes.length - 1
                    }
                }
            }
        }

        // Theme Pills ListView
        ListView {
            id: listView
            width: parent.width - 48 - 8 // 24*2 for arrows + spacing
            height: parent.height
            orientation: ListView.Horizontal
            interactive: true
            clip: true
            model: root.themes
            spacing: C.Style.sp.sm
            
            currentIndex: root.currentIndex
            onCurrentIndexChanged: root.currentIndex = currentIndex

            Connections {
                target: root
                function onCurrentIndexChanged() {
                    listView.positionViewAtIndex(root.currentIndex, ListView.Contain)
                }
            }

            delegate: Rectangle {
                width: 90
                height: listView.height
                radius: C.Style.r.md
                color: (listView.currentIndex === index) ? C.Colors.alpha(C.Colors.accent, 0.2) : (mouseArea.containsMouse ? C.Colors.overlay0 : "transparent")
                
                Text {
                    anchors.centerIn: parent
                    text: modelData.name
                    font.family: C.Style.fontMono
                    font.pixelSize: C.Style.fs.xs
                    color: (listView.currentIndex === index) ? C.Colors.accent : C.Colors.text
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        listView.currentIndex = index
                        Quickshell.execDetached(["/home/vin/.config/quickshell/scripts/apply_theme.sh", modelData.id])
                    }
                }
            }
        }

        // Right Arrow
        Item {
            width: 24
            height: parent.height
            Text {
                anchors.centerIn: parent
                text: "chevron_right"
                font.family: C.Style.fontIcon
                font.pixelSize: C.Style.icon.md
                color: rightArrowHover.containsMouse ? C.Colors.accent : C.Colors.subtext1
                Behavior on color { ColorAnimation { duration: C.Style.durFast } }
            }
            MouseArea {
                id: rightArrowHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.currentIndex < root.themes.length - 1) {
                        root.currentIndex++
                    } else {
                        root.currentIndex = 0
                    }
                }
            }
        }
    }
}
