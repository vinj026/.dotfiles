pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../components"

PanelWindow {
    id: root

    required property ShellScreen screen

    readonly property bool isTargetScreen: {
        if (MangoService.activeMonitor !== "") {
            return screen.name === MangoService.activeMonitor;
        }
        return screen === Quickshell.screens[0];
    }

    visible: isTargetScreen && NotificationService.hasNotifications

    anchors {
        top: true
        right: true
    }

    margins {
        top: 40
        right: 14
    }

    implicitWidth: 350
    implicitHeight: screen.height - 60
    color: "transparent"

    WlrLayershell.namespace: "notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    mask: Region {
        item: notifList
    }

    ListView {
        id: notifList
        width: 336
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: contentHeight
        height: contentHeight
        spacing: 8
        interactive: false
        clip: false

        model: ScriptModel {
            values: [...NotificationService.notifications]
            comparisonMode: ObjectComparison.Identity
        }

        delegate: NotificationCard {
            required property var modelData
            notif: modelData
        }

        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: Theme.durationExpressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.curveExpressiveDefaultSpatial
            }
        }
    }
}
