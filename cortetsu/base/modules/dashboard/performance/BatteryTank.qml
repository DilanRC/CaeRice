import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.modules
import qs.services

StyledClippingRect {
    id: root

    property real animPerc: UPower.displayDevice.percentage

    color: CortetsuColours.palette.m3secondaryContainer
    radius: CortetsuTokens.rounding.large

    implicitWidth: CortetsuConfig.dashboard.performance.showCpu || (CortetsuConfig.dashboard.performance.showGpu && Gpu.type !== Gpu.noneType) || CortetsuConfig.dashboard.performance.showStorage || CortetsuConfig.dashboard.performance.showMemory ? CortetsuTokens.sizes.dashboard.perfBattWidth : CortetsuTokens.sizes.dashboard.perfBattWidthSingle
    implicitHeight: CortetsuTokens.sizes.dashboard.perfBattHeight

    Behavior on animPerc {
        Anim {}
    }

    Contents {
        id: layout

        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.medium

        accentColour: CortetsuColours.palette.m3primary
        textColour: CortetsuColours.palette.m3onSurface
        subTextColour: CortetsuColours.palette.m3onSurfaceVariant
    }

    CortetsuSurface {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: parent.height * root.animPerc

        color: CortetsuColours.palette.m3secondary
        radius: CortetsuTokens.rounding.extraSmall
        clip: true

        Contents {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: layout.anchors.margins
            height: layout.height

            accentColour: CortetsuColours.palette.m3primaryContainer
            textColour: CortetsuColours.palette.m3onSecondary
            subTextColour: CortetsuColours.palette.m3secondaryContainer
        }
    }

    component Contents: ColumnLayout {
        id: contents

        required property color accentColour
        required property color textColour
        required property color subTextColour
        readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)

        spacing: 0

        CortetsuIcon {
            Layout.leftMargin: -CortetsuTokens.padding.extraSmall
            text: "battery_full"
            color: contents.accentColour
            fontStyle: CortetsuTokens.font.icon.large
        }

        CortetsuText {
            Layout.fillWidth: true
            text: qsTr("Battery")
            color: contents.textColour
            font: CortetsuTokens.font.body.medium
        }

        Item {
            Layout.fillHeight: true
        }

        CortetsuText {
            Layout.alignment: Qt.AlignRight
            text: {
                if (UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
                    return qsTr("Full");

                if (contents.charging)
                    return qsTr("Charging");

                const s = UPower.displayDevice.timeToEmpty;
                if (s === 0)
                    return qsTr("...");

                const hr = Math.floor(s / 3600);
                const min = Math.floor((s % 3600) / 60);
                if (hr > 0)
                    return `${hr}h ${min}m`;

                return `${min}m`;
            }
            color: contents.subTextColour
            font: CortetsuTokens.font.body.small
            animate: true
        }

        RowLayout {
            Layout.topMargin: -CortetsuTokens.padding.extraSmall
            Layout.bottomMargin: -CortetsuTokens.padding.small
            Layout.rightMargin: -CortetsuTokens.padding.extraSmall
            Layout.alignment: Qt.AlignRight
            spacing: CortetsuTokens.spacing.extraSmall

            CortetsuIcon {
                text: "bolt"
                color: contents.accentColour
                fontStyle: CortetsuTokens.font.icon.large
                fill: 1

                scale: contents.charging ? 1 : 0
                opacity: contents.charging ? 1 : 0

                Behavior on scale {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
            }

            CortetsuText {
                text: `${Math.round(UPower.displayDevice.percentage * 100)}%`
                color: contents.accentColour
                font: CortetsuTokens.font.headline.medium
            }
        }
    }
}
