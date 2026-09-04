pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property var automation: ({})
    property string statusText: qsTr("Reading automation state…")
    property var controlArgs: []
    property bool actionBusy: false

    readonly property string controlPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) +
        "/.local/bin/cortetsu-power-auto-control"

    readonly property var config: automation?.config ?? ({})
    readonly property var service: automation?.service ?? ({})
    readonly property var last: automation?.last ?? ({})
    readonly property var events: automation?.events ?? []

    function profileLabel(name): string {
        if (name === "power-saver") return qsTr("Power saver");
        if (name === "performance") return qsTr("Performance");
        if (name === "balanced") return qsTr("Balanced");
        return qsTr("Unknown");
    }

    function profileIcon(name): string {
        if (name === "power-saver") return "eco";
        if (name === "performance") return "speed";
        return "balance";
    }

    function sourceLabel(event): string {
        if (event?.source === "ac") return qsTr("AC");
        if (event?.source === "battery") return qsTr("Battery");
        return "—";
    }

    function timeText(timestamp): string {
        if (!timestamp)
            return "—";
        const d = new Date(Number(timestamp) * 1000);
        return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}:${String(d.getSeconds()).padStart(2, "0")}`;
    }

    function refresh(): void {
        if (!statusProbe.running && !root.actionBusy)
            statusProbe.running = true;
    }

    function runControl(args, message): void {
        if (root.actionBusy)
            return;
        root.controlArgs = Array.from(args);
        root.actionBusy = true;
        root.statusText = message || qsTr("Applying change…");
        controlProcess.running = true;
    }

    function setProfile(slot, profile): void {
        runControl(["set-profile", slot, profile], qsTr("Updating automatic profile…"));
    }

    function threshold(delta): void {
        const current = Number(config?.low_battery_threshold ?? 25);
        runControl(
            ["set-threshold", String(Math.max(5, Math.min(80, current + delta)))],
            qsTr("Updating low-battery threshold…")
        );
    }

    function updateFromResult(parsed): void {
        if (parsed?.config !== undefined)
            root.automation = parsed;
        else
            root.refresh();

        if (parsed?.ok === false)
            root.statusText = parsed?.error ? String(parsed.error) : qsTr("Action failed");
        else if (parsed?.service?.active)
            root.statusText = qsTr("Automation service active");
        else if (parsed?.config?.enabled)
            root.statusText = qsTr("Automation enabled but service is not active");
        else
            root.statusText = qsTr("Automation disabled · no background watcher");
    }

    Component.onCompleted: { if (root.visible) refresh(); }
    onVisibleChanged: { if (visible) refresh(); }

    Timer {
        interval: 3500
        repeat: true
        running: root.visible
        onTriggered: root.refresh()
    }

    Process {
        id: statusProbe
        command: [root.controlPath, "status"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    root.automation = parsed;
                    root.statusText = parsed?.service?.active
                        ? qsTr("Automation service active")
                        : (parsed?.config?.enabled
                            ? qsTr("Automation enabled but service is not active")
                            : qsTr("Automation disabled · no background watcher"));
                } catch (error) {
                    root.statusText = qsTr("Automation status unavailable");
                }
            }
        }
    }

    Process {
        id: controlProcess
        command: [root.controlPath].concat(root.controlArgs)

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.updateFromResult(JSON.parse(text.trim()));
                } catch (error) {
                    root.statusText = qsTr("Automation action returned invalid output");
                }
                root.actionBusy = false;
                refreshAfterAction.restart();
            }
        }
    }

    Timer {
        id: refreshAfterAction
        interval: 450
        repeat: false
        onTriggered: root.refresh()
    }

    Column {
        anchors.fill: parent
        spacing: 12

        StyledRect {
            width: parent.width
            height: 126
            radius: Tokens.rounding.extraLarge
            color: Colours.palette.m3surfaceContainer
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            Row {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 18

                StyledRect {
                    width: 52
                    height: 52
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Tokens.rounding.extraLarge
                    color: config?.enabled
                        ? Colours.palette.m3primaryContainer
                        : Colours.palette.m3surfaceContainerHighest

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.actionBusy ? "progress_activity" : "auto_mode"
                        fill: config?.enabled ? 1 : 0
                        color: config?.enabled
                            ? Colours.palette.m3onPrimaryContainer
                            : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }
                }

                Column {
                    width: parent.width - 52 - toggleButton.width - 54
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    StyledText {
                        text: qsTr("Automatic power profiles")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.medium
                    }

                    StyledText {
                        width: parent.width
                        text: qsTr("AC, battery and low-battery rules. Disabled means no background watcher is running.")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        width: parent.width
                        text: root.statusText
                        color: service?.active ? Colours.palette.m3primary : Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    id: toggleButton
                    width: 142
                    height: 48
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Tokens.rounding.large
                    color: config?.enabled
                        ? Colours.palette.m3secondaryContainer
                        : Colours.palette.m3surfaceContainerHighest
                    border.width: config?.enabled ? 1 : 0
                    border.color: Colours.palette.m3primary
                    opacity: root.actionBusy ? 0.55 : 1

                    StateLayer {
                        radius: parent.radius
                        enabled: !root.actionBusy
                        onClicked: root.runControl(
                            ["set-enabled", config?.enabled ? "false" : "true"],
                            config?.enabled ? qsTr("Stopping automation…") : qsTr("Starting automation…")
                        )
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 7
                        MaterialIcon {
                            text: config?.enabled ? "toggle_on" : "toggle_off"
                            color: config?.enabled
                                ? Colours.palette.m3onSecondaryContainer
                                : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }
                        StyledText {
                            text: config?.enabled ? qsTr("Enabled") : qsTr("Disabled")
                            color: config?.enabled
                                ? Colours.palette.m3onSecondaryContainer
                                : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.medium
                        }
                    }
                }
            }
        }

        Grid {
            id: scenarioGrid
            width: parent.width
            height: 192
            columns: 2
            columnSpacing: 12

            Repeater {
                model: [
                    {
                        title: qsTr("On AC power"),
                        subtitle: qsTr("External power source online"),
                        icon: "power",
                        slot: "ac",
                        value: config?.ac_profile ?? "performance"
                    },
                    {
                        title: qsTr("On battery"),
                        subtitle: qsTr("Normal battery rule above the low threshold"),
                        icon: "battery_5_bar",
                        slot: "battery",
                        value: config?.battery_profile ?? "balanced"
                    }
                ]

                delegate: StyledRect {
                    id: scenarioCard
                    required property var modelData
                    width: (scenarioGrid.width - 12) / 2
                    height: scenarioGrid.height
                    radius: Tokens.rounding.extraLarge
                    color: Colours.palette.m3surfaceContainer
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 11

                        Row {
                            width: parent.width
                            spacing: 10

                            StyledRect {
                                width: 42
                                height: 42
                                radius: Tokens.rounding.large
                                color: Colours.palette.m3secondaryContainer
                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: scenarioCard.modelData.icon
                                    color: Colours.palette.m3onSecondaryContainer
                                    fontStyle: Tokens.font.icon.large
                                }
                            }

                            Column {
                                width: parent.width - 52
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                StyledText {
                                    text: scenarioCard.modelData.title
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.title.small
                                }
                                StyledText {
                                    width: parent.width
                                    text: scenarioCard.modelData.subtitle
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: ["power-saver", "balanced", "performance"]

                                delegate: StyledRect {
                                    id: profileChoice
                                    required property string modelData
                                    readonly property bool active: modelData === scenarioCard.modelData.value
                                    width: (parent.width - 16) / 3
                                    height: 78
                                    radius: Tokens.rounding.large
                                    color: active
                                        ? Colours.palette.m3secondaryContainer
                                        : Colours.palette.m3surfaceContainerHigh
                                    border.width: active ? 1 : 0
                                    border.color: Colours.palette.m3primary

                                    StateLayer {
                                        radius: parent.radius
                                        enabled: !root.actionBusy
                                        onClicked: root.setProfile(scenarioCard.modelData.slot, profileChoice.modelData)
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 5
                                        MaterialIcon {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.profileIcon(profileChoice.modelData)
                                            fill: profileChoice.active ? 1 : 0
                                            color: profileChoice.active
                                                ? Colours.palette.m3onSecondaryContainer
                                                : Colours.palette.m3onSurfaceVariant
                                            fontStyle: Tokens.font.icon.medium
                                        }
                                        StyledText {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.profileLabel(profileChoice.modelData)
                                            color: profileChoice.active
                                                ? Colours.palette.m3onSecondaryContainer
                                                : Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.label.small
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Grid {
            width: parent.width
            height: parent.height - 342
            columns: 2
            columnSpacing: 12

            StyledRect {
                width: (parent.width - 12) / 2
                height: parent.height
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 11

                    Row {
                        width: parent.width

                        Column {
                            width: parent.width - lowToggle.width - 12
                            spacing: 2
                            StyledText {
                                text: qsTr("Low battery override")
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.title.small
                            }
                            StyledText {
                                width: parent.width
                                text: qsTr("A separate profile can take over below the selected threshold.")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                wrapMode: Text.WordWrap
                            }
                        }

                        StyledRect {
                            id: lowToggle
                            width: 90
                            height: 38
                            radius: Tokens.rounding.large
                            color: config?.low_battery_enabled
                                ? Colours.palette.m3secondaryContainer
                                : Colours.palette.m3surfaceContainerHigh
                            StateLayer {
                                radius: parent.radius
                                enabled: !root.actionBusy
                                onClicked: root.runControl(
                                    ["set-low-enabled", config?.low_battery_enabled ? "false" : "true"],
                                    qsTr("Updating low-battery rule…")
                                )
                            }
                            StyledText {
                                anchors.centerIn: parent
                                text: config?.low_battery_enabled ? qsTr("Enabled") : qsTr("Off")
                                color: config?.low_battery_enabled
                                    ? Colours.palette.m3onSecondaryContainer
                                    : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 46
                        spacing: 8

                        StyledRect {
                            width: 46
                            height: 46
                            radius: Tokens.rounding.large
                            color: Colours.palette.m3surfaceContainerHigh
                            StateLayer { radius: parent.radius; enabled: !root.actionBusy; onClicked: root.threshold(-5) }
                            MaterialIcon { anchors.centerIn: parent; text: "remove"; color: Colours.palette.m3onSurfaceVariant }
                        }
                        Column {
                            width: parent.width - 108
                            anchors.verticalCenter: parent.verticalCenter
                            StyledText {
                                width: parent.width
                                text: `${Number(config?.low_battery_threshold ?? 25)}%`
                                color: Colours.palette.m3primary
                                font: Tokens.font.title.medium
                                horizontalAlignment: Text.AlignHCenter
                            }
                            StyledText {
                                width: parent.width
                                text: qsTr("low-battery threshold")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        StyledRect {
                            width: 46
                            height: 46
                            radius: Tokens.rounding.large
                            color: Colours.palette.m3surfaceContainerHigh
                            StateLayer { radius: parent.radius; enabled: !root.actionBusy; onClicked: root.threshold(5) }
                            MaterialIcon { anchors.centerIn: parent; text: "add"; color: Colours.palette.m3onSurfaceVariant }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: ["power-saver", "balanced", "performance"]
                            delegate: StyledRect {
                                id: lowChoice
                                required property string modelData
                                readonly property bool active: modelData === (config?.low_battery_profile ?? "power-saver")
                                width: (parent.width - 16) / 3
                                height: 54
                                radius: Tokens.rounding.large
                                color: active ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                                StateLayer {
                                    radius: parent.radius
                                    enabled: !root.actionBusy
                                    onClicked: root.setProfile("low", lowChoice.modelData)
                                }
                                StyledText {
                                    anchors.centerIn: parent
                                    text: root.profileLabel(lowChoice.modelData)
                                    color: lowChoice.active
                                        ? Colours.palette.m3onSecondaryContainer
                                        : Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                }
                            }
                        }
                    }

                    StyledRect {
                        width: parent.width
                        height: 42
                        radius: Tokens.rounding.large
                        color: Colours.palette.m3primaryContainer
                        StateLayer {
                            radius: parent.radius
                            enabled: !root.actionBusy
                            onClicked: root.runControl(["apply-now"], qsTr("Applying current rule once…"))
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 7
                            MaterialIcon {
                                text: "play_arrow"
                                color: Colours.palette.m3onPrimaryContainer
                                fontStyle: Tokens.font.icon.small
                            }
                            StyledText {
                                text: qsTr("Apply current rule once")
                                color: Colours.palette.m3onPrimaryContainer
                                font: Tokens.font.label.medium
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: qsTr("Apply once works even while automation is disabled; it does not enable the watcher.")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }
            }

            StyledRect {
                width: (parent.width - 12) / 2
                height: parent.height
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Row {
                        width: parent.width

                        StyledText {
                            width: parent.width - eventActions.width - 10
                            text: qsTr("Automation status & events")
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.title.small
                        }

                        Row {
                            id: eventActions
                            spacing: 6

                            StyledRect {
                                width: 76
                                height: 32
                                radius: Tokens.rounding.medium
                                color: Colours.palette.m3surfaceContainerHigh
                                StateLayer {
                                    radius: parent.radius
                                    enabled: !root.actionBusy
                                    onClicked: root.runControl(["reset-defaults"], qsTr("Restoring rule defaults…"))
                                }
                                StyledText {
                                    anchors.centerIn: parent
                                    text: qsTr("Defaults")
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                }
                            }

                            StyledRect {
                                width: 68
                                height: 32
                                radius: Tokens.rounding.medium
                                color: Colours.palette.m3surfaceContainerHigh
                                StateLayer {
                                    radius: parent.radius
                                    enabled: !root.actionBusy
                                    onClicked: root.runControl(["clear-events"], qsTr("Clearing event history…"))
                                }
                                StyledText {
                                    anchors.centerIn: parent
                                    text: qsTr("Clear")
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                }
                            }
                        }
                    }

                    Repeater {
                        model: [
                            { label: qsTr("Service"), value: service?.active ? qsTr("Active") : qsTr("Stopped") },
                            { label: qsTr("Current / desired"), value: `${root.profileLabel(last?.profile ?? "")} → ${root.profileLabel(last?.desired_profile ?? "")}` },
                            { label: qsTr("Reason"), value: last?.reason ?? qsTr("No automatic switch yet") },
                            { label: qsTr("Battery"), value: last?.battery_percent !== undefined && last?.battery_percent !== null ? `${last.battery_percent}%` : "—" }
                        ]

                        delegate: Row {
                            required property var modelData
                            width: parent.width
                            height: 22
                            StyledText {
                                width: parent.width * 0.38
                                text: modelData.label
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                            }
                            StyledText {
                                width: parent.width * 0.62
                                text: modelData.value
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                            }
                        }
                    }

                    StyledText {
                        text: qsTr("Recent profile events")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }

                    Repeater {
                        model: Array.from(root.events ?? []).slice(0, 5)

                        delegate: StyledRect {
                            required property var modelData
                            width: parent.width
                            height: 34
                            radius: Tokens.rounding.medium
                            color: Colours.palette.m3surfaceContainerHigh

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * 0.18
                                    text: root.timeText(modelData?.timestamp)
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * 0.17
                                    text: root.sourceLabel(modelData)
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * 0.29
                                    text: root.profileLabel(modelData?.profile ?? modelData?.desired_profile ?? "")
                                    color: modelData?.ok === false ? Colours.palette.m3error : Colours.palette.m3primary
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * 0.36
                                    text: modelData?.reason ?? modelData?.error ?? "—"
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideLeft
                                }
                            }
                        }
                    }

                    StyledText {
                        visible: root.events.length === 0
                        text: qsTr("No automatic profile events recorded yet.")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                    }
                }
            }
        }
    }
}
