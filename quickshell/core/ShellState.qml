pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Global shell state — control center visibility, launcher state, etc.
Singleton {
    id: root

    // Control center
    property string activeControlCenterScreen: ""

    function isControlCenterOpen(screenName) {
        return activeControlCenterScreen === screenName && screenName !== ""
    }

    function openControlCenter(screenName) {
        activeControlCenterScreen = screenName
    }

    function closeControlCenter() {
        activeControlCenterScreen = ""
    }

    function toggleControlCenter(screenName) {
        if (isControlCenterOpen(screenName)) closeControlCenter()
        else openControlCenter(screenName)
    }

    // Media popup
    property string activeMediaPopupScreen: ""
    property int mediaPopupX: 0
    property int mediaPopupWidth: 0

    function isMediaPopupOpen(screenName) {
        return activeMediaPopupScreen === screenName && screenName !== ""
    }

    // Open media popup and center it based on screen coordinates and source width
    function openMediaPopup(screenName, xCoord, widthVal) {
        // Close other control center panels
        closeControlCenter()
        activeMediaPopupScreen = screenName
        mediaPopupX = xCoord
        mediaPopupWidth = widthVal
    }

    // Close the active media popup
    function closeMediaPopup() {
        activeMediaPopupScreen = ""
    }

    // Toggle the active media popup
    function toggleMediaPopup(screenName, xCoord, widthVal) {
        if (isMediaPopupOpen(screenName)) closeMediaPopup()
        else openMediaPopup(screenName, xCoord, widthVal)
    }

    // Launcher
    property bool launcherOpen: false

    function openLauncher()  { launcherOpen = true  }
    function closeLauncher() { launcherOpen = false }
    function toggleLauncher() { launcherOpen = !launcherOpen }

    // Notification center
    property bool notifCenterOpen: false
    function toggleNotifCenter() { notifCenterOpen = !notifCenterOpen }

    // Wifi picker
    property bool wifiPickerOpen: false
    function toggleWifiPicker() { wifiPickerOpen = !wifiPickerOpen }
    function closeWifiPicker()  { wifiPickerOpen = false }

    // Battery Profile Picker
    property bool batteryPickerOpen: false
    function toggleBatteryPicker() { batteryPickerOpen = !batteryPickerOpen }
    function closeBatteryPicker()  { batteryPickerOpen = false }

    // Wallpaper Picker
    property bool wallpaperPickerOpen: false
    property string currentWallpaperPath: ""
    function toggleWallpaperPicker() { wallpaperPickerOpen = !wallpaperPickerOpen }
    function closeWallpaperPicker()  { wallpaperPickerOpen = false }

    function saveSetting(key, val) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "set", key, val.toString()])
    }
    function saveMultipleSettings(jsonStr) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "set_multiple", jsonStr])
    }
    function saveRules(jsonStr) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "save_rules", jsonStr])
    }
    function saveAutostart(jsonStr) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "save_autostart", jsonStr])
    }
    function saveMonitors(jsonStr) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "save_monitors", jsonStr])
    }
    function saveLayouts(settingsJson, tagrulesJson) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "save_layouts", settingsJson, tagrulesJson])
    }
    function updateKeybind(disp, param, mods, trig) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "update_keybind", disp, param, mods, trig])
    }
    function saveEnvVars(jsonStr) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "save_env", jsonStr])
    }
    function addKeybind(bType, mods, trig, disp, param) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "add_keybind", bType, mods, trig, disp, param])
    }
    function deleteKeybind(disp, param) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "delete_keybind", disp, param])
    }

    function saveProfile(name) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "save_profile", name])
    }
    function loadProfile(name) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "load_profile", name])
    }
    function deleteProfile(name) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "delete_profile", name])
    }
    function saveShellStyle(jsonStr) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "save_shell_style", jsonStr])
    }
    function saveMediaConfig(jsonStr) {
        Quickshell.execDetached(["/home/vin/.config/mango/config_manager.py", "save_media_config", jsonStr])
    }
    function applyWallpaper(path, resize, transition, duration, gravity) {
        let args = ["/home/vin/.local/bin/awww", "img", path];
        if (resize) {
            args.push("--resize", resize);
        }
        if (transition) {
            args.push("--transition-type", transition);
        }
        if (duration && transition !== "simple" && transition !== "none") {
            args.push("--transition-duration", duration.toString());
        }
        if (resize === "crop" && gravity) {
            args.push("--crop-gravity", gravity);
        }
        Quickshell.execDetached(args);
    }

    // Screen fallback helper
    function fallbackScreen() {
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    }

    // Pomodoro Timer State
    property int pomoMinutes: 25
    property int pomoSeconds: 0
    property string pomoMode: "Focus" // "Focus" or "Break"
    property bool pomoRunning: false
    property bool pomoActive: false

    Timer {
        id: pomodoroTimer
        interval: 1000
        repeat: true
        running: root.pomoRunning
        onTriggered: {
            if (root.pomoSeconds > 0) {
                root.pomoSeconds--;
            } else if (root.pomoMinutes > 0) {
                root.pomoMinutes--;
                root.pomoSeconds = 59;
            } else {
                // Timer finished
                root.pomoRunning = false;
                if (root.pomoMode === "Focus") {
                    root.pomoMode = "Break";
                    root.pomoMinutes = 5;
                } else {
                    root.pomoMode = "Focus";
                    root.pomoMinutes = 25;
                    root.pomoSeconds = 0;
                }
            }
        }
    }

    // ── Screen Recording State & Functions ────────────────
    property bool isRecording: false
    property bool isRecordingPaused: false
    property int recordingTime: 0
    property string recordingFile: ""

    Timer {
        id: recordingTimer
        interval: 1000
        repeat: true
        running: root.isRecording && !root.isRecordingPaused
        onTriggered: {
            root.recordingTime++
        }
    }



    Process {
        id: checkRecProcess
        command: ["/home/vin/.local/bin/screenrecord.sh", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let status = text.trim()
                if (status === "stopped") {
                    if (root.isRecording) {
                        root.isRecording = false
                        root.isRecordingPaused = false
                        root.recordingTime = 0
                    }
                } else if (status === "running") {
                    if (!root.isRecording) {
                        root.isRecording = true
                        root.isRecordingPaused = false
                        root.recordingTime = 0
                    }
                }
            }
        }
    }

    Timer {
        id: recordingCheckTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            if (!checkRecProcess.running) {
                checkRecProcess.running = true
            }
        }
    }

    Timer {
        id: actionDelayTimer
        interval: 350
        repeat: false
        property string pendingActionName: ""
        onTriggered: {
            let act = pendingActionName
            pendingActionName = ""
            if (act === "start-full") {
                root.startRecording(false)
            } else if (act === "start-region") {
                root.startRecording(true)
            } else if (act === "ss-full") {
                Quickshell.execDetached(["/home/vin/.local/bin/screenshot.sh", "full"])
            } else if (act === "ss-region") {
                Quickshell.execDetached(["/home/vin/.local/bin/screenshot.sh", "region"])
            } else if (act === "ss-region-clip") {
                Quickshell.execDetached(["/home/vin/.local/bin/screenshot.sh", "region-clip"])
            }
        }
    }

    function runDelayedAction(actionName) {
        actionDelayTimer.pendingActionName = actionName
        actionDelayTimer.start()
    }

    function startRecording(region) {
        Quickshell.execDetached(["/home/vin/.local/bin/screenrecord.sh", region ? "start-region" : "start-full"])
        if (!region) {
            root.isRecording = true
            root.isRecordingPaused = false
            root.recordingTime = 0
        }
    }

    function togglePauseRecording() {
        Quickshell.execDetached(["/home/vin/.local/bin/screenrecord.sh", "pause"])
        root.isRecordingPaused = !root.isRecordingPaused
    }

    function stopRecording() {
        Quickshell.execDetached(["/home/vin/.local/bin/screenrecord.sh", "stop"])
        root.isRecording = false
        root.isRecordingPaused = false
        root.recordingTime = 0
    }

    // IPC handler for keybindings
    IpcHandler {
        target: "recording"
        function startFull() { root.startRecording(false); }
        function startRegion() { root.startRecording(true); }
        function togglePause() { root.togglePauseRecording(); }
        function stop() { root.stopRecording(); }
    }

    Component.onCompleted: {
        checkRecProcess.running = true
    }
}

