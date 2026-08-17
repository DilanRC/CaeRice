pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property var processes

    property string filterText: ""
    property string sortKey: "cpu"
    property bool sortDescending: true
    property bool paused: false
    property var frozenProcesses: []
    property int selectedPid: -1
    property string actionStatus: ""

    readonly property var sourceProcesses: paused ? frozenProcesses : processes
    readonly property var visibleProcesses: buildProcesses(sourceProcesses)
    readonly property var selectedProcess: findSelected()

    function buildProcesses(source): var {
        const query = filterText.trim().toLowerCase();
        let result = Array.from(source ?? []);
        if (query.length > 0) {
            const terms = query.split(/\s+/).filter(t => t.length > 0);
            result = result.filter(p => {
                const haystack = `${p?.name ?? ""} ${p?.user ?? ""} ${p?.command ?? ""} ${p?.pid ?? ""}`.toLowerCase();
                return terms.every(term => haystack.includes(term));
            });
        }

        result.sort((a, b) => {
            let left = a?.[sortKey] ?? 0;
            let right = b?.[sortKey] ?? 0;
            if (sortKey === "name" || sortKey === "user") {
                left = String(left).toLowerCase();
                right = String(right).toLowerCase();
                const cmp = left.localeCompare(right);
                return sortDescending ? -cmp : cmp;
            }
            const cmp = Number(left) - Number(right);
            return sortDescending ? -cmp : cmp;
        });
        return result;
    }

    function findSelected(): var {
        const source = visibleProcesses ?? [];
        for (const proc of source) {
            if (Number(proc?.pid) === selectedPid)
                return proc;
        }
        return source.length > 0 ? source[0] : ({});
    }

    function setSort(key): void {
        if (sortKey === key)
            sortDescending = !sortDescending;
        else {
            sortKey = key;
            sortDescending = key !== "name" && key !== "user";
        }
    }

    function togglePause(): void {
        if (!paused)
            frozenProcesses = Array.from(processes ?? []);
        paused = !paused;
    }

    function sendSignal(signal): void {
        const pid = Number(selectedProcess?.pid ?? -1);
        if (pid <= 1)
            return;
        Quickshell.execDetached(["kill", `-${signal}`, String(pid)]);
        actionStatus = `${signal} → PID ${pid}`;
    }

    onVisibleProcessesChanged: {
        if (visibleProcesses.length === 0) {
            selectedPid = -1;
            return;
        }
        if (!visibleProcesses.some(p => Number(p?.pid) === selectedPid))
            selectedPid = Number(visibleProcesses[0]?.pid ?? -1);
    }

    Row {
        anchors.fill: parent
        spacing: 12

        StyledRect {
            id: listCard
            width: parent.width * 0.66
            height: parent.height
            radius: Tokens.rounding.extraLarge
            color: Colours.palette.m3surfaceContainer
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Row {
                    width: parent.width
                    height: 42
                    spacing: 9

                    StyledRect {
                        width: parent.width - sortControls.width - pauseButton.width - 18
                        height: 42
                        radius: Tokens.rounding.large
                        color: Colours.palette.m3surfaceContainerHigh
                        border.width: searchInput.activeFocus ? 1 : 0
                        border.color: Colours.palette.m3primary

                        MaterialIcon {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "search"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }

                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: 42
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text.length === 0
                            text: qsTr("Filter processes…")
                            color: Colours.palette.m3outline
                            font: Tokens.font.body.medium
                        }

                        TextInput {
                            id: searchInput
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 42
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            verticalAlignment: TextInput.AlignVCenter
                            color: Colours.palette.m3onSurface
                            selectionColor: Colours.palette.m3primary
                            selectedTextColor: Colours.palette.m3onPrimary
                            font.pixelSize: 15
                            text: root.filterText
                            onTextChanged: root.filterText = text
                        }
                    }

                    Row {
                        id: sortControls
                        spacing: 5

                        Repeater {
                            model: [
                                { label: "CPU", key: "cpu" },
                                { label: "RAM", key: "mem" },
                                { label: "PID", key: "pid" }
                            ]

                            delegate: StyledRect {
                                required property var modelData
                                width: 54
                                height: 42
                                radius: Tokens.rounding.large
                                color: root.sortKey === modelData.key
                                    ? Colours.palette.m3secondaryContainer
                                    : Colours.palette.m3surfaceContainerHigh

                                StateLayer {
                                    radius: parent.radius
                                    onClicked: root.setSort(modelData.key)
                                }

                                StyledText {
                                    anchors.centerIn: parent
                                    text: `${modelData.label}${root.sortKey === modelData.key ? (root.sortDescending ? " ↓" : " ↑") : ""}`
                                    color: root.sortKey === modelData.key
                                        ? Colours.palette.m3onSecondaryContainer
                                        : Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                }
                            }
                        }
                    }

                    StyledRect {
                        id: pauseButton
                        width: 44
                        height: 42
                        radius: Tokens.rounding.large
                        color: root.paused
                            ? Colours.palette.m3tertiaryContainer
                            : Colours.palette.m3surfaceContainerHigh

                        StateLayer {
                            radius: parent.radius
                            onClicked: root.togglePause()
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: root.paused ? "play_arrow" : "pause"
                            color: root.paused
                                ? Colours.palette.m3onTertiaryContainer
                                : Colours.palette.m3onSurfaceVariant
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 26

                    StyledText {
                        width: parent.width * 0.43
                        text: qsTr("Process")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                    StyledText {
                        width: parent.width * 0.17
                        text: qsTr("User")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                    StyledText {
                        width: parent.width * 0.12
                        text: qsTr("PID")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        horizontalAlignment: Text.AlignRight
                    }
                    StyledText {
                        width: parent.width * 0.14
                        text: qsTr("CPU")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        horizontalAlignment: Text.AlignRight
                    }
                    StyledText {
                        width: parent.width * 0.14
                        text: qsTr("RAM")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        horizontalAlignment: Text.AlignRight
                    }
                }

                ListView {
                    id: processList
                    width: parent.width
                    height: parent.height - 88
                    clip: true
                    spacing: 3
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.visibleProcesses

                    delegate: StyledRect {
                        id: processRow
                        required property var modelData
                        required property int index
                        width: processList.width
                        height: 36
                        radius: Tokens.rounding.medium
                        color: Number(modelData?.pid) === root.selectedPid
                            ? Colours.palette.m3secondaryContainer
                            : (index % 2 === 0
                                ? Colours.palette.m3surfaceContainerLow
                                : Colours.palette.m3surfaceContainer)

                        StateLayer {
                            radius: parent.radius
                            onClicked: root.selectedPid = Number(processRow.modelData?.pid ?? -1)
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.43
                                text: processRow.modelData?.name ?? "—"
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.17
                                text: processRow.modelData?.user ?? "—"
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.12
                                text: String(processRow.modelData?.pid ?? "—")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                horizontalAlignment: Text.AlignRight
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.14
                                text: `${Number(processRow.modelData?.cpu ?? 0).toFixed(1)}%`
                                color: Number(processRow.modelData?.cpu ?? 0) >= 50
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                horizontalAlignment: Text.AlignRight
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.14
                                text: `${Number(processRow.modelData?.mem ?? 0).toFixed(1)}%`
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }
        }

        StyledRect {
            id: details
            width: parent.width - listCard.width - 12
            height: parent.height
            radius: Tokens.rounding.extraLarge
            color: Colours.palette.m3surfaceContainer
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Row {
                    width: parent.width
                    spacing: 10

                    StyledRect {
                        width: 44
                        height: 44
                        radius: Tokens.rounding.large
                        color: Colours.palette.m3primaryContainer

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "terminal"
                            color: Colours.palette.m3onPrimaryContainer
                            fontStyle: Tokens.font.icon.large
                        }
                    }

                    Column {
                        width: parent.width - 54
                        spacing: 1

                        StyledText {
                            width: parent.width
                            text: root.selectedProcess?.name ?? qsTr("No process selected")
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.title.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            width: parent.width
                            text: root.selectedProcess?.pid
                                ? `PID ${root.selectedProcess.pid} · ${root.selectedProcess?.user ?? "—"}`
                                : ""
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.medium
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 104
                    radius: Tokens.rounding.large
                    color: Colours.palette.m3surfaceContainerHigh

                    StyledText {
                        anchors.fill: parent
                        anchors.margins: 12
                        text: root.selectedProcess?.command ?? qsTr("Select a process to inspect its command line.")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        wrapMode: Text.WrapAnywhere
                        elide: Text.ElideRight
                        maximumLineCount: 5
                    }
                }

                Repeater {
                    model: [
                        { label: qsTr("CPU"), value: root.selectedProcess?.cpu !== undefined ? `${Number(root.selectedProcess.cpu).toFixed(1)}%` : "—" },
                        { label: qsTr("Memory"), value: root.selectedProcess?.mem !== undefined ? `${Number(root.selectedProcess.mem).toFixed(1)}%` : "—" },
                        { label: qsTr("State"), value: root.selectedProcess?.state ?? "—" },
                        { label: qsTr("Threads"), value: String(root.selectedProcess?.threads ?? "—") },
                        { label: qsTr("Parent PID"), value: String(root.selectedProcess?.ppid ?? "—") },
                        { label: qsTr("Elapsed"), value: root.selectedProcess?.elapsed_sec !== undefined ? `${Math.floor(Number(root.selectedProcess.elapsed_sec) / 60)}m` : "—" }
                    ]

                    delegate: Row {
                        required property var modelData
                        width: parent.width
                        height: 23

                        StyledText {
                            width: parent.width * 0.46
                            text: modelData.label
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }

                        StyledText {
                            width: parent.width * 0.54
                            text: modelData.value
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideLeft
                        }
                    }
                }

                Item {
                    width: 1
                    height: Math.max(0, parent.height - 390)
                }

                StyledText {
                    width: parent.width
                    text: root.actionStatus.length > 0
                        ? root.actionStatus
                        : qsTr("Process controls send Unix signals directly.")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    spacing: 8

                    StyledRect {
                        width: (parent.width - 8) / 2
                        height: 42
                        radius: Tokens.rounding.large
                        color: Colours.palette.m3secondaryContainer

                        StateLayer {
                            radius: parent.radius
                            onClicked: root.sendSignal("TERM")
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: qsTr("Terminate")
                            color: Colours.palette.m3onSecondaryContainer
                            font: Tokens.font.label.medium
                        }
                    }

                    StyledRect {
                        width: (parent.width - 8) / 2
                        height: 42
                        radius: Tokens.rounding.large
                        color: Colours.palette.m3errorContainer

                        StateLayer {
                            radius: parent.radius
                            onClicked: root.sendSignal("KILL")
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: qsTr("Kill")
                            color: Colours.palette.m3onErrorContainer
                            font: Tokens.font.label.medium
                        }
                    }
                }
            }
        }
    }
}
