// Launcher.qml — App launcher popup window, centered
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.components.launcher
import qs.core as C
PanelWindow {
    id: root

    property var focusedScreen: {
        let name = mangoService.selectedMonitor
        return Quickshell.screens.find(s => s.name === name) ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    }

    screen: focusedScreen
    visible: C.ShellState.launcherOpen
    color: "transparent"

    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer:     WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    implicitWidth: 240
    implicitHeight: {
        let baseHeight = searchBar.height + C.Style.sp.xs * 2
        if (filteredApps.length > 0) {
            baseHeight += Math.min(filteredApps.length * 22, 220)
        } else if (searchQuery !== "") {
            baseHeight += 24
        }
        return baseHeight
    }
    Behavior on implicitHeight { NumberAnimation { duration: C.Style.durFast; easing.type: Easing.OutCubic } }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            C.ShellState.closeLauncher()
            searchInput.text = ""
            root.searchQuery = ""
        }
    }

    IpcHandler {
        target: "launcher"
        function open() { C.ShellState.openLauncher() }
        function close() { C.ShellState.closeLauncher() }
        function toggle() { C.ShellState.toggleLauncher() }
    }

    // Filtered model
    property string searchQuery: ""
    property var filteredApps: {
        if (!DesktopEntries.applications || !DesktopEntries.applications.values) return []
        let q = searchQuery.toLowerCase()
        let apps = []
        let values = DesktopEntries.applications.values
        for (let i = 0; i < values.length; i++) {
            let app = values[i]
            if (!app.noDisplay && (
                q === "" ||
                (app.name ?? "").toLowerCase().includes(q) ||
                (app.genericName ?? "").toLowerCase().includes(q) ||
                (app.description ?? "").toLowerCase().includes(q)
            )) {
                apps.push(app)
            }
        }
        // Sort: exact match first, then alphabetical
        apps.sort((a, b) => {
            let an = (a.name ?? "").toLowerCase()
            let bn = (b.name ?? "").toLowerCase()
            let aExact = an.startsWith(q)
            let bExact = bn.startsWith(q)
            if (aExact && !bExact) return -1
            if (!aExact && bExact) return 1
            return an.localeCompare(bn)
        })
        return apps.slice(0, 20)
    }

    property int selectedIndex: 0





    function launchSelected() {
        if (filteredApps.length > selectedIndex) {
            filteredApps[selectedIndex].execute()
            C.ShellState.closeLauncher()
            searchInput.text = ""
            searchQuery = ""
        }
    }

    // Centered container
    Rectangle {
        id: container
        width: 240
        height: {
            let baseHeight = searchBar.height + C.Style.sp.xs * 2
            if (filteredApps.length > 0) {
                baseHeight += Math.min(filteredApps.length * 22, 220)
            } else if (searchQuery !== "") {
                baseHeight += 24
            }
            return baseHeight
        }
        Behavior on height { NumberAnimation { duration: C.Style.durFast; easing.type: Easing.OutCubic } }
        anchors.centerIn: parent

        radius: C.Style.r.lg
        color:  C.Colors.alpha(C.Colors.base, C.Style.opPanel)
        border.width: 0

        // Swallow taps on the launcher UI itself so they don't propagate to the background TapHandler
        TapHandler {}

        focus: true
        Keys.onEscapePressed: {
            C.ShellState.closeLauncher()
            searchInput.text = ""
            root.searchQuery = ""
        }
        Keys.onUpPressed: {
            root.selectedIndex = Math.max(0, root.selectedIndex - 1)
            listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        }
        Keys.onDownPressed: {
            root.selectedIndex = Math.min(root.filteredApps.length - 1, root.selectedIndex + 1)
            listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        }
        Keys.onReturnPressed: root.launchSelected()

        Column {
            anchors.fill: parent
            anchors.margins: C.Style.sp.xs

            // ── Search bar ────────────────────────────────────
            Rectangle {
                id: searchBar
                width: parent.width
                height: 26
                radius: C.Style.r.sm
                color:  C.Colors.mantle
                border.width: 0

                TextInput {
                    id: searchInput
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: C.Style.sp.sm
                    anchors.rightMargin: C.Style.sp.sm
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: C.Style.fontMono
                    font.pixelSize: C.Style.fs.md
                    color: C.Colors.text
                    focus: C.ShellState.launcherOpen
                    cursorVisible: focus
                    selectionColor: C.Colors.alpha(C.Colors.accent, 0.3)
                    clip: true

                    // Placeholder
                    Text {
                        visible: searchInput.text === ""
                        text: "Search apps…"
                        font: searchInput.font
                        color: C.Colors.subtext0
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    onTextChanged: {
                        root.searchQuery = text
                        root.selectedIndex = 0
                    }

                    onAccepted: root.launchSelected()

                    onActiveFocusChanged: {
                        if (!activeFocus && C.ShellState.launcherOpen) {
                            C.ShellState.closeLauncher()
                            searchInput.text = ""
                            root.searchQuery = ""
                        }
                    }

                    Keys.forwardTo: [container]
                }
            }

            // Thin separator (hidden for super clean look)
            Rectangle {
                width: parent.width
                height: 1
                color: C.Colors.border
                visible: false
            }

            // ── App list ──────────────────────────────────────
            ListView {
                id: listView
                width:  parent.width
                height: Math.max(0, parent.height - searchBar.height)
                model:  root.filteredApps
                spacing: 0
                clip: true

                delegate: AppItem {
                    app: modelData
                    width: listView.width
                    // Highlight selected
                    color: (index === root.selectedIndex)
                        ? C.Colors.alpha(C.Colors.accent, 0.15)
                        : "transparent"
                    border.width: 0
                    scale: mouseArea.pressed ? 0.98 : (mouseArea.containsMouse ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.activated()
                    }
                }

                // Empty state
                Text {
                    visible: root.filteredApps.length === 0 && root.searchQuery !== ""
                    anchors.centerIn: parent
                    text: "No results for \"" + root.searchQuery + "\""
                    font.family: C.Style.fontMono
                    font.pixelSize: C.Style.fs.md
                    color: C.Colors.subtext0
                }

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            }
        }
    }
}
