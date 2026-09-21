// Network.qml — Full Wi-Fi manager singleton using nmcli backend with fallback / parity to Quickshell.Networking
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property string wifiDevice: ""
    property string ssid: ""
    property int signal: 0
    property bool connected: false
    property bool scanning: false
    property string lastError: ""
    property string connectingSsid: ""
    property bool isConnecting: false
    property var savedConnections: new Set()

    // Network Details for Active Connection (Troubleshooting & Info)
    property string ipAddress: ""
    property string gateway: ""
    property string dnsServer: ""
    property string frequency: ""
    property string bitRate: ""
    property string channel: ""
    property string securityProtocol: ""

    function formatBand(freqStr) {
        const f = parseInt(freqStr);
        if (isNaN(f) || f <= 0) return "";
        if (f >= 5925) return "6 GHz";
        if (f >= 5000) return "5 GHz";
        return "2.4 GHz";
    }

    function refreshDetails() {
        const dev = wifiDevice || "wlan0";
        detailsTask.command = [
            "bash", "-c",
            'dev="${1:-wlan0}"\n' +
            'ip_info=$(nmcli -t -f IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show "$dev" 2>/dev/null)\n' +
            'ip=$(echo "$ip_info" | grep "^IP4.ADDRESS" | head -n1 | cut -d: -f2 | cut -d/ -f1)\n' +
            'gw=$(echo "$ip_info" | grep "^IP4.GATEWAY:" | head -n1 | cut -d: -f2)\n' +
            'dns=$(echo "$ip_info" | grep "^IP4.DNS" | head -n1 | cut -d: -f2)\n' +
            'wifi_info=$(nmcli -t -f ACTIVE,CHAN,FREQ,RATE,SECURITY device wifi list ifname "$dev" 2>/dev/null | grep "^yes:" | head -n1)\n' +
            'chan=$(echo "$wifi_info" | cut -d: -f2)\n' +
            'freq=$(echo "$wifi_info" | cut -d: -f3)\n' +
            'rate=$(echo "$wifi_info" | cut -d: -f4)\n' +
            'sec=$(echo "$wifi_info" | cut -d: -f5)\n' +
            'echo "$ip|$gw|$dns|$freq|$rate|$chan|$sec"\n',
            "--",
            dev
        ];
        if (!detailsTask.running) detailsTask.running = true;
    }

    signal connectSuccess()
    signal connectFailed(string error)

    property var pendingCommand: []
    property alias networks: networkModel
    readonly property var wifiTask: statusTask
    readonly property bool busy: actionTask.running

    function signalIconFor(level) {
        if (level >= 75) return "wifi"
        if (level >= 50) return "signal_wifi_2_bar"
        if (level >= 25) return "signal_wifi_1_bar"
        return "signal_wifi_1_bar"
    }

    // Material Icons / Symbols
    readonly property string icon: {
        if (!wifiEnabled) return "wifi_off"
        if (!connected)   return "signal_wifi_0_bar"
        return signalIconFor(signal)
    }

    function refreshStatus() {
        if (!radioTask.running) radioTask.running = true;
        if (!deviceTask.running) deviceTask.running = true;
        if (!statusTask.running) statusTask.running = true;
        if (!savedConnTask.running) savedConnTask.running = true;
    }

    function refreshNetworks() {
        if (!wifiEnabled) {
            networkModel.clear();
            return;
        }
        if (!scanTask.running) scanTask.running = true;
    }

    function refreshAll() {
        refreshStatus();
        refreshNetworks();
    }

    function runAction(command) {
        if (actionTask.running) return;
        pendingCommand = command;
        lastError = "";
        actionTask.running = true;
    }

    function toggleWifi() {
        runAction(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
    }

    function setWifiEnabled(enabled) {
        const target = enabled === true;
        if (target === wifiEnabled) return;
        runAction(["nmcli", "radio", "wifi", target ? "on" : "off"]);
    }

    function rescan() {
        if (!wifiEnabled) return;
        scanTask.command = [
            "nmcli", "-t", "-e", "no",
            "-f", "IN-USE,SSID,SIGNAL,SECURITY",
            "device", "wifi", "list", "--rescan", "yes"
        ];
        if (!scanTask.running) scanTask.running = true;
    }

    function cleanErrorMessage(raw) {
        if (!raw || raw.trim().length === 0) return "Connection failed";
        let str = raw.trim();
        if (str.includes("Secrets were required") || str.includes("802-11-wireless-security.psk") || str.includes("Passwords or encryption keys")) {
            return "Incorrect password. Please try again.";
        }
        if (str.includes("No network with SSID") || str.includes("not found")) {
            return "Network not found or out of range.";
        }
        if (str.includes("timeout") || str.includes("timed out")) {
            return "Connection timed out. Check signal strength.";
        }
        if (str.includes("already connected")) {
            return "Already connected to this network.";
        }
        // Remove nmcli Warning lines
        str = str.replace(/Warning:[^\n]*\n?/g, "").trim();
        // Remove "Error: Connection activation failed: " prefix
        str = str.replace(/^Error:\s*Connection activation failed:\s*/i, "").trim();
        if (str.startsWith("Error:")) {
            str = str.replace(/^Error:\s*/i, "").trim();
        }
        if (str.length > 65) {
            str = str.slice(0, 62) + "...";
        }
        return str || "Connection failed";
    }

    function connectTo(targetSsid, password) {
        if (!targetSsid || targetSsid.length === 0) return;
        connectingSsid = targetSsid;
        isConnecting = true;
        lastError = "";

        let script = "";
        const dev = wifiDevice || "wlan0";

        if (typeof password === "string" && password.length > 0) {
            // Password provided: delete any existing profiles for this SSID, then connect
            script = 'SSID="$1"\nPASS="$2"\nIFACE="$3"\n' +
                     'nmcli -t -f UUID,TYPE,NAME connection show | grep \':802-11-wireless:\' | grep -E ":($SSID|qs-$SSID)$" | cut -d: -f1 | while read -r u; do nmcli connection delete uuid "$u" 2>/dev/null; done\n' +
                     'if [ -n "$IFACE" ]; then\n' +
                     '    out=$(nmcli device wifi connect "$SSID" password "$PASS" ifname "$IFACE" 2>&1)\n' +
                     'else\n' +
                     '    out=$(nmcli device wifi connect "$SSID" password "$PASS" 2>&1)\n' +
                     'fi\n' +
                     'code=$?\n' +
                     'if [ $code -ne 0 ]; then\n' +
                     '    nmcli -t -f UUID,TYPE,NAME connection show | grep \':802-11-wireless:\' | grep -E ":($SSID|qs-$SSID)$" | cut -d: -f1 | while read -r u; do nmcli connection delete uuid "$u" 2>/dev/null; done\n' +
                     '    echo "$out"\n' +
                     '    exit $code\n' +
                     'fi\n';
            runAction(["bash", "-c", script, "--", targetSsid, password, dev]);
        } else {
            // No password provided: try connecting with existing saved profile or open network
            script = 'SSID="$1"\nIFACE="$2"\n' +
                     'for conn in "$SSID" "qs-$SSID"; do\n' +
                     '    if nmcli connection show "$conn" >/dev/null 2>&1; then\n' +
                     '        out=$(nmcli connection up "$conn" 2>&1)\n' +
                     '        code=$?\n' +
                     '        if [ $code -eq 0 ]; then exit 0; fi\n' +
                     '    fi\n' +
                     'done\n' +
                     'if [ -n "$IFACE" ]; then\n' +
                     '    out=$(nmcli device wifi connect "$SSID" ifname "$IFACE" 2>&1)\n' +
                     'else\n' +
                     '    out=$(nmcli device wifi connect "$SSID" 2>&1)\n' +
                     'fi\n' +
                     'code=$?\n' +
                     'if [ $code -ne 0 ]; then echo "$out"; exit $code; fi\n';
            runAction(["bash", "-c", script, "--", targetSsid, dev]);
        }
    }

    function disconnectCurrent() {
        const dev = wifiDevice || "wlan0";
        const targetSsid = ssid;
        const script = 'IFACE="$1"\nSSID="$2"\n' +
                       'if [ -n "$IFACE" ]; then nmcli device disconnect "$IFACE" 2>&1; fi\n' +
                       'if [ -n "$SSID" ]; then nmcli connection down "$SSID" 2>/dev/null; nmcli connection down "qs-$SSID" 2>/dev/null; fi\n';
        runAction(["bash", "-c", script, "--", dev, targetSsid]);
    }

    function forgetNetwork(targetSsid) {
        if (!targetSsid || targetSsid.length === 0) return;
        root.savedConnections.delete(targetSsid);
        root.savedConnections.delete("qs-" + targetSsid);
        if (targetSsid === root.ssid) {
            root.connected = false;
            root.ssid = "";
            root.signal = 0;
            root.ipAddress = "";
            root.gateway = "";
            root.dnsServer = "";
            root.frequency = "";
            root.bitRate = "";
            root.channel = "";
            root.securityProtocol = "";
        }
        const dev = wifiDevice || "wlan0";
        const script = 'SSID="$1"\n' +
                       'IFACE="$2"\n' +
                       'if [ -n "$IFACE" ]; then nmcli device disconnect "$IFACE" 2>/dev/null; fi\n' +
                       'nmcli connection down "$SSID" 2>/dev/null\n' +
                       'nmcli connection down "qs-$SSID" 2>/dev/null\n' +
                       'nmcli -t -f UUID,TYPE,NAME connection show | grep \':802-11-wireless:\' | grep -E ":($SSID|qs-$SSID)$" | cut -d: -f1 | while read -r u; do nmcli connection delete uuid "$u" 2>/dev/null; done\n';
        runAction(["bash", "-c", script, "--", targetSsid, dev]);
    }

    function updateNetworkModelFromScan(rawText) {
        const rows = [];
        const seen = new Map();
        const lines = rawText.split("\n");

        for (const line of lines) {
            if (!line || line.trim().length === 0) continue;

            // Terse format: IN-USE:SSID:SIGNAL:SECURITY
            const parts = line.split(":");
            if (parts.length < 4) continue;

            const inUse = parts[0] === "*";
            const signalValue = Number(parts[parts.length - 2]) || 0;
            const securityValue = parts[parts.length - 1] || "";
            const ssidValue = parts.slice(1, parts.length - 2).join(":").trim();

            if (!ssidValue || ssidValue.length === 0 || ssidValue === "--") continue;

            const isSecure = securityValue.trim().length > 0 && securityValue.trim() !== "--";
            const isKnown = root.savedConnections.has(ssidValue) || root.savedConnections.has("qs-" + ssidValue);

            if (seen.has(ssidValue)) {
                const existing = seen.get(ssidValue);
                if (inUse) existing.active = true;
                if (signalValue > existing.signal) {
                    existing.signal = signalValue;
                    existing.secure = isSecure;
                    existing.known = isKnown;
                }
                continue;
            }

            const item = {
                "ssid": ssidValue,
                "signal": signalValue,
                "secure": isSecure,
                "known": isKnown,
                "active": inUse
            };
            seen.set(ssidValue, item);
            rows.push(item);
        }

        rows.sort((a, b) => {
            if (a.active !== b.active) return a.active ? -1 : 1;
            if (a.signal !== b.signal) return b.signal - a.signal;
            return a.ssid.localeCompare(b.ssid);
        });

        networkModel.clear();
        for (const row of rows) networkModel.append(row);
    }

    ListModel {
        id: networkModel
    }

    Process {
        id: radioTask
        command: ["nmcli", "-t", "radio", "wifi"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim().toLowerCase();
                root.wifiEnabled = state === "enabled";
                if (!root.wifiEnabled) {
                    root.connected = false;
                    root.ssid = "";
                    root.signal = 0;
                    networkModel.clear();
                } else if (networkModel.count === 0 && !scanTask.running) {
                    scanTask.running = true;
                }
            }
        }
    }

    Process {
        id: savedConnTask
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const s = new Set();
                const lines = text.split("\n");
                for (const line of lines) {
                    if (!line || line.trim().length === 0) continue;
                    const parts = line.split(":");
                    if (parts.length >= 2 && parts[1] === "802-11-wireless") {
                        s.add(parts[0]);
                    }
                }
                root.savedConnections = s;
            }
        }
    }

    Process {
        id: deviceTask
        command: ["nmcli", "-t", "-e", "no", "-f", "DEVICE,TYPE,STATE", "device", "status"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let foundDevice = "";
                const lines = text.split("\n");
                for (const line of lines) {
                    if (!line || line.trim().length === 0) continue;
                    const parts = line.split(":");
                    if (parts.length < 3) continue;
                    if (parts[1] === "wifi") {
                        foundDevice = parts[0];
                        break;
                    }
                }
                root.wifiDevice = foundDevice || "wlan0";
            }
        }
    }

    Process {
        id: statusTask
        command: ["nmcli", "-t", "-e", "no", "-f", "ACTIVE,SSID,SIGNAL", "device", "wifi"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let found = false;
                const lines = text.split("\n");
                for (const line of lines) {
                    if (!line || line.trim().length === 0) continue;
                    const parts = line.split(":");
                    if (parts.length < 3) continue;

                    if (parts[0] === "yes") {
                        root.ssid = parts[1];
                        root.signal = Number(parts[2]) || 0;
                        root.connected = true;
                        found = true;
                        root.refreshDetails();
                        break;
                    }
                }

                if (!found) {
                    root.connected = false;
                    root.ssid = "";
                    root.signal = 0;
                    root.ipAddress = "";
                    root.gateway = "";
                    root.dnsServer = "";
                    root.frequency = "";
                    root.bitRate = "";
                    root.channel = "";
                    root.securityProtocol = "";
                }
            }
        }
    }

    Process {
        id: detailsTask
        command: [
            "bash", "-c",
            'dev="${1:-wlan0}"\n' +
            'ip_info=$(nmcli -t -f IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show "$dev" 2>/dev/null)\n' +
            'ip=$(echo "$ip_info" | grep "^IP4.ADDRESS" | head -n1 | cut -d: -f2 | cut -d/ -f1)\n' +
            'gw=$(echo "$ip_info" | grep "^IP4.GATEWAY:" | head -n1 | cut -d: -f2)\n' +
            'dns=$(echo "$ip_info" | grep "^IP4.DNS" | head -n1 | cut -d: -f2)\n' +
            'wifi_info=$(nmcli -t -f ACTIVE,CHAN,FREQ,RATE,SECURITY device wifi list ifname "$dev" 2>/dev/null | grep "^yes:" | head -n1)\n' +
            'chan=$(echo "$wifi_info" | cut -d: -f2)\n' +
            'freq=$(echo "$wifi_info" | cut -d: -f3)\n' +
            'rate=$(echo "$wifi_info" | cut -d: -f4)\n' +
            'sec=$(echo "$wifi_info" | cut -d: -f5)\n' +
            'echo "$ip|$gw|$dns|$freq|$rate|$chan|$sec"\n',
            "--",
            root.wifiDevice || "wlan0"
        ]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");
                if (parts.length >= 7) {
                    root.ipAddress = parts[0] || "";
                    root.gateway = parts[1] || "";
                    root.dnsServer = parts[2] || "";
                    root.frequency = parts[3] || "";
                    root.bitRate = parts[4] || "";
                    root.channel = parts[5] || "";
                    root.securityProtocol = parts[6] || "";
                }
            }
        }
    }

    Process {
        id: scanTask
        command: [
            "nmcli", "-t", "-e", "no",
            "-f", "IN-USE,SSID,SIGNAL,SECURITY",
            "device", "wifi", "list", "--rescan", "auto"
        ]
        running: false

        onRunningChanged: root.scanning = running

        stdout: StdioCollector {
            onStreamFinished: root.updateNetworkModelFromScan(text)
        }
    }

    Process {
        id: actionTask
        command: root.pendingCommand
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                const err = text.trim();
                if (err.length > 0) {
                    root.lastError = root.cleanErrorMessage(err);
                }
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                if (out.startsWith("Error:") || out.toLowerCase().includes("failed") || out.toLowerCase().includes("warning:") || out.toLowerCase().includes("secrets were required")) {
                    root.lastError = root.cleanErrorMessage(out);
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.lastError.length === 0) {
                root.lastError = "Connection failed";
            }

            if (exitCode === 0) {
                root.lastError = "";
                root.connectingSsid = "";
                root.connectSuccess();
            } else {
                root.connectFailed(root.lastError);
            }
            root.isConnecting = false;
            root.pendingCommand = [];
            root.refreshStatus();
            refreshAfterAction.restart();
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

    Timer {
        id: refreshAfterAction
        interval: 900
        repeat: false
        onTriggered: root.refreshAll()
    }
}
