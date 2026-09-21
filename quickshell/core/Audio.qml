pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Audio singleton — Pipewire sink/source control
Singleton {
    id: root

    signal triggered()
    signal triggeredMic()

    readonly property bool isPipewireReady: Pipewire.ready

    // Speaker (sink)
    readonly property PwNode sink:     Pipewire.defaultAudioSink
    readonly property int    volLevel: sink?.audio ? Math.min(Math.round(sink.audio.volume * 100), 100) : 0
    readonly property bool   volMuted: sink?.audio?.muted ?? true

    // Mic (source)
    readonly property PwNode source:   Pipewire.defaultAudioSource
    readonly property int    micLevel: source?.audio ? Math.min(Math.round(source.audio.volume * 100), 100) : 0
    readonly property bool   micMuted: source?.audio?.muted ?? true

    // Auto-trigger OSD when volume changes externally (e.g. keyboard via wpctl)
    onVolLevelChanged: triggered()
    onVolMutedChanged: triggered()
    onMicLevelChanged: triggeredMic()
    onMicMutedChanged: triggeredMic()

    PwNodeLinkTracker {
        id: sourceLinks
        node: root.source
        onLinkGroupsChanged: {
            console.log("DEBUG: sourceLinks.linkGroups changed, count =", linkGroups.length)
            for (let i = 0; i < linkGroups.length; i++) {
                let g = linkGroups[i]
                if (g) {
                    console.log("DEBUG: group[" + i + "] state = " + g.state + ", target = " + (g.target ? g.target.name : 'null') + ", source = " + (g.source ? g.source.name : 'null'))
                }
            }
        }
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    function toggleMute() {
        if (sink?.audio) {
            sink.audio.muted = !sink.audio.muted
        }
    }

    function addVolume(delta) {
        if (sink?.audio) {
            let v = sink.audio.volume + delta
            sink.audio.volume = Math.max(0, Math.min(v, 1.5))
        }
    }

    function setVolume(pct) {
        if (sink?.audio) {
            sink.audio.volume = Math.max(0, Math.min(pct / 100.0, 1.5))
        }
    }

    function toggleMicMute() {
        if (source?.audio) source.audio.muted = !source.audio.muted
    }

    function addMicVolume(delta) {
        if (source?.audio) {
            let v = source.audio.volume + delta
            if (delta > 0 && source.audio.muted) {
                source.audio.muted = false
            }
            source.audio.volume = Math.max(0, Math.min(v, 1.5))
        }
    }

    // Set mic volume in percentage (0-150)
    function setMicVolume(pct) {
        if (source?.audio) {
            if (pct > 0 && source.audio.muted) {
                source.audio.muted = false
            }
            source.audio.volume = Math.max(0, Math.min(pct / 100.0, 1.5))
        }
    }

    // Material Symbols Rounded
    readonly property string volIcon: {
        if (!isPipewireReady) return "volume_off"
        if (volMuted || volLevel === 0) return "volume_off"
        if (volLevel < 30)  return "volume_mute"
        if (volLevel < 70)  return "volume_down"
        return "volume_up"
    }

    readonly property string micIcon: micMuted ? "mic_off" : "mic"

    // Check if mic is actively recording (has active pipewire link)
    readonly property bool micActive: sourceLinks.linkGroups && sourceLinks.linkGroups.length > 0

    // Check if camera is actively recording (via uvcvideo refcnt)
    property bool camActive: false

    Timer {
        id: camTimer
        interval: 2000
        running: Pipewire.ready
        repeat: true
        triggeredOnStart: true
        onTriggered: camCheck.running = true
    }

    Process {
        id: camCheck
        command: ["cat", "/sys/module/uvcvideo/refcnt"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim())
                root.camActive = (!isNaN(val) && val > 0)
            }
        }
    }
}
