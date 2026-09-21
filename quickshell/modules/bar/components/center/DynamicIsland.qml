import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../left"
import "../right"
import "../../../../theme"
import "../../../../components"
import "../../../../core" // Untuk DeviceStats & Battery

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
    // Fixed notch resting width: constant across all carousel pages so content adapts to it
    readonly property real baseWidth: defaultRow.implicitWidth
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

    // ── Scrolling text for long titles (Calm, readable M3 marquee) ──
    property real scrollOffset: 0
    readonly property bool needsScroll: mediaTitleText.implicitWidth > mediaTextClip.width

    NumberAnimation {
        id: scrollAnim
        target: root
        property: "scrollOffset"
        from: 0
        to: root.needsScroll ? (mediaTitleText.implicitWidth + 28) : 0
        duration: root.needsScroll ? (mediaTitleText.implicitWidth + 28) * 65 : 1000
        loops: Animation.Infinite
        easing.type: Easing.Linear
        running: root.currentPage === 2 && MediaService.hasMedia && root.needsScroll
    }

    onCurrentPageChanged: {
        if (currentPage !== 2) {
            scrollAnim.stop();
            root.scrollOffset = 0;
        }
        if (currentPage === 1) {
            DeviceStats.retain();
        } else {
            DeviceStats.release();
        }
    }

    Component.onCompleted: {
        if (root.currentPage === 1) {
            DeviceStats.retain();
        }
    }

    Component.onDestruction: {
        if (root.currentPage === 1) {
            DeviceStats.release();
        }
    }

    // ── Page State for Carousel ──
    property int currentPage: 0
    readonly property int maxPages: MediaService.hasMedia ? 3 : 2
    
    Timer {
        id: pageRevertTimer
        interval: 6000
        onTriggered: root.currentPage = 0
    }
    
    // Dedicated MouseArea for scrolling to switch pages across the entire notch
    MouseArea {
        id: pageScrollArea
        anchors.fill: parent
        z: 99
        acceptedButtons: Qt.NoButton
        hoverEnabled: false
        enabled: !root.isLayoutActive && !root.isOsdActive
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                root.currentPage = (root.currentPage - 1 + root.maxPages) % root.maxPages;
            } else if (wheel.angleDelta.y < 0) {
                root.currentPage = (root.currentPage + 1) % root.maxPages;
            }
            pageRevertTimer.restart();
            wheel.accepted = true;
        }
    }

    Connections {
        target: MediaService
        function onHasMediaChanged() {
            if (!MediaService.hasMedia && root.currentPage >= 2) {
                root.currentPage = 0;
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE 0: SYSTEM SECTION (Workspaces & Clock)
    // ════════════════════════════════════════════════════════════════
    Row {
        id: defaultRow
        anchors.centerIn: parent
        spacing: 12

        readonly property bool isHidden: root.isOsdActive || root.isLayoutActive
        opacity: (!isHidden && root.currentPage === 0) ? 1.0 : 0.0
        scale: opacity > 0.5 ? 1.0 : 0.92
        visible: opacity > 0.01

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: (defaultRow.isHidden || root.currentPage !== 0) ? 0 : 90 }
                NumberAnimation { duration: 210; easing.type: Easing.Linear }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: (defaultRow.isHidden || root.currentPage !== 0) ? 0 : 90 }
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
        }

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

                Text {
                    id: h1Text
                    text: root.hourDigit1
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.hourDigit2
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.rawSurface
                    style: Text.Outline
                    styleColor: Theme.rawSurface
                    x: h1Text.implicitWidth - root.overlap
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    id: h2Text
                    text: root.hourDigit2
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.primary
                    x: h1Text.implicitWidth - root.overlap
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: ":"
                font.pixelSize: root.fontSize
                font.family: root.displayFont
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                id: minutePair
                implicitWidth: m1Text.implicitWidth + m2Text.implicitWidth - root.overlap
                implicitHeight: root.fontSize + 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: m1Text
                    text: root.minuteDigit1
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.minuteDigit2
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.rawSurface
                    style: Text.Outline
                    styleColor: Theme.rawSurface
                    x: m1Text.implicitWidth - root.overlap
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    id: m2Text
                    text: root.minuteDigit2
                    font.pixelSize: root.fontSize
                    font.family: root.displayFont
                    color: Theme.primary
                    x: m1Text.implicitWidth - root.overlap
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Workspaces {
            screen: root.screen
            startTag: 6
            count: 5
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE 1: SYSTEM INFORMATION (CPU Usage • RAM Usage • Battery)
    // ════════════════════════════════════════════════════════════════
    Item {
        id: utilityRow
        anchors.centerIn: parent
        width: defaultRow.implicitWidth
        height: parent.height

        readonly property bool isHidden: root.isOsdActive || root.isLayoutActive
        opacity: (!isHidden && root.currentPage === 1) ? 1.0 : 0.0
        scale: opacity > 0.5 ? 1.0 : 0.92
        visible: opacity > 0.01

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: (utilityRow.isHidden || root.currentPage !== 1) ? 0 : 90 }
                NumberAnimation { duration: 210; easing.type: Easing.Linear }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: (utilityRow.isHidden || root.currentPage !== 1) ? 0 : 90 }
                NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershootExpressive }
            }
        }

        // ── LEFT: CPU Usage ──
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                font.family: matSymbols.name
                font.pixelSize: 13
                text: "\ue30d" // developer_board (CPU)
                color: DeviceStats.cpuPercent > 80 ? Theme.error : Theme.textMuted
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                text: Math.round(DeviceStats.cpuPercent) + "%"
                color: Theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── CENTER: RAM Usage ──
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                font.family: matSymbols.name
                font.pixelSize: 13
                text: "\ue322" // memory (RAM)
                color: DeviceStats.ramPercent > 85 ? Theme.error : Theme.textMuted
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                text: Math.round(DeviceStats.ramPercent) + "%"
                color: Theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── RIGHT: Battery (Click to open Battery Profile Popup) ──
        Item {
            id: batterySection
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: batteryContent.implicitWidth + 8
            height: 22
            scale: batteryMouse.pressed ? 0.92 : (batteryMouse.containsMouse ? 1.06 : 1.0)
            Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Easing.OutCubic } }
            opacity: batteryMouse.containsMouse ? 1.0 : 0.88
            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }

            Row {
                id: batteryContent
                anchors.centerIn: parent
                spacing: 5

                // Custom-drawn battery icon (body + nub + fill)
                Item {
                    width: 20
                    height: 10
                    anchors.verticalCenter: parent.verticalCenter

                    // Battery body
                    Rectangle {
                        id: batteryBody
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 17
                        height: 10
                        radius: 2
                        color: "transparent"

                        // Outline
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.55)
                        }

                        // Fill level
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 2
                            width: Math.max(0, (parent.width - 4) * Math.min(1, (typeof Battery !== "undefined" ? Battery.percentage : 100) / 100))
                            radius: 1
                            color: Theme.textPrimary
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        }
                    }

                    // Battery nub
                    Rectangle {
                        anchors.left: batteryBody.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 4
                        radius: 1
                        color: Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.55)
                    }
                }

                // Percentage text
                Text {
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    text: (typeof Battery !== "undefined" ? Battery.percentage : 100) + "%"
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: batteryMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    BatteryService.toggle(root.screen.name);
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // ════════════════════════════════════════════════════════════════
    // PAGE 2: MEDIA SECTION (Minimalist Material 3 Expressive)
    // ════════════════════════════════════════════════════════════════
    Row {
        id: mediaRow
        anchors.centerIn: parent
        spacing: 8

        readonly property bool isHidden: root.isOsdActive || root.isLayoutActive
        opacity: (!isHidden && root.currentPage === 2) ? 1.0 : 0.0
        scale: opacity > 0.5 ? 1.0 : 0.92
        visible: opacity > 0.01

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: (mediaRow.isHidden || root.currentPage !== 2) ? 0 : 90 }
                NumberAnimation { duration: 210; easing.type: Easing.Linear }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: (mediaRow.isHidden || root.currentPage !== 2) ? 0 : 90 }
                NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershootExpressive }
            }
        }

        // 1. Ukishima-style Animated Audio Wave (Interactive)
        Item {
            id: waveContainer
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            scale: waveMouse.pressed ? 0.88 : (waveMouse.containsMouse ? 1.10 : 1.0)

            Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershootExpressive } }

            // Dynamic 4-bar sound wave
            Row {
                anchors.centerIn: parent
                spacing: 2
                height: 16

                Rectangle {
                    id: bar1
                    width: 2.5
                    height: 16
                    radius: 1.25
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                    antialiasing: true
                    border.width: 0

                    property real barScale: 0.22

                    Behavior on barScale {
                        enabled: !anim1.running
                        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }

                    transform: Scale {
                        origin.x: 1.25
                        origin.y: 8
                        yScale: bar1.barScale
                    }

                    SequentialAnimation {
                        id: anim1
                        running: MediaService.isPlaying && root.currentPage === 2
                        loops: Animation.Infinite
                        NumberAnimation { target: bar1; property: "barScale"; from: 0.22; to: 0.72; duration: 580; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar1; property: "barScale"; from: 0.72; to: 0.35; duration: 480; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar1; property: "barScale"; from: 0.35; to: 0.92; duration: 640; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar1; property: "barScale"; from: 0.92; to: 0.45; duration: 520; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar1; property: "barScale"; from: 0.45; to: 0.22; duration: 600; easing.type: Easing.InOutSine }
                        onRunningChanged: if (!running) bar1.barScale = 0.22
                    }
                }

                Rectangle {
                    id: bar2
                    width: 2.5
                    height: 16
                    radius: 1.25
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                    antialiasing: true
                    border.width: 0

                    property real barScale: 0.25

                    Behavior on barScale {
                        enabled: !anim2.running
                        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }

                    transform: Scale {
                        origin.x: 1.25
                        origin.y: 8
                        yScale: bar2.barScale
                    }

                    SequentialAnimation {
                        id: anim2
                        running: MediaService.isPlaying && root.currentPage === 2
                        loops: Animation.Infinite
                        NumberAnimation { target: bar2; property: "barScale"; from: 0.25; to: 0.92; duration: 680; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar2; property: "barScale"; from: 0.92; to: 0.45; duration: 540; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar2; property: "barScale"; from: 0.45; to: 1.00; duration: 620; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar2; property: "barScale"; from: 1.00; to: 0.38; duration: 500; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar2; property: "barScale"; from: 0.38; to: 0.78; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar2; property: "barScale"; from: 0.78; to: 0.25; duration: 650; easing.type: Easing.InOutSine }
                        onRunningChanged: if (!running) bar2.barScale = 0.25
                    }
                }

                Rectangle {
                    id: bar3
                    width: 2.5
                    height: 16
                    radius: 1.25
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                    antialiasing: true
                    border.width: 0

                    property real barScale: 0.25

                    Behavior on barScale {
                        enabled: !anim3.running
                        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }

                    transform: Scale {
                        origin.x: 1.25
                        origin.y: 8
                        yScale: bar3.barScale
                    }

                    SequentialAnimation {
                        id: anim3
                        running: MediaService.isPlaying && root.currentPage === 2
                        loops: Animation.Infinite
                        NumberAnimation { target: bar3; property: "barScale"; from: 0.25; to: 0.45; duration: 460; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar3; property: "barScale"; from: 0.45; to: 1.00; duration: 650; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar3; property: "barScale"; from: 1.00; to: 0.32; duration: 560; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar3; property: "barScale"; from: 0.32; to: 0.82; duration: 520; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar3; property: "barScale"; from: 0.82; to: 0.52; duration: 580; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar3; property: "barScale"; from: 0.52; to: 0.25; duration: 640; easing.type: Easing.InOutSine }
                        onRunningChanged: if (!running) bar3.barScale = 0.25
                    }
                }

                Rectangle {
                    id: bar4
                    width: 2.5
                    height: 16
                    radius: 1.25
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                    antialiasing: true
                    border.width: 0

                    property real barScale: 0.22

                    Behavior on barScale {
                        enabled: !anim4.running
                        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }

                    transform: Scale {
                        origin.x: 1.25
                        origin.y: 8
                        yScale: bar4.barScale
                    }

                    SequentialAnimation {
                        id: anim4
                        running: MediaService.isPlaying && root.currentPage === 2
                        loops: Animation.Infinite
                        NumberAnimation { target: bar4; property: "barScale"; from: 0.22; to: 0.78; duration: 620; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar4; property: "barScale"; from: 0.78; to: 0.28; duration: 500; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar4; property: "barScale"; from: 0.28; to: 0.65; duration: 580; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar4; property: "barScale"; from: 0.65; to: 0.40; duration: 480; easing.type: Easing.InOutSine }
                        NumberAnimation { target: bar4; property: "barScale"; from: 0.40; to: 0.22; duration: 620; easing.type: Easing.InOutSine }
                        onRunningChanged: if (!running) bar4.barScale = 0.22
                    }
                }
            }

            MouseArea {
                id: waveMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaPopupService.toggle(root.screen.name)
            }
        }

        // 2. Track Title Capsule with smooth marquee + scroll to skip
        Rectangle {
            id: trackCapsule
            height: 22
            width: mediaTextClip.width + 12
            radius: 11
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            scale: trackMouse.pressed ? 0.97 : (trackMouse.containsMouse ? 1.02 : 1.0)

            Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershootExpressive } }

            Item {
                id: mediaTextClip
                anchors.centerIn: parent
                width: Math.max(90, defaultRow.implicitWidth - 100)
                height: 16
                clip: true

                Text {
                    id: mediaTitleText
                    y: (parent.height - height) / 2
                    x: root.needsScroll ? -root.scrollOffset : 0
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Theme.textPrimary
                    text: MediaService.displayText || "No media"
                    opacity: trackMouse.containsMouse ? 1.0 : 0.85
                    Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                }

                Text {
                    visible: root.needsScroll && root.currentPage === 2
                    y: (parent.height - height) / 2
                    x: mediaTitleText.x + mediaTitleText.implicitWidth + 28
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Theme.textPrimary
                    text: MediaService.displayText || ""
                    opacity: trackMouse.containsMouse ? 1.0 : 0.85
                    Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                }

                // Left & right edge fades
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 6
                    visible: root.needsScroll
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.surface }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 6
                    visible: root.needsScroll
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Theme.surface }
                    }
                }
            }

            MouseArea {
                id: trackMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaPopupService.toggle(root.screen.name)
            }
        }

        // 3. Material 3 Expressive Action Pill (Play/Pause + Ghost Next)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            // Play / Pause Primary Action Capsule (Modern M3 Tonal Pill)
            Rectangle {
                id: playPauseCapsule
                width: 28
                height: 22
                radius: 11
                anchors.verticalCenter: parent.verticalCenter
                border.width: 0
                color: MediaService.isPlaying
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                    : Qt.rgba(1, 1, 1, 0.08)
                scale: playMouse.pressed ? 0.90 : (playMouse.containsMouse ? 1.08 : 1.0)

                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershootExpressive } }

                Text {
                    anchors.centerIn: parent
                    font.family: matSymbols.name
                    font.pixelSize: 14
                    text: MediaService.isPlaying ? "\uE034" : "\uE037"
                    color: MediaService.isPlaying ? Theme.primary : Theme.textPrimary
                    opacity: playMouse.containsMouse ? 1.0 : 0.85
                    Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }

                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MediaService.togglePlay()
                }
            }

            // Ghost Next Button (Clean, Modern Companion)
            Rectangle {
                width: 22
                height: 22
                radius: 11
                anchors.verticalCenter: parent.verticalCenter
                border.width: 0
                color: "transparent"
                scale: nextMouse.pressed ? 0.88 : (nextMouse.containsMouse ? 1.08 : 1.0)

                Behavior on scale { NumberAnimation { duration: Theme.animDurationMicro; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershootExpressive } }

                Text {
                    anchors.centerIn: parent
                    font.family: matSymbols.name
                    font.pixelSize: 13
                    text: "\uE044"
                    color: nextMouse.containsMouse ? Theme.textPrimary : Theme.textMuted
                    opacity: nextMouse.containsMouse ? 1.0 : 0.75
                    Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }

                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MediaService.next()
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // 3. OSD VIEW: Volume/Brightness Slider (Highest Priority)
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
                NumberAnimation { 
                    duration: osdRow.isShown ? 210 : 90 
                    easing.type: Easing.Linear 
                }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: osdRow.isShown ? 90 : 0 }
                NumberAnimation { 
                    duration: 300 
                    easing.type: Easing.OutBack 
                    easing.overshoot: Theme.springOvershootExpressive 
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: matSymbols.name
            font.pixelSize: 18
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
            width: 140
            height: 12

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
                color: Theme.surfaceVariant
                opacity: 0.75
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
            width: 34
            horizontalAlignment: Text.AlignRight
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Theme.textPrimary
            text: Math.round(root.animLevel * 100) + "%"
        }
    }

    // ════════════════════════════════════════════════════════════════
    // 4. LAYOUT OSD VIEW: Expressive Material 3 Layout Display
    // ════════════════════════════════════════════════════════════════
    Item {
        id: layoutContainer
        anchors.fill: parent
        visible: opacity > 0.01

        readonly property bool isShown: !root.isOsdActive && root.isLayoutActive
        opacity: isShown ? 1.0 : 0.0
        // Scale 0.92 when hiding to match M3 pattern
        scale: isShown ? 1.0 : 0.92

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: layoutContainer.isShown ? 90 : 0 }
                NumberAnimation { 
                    duration: layoutContainer.isShown ? 210 : 90
                    easing.type: Easing.Linear 
                }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: layoutContainer.isShown ? 90 : 0 }
                NumberAnimation { 
                    duration: 300 
                    easing.type: Easing.OutBack 
                    easing.overshoot: Theme.springOvershootSubtle 
                }
            }
        }

        // Inner content with expressive pop scale when cycling
        Row {
            anchors.centerIn: parent
            scale: root.layoutPopScale
            transformOrigin: Item.Center
            spacing: 8

            // Clean primary icon
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: matSymbols.name
                font.pixelSize: 18
                color: Theme.primary
                text: root.currentLayoutIcon
            }

            // Clean typography for layout name
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                text: root.currentLayoutName
            }

            // Subtle workspace tag
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Theme.textMuted
                text: "•  WS " + root.currentLayoutTag
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: MangoService.cycleLayout()
        }
    }

    // Scroll wheel gesture on notch while layout is active to cycle layout
    WheelHandler {
        target: null
        enabled: root.isLayoutActive
        onWheel: event => {
            MangoService.cycleLayout();
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }
}
