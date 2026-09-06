pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.components.effects
import qs.modules
import qs.services
import qs.utils

CortetsuSurface {
    id: root

    required property real rootHeight
    readonly property int cBoxSize: CortetsuTokens.font.body.medium.pointSize * 2

    function clamp(value: real, low: real, high: real): real {
        return Math.max(low, Math.min(high, value));
    }

    implicitHeight: layout.implicitHeight + layout.anchors.topMargin + layout.anchors.margins
    radius: CortetsuTokens.rounding.medium
    color: CortetsuColours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.extraLarge
        anchors.topMargin: CortetsuTokens.padding.extraLarge
        anchors.bottomMargin: CortetsuTokens.padding.extraLarge

        spacing: CortetsuTokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: CortetsuTokens.spacing.medium

            CortetsuSurface {
                implicitWidth: prompt.implicitWidth + CortetsuTokens.padding.medium * 2
                implicitHeight: prompt.implicitHeight + CortetsuTokens.padding.small * 2

                color: CortetsuColours.palette.m3primary
                radius: CortetsuTokens.rounding.medium

                MonoText {
                    id: prompt

                    anchors.centerIn: parent
                    text: ">"
                    color: CortetsuColours.palette.m3onPrimary
                }
            }

            MonoText {
                Layout.fillWidth: true
                text: "cortetsufetch.sh"
                elide: Text.ElideRight
            }

            WrappedLoader {
                Layout.fillHeight: true
                Layout.preferredWidth: height
                Layout.preferredHeight: 0
                active: !iconLoader.active

                sourceComponent: SysInfo.isDefaultLogo ? cortetsuLogo : distroIcon
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: CortetsuTokens.spacing.extraLarge

            WrappedLoader {
                id: iconLoader

                Layout.fillHeight: true
                active: root.width > CortetsuTokens.sizes.lock.largeLogoWidth

                sourceComponent: SysInfo.isDefaultLogo ? cortetsuLogo : distroIcon
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: CortetsuTokens.padding.medium
                Layout.bottomMargin: iconLoader.active || colourRowLoader.active ? CortetsuTokens.padding.medium : 0
                spacing: CortetsuTokens.spacing.medium

                Repeater {
                    model: {
                        const items = [];
                        const hasBatt = UPower.displayDevice.isLaptopBattery;
                        const rHeight = root.rootHeight;

                        if (!hasBatt && rHeight > CortetsuTokens.sizes.lock.fetch4LinesHeight)
                            items.push(`OS  : ${SysInfo.osPrettyName || SysInfo.osName}`);

                        if (rHeight > (hasBatt ? CortetsuTokens.sizes.lock.fetch4LinesHeight : CortetsuTokens.sizes.lock.fetch3LinesHeight))
                            items.push(`WM  : ${SysInfo.wm}`);

                        if (!hasBatt || rHeight > CortetsuTokens.sizes.lock.fetch3LinesHeight)
                            items.push(`USER: ${SysInfo.user}`);

                        items.push(`UP  : ${SysInfo.uptime}`);

                        if (hasBatt)
                            items.push(`BATT: ${[UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state) ? "(+) " : ""}${Math.round(UPower.displayDevice.percentage * 100)}%`);

                        return items;
                    }

                    MonoText {
                        required property string modelData

                        Layout.fillWidth: true
                        text: modelData
                        elide: Text.ElideRight
                    }
                }
            }
        }

        WrappedLoader {
            id: colourRowLoader

            Layout.topMargin: iconLoader.active ? CortetsuTokens.spacing.small : 0
            Layout.alignment: Qt.AlignHCenter
            active: root.rootHeight > CortetsuTokens.sizes.lock.showColourBoxRowHeight

            sourceComponent: RowLayout {
                id: coloursRow

                spacing: CortetsuTokens.spacing.largeIncreased

                Repeater {
                    model: root.clamp(Math.floor((layout.width + coloursRow.spacing) / (root.cBoxSize + coloursRow.spacing)), 0, 8)

                    CortetsuSurface {
                        required property int index

                        implicitWidth: implicitHeight
                        implicitHeight: root.cBoxSize
                        color: CortetsuColours.palette[`term${index}`]
                        radius: CortetsuTokens.rounding.medium
                    }
                }
            }
        }
    }

    Component {
        id: cortetsuLogo

        Logo {
            width: height
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: height
            colour: CortetsuColours.palette.m3primary
            layer.enabled: CortetsuConfig.lockRecolourLogo
        }
    }

    component WrappedLoader: Loader {
        asynchronous: true
        visible: active
    }

    component MonoText: CortetsuText {
        font: root.width > CortetsuTokens.sizes.lock.largeFontWidth ? CortetsuTokens.font.mono.medium : CortetsuTokens.font.mono.small
    }
}
