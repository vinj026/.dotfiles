pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// MPRIS media player singleton
Singleton {
    id: root

    readonly property MprisPlayer player: {
        let playersModel = Mpris.players;
        if (!playersModel || !playersModel.values || playersModel.values.length === 0) return null;
        let playersList = playersModel.values;
        for (let i = 0; i < playersList.length; i++) {
            let p = playersList[i];
            if (p && p.playbackState === MprisPlaybackState.Playing) {
                return p;
            }
        }
        return playersList[0] || null;
    }

    readonly property bool hasPlayer:     player !== null
    readonly property bool isPlaying:     player?.playbackState === MprisPlaybackState.Playing ?? false

    function cleanTitle(s) {
        if (!s) return "";
        let t = s.trim();
        t = t.replace(/\s*-\s*YouTube$/, "");
        return t;
    }

    readonly property string title:  cleanTitle(player?.trackTitle ?? "")
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album:  player?.trackAlbum  ?? ""

    // Truncate panjang
    function truncate(s, maxLen) {
        return (s && s.length > maxLen) ? s.slice(0, maxLen - 1) + "…" : (s ?? "")
    }

    readonly property string displayTitle:  truncate(title,  30)
    readonly property string displayArtist: truncate(artist, 20)

    function playPause() { player?.togglePlaying() }
    function next()      { player?.next() }
    function previous()  { player?.previous() }

    readonly property string playIcon: isPlaying ? "pause" : "play_arrow"
}
