pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../../theme"
import "../../../../../components"
import "../../../../../core" as Core

Item {
    id: root

    signal backClicked()

    implicitWidth: 296
    implicitHeight: 262

    FontLoader {
        id: matSymbols
        source: "file:///home/vin/.local/share/fonts/MaterialSymbolsRounded-Filled.ttf"
    }

    // State for network selection & inline password
    property string selectedSsid: ""
    property string passwordInputText: ""
    property bool showPassword: false
    property string inlineError: ""

    Connections {
        target: Core.Network
        function onConnectSuccess() {
            root.selectedSsid = "";
            root.passwordInputText = "";
            root.inlineError = "";
        }
        function onConnectFailed(error) {
            if (root.selectedSsid === "" && Core.Network.connectingSsid !== "") {
                root.selectedSsid = Core.Network.connectingSsid;
            }
            root.inlineError = error || "Failed to connect to network";
            Qt.callLater(() => {
                if (typeof netList !== "undefined") {
                    for (let i = 0; i < Core.Network.networks.count; ++i) {
                        if (Core.Network.networks.get(i).ssid === root.selectedSsid) {
                            netList.positionViewAtIndex(i, ListView.Contain);
                            break;
                        }
                    }
                }
            });
        }
    }

    function resetState() {
        root.selectedSsid = "";
        root.passwordInputText = "";
        root.inlineError = "";
        root.showPassword = false;
    }

    function getWifiIcon(signal) {
        if (signal >= 75) return "\ue1d8"; // signal_wifi_4_bar
        if (signal >= 50) return "\ue1ba"; // network_wifi
        if (signal >= 25) return "\ue4d9"; // wifi_2_bar
        return "\ue4ca"; // wifi_1_bar
    }

    // ── 1. Header (Clean row, no background container) ──
    Item {
        id: headerRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32

        Row {
            anchors.fill: parent
            spacing: 6

            // Back Button
            Rectangle {
                width: 26
                height: 26
                radius: 6
                color: "transparent"
                scale: backMouse.pressed ? 0.90 : (backMouse.containsMouse ? 1.08 : 1.0)
                opacity: backMouse.containsMouse ? 1.0 : 0.85
                anchors.verticalCenter: parent.verticalCenter
                Behavior on scale { NumberAnimation { duration: 100 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "\ue5c4" // arrow_back
                    font.family: matSymbols.name
                    font.pixelSize: 16
                    color: Theme.textPrimary
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.resetState();
                        root.backClicked();
                    }
                }
            }

            // Title & Status text
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 26 - 6 - headerActions.width - 6
                spacing: 0

                Text {
                    text: "Wi-Fi"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                }

                Text {
                    text: Core.Network.wifiEnabled
                        ? (Core.Network.connected ? ("Connected to " + Core.Network.ssid) : "Not connected")
                        : "Wi-Fi is off"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: Core.Network.connected ? Theme.primary : Theme.textMuted
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            // Right Actions: Rescan & Switch
            Row {
                id: headerActions
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Rescan Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    color: "transparent"
                    scale: rescanMouse.pressed ? 0.90 : (rescanMouse.containsMouse ? 1.08 : 1.0)
                    opacity: rescanMouse.containsMouse ? 1.0 : 0.85
                    visible: Core.Network.wifiEnabled
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\ue5d5" // refresh
                        font.family: matSymbols.name
                        font.pixelSize: 15
                        color: Theme.textPrimary

                        RotationAnimation on rotation {
                            running: Core.Network.scanning
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 800
                        }
                    }

                    MouseArea {
                        id: rescanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Core.Network.rescan()
                    }
                }

                // Switch Pill
                Rectangle {
                    width: 34
                    height: 18
                    radius: 9
                    color: Core.Network.wifiEnabled ? Theme.primary : Qt.rgba(1, 1, 1, 0.14)
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: Core.Network.wifiEnabled ? Theme.textOnPrimary : Theme.textMuted
                        anchors.verticalCenter: parent.verticalCenter
                        x: Core.Network.wifiEnabled ? 18 : 2

                        Behavior on x {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Core.Network.toggleWifi()
                    }
                }
            }
        }
    }

    // ── 2. Network List (Directly on surface, no outer container box) ──
    ListView {
        id: netList
        anchors.top: headerRow.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        visible: Core.Network.wifiEnabled && Core.Network.networks.count > 0

        model: Core.Network.networks

        delegate: Rectangle {
            id: delegateRoot
            required property string ssid
            required property int signal
            required property bool secure
            required property bool known
            required property bool active
            required property int index

            readonly property bool isSelected: root.selectedSsid === delegateRoot.ssid
            readonly property bool isConnectingThis: Core.Network.isConnecting && Core.Network.connectingSsid === delegateRoot.ssid

            width: netList.width
            height: isSelected ? (expandedLayout.implicitHeight + 14) : 32
            radius: 6
            color: isSelected
                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)
                : (delegateRoot.active
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                    : "transparent")
            scale: itemMouse.pressed ? 0.98 : (itemMouse.containsMouse ? 1.015 : 1.0)
            clip: true

            Behavior on scale { NumberAnimation { duration: 100 } }

            onIsSelectedChanged: {
                if (isSelected) {
                    Qt.callLater(() => {
                        netList.positionViewAtIndex(delegateRoot.index, ListView.Contain);
                    });
                }
            }

            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

            // ── COMPACT NETWORK ROW ──
            Item {
                id: collapsedRow
                anchors.fill: parent
                visible: !delegateRoot.isSelected

                // Click area for the network item (anchored to left of rightStatus)
                MouseArea {
                    id: itemMouse
                    anchors.left: parent.left
                    anchors.right: rightStatus.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    cursorShape: delegateRoot.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (delegateRoot.active) return;
                        if (!delegateRoot.secure || delegateRoot.known) {
                            // Direct connect if open network or already saved
                            root.inlineError = "";
                            Core.Network.connectTo(delegateRoot.ssid, "");
                            return;
                        }
                        // If password required and unknown, open inline password input
                        root.selectedSsid = delegateRoot.ssid;
                        root.passwordInputText = "";
                        root.inlineError = "";
                        Core.Network.lastError = "";
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: rightStatus.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    Text {
                        text: root.getWifiIcon(delegateRoot.signal)
                        font.family: matSymbols.name
                        font.pixelSize: 15
                        color: delegateRoot.active
                            ? Theme.primary
                            : (delegateRoot.signal >= 50 ? Theme.textPrimary : Theme.textMuted)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: delegateRoot.ssid
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: delegateRoot.active ? Font.DemiBold : Font.Normal
                        color: delegateRoot.active ? Theme.primary : Theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, parent.width - 30)
                    }

                    Text {
                        text: "\ue897" // lock
                        font.family: matSymbols.name
                        font.pixelSize: 10
                        color: Theme.textMuted
                        visible: delegateRoot.secure
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Right Status / Actions (ghost buttons with zero idle containers)
                Row {
                    id: rightStatus
                    z: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    // Checkmark indicator (if connected)
                    Text {
                        text: "\ue5ca" // check
                        font.family: matSymbols.name
                        font.pixelSize: 13
                        color: Theme.primary
                        visible: delegateRoot.active
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Disconnect Ghost Button (if connected)
                    Rectangle {
                        id: discBtn
                        width: discText.implicitWidth + 8
                        height: 20
                        radius: 4
                        color: "transparent"
                        scale: discMouse.pressed ? 0.92 : (discMouse.containsMouse ? 1.06 : 1.0)
                        opacity: discMouse.containsMouse ? 1.0 : 0.8
                        visible: delegateRoot.active
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        Text {
                            id: discText
                            anchors.centerIn: parent
                            text: "Disconnect"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: discMouse.containsMouse ? Theme.textPrimary : Theme.textMuted
                        }

                        MouseArea {
                            id: discMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Core.Network.disconnectCurrent()
                        }
                    }

                    // Forget Ghost Button (if connected)
                    Rectangle {
                        id: forgetBtn
                        width: forgetBtnText.implicitWidth + 8
                        height: 20
                        radius: 4
                        color: "transparent"
                        scale: forgetBtnMouse.pressed ? 0.92 : (forgetBtnMouse.containsMouse ? 1.06 : 1.0)
                        opacity: forgetBtnMouse.containsMouse ? 1.0 : 0.8
                        visible: delegateRoot.active
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        Text {
                            id: forgetBtnText
                            anchors.centerIn: parent
                            text: "Forget"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: forgetBtnMouse.containsMouse ? Theme.error : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.70)
                        }

                        MouseArea {
                            id: forgetBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Core.Network.forgetNetwork(delegateRoot.ssid)
                        }
                    }

                    // Connecting spinner indicator
                    Row {
                        visible: !delegateRoot.active && delegateRoot.isConnectingThis
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "\ue5d5"
                            font.family: matSymbols.name
                            font.pixelSize: 11
                            color: Theme.primary

                            RotationAnimation on rotation {
                                running: delegateRoot.isConnectingThis
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 700
                            }
                        }

                        Text {
                            text: "Connecting..."
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: Theme.primary
                        }
                    }

                    // Signal % (when not active & not connecting)
                    Text {
                        visible: !delegateRoot.active && !delegateRoot.isConnectingThis
                        text: delegateRoot.signal + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Normal
                        color: Theme.textDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ── EXPANDED ROW (Inline Password Entry) ──
            Column {
                id: expandedLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 6
                spacing: 5
                visible: delegateRoot.isSelected

                // Line 1: Header (Wifi Icon, SSID, Lock, Signal %, Forget & Dismiss ✕)
                Item {
                    width: parent.width
                    height: 16

                    Row {
                        anchors.left: parent.left
                        anchors.right: actionBtnsRow.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            text: root.getWifiIcon(delegateRoot.signal)
                            font.family: matSymbols.name
                            font.pixelSize: 14
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: delegateRoot.ssid
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, parent.width - 90)
                        }

                        Text {
                            text: "\ue897" // lock
                            font.family: matSymbols.name
                            font.pixelSize: 11
                            color: Theme.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: delegateRoot.signal + "%"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: Theme.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Action buttons (Forget if known, and Dismiss ✕)
                    Row {
                        id: actionBtnsRow
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        // Forget button (only if profile is known)
                        Rectangle {
                            width: forgetText.implicitWidth + 8
                            height: 18
                            radius: 4
                            visible: delegateRoot.known
                            color: "transparent"
                            scale: forgetMouse.pressed ? 0.92 : (forgetMouse.containsMouse ? 1.06 : 1.0)
                            opacity: forgetMouse.containsMouse ? 1.0 : 0.8
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            Behavior on opacity { NumberAnimation { duration: 100 } }

                            Text {
                                id: forgetText
                                anchors.centerIn: parent
                                text: "Forget"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                color: forgetMouse.containsMouse ? Theme.error : Theme.textDim
                            }

                            MouseArea {
                                id: forgetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Core.Network.forgetNetwork(delegateRoot.ssid);
                                    root.selectedSsid = "";
                                    root.inlineError = "";
                                }
                            }
                        }

                        // Dismiss ✕ Button
                        Rectangle {
                            id: dismissBtn
                            width: 18
                            height: 18
                            radius: 4
                            color: "transparent"
                            scale: dismissMouse.pressed ? 0.90 : (dismissMouse.containsMouse ? 1.08 : 1.0)
                            opacity: dismissMouse.containsMouse ? 1.0 : 0.8
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            Behavior on opacity { NumberAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "\ue5cd" // close
                                font.family: matSymbols.name
                                font.pixelSize: 13
                                color: Theme.textMuted
                            }

                            MouseArea {
                                id: dismissMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedSsid = "";
                                    root.inlineError = "";
                                }
                            }
                        }
                    }
                }

                // Line 2: Single Horizontal Row: Password Pill + Connect Button
                Row {
                    width: parent.width
                    height: 28
                    spacing: 6

                    // Password Input Pill
                    Rectangle {
                        width: parent.width - 68 - 6
                        height: 28
                        radius: 6
                        color: Qt.rgba(0, 0, 0, 0.28)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 7
                            anchors.rightMargin: 4
                            spacing: 5

                            Text {
                                text: "\ue897" // lock
                                font.family: matSymbols.name
                                font.pixelSize: 12
                                color: Theme.textMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            TextInput {
                                id: pwdField
                                width: parent.width - 16 - eyeBtn.width - 5
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.textPrimary
                                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                                focus: delegateRoot.isSelected
                                text: root.passwordInputText
                                onTextChanged: root.passwordInputText = text

                                Component.onCompleted: {
                                    if (delegateRoot.isSelected) forceActiveFocus();
                                }

                                Text {
                                    text: "Password..."
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textDim
                                    visible: !pwdField.text && !pwdField.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Keys.onReturnPressed: {
                                    if (pwdField.text.length > 0 && !delegateRoot.isConnectingThis) {
                                        root.inlineError = "";
                                        Core.Network.connectTo(delegateRoot.ssid, pwdField.text);
                                    }
                                }
                            }

                            // Eye Toggle Button
                            Rectangle {
                                id: eyeBtn
                                width: 20
                                height: 20
                                radius: 4
                                color: "transparent"
                                scale: eyeMouse.pressed ? 0.90 : (eyeMouse.containsMouse ? 1.08 : 1.0)
                                opacity: eyeMouse.containsMouse ? 1.0 : 0.8
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on scale { NumberAnimation { duration: 100 } }
                                Behavior on opacity { NumberAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.showPassword ? "\ue8f5" : "\ue8f4"
                                    font.family: matSymbols.name
                                    font.pixelSize: 13
                                    color: root.showPassword ? Theme.primary : Theme.textMuted
                                }

                                MouseArea {
                                    id: eyeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showPassword = !root.showPassword
                                }
                            }
                        }
                    }

                    // Connect Button Pill
                    Rectangle {
                        width: 68
                        height: 28
                        radius: 6
                        color: (pwdField.text.length === 0 || delegateRoot.isConnectingThis)
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
                            : Theme.primary
                        scale: connectMouse.pressed ? 0.94 : (connectMouse.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "\ue5d5"
                                font.family: matSymbols.name
                                font.pixelSize: 11
                                color: Theme.textOnPrimary
                                visible: delegateRoot.isConnectingThis

                                RotationAnimation on rotation {
                                    running: delegateRoot.isConnectingThis
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                    duration: 700
                                }
                            }

                            Text {
                                text: delegateRoot.isConnectingThis ? "Wait..." : "Connect"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.textOnPrimary
                            }
                        }

                        MouseArea {
                            id: connectMouse
                            anchors.fill: parent
                            enabled: pwdField.text.length > 0 && !delegateRoot.isConnectingThis
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                root.inlineError = "";
                                Core.Network.connectTo(delegateRoot.ssid, pwdField.text);
                            }
                        }
                    }
                }

                // Line 3: Inline Error Text (if any)
                Row {
                    width: parent.width
                    height: 14
                    spacing: 4
                    visible: root.inlineError.length > 0 && delegateRoot.isSelected

                    Text {
                        text: "\ue000" // error
                        font.family: matSymbols.name
                        font.pixelSize: 11
                        color: Theme.error
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.inlineError
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        color: Theme.error
                        elide: Text.ElideRight
                        width: parent.width - 16
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // ── 3. Empty States (Directly on surface) ──
    // Wi-Fi Off
    Item {
        anchors.top: headerRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !Core.Network.wifiEnabled

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\ue648" // wifi_off
                font.family: matSymbols.name
                font.pixelSize: 28
                color: Theme.textMuted
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Wi-Fi is turned off"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.textMuted
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: enableWifiText.implicitWidth + 16
                height: 24
                radius: 6
                color: Theme.primary

                Text {
                    id: enableWifiText
                    anchors.centerIn: parent
                    text: "Turn On Wi-Fi"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Theme.textOnPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Core.Network.toggleWifi()
                }
            }
        }
    }

    // Scanning state (when networks count is 0)
    Item {
        anchors.top: headerRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: Core.Network.wifiEnabled && Core.Network.scanning && Core.Network.networks.count === 0

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\ue5d5"
                font.family: matSymbols.name
                font.pixelSize: 22
                color: Theme.primary

                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 800
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Scanning for networks..."
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.textMuted
            }
        }
    }
}
