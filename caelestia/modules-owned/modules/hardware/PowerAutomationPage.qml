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

    property var automation: ({})
    property string statusText: qsTr("Reading automation state…")

    readonly property string controlPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) +
        "/.local/bin/caerice-power-auto-control"

    readonly property var config: automation?.config ?? ({})
    readonly property var service: automation?.service ?? ({})
    readonly property var last: automation?.last ?? ({})

    function profileLabel(name): string {
        if (name === "power-saver") return qsTr("Power saver");
        if (name === "performance") return qsTr("Performance");
        return qsTr("Balanced");
    }

    function profileIcon(name): string {
        if (name === "power-saver") return "eco";
        if (name === "performance") return "speed";
        return "balance";
    }

    function refresh(): void {
        if (!statusProbe.running)
            statusProbe.running = true;
    }

    function runControl(args): void {
        Quickshell.execDetached([root.controlPath].concat(args));
        refreshAfterAction.restart();
    }

    function setProfile(slot, profile): void {
        runControl(["set-profile", slot, profile]);
    }

    function threshold(delta): void {
        const current = Number(config?.low_battery_threshold ?? 25);
        runControl(["set-threshold", String(Math.max(5, Math.min(80, current + delta)))]);
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 3500
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshAfterAction
        interval: 700
        repeat: false
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

    Column {
        anchors.fill: parent
        spacing: 12

        StyledRect {
            width: parent.width
            height: 132
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
                        text: "auto_mode"
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
                        text: qsTr("Switch profiles automatically when AC is connected, on battery, or below a low-battery threshold.")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        width: parent.width
                        text: root.statusText
                        color: service?.active ? Colours.palette.m3primary : Colours.palette.m3outline
                        font: Tokens.font.label.small
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

                    StateLayer {
                        radius: parent.radius
                        onClicked: root.runControl(["set-enabled", config?.enabled ? "false" : "true"])
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
            id: profileGrid
            width: parent.width
            height: 202
            columns: 2
            columnSpacing: 12

            Repeater {
                model: [
                    {
                        title: qsTr("On AC power"),
                        subtitle: qsTr("Applied while an external power source is online"),
                        icon: "power",
                        slot: "ac",
                        value: config?.ac_profile ?? "performance"
                    },
                    {
                        title: qsTr("On battery"),
                        subtitle: qsTr("Normal battery profile above the low-battery threshold"),
                        icon: "battery_5_bar",
                        slot: "battery",
                        value: config?.battery_profile ?? "balanced"
                    }
                ]

                delegate: StyledRect {
                    id: scenarioCard
                    required property var modelData
                    width: (profileGrid.width - 12) / 2
                    height: profileGrid.height
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
                                    height: 84
                                    radius: Tokens.rounding.large
                                    color: active
                                        ? Colours.palette.m3secondaryContainer
                                        : Colours.palette.m3surfaceContainerHigh
                                    border.width: active ? 1 : 0
                                    border.color: Colours.palette.m3primary

                                    StateLayer {
                                        radius: parent.radius
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
            height: parent.height - 358
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
                    spacing: 12

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
                                text: qsTr("Use a separate profile when battery charge falls below the threshold.")
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
                                onClicked: root.runControl(["set-low-enabled", config?.low_battery_enabled ? "false" : "true"])
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
                            StateLayer { radius: parent.radius; onClicked: root.threshold(-5) }
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
                                text: qsTr("threshold")
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
                            StateLayer { radius: parent.radius; onClicked: root.threshold(5) }
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
                                height: 58
                                radius: Tokens.rounding.large
                                color: active ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                                StateLayer {
                                    radius: parent.radius
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
                    spacing: 10

                    StyledText {
                        text: qsTr("Automation status")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                    }

                    Repeater {
                        model: [
                            { label: qsTr("Service"), value: service?.active ? qsTr("Active") : qsTr("Stopped") },
                            { label: qsTr("Last profile"), value: root.profileLabel(last?.profile ?? "") },
                            { label: qsTr("Desired"), value: root.profileLabel(last?.desired_profile ?? "") },
                            { label: qsTr("Reason"), value: last?.reason ?? qsTr("No automatic switch yet") },
                            { label: qsTr("Battery"), value: last?.battery_percent !== undefined && last?.battery_percent !== null ? `${last.battery_percent}%` : "—" }
                        ]

                        delegate: Row {
                            required property var modelData
                            width: parent.width
                            height: 24
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
                                font: Tokens.font.label.medium
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                            }
                        }
                    }

                    Item { width: 1; height: 4 }

                    StyledRect {
                        width: parent.width
                        height: 42
                        radius: Tokens.rounding.large
                        color: Colours.palette.m3surfaceContainerHigh
                        StateLayer {
                            radius: parent.radius
                            onClicked: root.runControl(["apply-now"])
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 7
                            MaterialIcon {
                                text: "sync"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.small
                            }
                            StyledText {
                                text: qsTr("Apply current rule now")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.medium
                            }
                        }
                    }
                }
            }
        }
    }
}
