pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal tagsUpdated()
    signal layoutChanged(string monitor, string symbol, string name, string icon, int tag)

    property var monitorTags: ({})
    property var monitorLayouts: ({})
    property var monitorActiveTags: ({})
    property bool layoutInitDone: false
    property string activeAppId: ""
    property string activeTitle: ""
    property string activeMonitor: ""

    // Persistent stream for all tags on all monitors
    Process {
        id: tagsWatcher
        command: ["mmsg", "watch", "all-tags"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let json = JSON.parse(data);
                    if (json && json.all_tags) {
                        let newMap = {};
                        for (let i = 0; i < json.all_tags.length; i++) {
                            let mon = json.all_tags[i];
                            newMap[mon.monitor] = mon.tags;
                        }
                        root.monitorTags = newMap;
                        root.tagsUpdated();
                    }
                } catch (e) {}
            }
        }
    }

    // Persistent stream for focused client
    Process {
        id: clientWatcher
        command: ["mmsg", "watch", "focusing-client"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let json = JSON.parse(data);
                    if (json) {
                        root.activeAppId = json.appid || "";
                        root.activeTitle = json.title || "";
                    }
                } catch (e) {}
            }
        }
    }

    // Persistent stream for monitors & active monitor
    Process {
        id: monitorsWatcher
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let json = JSON.parse(data);
                    if (json && json.monitors) {
                        for (let i = 0; i < json.monitors.length; i++) {
                            let mon = json.monitors[i];
                            if (mon.active) {
                                root.activeMonitor = mon.name;
                            }

                            let monName = mon.name;
                            let sym = mon.layout_symbol || "T";
                            let activeTag = 1;
                            if (mon.active_tags && mon.active_tags.length > 0) {
                                activeTag = mon.active_tags[0];
                            } else if (mon.tags) {
                                for (let t = 0; t < mon.tags.length; t++) {
                                    if (mon.tags[t].is_active) {
                                        activeTag = mon.tags[t].index;
                                        break;
                                    }
                                }
                            }

                            let prevSym = root.monitorLayouts[monName];
                            let prevTag = root.monitorActiveTags[monName];

                            root.monitorLayouts[monName] = sym;
                            root.monitorActiveTags[monName] = activeTag;

                            if (root.layoutInitDone) {
                                if (prevSym !== undefined && (sym !== prevSym || activeTag !== prevTag)) {
                                    let meta = root.getLayoutMeta(sym);
                                    root.layoutChanged(monName, sym, meta.name, meta.icon, activeTag);
                                }
                            }
                        }
                        if (!root.layoutInitDone) {
                            root.layoutInitDone = true;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    function switchTag(tagIndex, monitorName) {
        if (monitorName && monitorName.length > 0) {
            Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + tagIndex + "," + monitorName]);
        } else {
            Quickshell.execDetached(["mmsg", "dispatch", "view," + tagIndex + ",0"]);
        }
    }

    function focusTag(monitorName, tagIndex) {
        switchTag(tagIndex, monitorName);
    }

    function getLayoutMeta(symbol) {
        switch (symbol) {
            case "T":  return { name: "Master Tile",       icon: "\uE8F0" }; // grid_view
            case "VT": return { name: "Vertical Tile",     icon: "\uE8EB" }; // view_agenda
            case "CT": return { name: "Center Tile",       icon: "\uE8EE" }; // view_column
            case "S":  return { name: "Scroller",          icon: "\uE8EC" }; // view_carousel
            case "VS": return { name: "Vertical Scroller", icon: "\uE8EB" }; // view_stream
            case "K":  return { name: "Deck Stack",        icon: "\uE8D2" }; // layers
            case "VK": return { name: "Vertical Deck",     icon: "\uE8D2" }; // layers
            case "D":
            case "DW": return { name: "Dwindle",           icon: "\uE8F1" }; // view_quilt
            case "F":  return { name: "Floating",          icon: "\uE8D4" }; // tab
            case "VF": return { name: "Vertical Floating", icon: "\uE919" }; // picture_in_picture_alt
            case "M":  return { name: "Monocle",           icon: "\uE5D0" }; // fullscreen
            case "G":  return { name: "Grid",              icon: "\uE9B0" }; // grid_on
            case "VG": return { name: "Vertical Grid",     icon: "\uE9B0" }; // grid_on
            case "C":  return { name: "Columns",           icon: "\uE8EE" }; // view_column
            default:   return { name: (symbol ? (symbol + " Layout") : "Master Tile"), icon: "\uE8F0" };
        }
    }

    function cycleLayout() {
        Quickshell.execDetached(["mmsg", "dispatch", "switch_layout"]);
    }

    function triggerCurrentLayout(targetMonitor) {
        let monName = targetMonitor || root.activeMonitor || (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        let sym = root.monitorLayouts[monName] || "T";
        let tag = root.monitorActiveTags[monName] || 1;
        let meta = getLayoutMeta(sym);
        root.layoutChanged(monName, sym, meta.name, meta.icon, tag);
    }
}
