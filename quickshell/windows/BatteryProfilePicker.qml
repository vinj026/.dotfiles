// BatteryProfilePicker.qml — Power profile picker popup
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core as C

    id: root

    visible: C.ShellState.batteryPickerOpen || !closeAnim.stopped
    color: "transparent"
    WlrLayershell.namespace: "quickshell:batterypicker"
    WlrLayershell.layer:     WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    implicitWidth: 280

    anchors.top:    true
    anchors.bottom: false
    anchors.left:   false
    anchors.right:  true

    readonly property bool isMinimalist: C.Style.styleMode === "minimalist"

    margins.right: isMinimalist ? C.Style.sp.md : C.Style.sp.lg
    margins.top: windowMargin

    property real windowMargin: closedMargin

    onVisibleChanged: {
        if (visible) {
            root.windowMargin = closedMargin
            openAnim.start()
            C.Battery.refreshProfile()
            C.Battery.refreshChargeType()
        }
    }

    Connections {
        target: C.ShellState
        function onBatteryPickerOpenChanged() {
            if (!C.ShellState.batteryPickerOpen && root.visible) {
                closeAnim.start()
            }
        }
    }

    Connections {
        target: root.contentItem
        function onActiveFocusChanged() {
            if (!root.contentItem.activeFocus && C.ShellState.batteryPickerOpen) {
                closeAnim.start()
            }
        }
    }

    readonly property real closedMargin: isMinimalist ? (C.Style.barHeight - 20) : (C.Style.barHeight + C.Style.sp.md * 2 - 20)
    readonly property real openMargin:   isMinimalist ? (C.Style.barHeight + C.Style.sp.xs) : (C.Style.barHeight + C.Style.sp.md * 2 + C.Style.sp.sm)

    PropertyAnimation {
        id: openAnim
        target: root
        property: "windowMargin"
        to: root.openMargin
        duration: C.Style.durNormal
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: closeAnim
        PropertyAnimation {
            target: root
            property: "windowMargin"
            to: root.closedMargin
            duration: C.Style.durFast
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: C.ShellState.batteryPickerOpen = false
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: C.Colors.alpha(C.Colors.base, C.Style.opPanel)
        opacity: 1.0
        border.width: 0
        radius: C.Style.r.lg

        readonly property color barColor: {
            if (C.Battery.isCharging) return C.Colors.green
            if (C.Battery.percentage < 20) return C.Colors.red
            if (C.Battery.percentage < 40) return C.Colors.yellow
            return C.Colors.accent
        }

        TapHandler {}

        Column {
            id: cardContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: C.Style.sp.lg
            spacing: C.Style.sp.md

            // ── Battery Details Row ──
            Item {
                width: parent.width
                height: 18

                Row {
                    anchors.left: parent.left
                    spacing: C.Style.sp.xs

                    Text {
                        text: C.Battery.isCharging ? "battery_charging_full" : "battery_full"
                        font.family: C.Style.fontIcon
                        font.pixelSize: C.Style.fs.md
                        font.variableAxes: ({ "FILL": 1 })
                        color: C.Colors.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Battery: " + C.Battery.percentage + "%"
                        font.family: C.Style.fontMono
                        font.pixelSize: C.Style.fs.sm
                        font.weight: C.Style.fw.bold
                        color: C.Colors.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        let rate = C.Battery.device ? C.Battery.device.changeRate : 0
                        return Math.round(rate) + "w"
                    }
                    font.family: C.Style.fontMono
                    font.pixelSize: C.Style.fs.sm
                    color: C.Colors.subtext1
                }
            }

            // ── Segmented Battery Bar (styled like brightness slider) ──
            Item {
                width: parent.width
                height: 14

                Row {
                    id: batterySegRow
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    spacing: 2

                    Repeater {
                        model: 20
                        delegate: Rectangle {
                            required property int index
                            width: (batterySegRow.width - 19 * 2) / 20
                            height: 10
                            color: index < Math.round(C.Battery.percentage / 5)
                                ? card.barColor
                                : C.Colors.muted
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                        }
                    }
                }

                // Thumb indicator at current percentage
                Rectangle {
                    x: Math.min(
                        parent.width - width,
                        Math.max(0, (C.Battery.percentage / 100) * parent.width - width / 2)
                    )
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 14
                    color: C.Colors.text
                }
            }

            // ── Power Mode Subtitle ──
            Text {
                text: "Power Mode"
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.sm
                font.weight: C.Style.fw.bold
                color: C.Colors.accent
            }

            // ── Horizontal Profiles Row ──
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: C.Style.sp.xl

                Repeater {
                    model: [
                        { name: "power-saver", label: "Quiet" },
                        { name: "balanced",    label: "Balanced" },
                        { name: "performance", label: "Performance" }
                    ]

                    delegate: Item {
                        required property var modelData
                        width: optionText.implicitWidth + C.Style.sp.sm
                        height: 24

                        readonly property bool isActive: C.Battery.activeProfile === modelData.name

                        Text {
                            id: optionText
                            anchors.centerIn: parent
                            text: (isActive ? "* " : "  ") + modelData.label
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.sm
                            font.weight: isActive ? C.Style.fw.bold : C.Style.fw.normal
                            color: isActive ? C.Colors.accent : (optionMouse.containsMouse ? C.Colors.text : C.Colors.subtext1)

                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                        }

                        MouseArea {
                            id: optionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                C.Battery.setProfile(modelData.name)
                                closeAnim.start()
                            }
                        }
                    }
                }
            }

            // ── Charge Mode Subtitle ──
            Text {
                text: "Charge Mode"
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.sm
                font.weight: C.Style.fw.bold
                color: C.Colors.accent
            }

            // ── Horizontal Charge Modes Row ──
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: C.Style.sp.xl

                Repeater {
                    model: [
                        { name: "Long_Life", label: "Conservation" },
                        { name: "Fast",      label: "Rapid Charge" }
                    ]

                    delegate: Item {
                        id: chargeOptItem
                        required property var modelData
                        width: optionText.implicitWidth + C.Style.sp.sm
                        height: 24

                        readonly property bool isActive: C.Battery.activeChargeType === modelData.name

                        Text {
                            id: optionText
                            anchors.centerIn: parent
                            text: (chargeOptItem.isActive ? "* " : "  ") + modelData.label
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.sm
                            font.weight: chargeOptItem.isActive ? C.Style.fw.bold : C.Style.fw.normal
                            color: chargeOptItem.isActive ? C.Colors.accent : (optionMouse.containsMouse ? C.Colors.text : C.Colors.subtext1)

                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                        }

                        MouseArea {
                            id: optionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (chargeOptItem.isActive) {
                                    C.Battery.setChargeType("Standard")
                                } else {
                                    C.Battery.setChargeType(modelData.name)
                                }
                                closeAnim.start()
                            }
                        }
                    }
                }
            }
        }
    }
