import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../../theme"
import "../../../../../components"

Item {
    id: root

    property bool active: false
    property string symbolFont: ""

    implicitWidth: 348
    implicitHeight: mainCol.implicitHeight

    // ── Wallpaper discovery (shared with set-wallpaper.sh) ──
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.dotfiles/mango/wallpaper"
    property var wallpapers: []
    property var wpBuffer: []
    property string currentWallpaper: ""

    Process {
        id: wpListProc
        command: ["bash", "-c", "ls -1 \"$HOME/.dotfiles/mango/wallpaper\" 2>/dev/null | grep -Ei '\\.(jpg|jpeg|png|webp|gif|bmp)$' | grep -v '^current\\.'"]
        stdout: SplitParser {
            onRead: data => {
                let name = data.trim();
                if (name.length > 0) root.wpBuffer.push(name);
            }
        }
        onExited: {
            root.wallpapers = root.wpBuffer;
            root.wpBuffer = [];
        }
    }

    Process {
        id: wpCurrentProc
        command: ["bash", "-c", "readlink -f \"$HOME/.dotfiles/mango/wallpaper/current.jpg\" 2>/dev/null || readlink -f \"$HOME/.config/mango/wallpaper/current.jpg\" 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                let p = data.trim();
                if (p.length > 0) root.currentWallpaper = p;
            }
        }
    }

    Timer {
        interval: 8000; repeat: true; running: root.active; triggeredOnStart: true
        onTriggered: {
            root.wpBuffer = [];
            if (!wpListProc.running) wpListProc.running = true;
            if (!wpCurrentProc.running) wpCurrentProc.running = true;
        }
    }

    function applyWallpaper(path) {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.dotfiles/scripts/set-wallpaper.sh", path]);
    }

    function setPalette(theme) {
        ShellConfig.setTheme(theme);
    }

    function setBarStyle(style) {
        ShellConfig.setStyle(style);
    }

    Column {
        id: mainCol
        width: parent.width
        spacing: 8

        // ── Wallpaper Picker ──
        Text {
            font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
            text: "WALLPAPER"
            color: Theme.textMuted
        }

        Grid {
            id: wpGrid
            width: parent.width
            columns: 3
            columnSpacing: 8
            rowSpacing: 8

            readonly property real cellW: (width - 16) / 3

            Repeater {
                model: root.wallpapers.length

                Item {
                    id: wpCell
                    width: wpGrid.cellW
                    height: 62

                    readonly property string wpPath: root.wallpaperDir + "/" + root.wallpapers[index]
                    readonly property bool isCurrent: root.currentWallpaper === wpPath

                    Rectangle {
                        id: thumb
                        anchors.fill: parent
                        radius: Theme.shapeCornerLarge
                        color: Theme.surfaceContainerHighest
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: "file://" + wpCell.wpPath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 220
                            sourceSize.height: 124
                        }

                        // Current selection indicator (Borderless tonal tint)
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: wpCell.isCurrent ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25) : "transparent"
                            border.width: 0
                        }
                    }

                    scale: wpMouse.pressed ? 0.94 : (wpMouse.containsMouse ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Easing.OutCubic } }

                    MouseArea {
                        id: wpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyWallpaper(wpCell.wpPath)
                    }
                }
            }
        }

        Text {
            visible: root.wallpapers.length === 0
            width: parent.width
            font.family: Theme.fontFamily; font.pixelSize: 10
            text: "Drop images into ~/.dotfiles/mango/wallpaper"
            color: Theme.textDim
        }

        // ── Theme Palette ──
        Text {
            font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
            text: "THEME PALETTE"
            color: Theme.textMuted
        }

        Grid {
            width: parent.width
            columns: 3
            columnSpacing: 6
            rowSpacing: 6

            Repeater {
                model: [
                    { "label": "Wallpaper",  "value": "wallpaper" },
                    { "label": "Mono",       "value": "monochrome" },
                    { "label": "Everblush",  "value": "everblush" },
                    { "label": "Catppuccin", "value": "catppuccin" },
                    { "label": "Everforest", "value": "everforest" },
                    { "label": "Vercel",     "value": "vercel" }
                ]

                Rectangle {
                    id: palChip
                    width: (parent.width - 12) / 3
                    height: 32
                    radius: Theme.shapeCornerFull
                    color: palChip.isSelected ? Theme.secondaryContainer : Theme.surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    scale: palMouse.pressed ? 0.92 : (palMouse.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Easing.OutCubic } }

                    readonly property var pData: modelData
                    readonly property bool isSelected: ShellConfig.currentTheme === palChip.pData.value

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: palChip.isSelected ? Font.Bold : Font.Medium
                        text: palChip.pData.label
                        color: palChip.isSelected ? Theme.onSecondaryContainer : Theme.textMuted
                        opacity: palChip.isSelected ? 1.0 : (palMouse.containsMouse ? 1.0 : 0.8)
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                    }

                    MouseArea {
                        id: palMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setPalette(palChip.pData.value)
                    }
                }
            }
        }

        // ── Bar Style ──
        Text {
            font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
            text: "BAR STYLE"
            color: Theme.textMuted
        }

        Rectangle {
            width: parent.width
            height: 36
            radius: Theme.shapeCornerFull
            color: Theme.surfaceContainerHigh

            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: [
                        { "label": "Notch",    "value": "notch" },
                        { "label": "Floating", "value": "floating" },
                        { "label": "Classic",  "value": "classic" }
                    ]

                    Item {
                        id: styleItem
                        width: (parent.width - 6) / 3
                        height: parent.height

                        readonly property var sData: modelData
                        readonly property bool isSelected: ShellConfig.currentStyle === styleItem.sData.value

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.shapeCornerFull
                            color: styleItem.isSelected ? Theme.primaryContainer : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            scale: styleMouse.pressed ? 0.92 : (styleMouse.containsMouse ? 1.05 : 1.0)
                            Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: styleItem.isSelected ? Font.Bold : Font.Medium
                                text: styleItem.sData.label
                                color: styleItem.isSelected ? Theme.onPrimaryContainer : Theme.textMuted
                                opacity: styleItem.isSelected ? 1.0 : (styleMouse.containsMouse ? 1.0 : 0.8)
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                            }
                        }

                        MouseArea {
                            id: styleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setBarStyle(styleItem.sData.value)
                        }
                    }
                }
            }
        }
    }
}