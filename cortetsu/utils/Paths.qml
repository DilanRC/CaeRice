pragma Singleton

import QtQuick
import Quickshell
import "../modules"

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || `${home}/Pictures`
    readonly property string videos: Quickshell.env("XDG_VIDEOS_DIR") || `${home}/Videos`
    readonly property string data: `${Quickshell.env("XDG_DATA_HOME") || `${home}/.local/share`}/cortetsu`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`}/cortetsu`
    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/cortetsu`
    readonly property string config: `${Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`}/cortetsu`
    readonly property string imagecache: `${cache}/imagecache`
    readonly property string notifimagecache: `${imagecache}/notifs`
    readonly property string wallsdir: Quickshell.env("CORTETSU_WALLPAPERS_DIR") || absolutePath(CortetsuConfig.wallpaperDirectory)
    readonly property string recsdir: Quickshell.env("CORTETSU_RECORDINGS_DIR") || `${videos}/Recordings`
    readonly property string libdir: `${data}/lib`
    readonly property string noNotifsPic: Quickshell.shellPath("assets/dino.png")
    readonly property string lockNoNotifsPic: noNotifsPic

    function toLocalFile(path: url): string {
        const resolved = String(Qt.resolvedUrl(path));
        return resolved.startsWith("file://") ? decodeURIComponent(resolved.slice(7)) : resolved;
    }

    function absolutePath(path: string): string {
        return path.replace(/~|\$({?)HOME(}?)/g, home);
    }

    function shortenHome(path: string): string {
        return path.startsWith(home) ? `~${path.slice(home.length)}` : path;
    }
}
