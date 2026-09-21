pragma Singleton
import QtQuick
import Quickshell
import "."
import "../core" as Core

Singleton {
    id: root

    property bool isOpen: false

    function open(monitor): void {
        isOpen = true;
        BatteryService.close();
        ControlCenterService.open(monitor);
        Core.Network.refreshAll();
        Core.Network.rescan();
    }

    function close(): void {
        isOpen = false;
    }

    function toggle(monitor): void {
        if (ControlCenterService.isOpen && isOpen) {
            ControlCenterService.close();
            isOpen = false;
        } else {
            open(monitor);
        }
    }
}
