import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../../theme"
import "../../../../components"

Item {
    id: root

    anchors.verticalCenter: parent.verticalCenter
    width: textItem.width
    height: textItem.implicitHeight
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutExpo
        }
    }

    Text {
        id: textItem

        anchors.left: parent.left
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: mouseArea.containsMouse ? Theme.primary : Theme.textPrimary
        elide: Text.ElideRight
        width: Math.min(implicitWidth, Theme.appNameMaxWidth)

        text: getTitle()

        function getTitle() {
            // First check Wayland toplevel
            if (ToplevelManager.activeToplevel !== null) {
                let toplevel = ToplevelManager.activeToplevel;
                let app = toplevel.appId || toplevel.title || "";
                if (app) return formatApp(app);
            }
            // Fallback to Mango IPC
            if (MangoService.activeAppId) {
                return formatApp(MangoService.activeAppId);
            }
            if (MangoService.activeTitle) {
                return MangoService.activeTitle;
            }
            return "Mango";
        }

        function formatApp(appId) {
            if (!appId) return "Mango";
            if (appId.includes(".")) {
                const parts = appId.split(".");
                let last = parts[parts.length - 1];
                return last.charAt(0).toUpperCase() + last.slice(1);
            }
            return appId.charAt(0).toUpperCase() + appId.slice(1);
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: LauncherService.toggle()
    }
}
