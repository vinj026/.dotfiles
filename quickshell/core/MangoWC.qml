// core/MangoWC.qml — Mango WM integration via mmsg (JSON-based)
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property ListModel workspaces: ListModel {}
    property string selectedMonitor: ""
    property bool initialized: false

    // Ambil snapshot awal saat startup
    Process {
        id: initialQuery
        command: ["mmsg", "get", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => root.parseLine(line)
        }
        onExited: root.initialized = true
    }

    // Watch real-time events dari Mango WM
    Process {
        id: eventStream
        command: ["mmsg", "watch", "all-monitors"]
        running: root.initialized
        stdout: SplitParser {
            onRead: line => root.parseLine(line)
        }
    }

    function parseLine(line) {
        if (!line.trim()) return
        try {
            let data = JSON.parse(line)
            if (data.monitors) {
                updateFromMonitors(data.monitors)
            }
        } catch (e) {
            console.warn("JSON parse error in MangoWC parseLine:", e, "Line:", line)
        }
    }

    function updateFromMonitors(monitors) {
        for (let m = 0; m < monitors.length; m++) {
            let monitor = monitors[m]
            if (monitor.active) {
                root.selectedMonitor = monitor.name
            }
            
            let monitorName = monitor.name
            let isMonitorActive = monitor.active
            let tags = monitor.tags || []
            
            for (let t = 0; t < tags.length; t++) {
                let tag = tags[t]
                let tagId = tag.index
                let isOccupied = tag.client_count > 0
                let isActive = tag.is_active
                let isUrgent = tag.is_urgent
                let isFocused = isActive && isMonitorActive

                // Cari apakah workspace ini sudah ada di ListModel
                let found = false
                for (let j = 0; j < workspaces.count; j++) {
                    let item = workspaces.get(j)
                    if (item.output === monitorName && item.idx === tagId) {
                        workspaces.setProperty(j, "isOccupied", isOccupied)
                        workspaces.setProperty(j, "isFocused",  isFocused)
                        workspaces.setProperty(j, "isUrgent",   isUrgent)
                        workspaces.setProperty(j, "isActive",   isActive)
                        found = true
                        break
                    }
                }

                if (!found) {
                    workspaces.append({
                        "output":     monitorName,
                        "idx":        tagId,
                        "isOccupied": isOccupied,
                        "isFocused":  isFocused,
                        "isUrgent":   isUrgent,
                        "isActive":   isActive
                    })
                }
            }
        }
    }

    function switchToWorkspace(tagIdx, outputName) {
        Quickshell.execDetached(["mmsg", "dispatch", "view," + tagIdx.toString() + "," + outputName])
    }
}

