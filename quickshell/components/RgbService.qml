pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string helperPath: "/home/vin/.config/quickshell/scripts/rgb_helper.py"

    property bool supported: true
    property bool power: true
    property string mode: "wave"
    property int speed: 1
    property string brightness: "high"
    property var zones: ["#00d4ff", "#00d4ff", "#00d4ff", "#00d4ff"]
    property string lastError: ""

    function refresh() {
        if (!statusProc.running) {
            statusProc.running = true;
        }
    }

    function togglePower() {
        root.power = !root.power;
        execAction(["toggle-power"]);
    }

    function setMode(m) {
        root.mode = m;
        root.power = true;
        execAction(["set-mode", m]);
    }

    function setBrightness(b) {
        root.brightness = b;
        if (b === "off") root.power = false;
        else root.power = true;
        execAction(["set-brightness", b]);
    }

    function setSpeed(s) {
        root.speed = s;
        execAction(["set-speed", s.toString()]);
    }

    function setColor(hex) {
        root.mode = "static";
        root.power = true;
        root.zones = [hex, hex, hex, hex];
        execAction(["set-color", hex]);
    }

    function setZone(zoneIndex, hex) {
        let newZones = [...root.zones];
        newZones[zoneIndex] = hex;
        root.zones = newZones;
        root.mode = "static";
        root.power = true;
        execAction(["set-zone", (zoneIndex + 1).toString(), hex]);
    }

    function execAction(args) {
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
                    try {
                        let d = JSON.parse(text);
                        if (d.state) updateFromState(d.state);
                    } catch (e) {}
                    proc.destroy();
                }
            }
        }
    }

    function updateFromState(d) {
        if (d.supported !== undefined) root.supported = d.supported;
        if (d.power !== undefined) root.power = d.power;
        if (d.mode !== undefined) root.mode = d.mode;
        if (d.speed !== undefined) root.speed = d.speed;
        if (d.brightness !== undefined) root.brightness = d.brightness;
        if (d.zones !== undefined) root.zones = d.zones;
        if (d.error) root.lastError = d.error;
    }

    Process {
        id: statusProc
        command: [root.helperPath, "status"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text);
                    root.updateFromState(d);
                } catch (e) {}
            }
        }
    }
}
