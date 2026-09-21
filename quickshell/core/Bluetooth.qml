// Bluetooth.qml — Bluetooth singleton wrapper
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    // Get first adapter
    readonly property BluetoothAdapter adapter: Bluetooth.adapters.values[0] ?? null
    
    readonly property bool isPowered: adapter?.powered ?? false
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
        const target = !root.isPowered
        Quickshell.execDetached(["bluetoothctl", "power", target ? "on" : "off"])
    }
}
