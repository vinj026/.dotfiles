pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

Singleton {
    id: root

    property bool isOpen: false
    property string targetMonitor: ""
    property var wallpapers: []
    property int currentIndex: 0
    property string lastAppliedPath: ""
    property string pendingPath: ""

    readonly property var currentWallpaper: (wallpapers && currentIndex >= 0 && currentIndex < wallpapers.length) ? wallpapers[currentIndex] : null

    Timer {
        id: autoApplyTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (root.isOpen && root.currentWallpaper && root.currentWallpaper.path) {
                if (root.currentWallpaper.path !== root.lastAppliedPath) {
                    root.lastAppliedPath = root.currentWallpaper.path;
                    root.applyWallpaper(root.currentWallpaper.path);
                }
            }
        }
    }

    function scheduleAutoApply(): void {
        if (root.isOpen) {
            autoApplyTimer.restart();
        }
    }

    function open(monitor): void {
        if (ControlCenterService.isOpen) ControlCenterService.close();
        if (LauncherService.isOpen) LauncherService.close();
        if (MediaPopupService.isOpen) MediaPopupService.close();
        if (typeof BatteryService !== "undefined" && BatteryService.isOpen) BatteryService.close();
        if (typeof WifiService !== "undefined" && WifiService.isOpen) WifiService.close();

        root.targetMonitor = monitor || MangoService.activeMonitor || (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        root.lastAppliedPath = root.currentWallpaper ? root.currentWallpaper.path : "";
        root.isOpen = true;
        root.refreshWallpapers();
    }

    function close(): void {
        autoApplyTimer.stop();
        root.isOpen = false;
    }

    function toggle(monitor): void {
        if (root.isOpen) {
            close();
        } else {
            open(monitor);
        }
    }

    function next(): void {
        if (!wallpapers || wallpapers.length === 0) return;
        root.currentIndex = (root.currentIndex + 1) % wallpapers.length;
        scheduleAutoApply();
    }

    function prev(): void {
        if (!wallpapers || wallpapers.length === 0) return;
        root.currentIndex = (root.currentIndex - 1 + wallpapers.length) % wallpapers.length;
        scheduleAutoApply();
    }

    function selectIndex(idx: int): void {
        if (idx >= 0 && idx < wallpapers.length && idx !== root.currentIndex) {
            root.currentIndex = idx;
            scheduleAutoApply();
        }
    }

    function applyCurrent(): void {
        autoApplyTimer.stop();
        if (root.currentWallpaper && root.currentWallpaper.path) {
            if (root.currentWallpaper.path !== root.lastAppliedPath) {
                root.lastAppliedPath = root.currentWallpaper.path;
                applyWallpaper(root.currentWallpaper.path);
            }
            close();
        }
    }

    function applyWallpaper(wpPath: string): void {
        if (!wpPath) return;
        if (applyProcess.running) {
            root.pendingPath = wpPath;
            return;
        }
        root.pendingPath = "";

        // Update in-memory active states
        if (root.wallpapers && Array.isArray(root.wallpapers)) {
            for (let i = 0; i < root.wallpapers.length; i++) {
                root.wallpapers[i].isCurrent = (root.wallpapers[i].path === wpPath);
            }
        }

        applyProcess.command = ["/home/vin/.dotfiles/scripts/set-wallpaper.sh", wpPath];
        applyProcess.running = true;
    }

    FileView {
        id: cacheWatcher
        path: Quickshell.env("HOME") + "/.cache/quickshell/wallpapers.json"
        watchChanges: true
        printErrors: false
        onLoaded: root.loadFromCache(text())
        onFileChanged: reload()
    }

    function loadFromCache(jsonText): void {
        if (!jsonText) return;
        try {
            let items = JSON.parse(jsonText.trim());
            if (items && Array.isArray(items) && items.length > 0) {
                console.log("[WallpaperSwitcherService] Loaded " + items.length + " wallpapers successfully.");
                root.wallpapers = items;
                let foundIdx = items.findIndex(w => w.isCurrent);
                if (foundIdx !== -1) {
                    root.currentIndex = foundIdx;
                    root.lastAppliedPath = items[foundIdx].path;
                } else if (root.currentIndex >= items.length) {
                    root.currentIndex = 0;
                }
            }
        } catch (e) {
            console.log("[WallpaperSwitcherService] Cache parse error:", e);
        }
    }

    function refreshWallpapers(): void {
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/list_wallpapers.py"]);
    }

    Component.onCompleted: {
        root.refreshWallpapers();
    }

    Process {
        id: applyProcess
        running: false
        onExited: (code, status) => {
            console.log("[WallpaperSwitcherService] Wallpaper applied with code:", code);
            if (root.pendingPath && root.pendingPath !== root.lastAppliedPath) {
                let nextP = root.pendingPath;
                root.pendingPath = "";
                root.lastAppliedPath = nextP;
                root.applyWallpaper(nextP);
            }
        }
    }
}
