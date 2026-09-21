pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isRecording: false
    property int elapsedSeconds: 0
    property string recordingTimeStr: "00:00"
    property bool recordAudio: true
    property string recordMode: "region" // "region" | "fullscreen"
    property string lastSavedFile: ""

    Timer {
        id: recordTimer
        interval: 1000
        repeat: true
        running: root.isRecording
        onTriggered: {
            root.elapsedSeconds++;
            let mins = Math.floor(root.elapsedSeconds / 60);
            let secs = root.elapsedSeconds % 60;
            root.recordingTimeStr = (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs;
        }
    }

    // Process to check if wf-recorder is already running
    Process {
        id: checkProc
        command: ["pgrep", "-x", "wf-recorder"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim().length > 0) {
                    root.isRecording = true;
                }
            }
        }
    }

    Component.onCompleted: {
        checkProc.running = true;
    }

    function toggleRecording(): void {
        if (root.isRecording) {
            stopRecording();
        } else {
            startRecording(root.recordMode);
        }
    }

    function startRecording(mode: string): void {
        if (root.isRecording) return;
        root.recordMode = mode || "region";

        let dateStr = Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmss");
        let outFile = "/home/vin/Videos/recording_" + dateStr + ".mp4";
        root.lastSavedFile = outFile;
        root.elapsedSeconds = 0;
        root.recordingTimeStr = "00:00";

        let audioFlag = root.recordAudio ? "--audio" : "";
        let script = "";

        if (root.recordMode === "region") {
            script = "GEOM=$(slurp) || exit 1\n" +
                     "if [ -n \"$GEOM\" ]; then\n" +
                     "  exec wf-recorder " + audioFlag + " -g \"$GEOM\" -f \"" + outFile + "\"\n" +
                     "fi\n";
        } else {
            script = "exec wf-recorder " + audioFlag + " -f \"" + outFile + "\"\n";
        }

        let launcher = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        launcher.command = ["bash", "-c", script];
        launcher.running = true;
        root.isRecording = true;

        launcher.exited.connect((exitCode, exitStatus) => {
            root.isRecording = false;
            launcher.destroy();
        });
    }

    function stopRecording(): void {
        Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"]);
        root.isRecording = false;
    }
}
