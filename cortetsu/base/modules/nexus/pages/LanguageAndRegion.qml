import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Temperature units (index 0 = Celsius, 1 = Fahrenheit — matches Weather.formatTemp)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: "°C"
        },
        MenuItem {
            text: "°F"
        }
    ]

    // Clock format (index 0 = 24-hour, 1 = 12-hour — matches Time.useTwelveHourClock)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: qsTr("24-hour")
        },
        MenuItem {
            text: qsTr("12-hour")
        }
    ]

    title: qsTr("Language & region")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: CortetsuTokens.spacing.extraSmall / 2

        // Language
        SectionHeader {
            first: true
            text: qsTr("Language")
        }

        // Read-only: the shell follows the system locale (no in-shell translations yet)
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: localeLayout.implicitHeight + localeLayout.anchors.margins * 2

            RowLayout {
                id: localeLayout

                anchors.fill: parent
                anchors.margins: CortetsuTokens.padding.medium
                anchors.leftMargin: CortetsuTokens.padding.largeIncreased
                anchors.rightMargin: CortetsuTokens.padding.largeIncreased
                spacing: CortetsuTokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    CortetsuText {
                        Layout.fillWidth: true
                        text: qsTr("System language")
                        font: CortetsuTokens.font.body.small
                        elide: Text.ElideRight
                    }

                    CortetsuText {
                        Layout.fillWidth: true
                        text: qsTr("Follows your system locale (%1)").arg(Qt.locale().name)
                        color: CortetsuColours.palette.m3outline
                        font: CortetsuTokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                CortetsuText {
                    text: Qt.locale().nativeLanguageName || Qt.locale().name
                    color: CortetsuColours.palette.m3onSurfaceVariant
                    font: CortetsuTokens.font.body.small
                }
            }
        }

        // Weather
        SectionHeader {
            text: qsTr("Weather")
        }

        // Placeholder until the map-based location picker lands
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: comingSoon.implicitHeight + CortetsuTokens.padding.extraLarge * 2

            ColumnLayout {
                id: comingSoon

                anchors.centerIn: parent
                width: parent.width - CortetsuTokens.padding.largeIncreased * 2
                spacing: CortetsuTokens.padding.extraSmall

                CortetsuIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "map"
                    color: CortetsuColours.palette.m3outlineVariant
                    fontStyle: CortetsuTokens.font.icon.extraLarge
                }

                CortetsuText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Location picker coming soon")
                    color: CortetsuColours.palette.m3outlineVariant
                    font: CortetsuTokens.font.title.small
                }

                CortetsuText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Choose your weather location on a map in a future update")
                    color: CortetsuColours.palette.m3outlineVariant
                    font: CortetsuTokens.font.body.small
                }
            }
        }

        // Units
        SectionHeader {
            text: qsTr("Units")
        }

        SelectRow {
            first: true
            label: qsTr("Temperature")
            subtext: qsTr("Units for weather temperatures")
            menuItems: root.tempItems
            active: root.tempItems[CortetsuConfig.useFahrenheit ? 1 : 0]
            onSelected: item => CortetsuConfig.useFahrenheit = root.tempItems.indexOf(item) === 1
        }

        SelectRow {
            last: true
            label: qsTr("System temperatures")
            subtext: qsTr("Units for CPU and GPU temperatures")
            menuItems: root.tempItems
            active: root.tempItems[CortetsuConfig.useFahrenheitPerformance ? 1 : 0]
            onSelected: item => CortetsuConfig.useFahrenheitPerformance = root.tempItems.indexOf(item) === 1
        }

        // Time & date
        SectionHeader {
            text: qsTr("Time & date")
        }

        SelectRow {
            first: true
            last: true
            label: qsTr("Clock format")
            subtext: qsTr("How times are shown across the shell")
            menuItems: root.clockItems
            active: root.clockItems[CortetsuConfig.useTwelveHourClock ? 1 : 0]
            onSelected: item => CortetsuConfig.useTwelveHourClock = root.clockItems.indexOf(item) === 1
        }
    }
}
