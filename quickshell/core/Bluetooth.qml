// Bluetooth.qml — Bluetooth singleton wrapper
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Singleton {
    id: root

    // Get first adapter
    readonly property BluetoothAdapter adapter: Bluetooth.adapters.values[0] ?? null
    property bool rfkillPowered: true

    Process {
        id: rfkillQuery
        command: ["sh", "-c", "rfkill list bluetooth | grep -qi 'soft blocked: yes' && echo 'off' || echo 'on'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.rfkillPowered = (text.trim() === "on");
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: if (!rfkillQuery.running) rfkillQuery.running = true
    }
    
    readonly property bool isPowered: adapter ? adapter.powered : rfkillPowered
    readonly property bool isConnected: connectedDevices.length > 0

    // Filter devices whose status is connected
    readonly property list<var> connectedDevices: {
        if (!adapter) return [];
        return adapter.devices.values.filter(device => device.connected);
    }

    // Name of first connected device
    readonly property string activeDeviceName: isConnected ? connectedDevices[0].name : ""

    readonly property string icon: {
        if (!isPowered) return "bluetooth_disabled"
        if (isConnected) return "bluetooth_connected"
        return "bluetooth"
    }

    // Controls
    function togglePower() {
        if (adapter) {
            const target = !adapter.powered;
            Quickshell.execDetached(["bluetoothctl", "power", target ? "on" : "off"]);
        } else {
            const target = !root.rfkillPowered;
            root.rfkillPowered = target;
            Quickshell.execDetached(["rfkill", target ? "unblock" : "block", "bluetooth"]);
            rfkillTimer.restart();
        }
    }
    Timer { id: rfkillTimer; interval: 500; onTriggered: if (!rfkillQuery.running) rfkillQuery.running = true }
}
