import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../left"
import "../right"
import "../../../../theme"
import "../../../../components"
import "../../../../core"

Item {
    id: root

    required property ShellScreen screen
    property var currentDate: new Date()

    FontLoader {
        id: titanOneFont
        source: "file:///home/vin/.local/share/fonts/TitanOne-Regular.ttf"
    }

    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    readonly property string displayFont: titanOneFont.name || "Titan One"
    readonly property real fontSize: 16
    readonly property real overlap: 3.5
    readonly property bool is24Hour: true

    // Digit Splitting for Clock
    readonly property string hourDigit1: {
        let h = root.is24Hour ? root.currentDate.getHours() : (root.currentDate.getHours() % 12);
        if (!root.is24Hour && h === 0) h = 12;
        return Math.floor(h / 10).toString();
    }
    readonly property string hourDigit2: {
        let h = root.is24Hour ? root.currentDate.getHours() : (root.currentDate.getHours() % 12);
        if (!root.is24Hour && h === 0) h = 12;
        return (h % 10).toString();
    }
    readonly property string minuteDigit1: {
        let m = root.currentDate.getMinutes();
        return Math.floor(m / 10).toString();
    }
    readonly property string minuteDigit2: {
        let m = root.currentDate.getMinutes();
        return (m % 10).toString();
    }

    // Material 3 fluid animated level for slider
    property real animLevel: OSDService.level
    Behavior on animLevel {
        NumberAnimation {
            duration: Theme.animDurationFast
            easing.type: Easing.OutQuad
        }
    }

    // ════════════════════════════════════════════════════════════════
    // EXPORTED METRICS FOR NOTCHBARVIEW
    // ════════════════════════════════════════════════════════════════
    readonly property real baseWidth: mainLayout.implicitWidth
    readonly property real osdWidth: osdRow.implicitWidth
    readonly property bool isOsdActive: OSDService.isVisible
    readonly property bool isLauncherActive: LauncherService.isOpen && ((LauncherService.targetMonitor === "" && screen === Quickshell.screens[0]) || (LauncherService.targetMonitor === screen.name))
    
    // ── Layout OSD State ──
    property bool isLayoutActive: false
    property string currentLayoutName: "Master Tile"
    property string currentLayoutIcon: "\uE8F0"
    property int currentLayoutTag: 1
    property real layoutPopScale: 1.0

    SequentialAnimation {
        id: layoutPopAnim
        NumberAnimation {
            target: root
            property: "layoutPopScale"
            from: 0.72
            to: 1.16
            duration: 150
            easing.type: Easing.OutBack
            easing.overshoot: 1.5
        }
        NumberAnimation {
            target: root
            property: "layoutPopScale"
            from: 1.16
            to: 1.0
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: layoutTimer
        interval: 1400
        repeat: false
        onTriggered: {
            root.isLayoutActive = false;
        }
    }

    Connections {
        target: MangoService
        function onLayoutChanged(monitor, symbol, name, icon, tag) {
            if (root.screen && monitor === root.screen.name) {
                root.currentLayoutName = name;
                root.currentLayoutIcon = icon;
                root.currentLayoutTag = tag;
                root.isLayoutActive = true;
                layoutPopAnim.restart();
                layoutTimer.restart();
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // HOVER EXPAND STATE
    // ════════════════════════════════════════════════════════════════
    property bool isExpanded: false

    HoverHandler {
        id: islandHoverHandler
        onHoveredChanged: {
            if (hovered) {
                unhoverTimer.stop();
                root.isExpanded = true;
            } else {
                unhoverTimer.restart();
            }
        }
    }

    Timer {
        id: unhoverTimer
        interval: 400
        onTriggered: root.isExpanded = false
    }

    onIsExpandedChanged: {
        if (isExpanded) {
            DeviceStats.retain();
        } else {
            DeviceStats.release();
        }
    }

    Component.onCompleted: {
        if (root.isExpanded) DeviceStats.retain();
    }
    Component.onDestruction: {
        if (root.isExpanded) DeviceStats.release();
    }

    // ════════════════════════════════════════════════════════════════
    // MAIN LAYOUT (symmetric centering: defaultRow always stays put)
    // ════════════════════════════════════════════════════════════════
    Item {
        id: mainLayout
        anchors.centerIn: parent

        readonly property bool isHidden: root.isOsdActive || root.isLayoutActive
        opacity: isHidden ? 0.0 : 1.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 210; easing.type: Easing.Linear }
        }

        // Symmetric width calculation: pad both sides equally so center never shifts
        readonly property real sideSpacing: root.isExpanded ? 16 : 0
        readonly property real leftW: (root.isExpanded && MediaService.hasMedia) ? leftSection.implicitWidth : 0
        readonly property real rightW: root.isExpanded ? rightSection.implicitWidth : 0
        readonly property real maxSide: Math.max(leftW, rightW)
        readonly property real sideTotal: maxSide > 0 ? (maxSide + sideSpacing) * 2 : 0

        implicitWidth: defaultRow.implicitWidth + sideTotal
        implicitHeight: defaultRow.implicitHeight

        // ── CENTER: Workspaces + Clock (always visible, never moves) ──
        Row {
            id: defaultRow
            anchors.centerIn: parent
            spacing: 12

            Workspaces {
                screen: root.screen
                startTag: 1
                count: 5
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                id: clockRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Item {
                    id: hourPair
                    implicitWidth: h1Text.implicitWidth + h2Text.implicitWidth - root.overlap
                    implicitHeight: root.fontSize + 2
                    anchors.verticalCenter: parent.verticalCenter

                    Text { id: h1Text; text: root.hourDigit1; font.pixelSize: root.fontSize; font.family: root.displayFont; color: Theme.textPrimary; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: root.hourDigit2; font.pixelSize: root.fontSize; font.family: root.displayFont; color: Theme.rawSurface; style: Text.Outline; styleColor: Theme.rawSurface; x: h1Text.implicitWidth - root.overlap; anchors.verticalCenter: parent.verticalCenter }
                    Text { id: h2Text; text: root.hourDigit2; font.pixelSize: root.fontSize; font.family: root.displayFont; color: Theme.primary; x: h1Text.implicitWidth - root.overlap; anchors.verticalCenter: parent.verticalCenter }
                }

                Text { text: ":"; font.pixelSize: root.fontSize; font.family: root.displayFont; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }

                Item {
                    id: minutePair
                    implicitWidth: m1Text.implicitWidth + m2Text.implicitWidth - root.overlap
                    implicitHeight: root.fontSize + 2
                    anchors.verticalCenter: parent.verticalCenter

                    Text { id: m1Text; text: root.minuteDigit1; font.pixelSize: root.fontSize; font.family: root.displayFont; color: Theme.textPrimary; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: root.minuteDigit2; font.pixelSize: root.fontSize; font.family: root.displayFont; color: Theme.rawSurface; style: Text.Outline; styleColor: Theme.rawSurface; x: m1Text.implicitWidth - root.overlap; anchors.verticalCenter: parent.verticalCenter }
                    Text { id: m2Text; text: root.minuteDigit2; font.pixelSize: root.fontSize; font.family: root.displayFont; color: Theme.primary; x: m1Text.implicitWidth - root.overlap; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            Workspaces {
                screen: root.screen
                startTag: 6
                count: 5
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── LEFT: Media (anchored to defaultRow.left) ──
        Row {
            id: leftSection
            visible: root.isExpanded && MediaService.hasMedia
            anchors.right: defaultRow.left
            anchors.rightMargin: mainLayout.sideSpacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Audio wave visualizer
            Item {
                width: 16; height: 14
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    anchors.centerIn: parent
                    spacing: 2; height: 14

                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index
                            width: 2; height: 14; radius: 1
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                            border.width: 0
                            property real barScale: 0.2
                            Behavior on barScale { enabled: !barAnim.running; NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            transform: Scale { origin.x: 1; origin.y: 7; yScale: barScale }
                            SequentialAnimation {
                                id: barAnim
                                running: MediaService.isPlaying && root.isExpanded
                                loops: Animation.Infinite
                                NumberAnimation { target: parent; property: "barScale"; from: 0.2; to: 0.5 + Math.random() * 0.5; duration: 500 + index * 80; easing.type: Easing.InOutSine }
                                NumberAnimation { target: parent; property: "barScale"; from: 0.5 + Math.random() * 0.5; to: 0.2 + Math.random() * 0.3; duration: 450 + index * 70; easing.type: Easing.InOutSine }
                                NumberAnimation { target: parent; property: "barScale"; from: 0.2 + Math.random() * 0.3; to: 0.7 + Math.random() * 0.3; duration: 550 + index * 60; easing.type: Easing.InOutSine }
                                NumberAnimation { target: parent; property: "barScale"; from: 0.7 + Math.random() * 0.3; to: 0.2; duration: 480 + index * 90; easing.type: Easing.InOutSine }
                                onRunningChanged: if (!running) parent.barScale = 0.2
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent; anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MediaPopupService.toggle(root.screen.name)
                }
            }

            // Track title (marquee)
            Item {
                id: mediaTextClip
                width: 100; height: 16; clip: true
                anchors.verticalCenter: parent.verticalCenter

                readonly property bool needsScroll: mediaTitleText.implicitWidth > width
                property real scrollX: 0

                NumberAnimation on scrollX {
                    from: 0
                    to: mediaTextClip.needsScroll ? (mediaTitleText.implicitWidth + 28) : 0
                    duration: mediaTextClip.needsScroll ? (mediaTitleText.implicitWidth + 28) * 60 : 1000
                    loops: Animation.Infinite
                    running: root.isExpanded && MediaService.hasMedia && mediaTextClip.needsScroll
                    easing.type: Easing.Linear
                }

                Text {
                    id: mediaTitleText
                    x: -mediaTextClip.scrollX
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium
                    color: Theme.textPrimary; text: MediaService.displayText || "No media"
                }
                Text {
                    visible: mediaTextClip.needsScroll
                    x: mediaTitleText.x + mediaTitleText.implicitWidth + 28
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium
                    color: Theme.textPrimary; text: MediaService.displayText || ""
                }
            }

            // Play/Pause icon (bare, no container)
            Item {
                width: 14; height: 14
                anchors.verticalCenter: parent.verticalCenter
                scale: playMouse.pressed ? 0.85 : (playMouse.containsMouse ? 1.15 : 1.0)
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    font.family: matSymbols.name; font.pixelSize: 14
                    text: MediaService.isPlaying ? "\uE034" : "\uE037"
                    color: MediaService.isPlaying ? Theme.primary : Theme.textPrimary
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent; anchors.margins: -6
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: MediaService.togglePlay()
                }
            }
        }

        // ── RIGHT: Wifi, Volume, Battery (anchored to defaultRow.right) ──
        Row {
            id: rightSection
            visible: root.isExpanded
            anchors.left: defaultRow.right
            anchors.leftMargin: mainLayout.sideSpacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Wifi
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: matSymbols.name; font.pixelSize: 15
                text: sysStatus.isWifiConnected ? "\uE1BA" : "\uE1DA"
                color: sysStatus.isWifiConnected ? Theme.textPrimary : Theme.textDim
            }

            // Volume
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: matSymbols.name; font.pixelSize: 15
                text: (sysStatus.isMuted || sysStatus.volumeLevel === 0) ? "\uE04F" : "\uE050"
                color: sysStatus.isMuted ? Theme.error : Theme.textPrimary
            }

            // Battery
            Row {
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter

                Item {
                    width: 18; height: 9; anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        id: batBody
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        width: 15; height: 9; radius: 2; color: "transparent"
                        Rectangle { anchors.fill: parent; radius: parent.radius; color: Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.5) }
                        Rectangle {
                            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 2
                            width: Math.max(0, (parent.width - 4) * Math.min(1, sysStatus.batteryCapacity / 100))
                            radius: 1; color: Theme.textPrimary
                        }
                    }
                    Rectangle { anchors.left: batBody.right; anchors.verticalCenter: parent.verticalCenter; width: 2; height: 4; radius: 1; color: Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.5) }
                }
                Text {
                    font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium
                    text: sysStatus.batteryCapacity + "%"
                    color: Theme.textPrimary; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // Hidden SystemStatus instance for data (wifi, volume, battery polling)
    SystemStatus {
        id: sysStatus
        visible: false
    }

    // ════════════════════════════════════════════════════════════════
    // OSD VIEW: Volume/Brightness Slider (Highest Priority)
    // ════════════════════════════════════════════════════════════════
    Row {
        id: osdRow
        anchors.centerIn: parent
        spacing: 12
        visible: opacity > 0.01

        readonly property bool isShown: root.isOsdActive
        opacity: isShown ? 1.0 : 0.0
        scale: isShown ? 1.0 : 0.92

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: osdRow.isShown ? 90 : 0 }
                NumberAnimation { duration: osdRow.isShown ? 210 : 90; easing.type: Easing.Linear }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: osdRow.isShown ? 90 : 0 }
                NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershootExpressive }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: matSymbols.name; font.pixelSize: 18
            color: (OSDService.mode === "volume" && OSDService.isMuted) ? Theme.error : Theme.primary

            text: {
                if (OSDService.mode === "volume") {
                    if (OSDService.isMuted || root.animLevel === 0) return "\uE04F";
                    if (root.animLevel > 0.6) return "\uE050";
                    if (root.animLevel > 0.2) return "\uE04D";
                    return "\uE04E";
                } else {
                    if (root.animLevel > 0.6) return "\uE1AC";
                    if (root.animLevel > 0.2) return "\uE1AD";
                    return "\uE1AE";
                }
            }
        }

        Item {
            id: sliderArea
            anchors.verticalCenter: parent.verticalCenter
            width: 140; height: 12

            readonly property int gapSize: 5
            readonly property int activeWidth: Math.round(width * Math.max(0.0, Math.min(1.0, root.animLevel)))

            Rectangle {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: Math.max(0, sliderArea.activeWidth)
                radius: height / 2
                color: (OSDService.mode === "volume" && OSDService.isMuted) ? Theme.error : Theme.primary
                visible: width > 0
            }

            Rectangle {
                anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
                anchors.leftMargin: Math.min(sliderArea.width, sliderArea.activeWidth + (sliderArea.activeWidth > 0 ? sliderArea.gapSize : 0))
                radius: height / 2
                color: Theme.surfaceVariant; opacity: 0.75
                visible: (sliderArea.width - anchors.leftMargin) > 0
            }

            MouseArea {
                anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                function updatePos(mouseX: real) {
                    let relX = mouseX - 8;
                    let fraction = Math.max(0.0, Math.min(1.0, relX / sliderArea.width));
                    OSDService.setInteractiveLevel(fraction);
                }
                onPressed: mouse => updatePos(mouse.x)
                onPositionChanged: mouse => { if (pressed) updatePos(mouse.x); }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 34; horizontalAlignment: Text.AlignRight
            font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold
            color: Theme.textPrimary
            text: Math.round(root.animLevel * 100) + "%"
        }
    }

    // ════════════════════════════════════════════════════════════════
    // LAYOUT OSD VIEW: Expressive Material 3 Layout Display
    // ════════════════════════════════════════════════════════════════
    Item {
        id: layoutContainer
        anchors.fill: parent
        visible: opacity > 0.01

        readonly property bool isShown: !root.isOsdActive && root.isLayoutActive
        opacity: isShown ? 1.0 : 0.0
        scale: isShown ? 1.0 : 0.92

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: layoutContainer.isShown ? 90 : 0 }
                NumberAnimation { duration: layoutContainer.isShown ? 210 : 90; easing.type: Easing.Linear }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: layoutContainer.isShown ? 90 : 0 }
                NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershootSubtle }
            }
        }

        Row {
            anchors.centerIn: parent
            scale: root.layoutPopScale
            transformOrigin: Item.Center
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: matSymbols.name; font.pixelSize: 18
                color: Theme.primary; text: root.currentLayoutIcon
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold
                color: Theme.textPrimary; text: root.currentLayoutName
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Medium
                color: Theme.textMuted; text: "•  WS " + root.currentLayoutTag
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: MangoService.cycleLayout()
        }
    }

    WheelHandler {
        target: null
        enabled: root.isLayoutActive
        onWheel: event => { MangoService.cycleLayout(); }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: root.currentDate = new Date()
    }
}
