// WifiPicker.qml — WiFi network picker popup
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core as C

PanelWindow {
    id: root
    visible: C.ShellState.wifiPickerOpen || !closeAnim.stopped
    color: "transparent"
    WlrLayershell.namespace: "quickshell:wifipicker"
    WlrLayershell.layer:     WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    implicitWidth: 260

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
            C.Network.refreshNetworks()
        }
    }

    Connections {
        target: C.ShellState
        function onWifiPickerOpenChanged() {
            if (!C.ShellState.wifiPickerOpen && root.visible) {
                closeAnim.start()
            }
        }
    }

    Connections {
        target: root.contentItem
        function onActiveFocusChanged() {
            if (!root.contentItem.activeFocus && C.ShellState.wifiPickerOpen) {
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
            script: C.ShellState.wifiPickerOpen = false
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: C.Colors.alpha(C.Colors.surface, C.Style.opPanel)
        opacity: 1.0
        border.width: 0
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

        TapHandler {}

        Column {
            id: cardContent
            width: parent.width

            // ── Header: connection status ─────────────────────
            Column {
                width: parent.width
                padding: C.Style.sp.lg
                spacing: C.Style.sp.px2

                Row {
                    width: parent.width - C.Style.sp.lg * 2
                    spacing: C.Style.sp.sm

                    Column {
                        spacing: C.Style.sp.px2
                        width: parent.width - restartBtn.implicitWidth - wifiToggle.implicitWidth - C.Style.sp.sm * 2

                        Text {
                            text: C.Network.connected ? "Wi-Fi Connected" : "Wi-Fi"
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.lg
                            font.weight: C.Style.fw.bold
                            color: C.Colors.text
                        }

                        Text {
                            visible: C.Network.connected
                            text: "SSID: " + C.Network.ssid
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.sm
                            color: C.Colors.subtext1
                        }

                        Text {
                            visible: C.Network.connected
                            text: "Signal: " + C.Network.signal + "%"
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.sm
                            color: C.Colors.subtext1
                        }
                    }

                    // Wi-Fi toggle switch (kotak) + Restart di bawahnya
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: C.Style.sp.px2

                        // Toggle switch kotak
                        Item {
                            id: wifiToggle
                            width: 32
                            height: 16

                            Rectangle {
                                anchors.fill: parent
                                color: C.Network.wifiEnabled ? C.Colors.accent : C.Colors.muted
                                Behavior on color { ColorAnimation { duration: C.Style.durFast } }

                                Rectangle {
                                    width: 12
                                    height: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: C.Network.wifiEnabled ? parent.width - width - 2 : 2
                                    color: C.Colors.base
                                    Behavior on x {
                                        NumberAnimation { duration: C.Style.durFast; easing.type: Easing.OutCubic }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: C.Network.toggleWifi()
                            }
                        }

                        // Restart label di bawah toggle
                        Text {
                            id: restartBtn
                            text: "Restart"
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.xs
                            color: restartMouse.containsMouse ? C.Colors.text : C.Colors.subtext1
                            horizontalAlignment: Text.AlignHCenter
                            width: wifiToggle.width
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }

                            MouseArea {
                                id: restartMouse
                                anchors.fill: parent
                                anchors.margins: -C.Style.sp.px2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    C.Network.setWifiEnabled(false)
                                    restartTimer.start()
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: C.Colors.border }

            // ── Networks section label ────────────────────────
            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: C.Style.sp.lg
                    anchors.verticalCenter: parent.verticalCenter
                    text: "WiFi Networks"
                    font.family: C.Style.fontMono
                    font.pixelSize: C.Style.fs.sm
                    font.weight: C.Style.fw.bold
                    color: C.Colors.text
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: C.Style.sp.lg
                    anchors.verticalCenter: parent.verticalCenter
                    text: C.Network.scanning ? "sync" : "refresh"
                    font.family: C.Style.fontIcon
                    font.variableAxes: ({ "FILL": 1 })
                    font.pixelSize: C.Style.icon.sm
                    color: refreshMouse.containsMouse ? C.Colors.text : C.Colors.subtext1

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        anchors.margins: -C.Style.sp.xs
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: C.Network.refreshNetworks()
                    }
                }
            }

            // ── Network list ──────────────────────────────────
            Repeater {
                model: C.Network.networks

                delegate: Item {
                    id: netDelegate
                    required property var modelData
                    required property int index
                    width: card.width
                    height: showDisconnect ? 56 : 30

                    readonly property bool isActive: modelData.active
                    readonly property int  netSignal: modelData.signal
                    readonly property string netSsid: modelData.ssid
                    readonly property bool netSecure: modelData.secure
                    property bool showDisconnect: false

                    Behavior on height {
                        NumberAnimation { duration: C.Style.durFast; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: netMouse.containsMouse ? C.Colors.overlay0 : "transparent"
                        Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                    }

                    // Active indicator (*)
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: C.Style.sp.lg
                        anchors.verticalCenter: parent.verticalCenter
                        text: netDelegate.isActive ? "●" : " "
                        font.family: C.Style.fontMono
                        font.pixelSize: C.Style.fs.xs
                        color: C.Colors.accent
                    }

                    // SSID
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: C.Style.sp.lg + 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: netDelegate.netSsid
                        font.family: C.Style.fontMono
                        font.pixelSize: C.Style.fs.sm
                        font.weight: netDelegate.isActive ? C.Style.fw.bold : C.Style.fw.normal
                        color: {
                            if (netDelegate.isActive && netMouse.containsMouse) return C.Colors.red
                            if (netDelegate.isActive) return C.Colors.accent
                            return C.Colors.text
                        }
                        elide: Text.ElideRight
                        width: parent.width - C.Style.sp.lg - 14 - 44 - C.Style.sp.lg

                        Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                    }

                    // Signal bar — 4 segmented bars, height increases left to right
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: C.Style.sp.lg
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        spacing: 2

                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                required property int index
                                width: 5
                                height: 4 + index * 3
                                anchors.bottom: parent?.bottom
                                color: (index < Math.ceil(netDelegate.netSignal / 25))
                                    ? (netDelegate.isActive ? C.Colors.accent : C.Colors.text)
                                    : C.Colors.muted
                                Behavior on color { ColorAnimation { duration: C.Style.durFast } }
                            }
                        }
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        anchors.bottomMargin: netDelegate.showDisconnect ? 26 : 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (netDelegate.isActive) {
                                netDelegate.showDisconnect = !netDelegate.showDisconnect
                                return
                            }
                            if (netDelegate.netSecure) {
                                passwordDialog.targetSsid = netDelegate.netSsid
                                passwordDialog.visible = true
                            } else {
                                C.Network.connectTo(netDelegate.netSsid, "")
                                closeAnim.start()
                            }
                        }
                    }

                    // Disconnect confirm row
                    Row {
                        visible: netDelegate.showDisconnect && netDelegate.isActive
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: C.Style.sp.lg + 14
                        anchors.bottomMargin: C.Style.sp.xs
                        spacing: C.Style.sp.sm

                        Text {
                            text: "Disconnect?"
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.xs
                            color: C.Colors.subtext1
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Yes"
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.xs
                            font.weight: C.Style.fw.bold
                            color: yesMouse.containsMouse ? C.Colors.red : C.Colors.text
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }

                            MouseArea {
                                id: yesMouse
                                anchors.fill: parent
                                anchors.margins: -C.Style.sp.xs
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    C.Network.disconnectCurrent()
                                    closeAnim.start()
                                }
                            }
                        }

                        Text {
                            text: "/"
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.xs
                            color: C.Colors.subtext0
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "No"
                            font.family: C.Style.fontMono
                            font.pixelSize: C.Style.fs.xs
                            color: noMouse.containsMouse ? C.Colors.accent : C.Colors.subtext1
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: C.Style.durFast } }

                            MouseArea {
                                id: noMouse
                                anchors.fill: parent
                                anchors.margins: -C.Style.sp.xs
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: netDelegate.showDisconnect = false
                            }
                        }
                    }
                }
            }

            // Scanning / empty
            Text {
                visible: C.Network.scanning
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: C.Style.sp.sm
                bottomPadding: C.Style.sp.sm
                text: "Scanning..."
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.sm
                color: C.Colors.subtext0
            }

            Text {
                visible: !C.Network.scanning && C.Network.networks.count === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: C.Style.sp.sm
                bottomPadding: C.Style.sp.sm
                text: "No networks found"
                font.family: C.Style.fontMono
                font.pixelSize: C.Style.fs.sm
                color: C.Colors.subtext0
            }

            // ── Password dialog ───────────────────────────────
            Column {
                id: passwordDialog
                visible: false
                width: parent.width
                spacing: C.Style.sp.sm
                topPadding: C.Style.sp.sm
                leftPadding: C.Style.sp.lg
                rightPadding: C.Style.sp.lg
                bottomPadding: C.Style.sp.sm
                property string targetSsid: ""

                Rectangle { width: parent.width - C.Style.sp.lg * 2; height: 1; color: C.Colors.border }

                Text {
                    text: "Password for " + passwordDialog.targetSsid
                    font.family: C.Style.fontMono
                    font.pixelSize: C.Style.fs.sm
                    color: C.Colors.subtext1
                    elide: Text.ElideRight
                    width: parent.width - C.Style.sp.lg * 2
                }

                Rectangle {
                    width: parent.width - C.Style.sp.lg * 2
                    height: 28
                    color: C.Colors.overlay0
                    border.width: 1
                    border.color: passInput.activeFocus ? C.Colors.accent : C.Colors.border

                    TextInput {
                        id: passInput
                        anchors.fill: parent
                        anchors.margins: C.Style.sp.xs
                        font.family: C.Style.fontMono
                        font.pixelSize: C.Style.fs.sm
                        color: C.Colors.text
                        echoMode: TextInput.Password
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        focus: passwordDialog.visible

                        Keys.onReturnPressed: {
                            C.Network.connectTo(passwordDialog.targetSsid, passInput.text)
                            passInput.text = ""
                            passwordDialog.visible = false
                            closeAnim.start()
                        }
                        Keys.onEscapePressed: {
                            passInput.text = ""
                            passwordDialog.visible = false
                        }
                    }
                }

                Row {
                    spacing: C.Style.sp.sm
                    width: parent.width - C.Style.sp.lg * 2

                    Rectangle {
                        width: (parent.width - C.Style.sp.sm) / 2
                        height: 26
                        color: cancelMouse.containsMouse ? C.Colors.overlay1 : C.Colors.overlay0
                        Behavior on color { ColorAnimation { duration: C.Style.durFast } }

                        Text { anchors.centerIn: parent; text: "Cancel"; font.family: C.Style.fontMono; font.pixelSize: C.Style.fs.sm; color: C.Colors.subtext1 }
                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { passInput.text = ""; passwordDialog.visible = false }
                        }
                    }

                    Rectangle {
                        width: (parent.width - C.Style.sp.sm) / 2
                        height: 26
                        color: connectMouse.containsMouse ? C.Colors.accent : C.Colors.accentDim
                        Behavior on color { ColorAnimation { duration: C.Style.durFast } }

                        Text { anchors.centerIn: parent; text: "Connect"; font.family: C.Style.fontMono; font.pixelSize: C.Style.fs.sm; color: C.Colors.base }
                        MouseArea {
                            id: connectMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                C.Network.connectTo(passwordDialog.targetSsid, passInput.text)
                                passInput.text = ""
                                passwordDialog.visible = false
                                closeAnim.start()
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: C.Colors.border }
        }
    }

    Timer {
        id: restartTimer
        interval: 1500
        onTriggered: {
            C.Network.setWifiEnabled(true)
            C.Network.refreshAll()
        }
    }
}
}
