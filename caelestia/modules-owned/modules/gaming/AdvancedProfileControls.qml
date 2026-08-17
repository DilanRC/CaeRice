pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property var contentItem

    readonly property var profile: contentItem?.profile ?? ({})
    readonly property bool gamescopeEnabled: Boolean(profile?.gamescope)
    readonly property var scalerValues: ["auto", "integer", "fit", "fill", "stretch"]
    readonly property var filterValues: ["linear", "nearest", "fsr", "nis", "pixel"]

    radius: Tokens.rounding.extraLarge
    color: Colours.palette.m3surfaceContainerHighest
    border.width: 1
    border.color: Colours.palette.m3outlineVariant

    function cycle(field, values): void {
        let index = values.indexOf(String(profile?.[field] ?? values[0]));
        if (index < 0) index = 0;
        contentItem.mutate(field, values[(index + 1) % values.length]);
    }

    function setResolution(prefix, width, height): void {
        contentItem.mutate(`${prefix}_width`, width);
        contentItem.mutate(`${prefix}_height`, height);
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7

        Row {
            width: parent.width
            height: 24
            StyledText {
                width: parent.width * 0.60
                text: qsTr("Gamescope advanced")
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.small
            }
            StyledText {
                width: parent.width * 0.40
                text: root.gamescopeEnabled ? qsTr("active profile") : qsTr("enable Gamescope above")
                color: root.gamescopeEnabled ? Colours.palette.m3primary : Colours.palette.m3outline
                font: Tokens.font.label.small
                horizontalAlignment: Text.AlignRight
            }
        }

        Row {
            width: parent.width
            height: 40
            spacing: 7

            Repeater {
                model: [
                    { label: qsTr("Scaler"), value: String(root.profile?.scaler ?? "auto"), click: () => root.cycle("scaler", root.scalerValues) },
                    { label: qsTr("Filter"), value: String(root.profile?.filter ?? "linear"), click: () => root.cycle("filter", root.filterValues) },
                    { label: qsTr("VRR"), value: root.profile?.adaptive_sync ? qsTr("On") : qsTr("Off"), click: () => root.contentItem.mutate("adaptive_sync", !Boolean(root.profile?.adaptive_sync)) }
                ]
                delegate: StyledRect {
                    required property var modelData
                    width: (parent.width - 14) / 3
                    height: 40
                    radius: Tokens.rounding.medium
                    color: root.gamescopeEnabled ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                    enabled: root.gamescopeEnabled
                    opacity: enabled ? 1 : 0.55
                    StateLayer { radius: parent.radius; onClicked: modelData.click() }
                    Row {
                        anchors.fill: parent
                        anchors.margins: 9
                        StyledText { width: parent.width * 0.44; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: Colours.palette.m3outline; font: Tokens.font.label.small }
                        StyledText { width: parent.width * 0.56; anchors.verticalCenter: parent.verticalCenter; text: modelData.value; color: root.gamescopeEnabled ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline; font: Tokens.font.label.small; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight }
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: 40
            spacing: 7

            StyledText { width: 88; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Game res"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
            Repeater {
                model: [
                    { label: qsTr("Native"), w: 0, h: 0 },
                    { label: "1280×720", w: 1280, h: 720 },
                    { label: "1920×1080", w: 1920, h: 1080 },
                    { label: "2560×1440", w: 2560, h: 1440 }
                ]
                delegate: StyledRect {
                    required property var modelData
                    width: (parent.width - 88 - 21) / 4
                    height: 40
                    radius: Tokens.rounding.medium
                    color: Number(root.profile?.game_width ?? 0) === modelData.w && Number(root.profile?.game_height ?? 0) === modelData.h ? Colours.palette.m3tertiaryContainer : Colours.palette.m3surfaceContainerHigh
                    enabled: root.gamescopeEnabled
                    opacity: enabled ? 1 : 0.55
                    StateLayer { radius: parent.radius; onClicked: root.setResolution("game", modelData.w, modelData.h) }
                    StyledText { anchors.centerIn: parent; text: modelData.label; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small }
                }
            }
        }

        Row {
            width: parent.width
            height: 40
            spacing: 7

            StyledText { width: 88; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Output res"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
            Repeater {
                model: [
                    { label: qsTr("Default"), w: 0, h: 0 },
                    { label: "1280×720", w: 1280, h: 720 },
                    { label: "1920×1080", w: 1920, h: 1080 },
                    { label: "2560×1440", w: 2560, h: 1440 }
                ]
                delegate: StyledRect {
                    required property var modelData
                    width: (parent.width - 88 - 21) / 4
                    height: 40
                    radius: Tokens.rounding.medium
                    color: Number(root.profile?.output_width ?? 0) === modelData.w && Number(root.profile?.output_height ?? 0) === modelData.h ? Colours.palette.m3tertiaryContainer : Colours.palette.m3surfaceContainerHigh
                    enabled: root.gamescopeEnabled
                    opacity: enabled ? 1 : 0.55
                    StateLayer { radius: parent.radius; onClicked: root.setResolution("output", modelData.w, modelData.h) }
                    StyledText { anchors.centerIn: parent; text: modelData.label; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small }
                }
            }
        }

        Row {
            width: parent.width
            height: 40
            spacing: 7
            StyledText { width: 88; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Sharpness"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
            StyledRect {
                width: 40; height: 40; radius: Tokens.rounding.medium; color: Colours.palette.m3surfaceContainerHigh
                enabled: root.gamescopeEnabled && (root.profile?.filter === "fsr" || root.profile?.filter === "nis")
                opacity: enabled ? 1 : 0.5
                StateLayer { radius: parent.radius; onClicked: root.contentItem.mutate("sharpness", Math.max(-1, Number(root.profile?.sharpness ?? -1) - 1)) }
                MaterialIcon { anchors.centerIn: parent; text: "remove"; color: Colours.palette.m3onSurfaceVariant }
            }
            StyledText {
                width: 80; anchors.verticalCenter: parent.verticalCenter
                text: Number(root.profile?.sharpness ?? -1) < 0 ? qsTr("Default") : String(root.profile.sharpness)
                color: Colours.palette.m3onSurface; font: Tokens.font.label.medium; horizontalAlignment: Text.AlignHCenter
            }
            StyledRect {
                width: 40; height: 40; radius: Tokens.rounding.medium; color: Colours.palette.m3surfaceContainerHigh
                enabled: root.gamescopeEnabled && (root.profile?.filter === "fsr" || root.profile?.filter === "nis")
                opacity: enabled ? 1 : 0.5
                StateLayer { radius: parent.radius; onClicked: root.contentItem.mutate("sharpness", Math.min(20, Number(root.profile?.sharpness ?? -1) + 1)) }
                MaterialIcon { anchors.centerIn: parent; text: "add"; color: Colours.palette.m3onSurfaceVariant }
            }
            StyledText {
                width: parent.width - 255
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("FSR/NIS only · -1 keeps Gamescope default")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }
    }
}
