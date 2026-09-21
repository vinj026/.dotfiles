pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../components"

PanelWindow {
    id: root

    required property ShellScreen screen

    readonly property bool isTargetScreen: (LauncherService.targetMonitor === "" && screen === Quickshell.screens[0]) || (LauncherService.targetMonitor === screen.name)
    readonly property bool active: LauncherService.isOpen && isTargetScreen && ShellConfig.currentStyle !== "notch"

    visible: active || modal.opacity > 0.01

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.namespace: "launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    property string searchText: ""
    readonly property var allApps: DesktopEntries.applications.values

    readonly property var filteredApps: {
        const apps = root.allApps;
        if (!apps) return [];
        let query = root.searchText.trim().toLowerCase();
        let list = [];
        for (let i = 0; i < apps.length; i++) {
            let app = apps[i];
            if (!app || app.noDisplay) continue;
            if (!query) {
                list.push(app);
                continue;
            }
            let nameMatch = app.name && app.name.toLowerCase().includes(query);
            let idMatch = app.id && app.id.toLowerCase().includes(query);
            if (nameMatch || idMatch) {
                list.push(app);
            }
        }
        list.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return list;
    }

    onActiveChanged: {
        if (active) {
            root.searchText = "";
            searchInput.text = "";
            appList.currentIndex = 0;
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 30
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    function launchApp(app) {
        if (!app) return;
        LauncherService.close();
        app.execute();
    }

    // Completely transparent backdrop to catch dismiss clicks without obscuring open apps
    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: LauncherService.close()
    }

    // ════════════════════════════════════════════════════════════════
    // Ukishima Floating Detached Island Launcher Card
    // Pure native Rectangle, constant height, zero FBO stalls, zero jitter.
    // Scales and fades smoothly into place at y: 8 without any black sliver.
    // ════════════════════════════════════════════════════════════════
    Rectangle {
        id: modal
        width: 250
        height: 182
        anchors.horizontalCenter: parent.horizontalCenter

        // Floating position: sits detached at y: 10, subtle scale-fade entrance
        y: root.active ? 10 : 2
        scale: root.active ? 1.0 : 0.94
        opacity: root.active ? 1.0 : 0.0

        Behavior on y {
            NumberAnimation {
                duration: Theme.durationMorph
                easing.type: Theme.easeMorph
                easing.bezierCurve: Theme.morphCurve
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationMorph
                easing.type: Theme.easeMorph
                easing.bezierCurve: Theme.morphCurve
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationStandard
                easing.type: Theme.easeStandard
            }
        }

        radius: 10
        color: Theme.surface
        border.width: 0
        border.color: "transparent"
        antialiasing: false
        smooth: false

        // Prevent click-through to dismiss backdrop
        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            onClicked: {}
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // ────────────────────────────────────────────────────────────
            // 1. Integrated Search Bar Header (Pure Minimalist, No Inner Box/Border)
            // ────────────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 8

                    // Search Input
                    Item {
                        width: parent.width - 34
                        height: parent.height

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Theme.textPrimary
                            selectByMouse: true
                            selectionColor: Theme.primary
                            selectedTextColor: Theme.textOnPrimary

                            Text {
                                text: "Search apps..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Theme.textMuted
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !searchInput.text && !searchInput.activeFocus
                            }

                            onTextChanged: {
                                root.searchText = text;
                                appList.currentIndex = 0;
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down) {
                                    event.accepted = true;
                                    if (appList.currentIndex < root.filteredApps.length - 1) {
                                        appList.currentIndex++;
                                    }
                                } else if (event.key === Qt.Key_Up) {
                                    event.accepted = true;
                                    if (appList.currentIndex > 0) {
                                        appList.currentIndex--;
                                    }
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    event.accepted = true;
                                    if (appList.currentIndex >= 0 && appList.currentIndex < root.filteredApps.length) {
                                        root.launchApp(root.filteredApps[appList.currentIndex]);
                                    }
                                } else if (event.key === Qt.Key_Escape) {
                                    event.accepted = true;
                                    LauncherService.close();
                                }
                            }
                        }
                    }

                    // Minimal ESC Badge (Zero Border, Transparent Border Color)
                    Rectangle {
                        width: 24
                        height: 16
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 0
                        border.color: "transparent"
                        anchors.verticalCenter: parent.verticalCenter
                        scale: escMouse.pressed ? 0.90 : (escMouse.containsMouse ? 1.08 : 1.0)
                        Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack } }

                        Text {
                            text: "ESC"
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            color: Theme.textMuted
                            anchors.centerIn: parent
                            opacity: escMouse.containsMouse ? 1.0 : 0.7
                            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                        }

                        MouseArea {
                            id: escMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: LauncherService.close()
                        }
                    }
                }
            }

            // ────────────────────────────────────────────────────────────
            // 2. Applications ListView (Title Only, Compact, Zero Border)
            // ────────────────────────────────────────────────────────────
            Item {
                id: listContainer
                width: parent.width
                height: parent.height - 44
                clip: true

                // Empty State
                Item {
                    anchors.fill: parent
                    visible: root.filteredApps.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: "No apps found"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.textMuted
                    }
                }

                ListView {
                    id: appList
                    anchors.fill: parent
                    visible: root.filteredApps.length > 0
                    clip: true
                    model: root.filteredApps
                    spacing: 1
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: delegateItem
                        width: appList.width
                        height: 25

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: appList.currentIndex === index

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            radius: 6
                            border.width: 0
                            border.color: "transparent"

                            color: delegateItem.isSelected 
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                                : "transparent"

                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            scale: mouseArea.pressed ? 0.98 : (mouseArea.containsMouse ? 1.02 : 1.0)
                            Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Easing.OutCubic } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                // App Name Only (No Icon, Single Line, Pure Minimalism)
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 20
                                    text: delegateItem.modelData ? (delegateItem.modelData.name || "") : ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: delegateItem.isSelected ? Font.Bold : Font.Medium
                                    color: delegateItem.isSelected ? Theme.primary : Theme.textPrimary
                                    opacity: delegateItem.isSelected ? 1.0 : (mouseArea.containsMouse ? 1.0 : 0.8)
                                    Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                                    elide: Text.ElideRight
                                }

                                // Ukishima-style Return Arrow Glyph (↵) when selected
                                Text {
                                    text: "↵"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: delegateItem.isSelected
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.launchApp(delegateItem.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
