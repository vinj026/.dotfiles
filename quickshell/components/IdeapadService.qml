pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string helperPath: "/home/vin/.config/quickshell/scripts/ideapad_helper.py"

    // Conservation Mode
    property bool conservationSupported: false
    property bool conservationEnabled: false

    // Rapid Charge
    property bool rapidChargeSupported: false
    property bool rapidChargeEnabled: false

    // Keyboard Backlight
    property bool kbdSupported: false
    property int kbdBrightness: 0
    property int kbdMaxBrightness: 0

    // Battery Telemetry & Health
    property bool batteryPresent: false
    property int percentage: 0
    property string status: "Unknown"
    property bool isCharging: false
    property real healthPercent: 100.0
    property real wearPercent: 0.0
    property int cycleCount: 0
    property real energyFullMwh: 0.0
    property real energyDesignMwh: 0.0
    property real powerNowW: 0.0

    property bool isBusy: false

    function refresh() {
        if (!statusProc.running) {
            statusProc.running = true;
        }
    }

    function toggleConservation() {
        let nextVal = !root.conservationEnabled;
        root.conservationEnabled = nextVal;
        if (nextVal && root.rapidChargeEnabled) {
            root.rapidChargeEnabled = false;
        }
        execHelper(["set-conservation", nextVal ? "1" : "0"]);
    }

    function toggleRapidCharge() {
        let nextVal = !root.rapidChargeEnabled;
        root.rapidChargeEnabled = nextVal;
        if (nextVal && root.conservationEnabled) {
            root.conservationEnabled = false;
        }
        execHelper(["set-rapid", nextVal ? "1" : "0"]);
    }

    function setKbdBrightness(val) {
        root.kbdBrightness = val;
        execHelper(["set-kbd", val.toString()]);
    }

    function execHelper(args) {
        root.isBusy = true;
        let cmd = [root.helperPath].concat(args);
        let proc = actionComponent.createObject(root, { command: cmd });
        proc.running = true;
    }

    Component {
        id: actionComponent
        Process {
            id: proc
            stdout: StdioCollector {
                onStreamFinished: {
                    root.isBusy = false;
                    root.refresh();
                    proc.destroy();
                }
            }
        }
    }

    Process {
        id: statusProc
        command: [root.helperPath, "status"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text);
                    if (d.battery) {
                        root.batteryPresent = d.battery.present || false;
                        root.percentage = d.battery.percentage || 0;
                        root.status = d.battery.status || "Unknown";
                        root.isCharging = d.battery.is_charging || false;
                        root.healthPercent = d.battery.health_percent || 100.0;
                        root.wearPercent = d.battery.wear_percent || 0.0;
                        root.cycleCount = d.battery.cycle_count || 0;
                        root.energyFullMwh = d.battery.energy_full_mwh || 0.0;
                        root.energyDesignMwh = d.battery.energy_design_mwh || 0.0;
                        root.powerNowW = d.battery.power_now_w || 0.0;
                    }

                    if (d.conservation_mode) {
                        root.conservationSupported = d.conservation_mode.supported || false;
                        root.conservationEnabled = d.conservation_mode.enabled || false;
                    }

                    if (d.rapid_charge) {
                        root.rapidChargeSupported = d.rapid_charge.supported || false;
                        root.rapidChargeEnabled = d.rapid_charge.enabled || false;
                    }

                    if (d.kbd_backlight) {
                        root.kbdSupported = d.kbd_backlight.supported || false;
                        root.kbdBrightness = d.kbd_backlight.brightness || 0;
                        root.kbdMaxBrightness = d.kbd_backlight.max_brightness || 0;
                    }
                } catch (e) {
                    console.warn("[IdeapadService] JSON parse error:", e);
                }
            }
        }
    }

    Timer {
        id: autoPollTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
}
