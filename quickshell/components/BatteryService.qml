pragma Singleton
import QtQuick
import Quickshell
import "."
import "../core" as Core

Singleton {
    id: root

    property bool isOpen: ControlCenterService.isOpen

    function open(monitor): void {
        WifiService.close();
        ControlCenterService.open(monitor);
        Core.Battery.refreshProfile();
        Core.Battery.refreshChargeType();
        IdeapadService.refresh();
        RgbService.refresh();
    }

    function close(): void {
        ControlCenterService.close();
    }

    function toggle(monitor): void {
        if (ControlCenterService.isOpen) {
            ControlCenterService.close();
        } else {
            open(monitor);
        }
    }
}

