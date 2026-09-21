// WallpaperPicker.qml — Wallpaper selector popup window, centered
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    visible: C.ShellState.wallpaperPickerOpen
    color:   "transparent"
    }

    screen: focusedScreen
    visible: C.ShellState.wallpaperPickerOpen
    implicitHeight: 400

    anchors {
        top: false
        bottom: false
        left: false
        right: false
    }

    Connections {
        target: root.contentItem
        function onActiveFocusChanged() {
            if (!root.contentItem.activeFocus && C.ShellState.wallpaperPickerOpen) {
                C.ShellState.closeWallpaperPicker()
            }
        }
    }

    property var wallpapers: []

    // Helper to get file basename
    function getBasename(path) {
        if (!path) return ""
        let parts = path.split("/")
        return parts[parts.length - 1]
    }

    // Process to scan wallpapers directory
    Process {
        id: wallpaperListQuery
        command: ["find", "/home/vin/.config/mango/wallpaper", "-maxdepth", "1", "-type", "f"]
        running: C.ShellState.wallpaperPickerOpen
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                let list = [];
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.endsWith(".jpg") || line.endsWith(".png") || line.endsWith(".jpeg")) {
                        list.push(line);
                    }
                }
                list.sort();
                root.wallpapers = list;
            }
        }
    }

    // Process to query active wallpaper
    Process {
        id: activeWallpaperQuery
        command: ["/home/vin/.local/bin/awww", "query"]
        running: C.ShellState.wallpaperPickerOpen
        stdout: StdioCollector {
            onStreamFinished: {
                let match = text.match(/currently displaying: image: (\S+)/)
                if (match && match[1]) {
                    C.ShellState.currentWallpaperPath = match[1].trim()
                }
            }
        }
    }

    onVisibleChanged: {
            wallpaperListQuery.running = true
            activeWallpaperQuery.running = true
        }
    }

    IpcHandler {
        target: "wallpaper"
        function open() { C.ShellState.wallpaperPickerOpen = true }
        function close() { C.ShellState.wallpaperPickerOpen = false }
        function toggle() { C.ShellState.wallpaperPickerOpen = !C.ShellState.wallpaperPickerOpen }
    }

    // Centered container
    Rectangle {
        id: container
        anchors.fill: parent

        radius: C.Style.r.lg
        color:  C.Colors.alpha(C.Colors.base, C.Style.opPanel)
        opacity: 1.0
        border.width: 0

        focus: true
        Keys.onEscapePressed: C.ShellState.closeWallpaperPicker()

        Column {
            anchors.fill: parent
            anchors.margins: C.Style.sp.lg
            spacing: C.Style.sp.md

            // ── Header ───────────────────────────────────────
            Item {
                id: headerItem
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SELECT WALLPAPER"
                    font.family: C.Style.fontMono
                    font.pixelSize: C.Style.fs.md
                    font.weight: C.Style.fw.bold
                    color: C.Colors.accent
                }

                // Close button
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "close"
                    font.family: C.Style.fontIcon
                    font.pixelSize: C.Style.icon.md
                    color: closeMouse.containsMouse ? C.Colors.red : C.Colors.subtext1
                    Behavior on color { ColorAnimation { duration: C.Style.durFast } }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: C.ShellState.closeWallpaperPicker()
                    }
                }
            }

            // Separator
            Rectangle {
                id: separatorItem
                width: parent.width
                height: 1
                color: C.Colors.border
            }

            // ── Grid of wallpapers ───────────────────────────
            GridView {
                id: gridView
                width: parent.width
                height: parent.height - headerItem.height - separatorItem.height - parent.spacing * 2
                cellWidth: 158
                cellHeight: 110
                model: root.wallpapers
                clip: true

                delegate: Item {
                    id: cellItem
                    required property var modelData
                    required property int index
                    width: 148
                    height: 102

                    readonly property bool isActive: modelData === C.ShellState.currentWallpaperPath

                    Rectangle {
                        anchors.fill: parent
                        border.width: 0
                        color: cellItem.isActive ? C.Colors.alpha(C.Colors.accent, 0.25) : (cellMouse.containsMouse ? C.Colors.overlay0 : "transparent")

                        // Thumbnail image
                        Image {
                            id: thumb
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 1
                            height: 74
                            source: "file://" + modelData
                            sourceSize.width: 146
                            sourceSize.height: 74
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                        }

                        // Bottom label
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 26
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 8
                                text: {
                                    let base = getBasename(modelData);
                                    // Remove extension
                                    let lastDot = base.lastIndexOf(".");
                                    return lastDot !== -1 ? base.substring(0, lastDot) : base;
                                }
                                font.family: C.Style.fontMono
                                font.pixelSize: C.Style.fs.xs
                                color: cellItem.isActive ? C.Colors.accent : C.Colors.text
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }

                        // Active Indicator dot in the top-right corner
                        Rectangle {
                            visible: cellItem.isActive
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 6
                            width: 8
                            height: 8
                            radius: 4
                            color: C.Colors.green
                        }
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            C.ShellState.currentWallpaperPath = modelData
                            Quickshell.execDetached(["/home/vin/.local/bin/awww", "img", modelData])
                            C.ShellState.closeWallpaperPicker()
                        }
                    }
                }
            }
        }
