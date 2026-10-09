pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    readonly property bool isOpen: ControlCenterService.activePopup === "battery"

    function open(monitor) {
        ControlCenterService.openPopup("battery", monitor);
    }

    function close() {
        if (isOpen) {
            ControlCenterService.closePopup();
        }
    }

    function toggle(monitor) {
        ControlCenterService.togglePopup("battery", monitor);
    }
}

