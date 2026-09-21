// DeviceStats.qml — System resources statistics singleton (CPU, RAM)
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuPercent: 0
    property real ramPercent: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property int cpuTemp: 0
    property int retainCount: 0

    function refresh() {
        if (!statsTask.running) statsTask.running = true;
    }

    // Keep CPU and Memory stats updated only when the Control Center is open
    function retain() {
        retainCount += 1;
        pollTimer.running = true;
        refresh();
    }

    function release() {
        retainCount = Math.max(0, retainCount - 1);
        if (retainCount === 0) pollTimer.running = false;
    }

    Process {
        id: statsTask
        running: false
        command: ["sh", "-c",
            "read _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat; " +
            "t1=$((u1+n1+s1+i1+w1+q1+sq1+st1)); id1=$((i1+w1)); " +
            "sleep 0.2; " +
            "read _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat; " +
            "t2=$((u2+n2+s2+i2+w2+q2+sq2+st2)); id2=$((i2+w2)); " +
            "dt=$((t2-t1)); di=$((id2-id1)); " +
            "if [ \"$dt\" -gt 0 ]; then cpu=$(( (1000*(dt-di)/dt + 5)/10 )); else cpu=0; fi; " +
            "mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo); " +
            "mem_avail=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo); " +
            "mem_used=$((mem_total-mem_avail)); " +
            "if [ -f /sys/class/thermal/thermal_zone0/temp ]; then temp=$(cat /sys/class/thermal/thermal_zone0/temp); else temp=0; fi; " +
            "printf 'CPU %s\\n' \"$cpu\"; " +
            "printf 'RAM_USED_KB %s\\n' \"$mem_used\"; " +
            "printf 'RAM_TOTAL_KB %s\\n' \"$mem_total\"; " +
            "printf 'TEMP %s\\n' \"$temp\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let usedKb = 0;
                let totalKb = 0;
                let tempRaw = 0;
                const lines = text.split("\n");
                for (const line of lines) {
                    if (line.startsWith("CPU ")) {
                        root.cpuPercent = Math.max(0, Math.min(100, parseFloat(line.slice(4)) || 0));
                    } else if (line.startsWith("RAM_USED_KB ")) {
                        usedKb = parseFloat(line.slice(12)) || 0;
                    } else if (line.startsWith("RAM_TOTAL_KB ")) {
                        totalKb = parseFloat(line.slice(13)) || 0;
                    } else if (line.startsWith("TEMP ")) {
                        tempRaw = parseFloat(line.slice(5)) || 0;
                    }
                }

                root.ramUsedGb = usedKb / (1024.0 * 1024.0);
                root.ramTotalGb = totalKb / (1024.0 * 1024.0);
                root.ramPercent = totalKb > 0 ? Math.max(0, Math.min(100, (usedKb / totalKb) * 100.0)) : 0;
                root.cpuTemp = Math.round(tempRaw / 1000.0);
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 2000
        running: false
        repeat: true
        onTriggered: root.refresh()
    }
}
