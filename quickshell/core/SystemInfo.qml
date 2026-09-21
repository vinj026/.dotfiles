// SystemInfo.qml — System info singleton (username, uptime, face icon)
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string username: ""
    property string hostname: ""
    property string wmName: ""
    property string uptimeText: ""
    property string uptimeLongText: ""
    property string profilePicturePath: ""
    property int retainCount: 0

    // Display-friendly WM name
    readonly property string wmDisplayName: {
        if (wmName.toLowerCase().indexOf("mango") !== -1)
            return "MangoWC";
        return wmName;
    }

    // Profile picture URL
    readonly property url profilePicture: profilePicturePath !== "" ? "file://" + profilePicturePath : ""

    function formatUptime(totalSeconds) {
        const safeSeconds = Math.max(0, Number(totalSeconds) || 0);
        const hours = Math.floor(safeSeconds / 3600);
        const minutes = Math.floor((safeSeconds % 3600) / 60);
        if (hours > 0)
            return hours + "h " + minutes + "m";
        return minutes + "m";
    }

    function formatUptimeLong(totalSeconds) {
        const safeSeconds = Math.max(0, Number(totalSeconds) || 0);
        const hours = Math.floor(safeSeconds / 3600);
        const minutes = Math.floor((safeSeconds % 3600) / 60);
        const hStr = hours === 1 ? "1 hour" : (hours + " hours");
        const mStr = minutes === 1 ? "1 minute" : (minutes + " minutes");
        if (hours > 0)
            return "up " + hStr + ", " + mStr;
        return "up " + mStr;
    }

    function refresh() {
        if (!infoTask.running)
            infoTask.running = true;
    }

    function retain() {
        retainCount += 1;
        refreshTimer.running = true;
        refresh();
    }

    function release() {
        retainCount = Math.max(0, retainCount - 1);
        if (retainCount === 0)
            refreshTimer.running = false;
    }

    Process {
        id: infoTask

        running: false
        command: ["sh", "-c", "printf 'USER %s\n' \"$(id -un)\"; " + "printf 'HOST %s\n' \"${HOSTNAME:-$(cat /etc/hostname 2>/dev/null || uname -n)}\"; " + "printf 'WM %s\n' \"${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-Wayland}}\"; " + "printf 'UP %s\n' \"$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)\"; " + "for f in \"$HOME/.face/pp.png\" \"$HOME/.face\" \"$HOME/.face.png\" \"$HOME/.face.jpg\"; do " + "[ -f \"$f\" ] && printf 'PFP %s\n' \"$f\" && break; " + "done"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                for (const line of lines) {
                    if (line.startsWith("USER "))
                        root.username = line.slice(5).trim();
                    else if (line.startsWith("HOST "))
                        root.hostname = line.slice(5).trim();
                    else if (line.startsWith("WM "))
                        root.wmName = line.slice(3).trim();
                    else if (line.startsWith("UP ")) {
                        const upSec = parseInt(line.slice(3).trim());
                        root.uptimeText = root.formatUptime(upSec);
                        root.uptimeLongText = root.formatUptimeLong(upSec);
                    }
                    else if (line.startsWith("PFP "))
                        root.profilePicturePath = line.slice(4).trim();
                }
            }
        }
    }

    Timer {
        id: refreshTimer

        interval: 30000
        running: false
        repeat: true
        onTriggered: root.refresh()
    }
}
