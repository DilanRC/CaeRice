pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services

Item {
    id: root

    required property var snapshot
    required property var cpuHistory
    required property var memoryHistory
    required property var networkRxHistory
    required property var networkTxHistory
    required property var diskReadHistory
    required property var diskWriteHistory
    required property var gpu0History
    required property var gpu1History

    readonly property var cpu: snapshot?.cpu ?? ({})
    readonly property var memory: snapshot?.memory ?? ({})
    readonly property var network: snapshot?.network ?? ({})
    readonly property var diskIo: snapshot?.disk_io ?? ({})
    readonly property var gpus: snapshot?.gpus ?? []

    function number(value, digits = 1): string {
        if (value === null || value === undefined || isNaN(Number(value)))
            return "—";
        return Number(value).toFixed(digits);
    }

    function pct(value): string {
        return `${number(value, 1)}%`;
    }

    function gpuAt(index): var {
        return index >= 0 && index < gpus.length ? gpus[index] : ({});
    }

    Grid {
        anchors.fill: parent
        columns: 2
        columnSpacing: 12
        rowSpacing: 12

        HistoryGraph {
            width: (parent.width - 12) / 2
            height: (parent.height - 24) / 3
            title: qsTr("CPU history")
            icon: "memory"
            headline: root.pct(root.cpu?.usage)
            subtitle: `${root.number(root.cpu?.temp_c, 1)} °C · ${root.number(root.cpu?.freq_mhz, 0)} MHz · ${root.cpu?.governor ?? "—"}`
            legendA: qsTr("Total CPU")
            seriesA: root.cpuHistory
            maxValue: 100
        }

        HistoryGraph {
            width: (parent.width - 12) / 2
            height: (parent.height - 24) / 3
            title: qsTr("Memory history")
            icon: "developer_board"
            headline: root.pct(root.memory?.usage)
            subtitle: `${root.number(root.memory?.used_gb, 2)} / ${root.number(root.memory?.total_gb, 2)} GiB`
            legendA: qsTr("RAM")
            seriesA: root.memoryHistory
            maxValue: 100
            colourA: Colours.palette.m3secondary
        }

        HistoryGraph {
            width: (parent.width - 12) / 2
            height: (parent.height - 24) / 3
            title: qsTr("Network")
            icon: "wifi"
            headline: `${root.number(root.network?.rx_mbps, 2)} ↓  ${root.number(root.network?.tx_mbps, 2)} ↑ Mb/s`
            subtitle: root.network?.interface ?? "—"
            legendA: qsTr("Download")
            legendB: qsTr("Upload")
            seriesA: root.networkRxHistory
            seriesB: root.networkTxHistory
            colourA: Colours.palette.m3primary
            colourB: Colours.palette.m3tertiary
        }

        HistoryGraph {
            width: (parent.width - 12) / 2
            height: (parent.height - 24) / 3
            title: qsTr("Disk I/O")
            icon: "hard_drive"
            headline: `${root.number(root.diskIo?.read_mib_s, 2)} R · ${root.number(root.diskIo?.write_mib_s, 2)} W MiB/s`
            subtitle: root.diskIo?.device ?? qsTr("Root device")
            legendA: qsTr("Read")
            legendB: qsTr("Write")
            seriesA: root.diskReadHistory
            seriesB: root.diskWriteHistory
            colourA: Colours.palette.m3secondary
            colourB: Colours.palette.m3tertiary
        }

        HistoryGraph {
            width: (parent.width - 12) / 2
            height: (parent.height - 24) / 3
            title: root.gpuAt(0)?.vendor ? `${root.gpuAt(0).vendor} ${qsTr("GPU")}` : qsTr("GPU 1")
            icon: "view_in_ar"
            headline: root.gpus.length > 0 ? root.pct(root.gpuAt(0)?.usage) : qsTr("Not detected")
            subtitle: root.gpus.length > 0
                ? `${root.number(root.gpuAt(0)?.temp_c, 1)} °C · ${root.number(root.gpuAt(0)?.power_w, 1)} W`
                : qsTr("No telemetry")
            legendA: qsTr("GPU usage")
            seriesA: root.gpu0History
            maxValue: 100
            colourA: Colours.palette.m3primary
        }

        HistoryGraph {
            width: (parent.width - 12) / 2
            height: (parent.height - 24) / 3
            title: root.gpuAt(1)?.vendor ? `${root.gpuAt(1).vendor} ${qsTr("GPU")}` : qsTr("GPU 2")
            icon: "sports_esports"
            headline: root.gpus.length > 1 ? root.pct(root.gpuAt(1)?.usage) : qsTr("Not detected")
            subtitle: root.gpus.length > 1
                ? `${root.number(root.gpuAt(1)?.temp_c, 1)} °C · ${root.number(root.gpuAt(1)?.power_w, 1)} W`
                : qsTr("No telemetry")
            legendA: qsTr("GPU usage")
            seriesA: root.gpu1History
            maxValue: 100
            colourA: Colours.palette.m3tertiary
        }
    }
}
