//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import "./modules/bar"
import "./modules/launcher"
import "./modules/notifications"
import "./modules/media"
import "./modules/wallpaper"
import "./components"

ShellRoot {
    FontLoader {
        id: interLoader
        source: "./assets/fonts/InterVariable.ttf"
    }

    FontLoader {
        id: zenLoader
        source: "./assets/fonts/ZenKakuGothicNew-Medium.ttf"
    }

    IpcHandler {
        target: "controlCenter"

        function toggle(monitor: string) {
            ControlCenterService.toggle(monitor);
        }

        function open(monitor: string) {
            ControlCenterService.open(monitor);
        }

        function close() {
            ControlCenterService.close();
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            LauncherService.toggle();
        }

        function open() {
            LauncherService.open();
        }

        function close() {
            LauncherService.close();
        }
    }

    IpcHandler {
        target: "media"

        function toggle(monitor: string) {
            MediaPopupService.toggle(monitor);
        }

        function open(monitor: string) {
            MediaPopupService.open(monitor);
        }

        function close() {
            MediaPopupService.close();
        }
    }

    IpcHandler {
        target: "wifi"

        function toggle(monitor: string) {
            WifiService.toggle(monitor);
        }

        function open(monitor: string) {
            WifiService.open(monitor);
        }

        function close() {
            WifiService.close();
        }
    }

    IpcHandler {
        target: "battery"

        function toggle(monitor: string) {
            BatteryService.toggle(monitor);
        }

        function open(monitor: string) {
            BatteryService.open(monitor);
        }

        function close() {
            BatteryService.close();
        }
    }

    IpcHandler {
        target: "wallpaperSwitcher"

        function toggle() {
            WallpaperSwitcherService.toggle();
        }

        function open() {
            WallpaperSwitcherService.open();
        }

        function close() {
            WallpaperSwitcherService.close();
        }

        function next() {
            WallpaperSwitcherService.next();
        }

        function prev() {
            WallpaperSwitcherService.prev();
        }

        function apply() {
            WallpaperSwitcherService.applyCurrent();
        }
    }

    IpcHandler {
        target: "notifications"

        function clear() {
            NotificationService.clearAll();
        }
    }

    IpcHandler {
        target: "osd"

        function showVolume() {
            OSDService.triggerVolume();
        }

        function showBrightness() {
            OSDService.triggerBrightness();
        }
    }

    IpcHandler {
        target: "config"

        function setStyle(style: string) {
            ShellConfig.setStyle(style);
        }

        function setTheme(theme: string) {
            ShellConfig.setTheme(theme);
        }

        function cycleStyle() {
            ShellConfig.cycleStyle();
        }

        function cycleTheme() {
            ShellConfig.cycleTheme();
        }

        function getStyle(): string {
            return ShellConfig.currentStyle;
        }

        function getTheme(): string {
            return ShellConfig.currentTheme;
        }
    }

    IpcHandler {
        target: "layout"

        function cycle() {
            MangoService.cycleLayout();
        }

        function showLayout() {
            MangoService.triggerCurrentLayout();
        }
    }


    Variants {
        model: Quickshell.screens

        Scope {
            id: scopeRoot
            required property ShellScreen modelData

            Bar {
                screen: scopeRoot.modelData
            }

            LauncherWindow {
                screen: scopeRoot.modelData
            }

            NotificationWindow {
                screen: scopeRoot.modelData
            }

            MediaPopupWindow {
                screen: scopeRoot.modelData
            }

            WallpaperSwitcherWindow {
                screen: scopeRoot.modelData
            }

        }
    }
}
