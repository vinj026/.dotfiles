pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var clipItems: []
    property string searchQuery: ""
    property int lastCopiedId: -1

    readonly property var filteredItems: {
        if (!root.searchQuery || root.searchQuery.trim().length === 0) {
            return root.clipItems;
        }
        let q = root.searchQuery.toLowerCase();
        return root.clipItems.filter(item => item && item.text && item.text.toLowerCase().includes(q));
    }

    Timer {
        id: feedbackTimer
        interval: 1500
        repeat: false
        onTriggered: root.lastCopiedId = -1
    }

    Timer {
        id: pollTimer
        interval: 3000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Process {
        id: listProc
        command: ["bash", "-c", "cliphist list | head -n 30"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                // Buffer rows
                if (!root._tempList) root._tempList = [];
                let line = data ? data.trim() : "";
                if (line.length > 0) {
                    let tabIdx = line.indexOf("\t");
                    if (tabIdx !== -1) {
                        let id = parseInt(line.substring(0, tabIdx).trim());
                        let text = line.substring(tabIdx + 1).trim();
                        let isBinary = text.startsWith("[[ binary");
                        if (!isBinary && text.length > 0) {
                            root._tempList.push({ id: id, text: text });
                        }
                    }
                }
            }
        }
        onExited: {
            if (root._tempList) {
                root.clipItems = root._tempList;
                root._tempList = null;
            }
        }
    }

    property var _tempList: null

    Component.onCompleted: {
        refresh();
    }

    function refresh(): void {
        if (listProc.running) return;
        root._tempList = [];
        listProc.running = true;
    }

    function copyItem(id: int): void {
        Quickshell.execDetached(["bash", "-c", "cliphist decode " + id + " | wl-copy"]);
        root.lastCopiedId = id;
        feedbackTimer.restart();
    }

    function clearAll(): void {
        Quickshell.execDetached(["cliphist", "wipe"]);
        root.clipItems = [];
        root.lastCopiedId = -1;
    }
}
