pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../components"
import "../bar/components/center"

PanelWindow {
    id: root

    required property ShellScreen screen

    readonly property bool isTargetScreen: (WallpaperSwitcherService.targetMonitor === "" && screen === Quickshell.screens[0]) || (WallpaperSwitcherService.targetMonitor === screen.name)
    readonly property bool active: WallpaperSwitcherService.isOpen && isTargetScreen && ShellConfig.currentStyle !== "notch"

    visible: active || card.opacity > 0.01

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.namespace: "wallpaper-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // Dismiss backdrop
    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: WallpaperSwitcherService.close()
    }

    // Floating card that drops down from the top bar (floating / classic styles)
    Rectangle {
        id: card
        width: 440
        height: 180
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.active ? 38 : 14

        opacity: root.active ? 1.0 : 0.0
        scale: root.active ? 1.0 : 0.96

        Behavior on y {
            NumberAnimation {
                duration: root.active ? Theme.durationGlide : 90
                easing.type: root.active ? Theme.easeMorph : Easing.InQuad
                easing.bezierCurve: Theme.morphCurve
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.active ? 130 : 80
                easing.type: Easing.OutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.active ? Theme.durationGlide : 90
                easing.type: root.active ? Theme.easeMorph : Easing.InQuad
                easing.bezierCurve: Theme.morphCurve
            }
        }

        radius: 16
        color: Theme.surface
        border.width: 0

        // Consume clicks inside card
        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            onClicked: {}
        }

        WallpaperSurface {
            anchors.fill: parent
            active: root.active
        }
    }
}
