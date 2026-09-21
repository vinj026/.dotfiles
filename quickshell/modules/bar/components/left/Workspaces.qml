import QtQuick
import QtQuick.Shapes
import Quickshell
import "../../../../shapes/material"
import "../../../../theme"
import "../../../../components"

Row {
    id: root

    required property ShellScreen screen

    spacing: 4
    anchors.verticalCenter: parent.verticalCenter

    readonly property string screenName: root.screen ? root.screen.name : ""

    property int activeTag: 1
    property var occupiedMap: ({})
    property var urgentMap: ({})

    property int activeShapeIndex: 0
    property real popScale: 1.0
    property int startTag: 1
    property int count: 5

    function refreshTags() {
        if (!screenName) return;
        let list = (MangoService.monitorTags && MangoService.monitorTags[screenName]) 
            ? MangoService.monitorTags[screenName] 
            : [];
        if (!list || list.length === 0) return;

        let newActive = 1;
        let newOcc = {};
        let newUrg = {};

        for (let i = 0; i < list.length; i++) {
            let tag = list[i];
            if (tag.is_active) {
                newActive = tag.index;
            }
            if ((tag.client_count ?? 0) > 0) {
                newOcc[tag.index] = true;
            }
            if (tag.is_urgent) {
                newUrg[tag.index] = true;
            }
        }

        if (root.activeTag !== newActive) {
            root.activeTag = newActive;
            root.activeShapeIndex = M3Shapes.getRandomIndex(root.activeShapeIndex);
            popAnimation.restart();
        }
        root.occupiedMap = newOcc;
        root.urgentMap = newUrg;
    }

    Connections {
        target: MangoService
        function onTagsUpdated() {
            root.refreshTags();
        }
        function onMonitorTagsChanged() {
            root.refreshTags();
        }
    }

    onScreenNameChanged: refreshTags()

    Component.onCompleted: {
        activeShapeIndex = M3Shapes.getRandomIndex(-1);
        refreshTags();
    }

    // Smooth Pop animation when active shape switches
    SequentialAnimation {
        id: popAnimation
        NumberAnimation {
            target: root
            property: "popScale"
            from: 0.35
            to: 1.25
            duration: 160
            easing.type: Easing.OutBack
        }
        NumberAnimation {
            target: root
            property: "popScale"
            from: 1.25
            to: 1.0
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Repeater {
        model: root.count

        Item {
            id: tagContainer

            required property int index
            readonly property int tagIndex: root.startTag + index
            readonly property bool isActive: (root.activeTag === tagIndex)
            readonly property bool isOccupied: Boolean(root.occupiedMap && root.occupiedMap[tagIndex])
            readonly property bool isUrgent: Boolean(root.urgentMap && root.urgentMap[tagIndex])

            // Generous hit target for clicking
            width: Math.max(12, shapeWrapper.width + 2)
            height: 22
            anchors.verticalCenter: parent.verticalCenter

            Item {
                id: shapeWrapper
                anchors.centerIn: parent

                width: {
                    if (tagContainer.isActive) return 16;
                    if (tagContainer.isUrgent) return 13;
                    if (tagContainer.isOccupied) return 9;
                    return 6;
                }

                height: {
                    if (tagContainer.isActive) return 16;
                    if (tagContainer.isUrgent) return 13;
                    if (tagContainer.isOccupied) return 9;
                    return 6;
                }

                scale: (tagContainer.isActive ? root.popScale : 1.0) * (mouseArea.containsMouse ? 1.22 : 1.0)
                opacity: {
                    if (tagContainer.isActive) return 1.0;
                    if (tagContainer.isUrgent) return 1.0;
                    if (tagContainer.isOccupied) return 0.95;
                    return mouseArea.containsMouse ? 0.90 : 0.60;
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animDurationMedium
                        easing.type: Easing.OutBack
                        easing.overshoot: Theme.springOvershootExpressive
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animDurationNormal
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.animDurationNormal
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animDurationFast }
                }

                // Morphing Material 3 Expressive Shape
                ShapeCanvas {
                    id: vectorShape
                    anchors.fill: parent
                    color: {
                        if (tagContainer.isUrgent) return Theme.error;
                        if (tagContainer.isActive) return Theme.primary;
                        if (tagContainer.isOccupied) return Theme.workspaceOccupied;
                        if (mouseArea.containsMouse) return Theme.textMuted;
                        return Theme.workspaceInactive;
                    }
                    borderWidth: 0
                    roundedPolygon: {
                        if (tagContainer.isActive) {
                            return M3Shapes.getPolygon(root.activeShapeIndex);
                        }
                        if (tagContainer.isOccupied) {
                            return M3Shapes.getPolygon((tagContainer.tagIndex * 3) % M3Shapes.count);
                        }
                        return M3Shapes.getPolygon(0);
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: MangoService.switchTag(tagContainer.tagIndex, root.screenName)
            }
        }
    }
}
