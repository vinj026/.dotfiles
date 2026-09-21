pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../../../theme"
import "../../../../components"

Item {
    id: root

    property bool active: false
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
        interval: 40
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    function launchApp(app) {
        if (!app) return;
        LauncherService.close();
        app.execute();
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: 8
        spacing: 5

        // ────────────────────────────────────────────────────────────
        // 1. Search Bar Header (Enlarged 12px text, 26px height)
        // ────────────────────────────────────────────────────────────
        Row {
            width: parent.width
            height: 26
            spacing: 6

            // Floating Search Input Field
            Rectangle {
                width: parent.width - 29
                height: 26
                radius: 6
                color: Qt.rgba(1, 1, 1, 0.07)
                border.width: 0
                border.color: "transparent"

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Theme.textPrimary
                    clip: true
                    selectByMouse: true
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.surface

                    Text {
                        text: "Search apps..."
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
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

            // Minimal ESC Badge
            Rectangle {
                width: 23
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
                    font.pixelSize: 9
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

        // ────────────────────────────────────────────────────────────
        // 2. Applications ListView (Enlarged 12px text, 24px rows)
        // ────────────────────────────────────────────────────────────
        Item {
            id: listContainer
            width: parent.width
            height: parent.height - 31
            clip: true

            // Empty State
            Item {
                anchors.fill: parent
                visible: root.filteredApps.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "No apps found"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
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
                    height: 24

                    required property var modelData
                    required property int index

                    readonly property bool isSelected: appList.currentIndex === index

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 2
                        anchors.rightMargin: 2
                        radius: 5
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
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 4

                            // App Name
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 18
                                text: delegateItem.modelData ? (delegateItem.modelData.name || "") : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: delegateItem.isSelected ? Font.Bold : Font.Medium
                                color: delegateItem.isSelected ? Theme.primary : Theme.textPrimary
                                opacity: delegateItem.isSelected ? 1.0 : (mouseArea.containsMouse ? 1.0 : 0.8)
                                Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                                elide: Text.ElideRight
                            }

                            // Return Arrow Glyph (↵)
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
