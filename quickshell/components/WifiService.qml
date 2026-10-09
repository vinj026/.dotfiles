pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    readonly property bool isOpen: ControlCenterService.activePopup === "wifi"

    function open(monitor) {
        ControlCenterService.openPopup("wifi", monitor);
    }

    function close() {
        if (isOpen) {
            ControlCenterService.closePopup();
        }
    }

    function toggle(monitor) {
        ControlCenterService.togglePopup("wifi", monitor);
    }
}
