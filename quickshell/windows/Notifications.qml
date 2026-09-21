// Notifications.qml — Toast notification popups
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components.notifications
import qs.core as C

PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    color: "transparent"
    WlrLayershell.namespace: "quickshell:notifications"
    WlrLayershell.layer:     WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors.top:   true
    anchors.right: true
    anchors.left:  false
    anchors.bottom: false

    implicitWidth:  360
    implicitHeight: listview.y + listview.contentHeight

    property bool keepVisible: false

    // Only visible when there are active popup toasts or during exit transition
    visible: C.Notifications.popupList.length > 0 || keepVisible

    Connections {
        target: C.Notifications
        function onPopupListChanged() {
            if (C.Notifications.popupList.length === 0 && root.visible) {
                root.keepVisible = true;
                hideTimer.start();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 300 // slightly longer than C.Style.durFast (150ms) / durNormal (220ms)
        repeat: false
        onTriggered: root.keepVisible = false;
    }

    mask: Region { item: listview }

    ListView {
        id: listview
        width: 340
        height: contentHeight
        x: parent.width - width - C.Style.sp.lg
        y: C.Style.barHeight + C.Style.sp.lg
        spacing: C.Style.sp.sm
        interactive: false
        clip: true

        model: ScriptModel {
            values: C.Notifications.popupList
        }

        delegate: NotificationItem {
            width: listview.width
            notifData: modelData
            onDismissed: C.Notifications.dismissPopup(modelData)
        }

        // Smooth transition when a notification is dismissed and others shift
        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: C.Style.durNormal
                easing.type: Easing.OutCubic
            }
        }

        remove: Transition {
            NumberAnimation {
                property: "scaleFactor"
                to: 0.0
                duration: C.Style.durFast
                easing.type: Easing.InCubic
            }
        }
    }
}

