pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../modules"
import "../utils"

Singleton {
    id: root

    enum Backend { Auto, Local, Lrclib, NetEase }

    property list<string> lyrics: []
    property int backend: Backend.Auto
    property int preferredBackend: CortetsuConfig.lyricsBackend
    property list<var> lyricCandidates: []
    property var selectedCandidate: ({ title: "", artist: "", album: "", id: "", backend: Backend.Auto })
    property bool loading: false
    readonly property bool hasLyrics: lyrics.length > 0
    property real offset: 0
    property string trackArtist: ""
    property string trackTitle: ""
    property string trackAlbum: ""
    property real trackDuration: 0
    property list<var> parsedLines: []
    readonly property string lyricsDir: Quickshell.env("CORTETSU_LYRICS_DIR") || `${Paths.home}/Music/Lyrics`

    function backendName(value: int): string {
        return [qsTr("Auto"), qsTr("Local"), "LRCLIB", "NetEase"][value] ?? qsTr("Auto");
    }

    function parseLrc(raw: string): var {
        const result = [];
        for (const line of raw.split("\n")) {
            const tags = [...line.matchAll(/\[(\d+):(\d+(?:\.\d+)?)\]/g)];
            const text = line.replace(/\[[^\]]+\]/g, "").trim();
            for (const tag of tags)
                result.push({ time: Number(tag[1]) * 60 + Number(tag[2]), text });
        }
        result.sort((a, b) => a.time - b.time);
        return result;
    }

    function clearLines(): void {
        root.parsedLines = [];
        root.lyrics = [];
        root.backend = Backend.Auto;
        root.selectedCandidate = ({ title: root.trackTitle, artist: root.trackArtist, album: root.trackAlbum, id: "", backend: Backend.Auto });
    }

    function setParsedLines(raw: string, source: int): void {
        root.parsedLines = parseLrc(raw);
        root.lyrics = root.parsedLines.map(line => line.text);
        root.backend = source;
        root.loading = false;
    }

    function indexForTime(time: real): int {
        const target = time - root.offset + 0.1;
        let low = 0, high = root.parsedLines.length;
        while (low < high) {
            const mid = Math.floor((low + high) / 2);
            if (root.parsedLines[mid].time <= target) low = mid + 1;
            else high = mid;
        }
        return low - 1;
    }

    function timeForIndex(index: int): real {
        return index >= 0 && index < root.parsedLines.length ? root.parsedLines[index].time + root.offset : -1;
    }

    function selectCandidate(candidate: var): void {
        root.selectedCandidate = candidate;
        if (candidate.syncedLyrics) {
            root.setParsedLines(candidate.syncedLyrics, candidate.backend);
            return;
        }
        if (candidate.backend === Backend.Local) {
            localFile.path = candidate.id;
            return;
        }
        const endpoint = candidate.backend === Backend.Lrclib ? `https://lrclib.net/api/get/${encodeURIComponent(candidate.id)}` : "";
        if (!endpoint) {
            root.loading = false;
            return;
        }
        root.loading = true;
        Requests.get(endpoint, root.handleFetch, () => root.loading = false, { "User-Agent": "Cortetsu/1.0" });
    }

    function handleFetch(output: string): void {
        try {
            const payload = JSON.parse(output);
            const text = payload.syncedLyrics || payload.lyrics || "";
            if (text) root.setParsedLines(text, root.selectedCandidate.backend);
            else root.loading = false;
        } catch (error) {
            root.loading = false;
        }
    }

    function searchOnline(): void {
        const query = `https://lrclib.net/api/search?track_name=${encodeURIComponent(root.trackTitle)}&artist_name=${encodeURIComponent(root.trackArtist)}`;
        Requests.get(query, output => {
            try {
                const items = JSON.parse(output).filter(item => item && item.id && item.syncedLyrics).slice(0, 20).map(item => ({
                    id: String(item.id), title: item.trackName || root.trackTitle, artist: item.artistName || root.trackArtist,
                    album: item.albumName || root.trackAlbum, backend: Backend.Lrclib, syncedLyrics: item.syncedLyrics
                }));
                root.lyricCandidates = items;
                if (items.length) root.selectCandidate(items[0]);
                else root.loading = false;
            } catch (error) {
                root.loading = false;
            }
        }, () => root.loading = false, { "User-Agent": "Cortetsu/1.0" });
    }

    function localCandidates(raw: string): void {
        const expected = `${root.trackArtist} - ${root.trackTitle}`.toLowerCase();
        const files = raw.split("\n").map(path => path.trim()).filter(path => path && path.toLowerCase().includes(expected));
        if (files.length) {
            const candidate = { id: files[0], title: root.trackTitle, artist: root.trackArtist, album: root.trackAlbum, backend: Backend.Local };
            root.lyricCandidates = [candidate];
            root.selectCandidate(candidate);
        } else if (root.preferredBackend !== Backend.Local) {
            root.searchOnline();
        } else {
            root.loading = false;
        }
    }

    function setTrack(artist, title, album = "", duration = 0): void {
        if (artist.trim() === root.trackArtist && title.trim() === root.trackTitle && album === root.trackAlbum && duration === root.trackDuration)
            return;
        root.trackArtist = artist.trim();
        root.trackTitle = title.trim();
        root.trackAlbum = album;
        root.trackDuration = duration;
        root.lyricCandidates = [];
        root.clearLines();
        if (!root.trackTitle) {
            root.loading = false;
            return;
        }
        root.loading = true;
        localSearch.running = true;
    }

    function clearTrack(): void {
        localSearch.running = false;
        root.trackArtist = "";
        root.trackTitle = "";
        root.trackAlbum = "";
        root.trackDuration = 0;
        root.lyricCandidates = [];
        root.clearLines();
        root.loading = false;
    }

    function refresh(): void {
        const artist = root.trackArtist, title = root.trackTitle, album = root.trackAlbum, duration = root.trackDuration;
        root.trackArtist = "";
        root.setTrack(artist, title, album, duration);
    }

    onPreferredBackendChanged: {
        if (CortetsuConfig.lyricsBackend !== preferredBackend)
            CortetsuConfig.lyricsBackend = preferredBackend;
    }

    FileView {
        id: localFile
        path: ""
        onLoaded: root.setParsedLines(text(), Backend.Local)
    }

    Process {
        id: localSearch
        command: ["find", root.lyricsDir, "-type", "f", "-iname", "*.lrc", "-print"]
        stdout: StdioCollector { onStreamFinished: root.localCandidates(text) }
    }
}
