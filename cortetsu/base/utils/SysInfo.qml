pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string osName
    property string osPrettyName
    property string osId
    property list<string> osIdLike
    property string osLogo: Qt.resolvedUrl(`${Quickshell.shellDir}/assets/logo.svg`)
    property bool isDefaultLogo: true
    property string uptime
    readonly property string user: Quickshell.env("USER")
    readonly property string wm: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP")
    readonly property string shell: (Quickshell.env("SHELL") || "sh").split("/").pop()
    property string kernel
    property string hostname
    property string firmware
    property string boardVendor
    property string boardName
    readonly property string device: !boardName ? boardVendor : (!boardVendor || boardName.toLowerCase().startsWith(boardVendor.toLowerCase()) ? boardName : `${boardVendor} ${boardName}`)

    function sanitiseDmi(value: string): string {
        const text = value.trim(), junk = ["to be filled by o.e.m.", "system product name", "system manufacturer", "system version", "default string", "o.e.m.", "not specified", "not applicable", "unknown", "none", ""];
        return junk.includes(text.toLowerCase()) ? "" : text;
    }
    FileView {
        id: osRelease
        path: "/etc/os-release"
        onLoaded: {
            const lines = text().split("\n"), field = key => lines.find(line => line.startsWith(`${key}=`))?.split("=")[1].replace(/"/g, "") ?? "";
            root.osName = field("NAME"); root.osPrettyName = field("PRETTY_NAME"); root.osId = field("ID"); root.osIdLike = field("ID_LIKE").split(" ");
            const logo = Quickshell.iconPath(field("LOGO"), true);
            if (logo) { root.osLogo = logo; root.isDefaultLogo = false; }
        }
    }
    FileView { path: "/proc/sys/kernel/osrelease"; onLoaded: root.kernel = text().trim() }
    FileView { path: "/proc/sys/kernel/hostname"; onLoaded: root.hostname = text().trim() }
    FileView { path: "/sys/class/dmi/id/sys_vendor"; printErrors: false; onLoaded: root.boardVendor = root.sanitiseDmi(text()) }
    FileView { path: "/sys/class/dmi/id/product_name"; printErrors: false; onLoaded: root.boardName = root.sanitiseDmi(text()) }
    FileView { path: "/sys/class/dmi/id/bios_version"; printErrors: false; onLoaded: root.firmware = root.sanitiseDmi(text()) }
    Timer { running: true; repeat: true; interval: 15000; onTriggered: fileUptime.reload() }
    FileView {
        id: fileUptime
        path: "/proc/uptime"
        onLoaded: {
            const up = parseInt(text().split(" ")[0] ?? 0), days = Math.floor(up / 86400), hours = Math.floor((up % 86400) / 3600), minutes = Math.floor((up % 3600) / 60);
            let result = days ? `${days} day${days === 1 ? "" : "s"}` : "";
            if (hours) result += `${result ? ", " : ""}${hours} hour${hours === 1 ? "" : "s"}`;
            if (minutes || !result) result += `${result ? ", " : ""}${minutes} minute${minutes === 1 ? "" : "s"}`;
            root.uptime = result;
        }
    }
}
