pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../components/center"
import "../components/right"
import "../../../shapes"
import "../../../theme"
import "../../../components"

Item {
    id: root

    required property ShellScreen screen
    required property var panel

    readonly property bool isLauncherActive: LauncherService.isOpen && (LauncherService.targetMonitor === "" || LauncherService.targetMonitor === root.screen.name)
    readonly property bool isControlCenterActive: ControlCenterService.isOpen && (ControlCenterService.targetMonitor === "" || ControlCenterService.targetMonitor === root.screen.name)
    readonly property bool isMediaActive: MediaPopupService.isOpen && (MediaPopupService.targetMonitor === "" || MediaPopupService.targetMonitor === root.screen.name)
    readonly property bool isWallpaperActive: WallpaperSwitcherService.isOpen && (WallpaperSwitcherService.targetMonitor === "" || WallpaperSwitcherService.targetMonitor === root.screen.name)
    readonly property bool isOverlayActive: root.isLauncherActive || root.isControlCenterActive || root.isMediaActive || root.isWallpaperActive

    // Base notch width based on active page
    readonly property real baseWidth: Math.max(160, centerIsland.baseWidth + 44)

    // Total target resting width
    readonly property real targetCenterWidth: centerIsland.isOsdActive
        ? (centerIsland.osdWidth + 44)
        : root.baseWidth

    // ALWAYS strictly centered
    readonly property real targetCenterLeft: (width - root.targetCenterWidth) / 2

    // Target Morphing Dimensions & Coordinates:
    // Launcher: 260 x 240, y: 8, radius: 10
    // Control Center (Material 3 Expressive): 500 x 280, y: 8, radius: 12
    // Rest: targetCenterWidth x 30, y: 0, radius: 14
    readonly property real ccTargetW: (controlCenterSurface && controlCenterSurface.implicitWidth > 0)
        ? controlCenterSurface.implicitWidth
        : 410

    readonly property real ccTargetH: (controlCenterSurface && controlCenterSurface.implicitHeight > 0)
        ? controlCenterSurface.implicitHeight
        : 300

    readonly property real mediaTargetW: (mediaSurface && mediaSurface.implicitWidth > 0)
        ? mediaSurface.implicitWidth
        : 410

    readonly property real wpTargetW: 440
    readonly property real wpTargetH: 180

    readonly property real targetW: root.isLauncherActive ? 260 : (root.isControlCenterActive ? root.ccTargetW : (root.isMediaActive ? root.mediaTargetW : (root.isWallpaperActive ? root.wpTargetW : root.targetCenterWidth)))
    readonly property real targetH: root.isLauncherActive ? 240 : (root.isControlCenterActive ? root.ccTargetH : (root.isMediaActive ? (mediaSurface && mediaSurface.implicitHeight > 0 ? mediaSurface.implicitHeight : 136) : (root.isWallpaperActive ? root.wpTargetH : Theme.notchHeight)))
    readonly property real targetX: root.isOverlayActive
        ? ((width - root.targetW) / 2)
        : root.targetCenterLeft
    readonly property real targetY: root.isOverlayActive ? 10 : 0
    readonly property real targetRadius: root.isControlCenterActive ? 16 : (root.isLauncherActive ? 10 : (root.isMediaActive ? 16 : (root.isWallpaperActive ? 16 : 14)))

    // Ukishima Morph Closeness (Chebyshev distance normalized to 110px)
    readonly property real morphCloseness: {
        const d = Math.max(Math.abs(morphIsland.width - root.targetW), Math.abs(morphIsland.height - root.targetH));
        return Math.max(0, 1 - Math.min(1, d / 110));
    }

    // Entrance Animation (Top-to-Bottom, strictly avoiding left-to-right initial sliding)
    property real entranceYOffset: -Theme.notchHeight - 12
    property bool isReady: false

    NumberAnimation {
        id: entranceAnim
        target: root
        property: "entranceYOffset"
        from: -Theme.notchHeight - 12
        to: 0
        duration: Theme.durationMorph
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.curveExpressiveDefaultSpatial
        onFinished: {
            root.isReady = true;
        }
    }

    Timer {
        id: initTimer
        interval: 30
        repeat: false
        onTriggered: {
            entranceAnim.restart();
        }
    }

    Component.onCompleted: {
        initTimer.restart();
    }

    onVisibleChanged: {
        if (visible) {
            root.isReady = false;
            entranceYOffset = -Theme.notchHeight - 12;
            initTimer.restart();
        }
    }

    // Fully docked at top bezel check
    readonly property bool isIslandDocked: (!root.isOverlayActive) && Math.abs(morphIsland.y - (root.targetY + root.entranceYOffset)) < 3 && Math.abs(morphIsland.height - root.targetH) < 3

    // Surface content blooms in only when the island has physically reached full height (targetH > 100 and within 25px of target)
    readonly property bool isCcFullyExpanded: root.isControlCenterActive && root.targetH > 100 && (morphIsland.height >= root.targetH - 25)
    readonly property bool isLauncherFullyExpanded: root.isLauncherActive && root.targetH > 100 && (morphIsland.height >= root.targetH - 25)
    readonly property bool isMediaFullyExpanded: root.isMediaActive && root.targetH > 80 && (morphIsland.height >= root.targetH - 20)
    readonly property bool isWallpaperFullyExpanded: root.isWallpaperActive && root.targetH > 100 && (morphIsland.height >= root.targetH - 25)

    // Expose items for input region masking in Bar.qml
    property alias morphIslandItem: morphIsland
    property alias batteryPillItem: dummyItem

    Item {
        id: dummyItem
        width: 0; height: 0; visible: false
    }

    // ────────────────────────────────────────────────────────────
    // 1. Fullscreen Backdrop MouseArea (Active ONLY when an overlay is open)
    // ────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        enabled: root.isOverlayActive
        onClicked: {
            if (root.isLauncherActive) LauncherService.close();
            if (root.isControlCenterActive) ControlCenterService.close();
            if (root.isMediaActive) MediaPopupService.close();
            if (root.isWallpaperActive) WallpaperSwitcherService.close();
        }
    }

    // ────────────────────────────────────────────────────────────
    // 2. Resting Notch Backdrop (Attached to monitor edge with fillets)
    // Only visible when resting; fades out when popup floats
    // ────────────────────────────────────────────────────────────
    NotchBar {
        anchors.left: parent.left
        anchors.right: parent.right
        y: root.entranceYOffset
        height: parent.height
        centerLeft: root.targetCenterLeft
        centerWidth: root.targetCenterWidth
        centerHeight: Theme.notchHeight
        topRadius: 12
        bottomRadius: 14
        color: Theme.surface
        opacity: root.isIslandDocked ? 1.0 : 0.0
        visible: !root.isOverlayActive && (opacity > 0.01)
        isReady: root.isReady

        Behavior on opacity {
            enabled: !root.isOverlayActive
            NumberAnimation {
                duration: 160
                easing.type: Theme.easeStandard
            }
        }
    }

    // ────────────────────────────────────────────────────────────
    // 3. Liquid Morphing Island (Ukishima Dynamic Island Architecture)
    // ────────────────────────────────────────────────────────────
    Item {
        id: morphIsland

        x: root.targetX
        y: root.targetY + root.entranceYOffset
        width: root.targetW
        height: root.targetH
        clip: true

        // Ukishima Liquid morph curve: [0.16, 1, 0.3, 1, 1, 1], duration: 420ms
        Behavior on x {
            enabled: root.isReady && !entranceAnim.running
            NumberAnimation {
                duration: Theme.durationMorph
                easing.type: Theme.easeMorph
                easing.bezierCurve: Theme.morphCurve
            }
        }

        Behavior on y {
            enabled: root.isReady && !entranceAnim.running
            NumberAnimation {
                duration: Theme.durationMorph
                easing.type: Theme.easeMorph
                easing.bezierCurve: Theme.morphCurve
            }
        }

        Behavior on width {
            enabled: root.isReady && !entranceAnim.running
            NumberAnimation {
                duration: Theme.durationMorph
                easing.type: Theme.easeMorph
                easing.bezierCurve: Theme.morphCurve
            }
        }

        Behavior on height {
            enabled: root.isReady && !entranceAnim.running
            NumberAnimation {
                duration: Theme.durationMorph
                easing.type: Theme.easeMorph
                easing.bezierCurve: Theme.morphCurve
            }
        }

        // Solid Morphing Card Background (Active during overlays/morphing; hidden when docked to avoid alpha doubling with NotchBar)
        Rectangle {
            id: popupCardBg
            anchors.fill: parent
            radius: root.targetRadius
            color: Theme.surface
            opacity: root.isIslandDocked ? 0.0 : 1.0
            border.width: 0
            border.color: "transparent"
            antialiasing: false
            smooth: false

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Theme.easeStandard
                }
            }

            Behavior on radius {
                NumberAnimation {
                    duration: Theme.durationMorph
                    easing.type: Theme.easeMorph
                    easing.bezierCurve: Theme.morphCurve
                }
            }
        }

        // Click on resting notch opens Control Center (Option 2)
        MouseArea {
            anchors.fill: parent
            enabled: !root.isOverlayActive
            cursorShape: Qt.PointingHandCursor
            onClicked: ControlCenterService.toggle(root.screen.name)
        }

        // Catch clicks on card padding so they don't trigger backdrop close
        MouseArea {
            anchors.fill: parent
            enabled: root.isOverlayActive
            onClicked: {}
        }

        // 3a. Normal Notch Content (Workspaces, Clock, Dynamic Island)
        // Instantly vanishes on open (0ms) so clock never lingers inside expanding card;
        // blooms in only after island has settled back to resting position (isIslandDocked)
        Item {
            id: barContent
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.targetCenterWidth
            height: Theme.notchHeight
            opacity: root.isIslandDocked ? 1.0 : 0.0
            visible: !root.isOverlayActive && (opacity > 0.01)

            Behavior on opacity {
                enabled: !root.isOverlayActive
                NumberAnimation {
                    duration: 160
                    easing.type: Theme.easeStandard
                }
            }

            DynamicIsland {
                id: centerIsland
                anchors.fill: parent
                screen: root.screen
            }
        }

        // 3b. Launcher Surface (Search Field & Compact Applications List)
        // Blooms in only when island reaches full size; exits instantly (0ms) on close so no ghosting occurs
        LauncherSurface {
            id: launcherSurface
            anchors.fill: parent
            active: root.isLauncherActive
            opacity: root.isLauncherFullyExpanded ? 1.0 : 0.0
            visible: root.isLauncherActive && (opacity > 0.01)

            Behavior on opacity {
                enabled: root.isLauncherActive
                NumberAnimation {
                    duration: 140
                    easing.type: Theme.easeStandard
                }
            }
        }

        // 3c. Control Center Surface (Material 3 Expressive Quick Settings)
        // Blooms in only when island reaches full size; exits instantly (0ms) on close so no ghosting occurs
        ControlCenterSurface {
            id: controlCenterSurface
            anchors.fill: parent
            active: root.isControlCenterActive
            opacity: root.isCcFullyExpanded ? 1.0 : 0.0
            visible: root.isControlCenterActive && (opacity > 0.01)

            Behavior on opacity {
                enabled: root.isControlCenterActive
                NumberAnimation {
                    duration: 140
                    easing.type: Theme.easeStandard
                }
            }
        }

        // 3d. Media Surface (Now Playing Card)
        // Blooms in only when island reaches full size; exits instantly (0ms) on close so no ghosting occurs
        MediaSurface {
            id: mediaSurface
            anchors.fill: parent
            active: root.isMediaActive
            opacity: root.isMediaFullyExpanded ? 1.0 : 0.0
            visible: root.isMediaActive && (opacity > 0.01)

            Behavior on opacity {
                enabled: root.isMediaActive
                NumberAnimation {
                    duration: 140
                    easing.type: Theme.easeStandard
                }
            }
        }

        // 3e. Wallpaper Switcher Surface (Mango Scroller Carousel)
        // Blooms in only when island reaches full size; exits instantly (0ms) on close so no ghosting occurs
        WallpaperSurface {
            id: wallpaperSurface
            anchors.fill: parent
            active: root.isWallpaperActive
            opacity: root.isWallpaperFullyExpanded ? 1.0 : 0.0
            visible: root.isWallpaperActive && (opacity > 0.01)

            Behavior on opacity {
                enabled: root.isWallpaperActive
                NumberAnimation {
                    duration: 140
                    easing.type: Theme.easeStandard
                }
            }
        }
    }
}
