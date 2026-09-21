pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property int tick: 0
    Timer {
        interval: 800
        repeat: true
        running: true
        onTriggered: root.tick++
    }

    // Active player reference (first playing, or first available)
    readonly property var activePlayer: {
        let _ = root.tick;
        let list = Mpris.players ? Mpris.players.values : null;
        if (!list || list.length === 0) return null;

        // 1. Prefer actively playing player with valid track title
        for (let i = 0; i < list.length; i++) {
            let p = list[i];
            if (p && p.isPlaying && p.trackTitle && p.trackTitle.trim().length > 0) return p;
        }
        // 2. Any playing player
        for (let i = 0; i < list.length; i++) {
            let p = list[i];
            if (p && p.isPlaying) return p;
        }
        // 3. Fallback: paused player with track title
        for (let i = 0; i < list.length; i++) {
            let p = list[i];
            if (p && p.playbackState === MprisPlaybackState.Paused && p.trackTitle && p.trackTitle.trim().length > 0) return p;
        }
        // 4. Any paused player
        for (let i = 0; i < list.length; i++) {
            let p = list[i];
            if (p && p.playbackState === MprisPlaybackState.Paused) return p;
        }
        return list[0] || null;
    }

    // Convenience properties
    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.isPlaying
    readonly property bool isPaused: hasPlayer && !isPlaying && (title.length > 0)
    readonly property bool hasMedia: hasPlayer && (isPlaying || (title.length > 0))

    readonly property string title: hasPlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string artist: hasPlayer ? (activePlayer.trackArtist || "") : ""
    readonly property string album: hasPlayer ? (activePlayer.trackAlbum || "") : ""
    readonly property string artUrl: hasPlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property string playerName: hasPlayer ? (activePlayer.identity || "") : ""

    readonly property bool canNext: hasPlayer && activePlayer.canGoNext
    readonly property bool canPrev: hasPlayer && activePlayer.canGoPrevious
    readonly property bool canToggle: hasPlayer && activePlayer.canTogglePlaying
    readonly property bool canSeek: hasPlayer && activePlayer.canSeek

    readonly property string playerIcon: {
        if (!hasPlayer) return "";
        let name = (playerName || "").toLowerCase();
        let candidate = "";
        if (name.includes("brave")) candidate = "brave-desktop";
        else if (name.includes("chrome")) candidate = "google-chrome";
        else if (name.includes("firefox")) candidate = "firefox";
        else if (name.includes("spotify")) candidate = "spotify";
        else if (activePlayer.desktopEntry) candidate = activePlayer.desktopEntry;
        else candidate = name;

        let path = Quickshell.iconPath(candidate, true);
        if (path) return path;
        if (name.includes("brave")) return "file:///usr/share/icons/hicolor/24x24/apps/brave-desktop.png";
        return Quickshell.iconPath("multimedia-audio-player", true) || "";
    }

    readonly property real volume: (hasPlayer && activePlayer.volumeSupported) ? activePlayer.volume : 1.0
    function setVolume(v: real): void {
        if (activePlayer && activePlayer.volumeSupported) {
            activePlayer.volume = Math.max(0.0, Math.min(1.0, v));
        }
    }

    // Position tracking (position and length in seconds/microseconds)
    readonly property double position: {
        let _ = root.tick;
        return (hasPlayer && activePlayer.position) ? activePlayer.position : 0;
    }
    readonly property double length: {
        let _ = root.tick;
        if (!hasPlayer || !activePlayer.lengthSupported || activePlayer.length <= 0) return 0;
        // Chromium/Brave sets mpris:length to INT64_MAX (9223372036854775807) for live streams.
        // Cap valid track lengths to 24 hours (86,400s * 1,000,000µs).
        if (activePlayer.length >= 86400 * 1000000) return 0;
        return activePlayer.length;
    }
    readonly property bool hasLength: length > 0 && !isLive

    // Live stream detection (YouTube Live, Twitch, Radio Streams, etc.)
    readonly property bool isLive: {
        let _ = root.tick;
        if (!hasMedia) return false;
        let t = (title || "").toLowerCase();
        let rawLen = (hasPlayer && activePlayer.lengthSupported && activePlayer.length) ? activePlayer.length : 0;
        // In Chromium/Brave/Firefox, a live stream has duration == Infinity, which MPRIS reports as INT64_MAX or <= 0
        let isIndeterminateLength = rawLen <= 0 || rawLen >= 86400 * 1000000;
        let hasLiveEmoji = (title || "").includes("🔴");
        let hasLiveKeyword = /\b(live|livestream|live\s*stream|siaran\s*langsung|radio|24\/7|stream)\b/i.test(title || "");
        let pName = (playerName || "").toLowerCase();
        let isBrowser = pName.includes("brave") || pName.includes("chrome") || 
                        pName.includes("chromium") || pName.includes("firefox") || 
                        pName.includes("vivaldi") || pName.includes("edge");

        // 1. Explicit live markers: 🔴 or [LIVE] or (LIVE)
        if (hasLiveEmoji || /\[live\]|\(live\)|🔴/i.test(title || "")) return true;

        // 2. Browser stream with indeterminate/infinite length (standard Chromium YouTube live behavior)
        if (isBrowser && isIndeterminateLength) return true;

        // 3. Keyword live/stream/radio combined with indeterminate length
        if (hasLiveKeyword && isIndeterminateLength) return true;

        return false;
    }

    readonly property real progress: {
        if (isLive) return 1.0;
        return (hasLength && length > 0) ? Math.max(0.0, Math.min(1.0, position / length)) : 0.0;
    }

    // Formatted subline (Artist · Album)
    readonly property string subline: {
        if (!hasMedia) return "";
        let parts = [];
        if (artist && artist.trim().length > 0) parts.push(artist.trim());
        if (album && album.trim().length > 0) parts.push(album.trim());
        return parts.join(" · ");
    }

    // Formatted display string for compact view
    readonly property string displayText: {
        if (!hasMedia) return "";
        let t = title || "Unknown";
        let a = artist;
        if (a) return t + " — " + a;
        return t;
    }

    // Helper: format seconds / microseconds to mm:ss
    function formatTime(val): string {
        if (!val || val <= 0) return "0:00";
        // Handle both seconds and microseconds (if > 100000 assume micro)
        let totalSec = Math.floor(val > 100000 ? val / 1000000 : val);
        let mins = Math.floor(totalSec / 60);
        let secs = totalSec % 60;
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    // Controls
    function togglePlay(): void {
        if (activePlayer && activePlayer.canTogglePlaying) {
            activePlayer.togglePlaying();
        }
    }

    function next(): void {
        if (activePlayer && activePlayer.canGoNext) {
            activePlayer.next();
        }
    }

    function previous(): void {
        if (activePlayer && activePlayer.canGoPrevious) {
            activePlayer.previous();
        }
    }

    function seekRatio(fraction: real): void {
        if (!activePlayer || !canSeek || !hasLength) return;
        let targetPos = fraction * length;
        // Quickshell MprisPlayer seek method takes offset, or set position
        try {
            if (activePlayer.positionSupported) {
                activePlayer.position = targetPos;
            } else if (activePlayer.seek) {
                activePlayer.seek(targetPos - activePlayer.position);
            }
        } catch (e) {
            console.warn("Seek failed:", e);
        }
    }
}
