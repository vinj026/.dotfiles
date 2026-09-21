// ControlCenter.qml — Control center, bottom-left corner
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core as C

PanelWindow {
    id: root

    property ShellScreen modelData
    readonly property bool isOpen: C.ShellState.isControlCenterOpen(root.modelData?.name ?? "")
    property bool powerMenuOpen: false

    property bool statsRetained: false
    property bool systemInfoRetained: false

    // Pomodoro properties moved to ShellState singleton

    // Calendar state
    property int currentYear: new Date().getFullYear()
    property int currentMonth: new Date().getMonth()
    property int today: new Date().getDate()
    property var days: {
        let firstDay = new Date(currentYear, currentMonth, 1).getDay();
        let numDays = new Date(currentYear, currentMonth + 1, 0).getDate();
        let prevNumDays = new Date(currentYear, currentMonth, 0).getDate();
        
        let arr = [];
        for (let i = firstDay - 1; i >= 0; i--) {
            arr.push({ day: prevNumDays - i, current: false, today: false });
        }
        let realToday = new Date();
        let isThisMonth = (realToday.getFullYear() === currentYear && realToday.getMonth() === currentMonth);
        for (let i = 1; i <= numDays; i++) {
            arr.push({ day: i, current: true, today: (isThisMonth && i === today) });
        }
        let remaining = 42 - arr.length;
        for (let i = 1; i <= remaining; i++) {
            arr.push({ day: i, current: false, today: false });
        }
        return arr;
    }

    function syncRuntimeSubscriptions() {
        const shouldRetain = root.isOpen
        if (shouldRetain && !root.statsRetained) { C.DeviceStats.retain(); root.statsRetained = true }
        else if (!shouldRetain && root.statsRetained) { C.DeviceStats.release(); root.statsRetained = false }
        if (shouldRetain && !root.systemInfoRetained) { C.SystemInfo.retain(); root.systemInfoRetained = true }
        else if (!shouldRetain && root.systemInfoRetained) { C.SystemInfo.release(); root.systemInfoRetained = false }
    }

    onIsOpenChanged: {
        syncRuntimeSubscriptions()
        if (!isOpen) {
            powerMenuOpen = false
        } else {
            currentYear = new Date().getFullYear()
            currentMonth = new Date().getMonth()
            today = new Date().getDate()
        }
    }
    Component.onCompleted: syncRuntimeSubscriptions()
    Component.onDestruction: {
        if (root.statsRetained) C.DeviceStats.release()
        if (root.systemInfoRetained) C.SystemInfo.release()
    }
    screen: modelData
    visible: root.isOpen || scaleXAnim.running || opacityAnim.running
    color: "transparent"
    WlrLayershell.namespace: "quickshell:controlcenter"
    WlrLayershell.layer:     WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    implicitWidth: 280
    implicitHeight: panelContent.implicitHeight

    anchors.top:    true
    anchors.bottom: false
    anchors.left:   true
    anchors.right:  false

    readonly property bool isMinimalist: C.Style.styleMode === "minimalist"

    margins.top: isMinimalist ? (C.Style.barHeight + C.Style.sp.xs) : (C.Style.barHeight + C.Style.sp.md * 2 + C.Style.sp.sm)
    margins.left: isMinimalist ? C.Style.sp.md : C.Style.sp.lg

    Connections {
        target: root.contentItem
        function onActiveFocusChanged() {
            if (!root.contentItem.activeFocus && root.isOpen) {
                C.ShellState.closeControlCenter()
            }
        }
    }

    Item {
        id: clipWrapper
        anchors.fill: parent
        clip: true

        Rectangle {
            id: panel
            anchors.fill: parent
            color: C.Colors.alpha(C.Colors.base, C.Style.opPanel)
            radius: C.Style.r.lg

        // No border overlay
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 0
            visible: false
            radius: C.Style.r.lg
            z: 999
        }

        Keys.onEscapePressed: C.ShellState.closeControlCenter()

        // Consume taps so they don't dismiss
        TapHandler {}

        // macOS-style squeeze out of the Start Button
        transform: Scale {
            id: scaleTransform
            origin.x: (C.Style.sp.xs + C.Style.barHeight / 2) - C.Style.sp.lg
            origin.y: (C.Style.barHeight / 2) - (C.Style.barHeight + C.Style.sp.md * 2 + C.Style.sp.sm)
            xScale: root.isOpen ? 1.0 : 0.0
            yScale: root.isOpen ? 1.0 : 0.0
            Behavior on xScale {
                NumberAnimation {
                    id: scaleXAnim
                    duration: root.isOpen ? C.Style.durNormal : C.Style.durFast
                    easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
                }
            }
            Behavior on yScale {
                NumberAnimation {
                    id: scaleYAnim
                    duration: root.isOpen ? C.Style.durNormal : C.Style.durFast
                    easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
                }
            }
        }
        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { id: opacityAnim; duration: C.Style.durFast } }

        Column {
            id: panelContent
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: C.Style.sp.lg
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: C.Style.sp.lg

                    Rectangle {
                        width: 44; height: 44
                        color: C.Colors.overlay0
                        anchors.verticalCenter: parent.verticalCenter
                        radius: width / 2

                        Text {
                            anchors.centerIn: parent
                            text: (C.SystemInfo.username ?? "U").charAt(0).toUpperCase()
                            font.family: C.Style.fontMono
                            font.pixelSize: 22
                            font.weight: C.Style.fw.bold
                            color: C.Colors.accent
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: C.SystemInfo.username ?? "user"
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.xl2
                            font.weight: C.Style.fw.bold
                            color: C.Colors.text
                        }
                        Text {
                            text: "uptime: " + (C.SystemInfo.uptimeText ?? "--")
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.md
                            color: C.Colors.subtext1
                        }
                    }
                }


                // Power button
                Item {
                    id: powerArea
                    anchors.right: parent.right
                    anchors.rightMargin: C.Style.sp.lg
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28; height: 28

                    Text {
                        anchors.centerIn: parent
                        text: "power_settings_new"
                        font.family: C.Style.fontIcon
                        font.variableAxes: ({ "FILL": 1 })
                        font.pixelSize: C.Style.icon.lg
                        color: pwHover.containsMouse ? C.Colors.red : C.Colors.subtext1
                        Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                    }
                    MouseArea {
                        id: pwHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.powerMenuOpen = !root.powerMenuOpen
                    }

                    // Power dropdown — below button
                    Column {
                        visible: root.powerMenuOpen
                        anchors.top: parent.bottom
                        anchors.right: parent.right
                        anchors.topMargin: C.Style.sp.xs
                        z: 1000

                        Repeater {
                            model: [
                                { label: "shutdown", icon: "power_settings_new", cmd: ["systemctl", "poweroff"] },
                                { label: "restart",  icon: "restart_alt",        cmd: ["systemctl", "reboot"]   },
                                { label: "logout",   icon: "logout",             cmd: ["mmsg", "dispatch", "quit"] }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 110; height: 28
                                color: pmi.containsMouse ? C.Colors.overlay0 : C.Colors.surface
                                radius: C.Style.r.xs

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: C.Style.sp.sm
                                    spacing: C.Style.sp.xs

                                    Text {
                                        text: modelData.icon
                                        font.family: C.Style.fontIcon
                                        font.variableAxes: ({ "FILL": 1 })
                                        font.pixelSize: C.Style.icon.sm
                                        color: C.Colors.text
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.label
                                        font.family: C.Style.fontMono
                                        font.pixelSize: C.Style.fs.sm
                                        color: C.Colors.text
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                MouseArea {
                                    id: pmi
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(modelData.cmd)
                                        root.powerMenuOpen = false
                                        C.ShellState.closeControlCenter()
                                    }
                                }
                            }
                        }
                    }
                }
            }



            // ── Volume ────────────────────────────────────────
            SliderRow {
                width: parent.width
                label: "Volume"
                icon: C.Audio.volIcon
                value: C.Audio.volLevel
                maxValue: 100
                accent: C.Audio.volMuted ? C.Colors.red : C.Colors.accent
                iconSize: C.Audio.volMuted ? C.Style.icon.sm : C.Style.icon.xl
                onSeek: (v) => C.Audio.setVolume(v)
                iconClickable: true
                onIconClicked: C.Audio.toggleMute()
            }

            // ── Mic Volume ────────────────────────────────────
            SliderRow {
                width: parent.width
                label: "Mic Volume"
                icon: C.Audio.micIcon
                value: C.Audio.micLevel
                maxValue: 100
                accent: C.Audio.micMuted ? C.Colors.red : C.Colors.accent
                iconSize: C.Audio.micMuted ? C.Style.icon.sm : C.Style.icon.xl
                onSeek: (v) => C.Audio.setMicVolume(v)
                iconClickable: true
                onIconClicked: C.Audio.toggleMicMute()
            }

            // ── Brightness ────────────────────────────────────
            SliderRow {
                width: parent.width
                label: "Brightness"
                icon: C.Brightness.icon
                value: C.Brightness.level
                maxValue: 100
                accent: C.Colors.accent
                onSeek: (v) => C.Brightness.setBrightness(v)
            }



            // ── Quick toggles ─────────────────────────────────
            Row {
                width: parent.width - C.Style.sp.lg * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 52

                Repeater {
                    model: [
                        { label: "Wi-Fi",     icon: C.Network.connected ? "network_wifi" : "wifi_off",      active: C.Network.wifiEnabled, fn: () => C.Network.toggleWifi()    },
                        { label: "Bluetooth", icon: C.Bluetooth.icon,    active: C.Bluetooth.isPowered, fn: () => C.Bluetooth.togglePower() },
                        { label: "Mic",       icon: C.Audio.micIcon,     active: !C.Audio.micMuted,     fn: () => C.Audio.toggleMicMute()   },
                        { label: "Wallpaper", icon: "wallpaper",         active: C.ShellState.wallpaperPickerOpen, fn: () => { C.ShellState.toggleWallpaperPicker(); C.ShellState.closeControlCenter() } }
                    ]

                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: parent.width / 4
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: C.Style.sp.xs
                            color: modelData.active
                                ? C.Colors.alpha(C.Colors.accent, 0.12)
                                : (tma.containsMouse ? C.Colors.overlay0 : "transparent")
                            radius: C.Style.r.sm
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: C.Style.sp.px2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                font.family: C.Style.fontIcon
                                font.variableAxes: ({ "FILL": 1 })
                                font.pixelSize: C.Style.icon.md
                                color: modelData.active ? C.Colors.accent : C.Colors.subtext1
                                Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.family: C.Style.fontMono
                                font.pixelSize: C.Style.fs.xs
                                color: modelData.active ? C.Colors.accent : C.Colors.subtext1
                                Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                            }
                        }



                        MouseArea {
                            id: tma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.fn()
                        }
                    }
                }
            }

            // ── Screen Actions Toggles ─────────────────────────────
            Row {
                width: parent.width - C.Style.sp.lg * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 52

                Repeater {
                    model: [
                        { label: "SS Area", icon: "crop", active: false, fn: () => { C.ShellState.closeControlCenter(); C.ShellState.runDelayedAction("ss-region") } },
                        { label: "SS Copy", icon: "content_paste", active: false, fn: () => { C.ShellState.closeControlCenter(); C.ShellState.runDelayedAction("ss-region-clip") } },
                        { label: "Rec Full", icon: "videocam", active: C.ShellState.isRecording, fn: () => { C.ShellState.closeControlCenter(); C.ShellState.runDelayedAction("start-full") } },
                        { label: "Rec Area", icon: "video_camera_back", active: C.ShellState.isRecording, fn: () => { C.ShellState.closeControlCenter(); C.ShellState.runDelayedAction("start-region") } }
                    ]

                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: parent.width / 4
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: C.Style.sp.xs
                            color: modelData.active
                                ? C.Colors.alpha(C.Colors.accent, 0.12)
                                : (tma2.containsMouse ? C.Colors.overlay0 : "transparent")
                            radius: C.Style.r.sm
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: C.Style.sp.px2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                font.family: C.Style.fontIcon
                                font.variableAxes: ({ "FILL": 1 })
                                font.pixelSize: C.Style.icon.md
                                color: modelData.active ? C.Colors.accent : C.Colors.subtext1
                                Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.family: C.Style.fontMono
                                font.pixelSize: C.Style.fs.xs
                                color: modelData.active ? C.Colors.accent : C.Colors.subtext1
                                Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                            }
                        }

                        MouseArea {
                            id: tma2
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.fn()
                        }
                    }
                }
            }

            // ── Theme Carousel ──────────────────────────────────────
            Item {
                width: parent.width - C.Style.sp.lg * 2
                height: 40
                anchors.horizontalCenter: parent.horizontalCenter

                property var themes: [
                    { name: "Wallpaper", id: "wallpaper" },
                    { name: "Monochrome", id: "monochrome" },
                    { name: "Everblush", id: "everblush" },
                    { name: "Gruvbox", id: "gruvbox" },
                    { name: "Everforest", id: "everforest" },
                    { name: "Monokai", id: "monokai" },
                    { name: "Catppuccin", id: "catppuccin" }
                ]
                property int currentIndex: 0

                Row {
                    anchors.fill: parent
                    spacing: 4

                    // Left Arrow
                    Item {
                        width: 24
                        height: parent.height
                        Text {
                            anchors.centerIn: parent
                            text: "chevron_left"
                            font.family: C.Style.fontIcon
                            font.pixelSize: C.Style.icon.md
                            color: leftArrowHover.containsMouse ? C.Colors.accent : C.Colors.subtext1
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                        }
                        MouseArea {
                            id: leftArrowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (parent.parent.parent.currentIndex > 0) {
                                    parent.parent.parent.currentIndex--
                                } else {
                                    parent.parent.parent.currentIndex = parent.parent.parent.themes.length - 1
                                }
                            }
                        }
                    }

                    // Theme Pills ListView
                    ListView {
                        id: themeListView
                        width: parent.width - 48 - 8 // 24*2 for arrows + spacing
                        height: parent.height
                        orientation: ListView.Horizontal
                        interactive: true
                        clip: true
                        model: parent.parent.themes
                        spacing: C.Style.sp.sm
                        
                        currentIndex: parent.parent.currentIndex
                        onCurrentIndexChanged: parent.parent.currentIndex = currentIndex

                        Connections {
                            target: themeListView.parent.parent
                            function onCurrentIndexChanged() {
                                themeListView.positionViewAtIndex(themeListView.parent.parent.currentIndex, ListView.Contain)
                            }
                        }

                        delegate: Rectangle {
                            width: 90
                            height: themeListView.height
                            radius: C.Style.r.md
                            color: (themeListView.currentIndex === index) ? C.Colors.alpha(C.Colors.accent, 0.2) : (themeMouseArea.containsMouse ? C.Colors.overlay0 : "transparent")
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                font.family: C.Style.fontMono
                                font.pixelSize: C.Style.fs.xs
                                color: (themeListView.currentIndex === index) ? C.Colors.accent : C.Colors.text
                            }
                            
                            MouseArea {
                                id: themeMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    themeListView.currentIndex = index
                                    Quickshell.execDetached(["/home/vin/.config/quickshell/scripts/apply_theme.sh", modelData.id])
                                }
                            }
                        }
                    }

                    // Right Arrow
                    Item {
                        width: 24
                        height: parent.height
                        Text {
                            anchors.centerIn: parent
                            text: "chevron_right"
                            font.family: C.Style.fontIcon
                            font.pixelSize: C.Style.icon.md
                            color: rightArrowHover.containsMouse ? C.Colors.accent : C.Colors.subtext1
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                        }
                        MouseArea {
                            id: rightArrowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (parent.parent.parent.currentIndex < parent.parent.parent.themes.length - 1) {
                                    parent.parent.parent.currentIndex++
                                } else {
                                    parent.parent.parent.currentIndex = 0
                                }
                            }
                        }
                    }
                }
            }

            // ── Session Actions (Logout / Reboot / Shutdown) ──────
            Item { width: parent.width; height: C.Style.sp.sm }

            Row {
                width: parent.width - C.Style.sp.lg * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 30
                spacing: C.Style.sp.sm

                Repeater {
                    model: [
                        { label: "Logout",   icon: "logout",             color: C.Colors.accent,  cmd: ["mmsg", "dispatch", "quit"]         },
                        { label: "Reboot",   icon: "restart_alt",        color: C.Colors.yellow,  cmd: ["systemctl", "reboot"]              },
                        { label: "Shutdown", icon: "power_settings_new", color: C.Colors.red,     cmd: ["systemctl", "poweroff"]            }
                    ]
                    delegate: Item {
                        required property var modelData
                        width: (parent.width - C.Style.sp.sm * 2) / 3
                        height: parent.height

                        Rectangle {
                            id: sessionBtnBg
                            anchors.fill: parent
                            radius: C.Style.r.sm
                            color: sessionBtnMouse.containsMouse
                                ? C.Colors.alpha(modelData.color, 0.18)
                                : C.Colors.alpha(modelData.color, 0.07)
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: C.Style.sp.xs

                            Text {
                                text: modelData.icon
                                font.family: C.Style.fontIcon
                                font.variableAxes: ({ "FILL": 1 })
                                font.pixelSize: C.Style.icon.sm
                                color: sessionBtnMouse.containsMouse ? modelData.color : C.Colors.alpha(modelData.color, 0.75)
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                            }
                            Text {
                                text: modelData.label
                                font.family: C.Style.fontMono
                                font.pixelSize: C.Style.fs.xs
                                color: sessionBtnMouse.containsMouse ? modelData.color : C.Colors.alpha(modelData.color, 0.75)
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                            }
                        }

                        MouseArea {
                            id: sessionBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                C.ShellState.closeControlCenter()
                                Quickshell.execDetached(modelData.cmd)
                            }
                        }
                    }
                }
            }

            Item { width: parent.width; height: C.Style.sp.sm }

            // Line separator with low contrast
            Rectangle {
                width: parent.width - C.Style.sp.lg * 2
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: C.Colors.alpha(C.Colors.border, 0.35)
            }

            // Spacer
            Item { width: parent.width; height: C.Style.sp.sm }

            // ── Pomodoro Widget (Modern Style) ───────────────────
            Item {
                width: parent.width - C.Style.sp.lg * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 24

                // Left: Icon + Mode + Timer
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: C.Style.sp.md

                    // Timer Icon
                    Text {
                        text: "timer"
                        font.family: C.Style.fontIcon
                        font.variableAxes: ({ "FILL": 1 })
                        font.pixelSize: C.Style.icon.md
                        color: C.Colors.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Mode Text (Focus / Break)
                    Text {
                        text: C.ShellState.pomoMode === "Focus" ? "FOCUS" : "BREAK"
                        font.family: C.Style.fontSans
                        font.pixelSize: C.Style.fs.md
                        font.weight: C.Style.fw.bold
                        color: C.ShellState.pomoMode === "Focus" ? C.Colors.accent : C.Colors.peach
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Time countdown
                    Text {
                        text: (C.ShellState.pomoMinutes < 10 ? "0" : "") + C.ShellState.pomoMinutes + ":" + (C.ShellState.pomoSeconds < 10 ? "0" : "") + C.ShellState.pomoSeconds
                        font.family: C.Style.fontMono
                        font.pixelSize: C.Style.fs.md
                        font.weight: C.Style.fw.bold
                        color: C.Colors.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Right: Play/Pause & Reset buttons
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: C.Style.sp.lg

                    // Play/Pause button
                    Text {
                        text: C.ShellState.pomoRunning ? "pause" : "play_arrow"
                        font.family: C.Style.fontIcon
                        font.variableAxes: ({ "FILL": 1 })
                        font.pixelSize: C.Style.icon.lg
                        color: playCCMouse.containsMouse ? C.Colors.accent : C.Colors.subtext1
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: playCCMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                C.ShellState.pomoRunning = !C.ShellState.pomoRunning
                                if (C.ShellState.pomoRunning) {
                                    C.ShellState.pomoActive = true
                                }
                            }
                        }

                        Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                    }

                    // Reset button
                    Text {
                        text: "replay"
                        font.family: C.Style.fontIcon
                        font.variableAxes: ({ "FILL": 1 })
                        font.pixelSize: C.Style.icon.lg
                        color: resetCCMouse.containsMouse ? C.Colors.red : C.Colors.subtext1
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: resetCCMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                C.ShellState.pomoRunning = false
                                C.ShellState.pomoActive = false
                                C.ShellState.pomoMode = "Focus"
                                C.ShellState.pomoMinutes = 25
                                C.ShellState.pomoSeconds = 0
                            }
                        }

                        Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                    }
                }
            }

            // Spacer
            Item { width: parent.width; height: C.Style.sp.sm }

            // Line separator with low contrast
            Rectangle {
                width: parent.width - C.Style.sp.lg * 2
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: C.Colors.alpha(C.Colors.border, 0.35)
            }

            // Spacer
            Item { width: parent.width; height: C.Style.sp.sm }

            // ── Calendar Widget ───────────────────────────────
            Column {
                width: parent.width
                spacing: C.Style.sp.sm
                bottomPadding: C.Style.sp.md

                // Month Year Header
                Item {
                    width: parent.width - C.Style.sp.lg * 2
                    height: 24
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.left: parent.left
                        text: {
                            const monthNames = ["January", "February", "March", "April", "May", "June",
                                                "July", "August", "September", "October", "November", "December"];
                            return monthNames[currentMonth] + " " + currentYear
                        }
                        font.family: C.Style.fontSans
                        font.pixelSize: C.Style.fs.sm
                        font.weight: C.Style.fw.bold
                        color: C.Colors.accent
                    }

                    // Navigation buttons
                    Row {
                        anchors.right: parent.right
                        spacing: C.Style.sp.md

                        Text {
                            text: "chevron_left"
                            font.family: C.Style.fontIcon
                            font.variableAxes: ({ "FILL": 1 })
                            font.pixelSize: C.Style.icon.xs
                            color: prevHover.containsMouse ? C.Colors.accent : C.Colors.subtext1
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                            MouseArea {
                                id: prevHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (currentMonth === 0) {
                                        currentMonth = 11;
                                        currentYear--;
                                    } else {
                                        currentMonth--;
                                    }
                                }
                            }
                        }

                        Text {
                            text: "chevron_right"
                            font.variableAxes: ({ "FILL": 1 })
                            font.pixelSize: C.Style.icon.xs
                            color: nextHover.containsMouse ? C.Colors.accent : C.Colors.subtext1
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                            MouseArea {
                                id: nextHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (currentMonth === 11) {
                                        currentMonth = 0;
                                        currentYear++;
                                    } else {
                                        currentMonth--;
                                    }
                                }
                            }
                        }
                    }
                }

                // Days of week header
                Grid {
                    columns: 7
                    width: parent.width - C.Style.sp.lg * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Repeater {
                        model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                        delegate: Item {
                            width: parent.width / 7
                            height: 16
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: C.Style.fontMono
                                font.pixelSize: C.Style.fs.xs
                                font.weight: C.Style.fw.bold
                                color: C.Colors.subtext0
                            }
                        }
                    }
                }

                // Days grid
                Grid {
                    columns: 7
                    rows: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0

                    Repeater {
                        model: days
                        delegate: Rectangle {
                            width: parent.width / 7
                            height: 24
                            color: model.modelData.today ? C.Colors.accent : "transparent"
                            radius: C.Style.r.xs
                            Text {
                                anchors.centerIn: parent
                                text: model.modelData.day.toString()
                                font.family: C.Style.fontMono
                                font.pixelSize: C.Style.fs.xs
                                font.weight: model.modelData.today ? C.Style.fw.bold : C.Style.fw.normal
                                color: {
                                    if (model.modelData.today) return C.Colors.mantle
                                    if (model.modelData.current) return C.Colors.text
                                    return C.Colors.muted
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Inline slider component
    component SliderRow: Item {
        id: sliderRow
        height: 36

        property string label: ""
        property string icon: ""
        property int value: 0
        property int maxValue: 100
        property color accent: C.Colors.accent
        property bool iconClickable: false
        property int iconSize: C.Style.icon.sm
        signal seek(int v)
        signal iconClicked()

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: C.Style.sp.lg
            anchors.rightMargin: C.Style.sp.lg
            spacing: C.Style.sp.sm

            Text {
                text: sliderRow.icon
                font.family: C.Style.fontIcon
                font.variableAxes: ({ "FILL": 1 })
                font.pixelSize: sliderRow.iconSize
                color: sliderRow.accent
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -C.Style.sp.xs
                    cursorShape: sliderRow.iconClickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: sliderRow.iconClickable
                    onClicked: sliderRow.iconClicked()
                }
            }

            Text {
                text: sliderRow.label
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.xs
                color: C.Colors.subtext1
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 84
            }

            // Segmented bar (clickable/draggable) with thumb indicator
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                Layout.alignment: Qt.AlignVCenter

                Row {
                    id: segRow
                    anchors.fill: parent
                    spacing: 2

                    Repeater {
                        model: 20
                        delegate: Rectangle {
                            required property int index
                            width: (segRow.width - 19 * 2) / 20
                            height: parent.height
                            color: index < Math.round(sliderRow.value / (sliderRow.maxValue / 20))
                                ? sliderRow.accent
                                : C.Colors.muted
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                        }
                    }
                }

                // Thumb indicator
                Rectangle {
                    x: Math.min(
                        parent.width - width,
                        (sliderRow.value / sliderRow.maxValue) * parent.width - width / 2
                    )
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 14
                    color: C.Colors.text
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => sliderRow.seek(Math.max(0, Math.round(mouse.x / width * sliderRow.maxValue)))
                    onPositionChanged: (mouse) => {
                        if (pressed)
                            sliderRow.seek(Math.max(0, Math.min(sliderRow.maxValue, Math.round(mouse.x / width * sliderRow.maxValue))))
                    }
                    onWheel: (wheel) => {
                        let step = sliderRow.maxValue / 20 // 5% steps
                        let delta = wheel.angleDelta.y > 0 ? step : -step
                        sliderRow.seek(Math.max(0, Math.min(sliderRow.maxValue, sliderRow.value + delta)))
                    }
                }
            }

            Text {
                text: sliderRow.value + "%"
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.xs
                color: C.Colors.subtext1
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
