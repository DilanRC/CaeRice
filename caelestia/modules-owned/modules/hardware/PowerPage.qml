pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property var power: ({})
    property string statusText: qsTr("Reading power policy…")
    property string pendingProfile: ""

    readonly property string helperPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) +
        "/.local/bin/cortetsu-hardware-power"

    readonly property var profiles: power?.profiles ?? ({})
    readonly property var cpu: power?.cpu ?? ({})
    readonly property var ac: power?.ac ?? ({})
    readonly property var battery: power?.battery ?? ({})
    readonly property var gpus: power?.gpus ?? []

    function number(value, digits = 1): string {
        if (value === null || value === undefined || isNaN(Number(value)))
            return "—";
        return Number(value).toFixed(digits);
    }

    function profileAvailable(name): bool {
        return Array.from(root.profiles?.available ?? []).includes(name);
    }

    function profileLabel(name): string {
        if (name === "power-saver")
            return qsTr("Power saver");
        if (name === "performance")
            return qsTr("Performance");
        if (name === "balanced")
            return qsTr("Balanced");
        return name || qsTr("Unknown");
    }

    function profileIcon(name): string {
        if (name === "power-saver")
            return "eco";
        if (name === "performance")
            return "speed";
        return "balance";
    }

    function refresh(): void {
        if (!powerProbe.running)
            powerProbe.running = true;
    }

    function requestProfile(name): void {
        if (!root.profiles?.can_set || !profileAvailable(name) || root.pendingProfile.length > 0)
            return;
        root.pendingProfile = name;
        root.statusText = qsTr("Applying %1…").arg(profileLabel(name));
        Quickshell.execDetached([root.helperPath, "set-profile", name]);
        refreshAfterAction.restart();
        verifyAction.restart();
    }

    function gpuAt(index): var {
        return index >= 0 && index < gpus.length ? gpus[index] : ({});
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 2500
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshAfterAction
        interval: 900
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: verifyAction
        interval: 2600
        repeat: false
        onTriggered: {
            if (root.pendingProfile.length > 0) {
                root.statusText = qsTr("Profile change could not be verified");
                root.pendingProfile = "";
            }
        }
    }

    Process {
        id: powerProbe
        command: [root.helperPath]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    root.power = parsed;
                    const current = parsed?.profiles?.current ?? "";
                    if (root.pendingProfile.length > 0 && current === root.pendingProfile) {
                        root.statusText = qsTr("Profile applied: %1").arg(root.profileLabel(current));
                        root.pendingProfile = "";
                        verifyAction.stop();
                    } else if (root.pendingProfile.length === 0) {
                        root.statusText = parsed?.profiles?.backend === "powerprofilesctl"
                            ? qsTr("Power Profiles daemon connected")
                            : qsTr("Read-only power telemetry · no profile backend detected");
                    }
                } catch (error) {
                    root.statusText = qsTr("Power telemetry returned invalid JSON");
                    console.warn(`Hardware Center Power: invalid JSON: ${error}`);
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 12

        StyledRect {
            width: parent.width
            height: 158
            radius: Tokens.rounding.extraLarge
            color: Colours.palette.m3surfaceContainer
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            Row {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Column {
                    width: 245
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Row {
                        spacing: 10

                        StyledRect {
                            width: 44
                            height: 44
                            radius: Tokens.rounding.large
                            color: Colours.palette.m3primaryContainer

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "bolt"
                                fill: 1
                                color: Colours.palette.m3onPrimaryContainer
                                fontStyle: Tokens.font.icon.large
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            StyledText {
                                text: qsTr("Power profile")
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.title.medium
                            }

                            StyledText {
                                text: root.profileLabel(root.profiles?.current ?? "")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.medium
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: root.statusText
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }

                Row {
                    id: profileButtons
                    width: parent.width - 261
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Repeater {
                        model: ["power-saver", "balanced", "performance"]

                        delegate: StyledRect {
                            id: profileButton
                            required property string modelData
                            readonly property bool supported: root.profileAvailable(modelData)
                            readonly property bool active: root.profiles?.current === modelData
                            readonly property bool pending: root.pendingProfile === modelData

                            width: (profileButtons.width - profileButtons.spacing * 2) / 3
                            height: 108
                            radius: Tokens.rounding.extraLarge
                            color: active
                                ? Colours.palette.m3secondaryContainer
                                : Colours.palette.m3surfaceContainerHigh
                            border.width: active ? 1 : 0
                            border.color: Colours.palette.m3primary
                            opacity: supported ? 1 : 0.45

                            StateLayer {
                                radius: parent.radius
                                enabled: profileButton.supported && root.profiles?.can_set && root.pendingProfile.length === 0
                                onClicked: root.requestProfile(profileButton.modelData)
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 7

                                MaterialIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: profileButton.pending ? "progress_activity" : root.profileIcon(profileButton.modelData)
                                    fill: profileButton.active ? 1 : 0
                                    color: profileButton.active
                                        ? Colours.palette.m3onSecondaryContainer
                                        : Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.large
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.profileLabel(profileButton.modelData)
                                    color: profileButton.active
                                        ? Colours.palette.m3onSecondaryContainer
                                        : Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.medium
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: profileButton.supported
                                        ? (profileButton.active ? qsTr("Active") : qsTr("Available"))
                                        : qsTr("Unavailable")
                                    color: profileButton.active
                                        ? Colours.palette.m3onSecondaryContainer
                                        : Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                }
                            }
                        }
                    }
                }
            }
        }

        Grid {
            id: powerGrid
            width: parent.width
            height: parent.height - 170
            columns: 2
            columnSpacing: 12
            rowSpacing: 12

            StyledRect {
                width: (powerGrid.width - 12) / 2
                height: (powerGrid.height - 12) / 2
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 11

                    Row {
                        width: parent.width

                        Column {
                            width: parent.width * 0.7
                            spacing: 2

                            StyledText {
                                text: qsTr("CPU policy")
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.title.medium
                            }
                            StyledText {
                                width: parent.width
                                text: root.cpu?.driver ?? qsTr("Unknown driver")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        StyledText {
                            width: parent.width * 0.3
                            text: root.cpu?.current_mhz
                                ? `${root.number(Number(root.cpu.current_mhz) / 1000, 2)} GHz`
                                : "—"
                            color: Colours.palette.m3primary
                            font: Tokens.font.title.small
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Repeater {
                        model: [
                            { label: qsTr("Governor"), value: root.cpu?.governor ?? "—" },
                            { label: qsTr("Energy preference"), value: root.cpu?.epp || "—" },
                            { label: qsTr("Frequency range"), value: root.cpu?.min_mhz && root.cpu?.max_mhz ? `${root.number(root.cpu.min_mhz / 1000, 2)}–${root.number(root.cpu.max_mhz / 1000, 2)} GHz` : "—" },
                            { label: qsTr("Platform profile"), value: root.cpu?.platform_profile || qsTr("Not exposed") }
                        ]

                        delegate: Row {
                            required property var modelData
                            width: parent.width
                            height: 25

                            StyledText {
                                width: parent.width * 0.43
                                text: modelData.label
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                            }
                            StyledText {
                                width: parent.width * 0.57
                                text: modelData.value
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.medium
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: root.cpu?.epp_choices?.length
                            ? `${qsTr("EPP exposed")}: ${root.cpu.epp_choices.join(" · ")}`
                            : qsTr("EPP choices are not exposed by the active CPU driver.")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }
            }

            StyledRect {
                width: (powerGrid.width - 12) / 2
                height: (powerGrid.height - 12) / 2
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Row {
                        width: parent.width

                        Column {
                            width: parent.width * 0.7
                            spacing: 2

                            StyledText {
                                text: qsTr("Power source")
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.title.medium
                            }
                            StyledText {
                                text: root.ac?.online ? qsTr("AC adapter connected") : qsTr("Running on battery")
                                color: root.ac?.online ? Colours.palette.m3primary : Colours.palette.m3tertiary
                                font: Tokens.font.label.medium
                            }
                        }

                        MaterialIcon {
                            width: parent.width * 0.3
                            text: root.ac?.online ? "power" : "battery_5_bar"
                            color: root.ac?.online ? Colours.palette.m3primary : Colours.palette.m3tertiary
                            fontStyle: Tokens.font.icon.extraLarge
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Repeater {
                        model: [
                            { label: qsTr("Battery"), value: root.battery?.present ? `${root.number(root.battery?.percent, 0)}% · ${root.battery?.status ?? "—"}` : qsTr("Not detected") },
                            { label: qsTr("Current draw"), value: root.battery?.power_w !== null && root.battery?.power_w !== undefined ? `${root.number(root.battery.power_w, 1)} W` : "—" },
                            { label: qsTr("Full capacity"), value: root.battery?.energy_full_wh !== null && root.battery?.energy_full_wh !== undefined ? `${root.number(root.battery.energy_full_wh, 1)} Wh` : "—" },
                            { label: qsTr("Battery health"), value: root.battery?.health_percent !== null && root.battery?.health_percent !== undefined ? `${root.number(root.battery.health_percent, 1)}%` : "—" }
                        ]

                        delegate: Row {
                            required property var modelData
                            width: parent.width
                            height: 25

                            StyledText {
                                width: parent.width * 0.48
                                text: modelData.label
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                            }
                            StyledText {
                                width: parent.width * 0.52
                                text: modelData.value
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.medium
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            Repeater {
                model: [root.gpuAt(0), root.gpuAt(1)]

                delegate: StyledRect {
                    required property var modelData
                    required property int index
                    width: (powerGrid.width - 12) / 2
                    height: (powerGrid.height - 12) / 2
                    radius: Tokens.rounding.extraLarge
                    color: Colours.palette.m3surfaceContainer
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                        Row {
                            width: parent.width

                            StyledRect {
                                width: 42
                                height: 42
                                radius: Tokens.rounding.large
                                color: Colours.palette.m3secondaryContainer

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: index === 0 ? "view_in_ar" : "sports_esports"
                                    color: Colours.palette.m3onSecondaryContainer
                                    fontStyle: Tokens.font.icon.large
                                }
                            }

                            Column {
                                width: parent.width - 54
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                StyledText {
                                    width: parent.width
                                    text: modelData?.vendor
                                        ? `${modelData.vendor} ${qsTr("GPU power")}`
                                        : qsTr("GPU power")
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.title.small
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    width: parent.width
                                    text: modelData?.name ?? modelData?.card ?? qsTr("No telemetry")
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Repeater {
                            model: modelData?.vendor === "NVIDIA"
                                ? [
                                    { label: qsTr("P-state"), value: modelData?.pstate ?? "—" },
                                    { label: qsTr("Power"), value: modelData?.power_w !== null && modelData?.power_w !== undefined ? `${root.number(modelData.power_w, 1)} / ${root.number(modelData.power_limit_w, 1)} W` : "—" },
                                    { label: qsTr("Graphics clock"), value: modelData?.graphics_clock_mhz !== null && modelData?.graphics_clock_mhz !== undefined ? `${root.number(modelData.graphics_clock_mhz, 0)} MHz` : "—" },
                                    { label: qsTr("Temperature"), value: modelData?.temp_c !== null && modelData?.temp_c !== undefined ? `${root.number(modelData.temp_c, 1)} °C` : "—" }
                                ]
                                : [
                                    { label: qsTr("Performance level"), value: modelData?.performance_level || "—" },
                                    { label: qsTr("Power state"), value: modelData?.power_state || "—" },
                                    { label: qsTr("Runtime"), value: modelData?.runtime_status || "—" },
                                    { label: qsTr("Power / temp"), value: modelData?.power_w !== null && modelData?.power_w !== undefined ? `${root.number(modelData.power_w, 1)} W · ${root.number(modelData.temp_c, 1)} °C` : "—" }
                                ]

                            delegate: Row {
                                required property var modelData
                                width: parent.width
                                height: 24

                                StyledText {
                                    width: parent.width * 0.48
                                    text: modelData.label
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                }
                                StyledText {
                                    width: parent.width * 0.52
                                    text: modelData.value
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.medium
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideLeft
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
