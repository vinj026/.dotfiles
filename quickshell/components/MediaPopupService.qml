pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    readonly property bool isOpen: ControlCenterService.activePopup === "media"
    readonly property string targetMonitor: ControlCenterService.targetMonitor

    function open(monitor) {
        ControlCenterService.openPopup("media", monitor);
    }

    function close() {
        if (isOpen) {
            ControlCenterService.closePopup();
        }
    }

    function toggle(monitor) {
        ControlCenterService.togglePopup("media", monitor);
    }
}
