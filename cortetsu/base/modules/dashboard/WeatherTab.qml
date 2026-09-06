import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
    id: root

    readonly property var today: Weather.forecast && Weather.forecast.length > 0 ? Weather.forecast[0] : null

    implicitWidth: layout.implicitWidth > 800 ? layout.implicitWidth : 840
    implicitHeight: layout.implicitHeight
    Component.onCompleted: Weather.reload()

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: CortetsuTokens.spacing.medium

        RowLayout {
            Layout.leftMargin: CortetsuTokens.padding.large
            Layout.rightMargin: CortetsuTokens.padding.large
            Layout.fillWidth: true

            Column {
                spacing: CortetsuTokens.spacing.extraSmall

                CortetsuText {
                    text: Weather.city || qsTr("Loading...")
                    font: CortetsuTokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
                    color: CortetsuColours.palette.m3onSurface
                }

                CortetsuText {
                    text: new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d")
                    font: CortetsuTokens.font.body.small
                    color: CortetsuColours.palette.m3onSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Row {
                spacing: CortetsuTokens.spacing.largeIncreased

                WeatherStat {
                    icon: "wb_twilight"
                    label: "Sunrise"
                    value: Weather.sunrise
                    colour: CortetsuColours.palette.m3tertiary
                }

                WeatherStat {
                    icon: "bedtime"
                    label: "Sunset"
                    value: Weather.sunset
                    colour: CortetsuColours.palette.m3tertiary
                }
            }
        }

        CortetsuSurface {
            Layout.fillWidth: true
            implicitHeight: bigInfoRow.implicitHeight + CortetsuTokens.padding.small

            radius: CortetsuTokens.rounding.extraLarge * 2
            color: CortetsuColours.tPalette.m3surfaceContainer

            RowLayout {
                id: bigInfoRow

                anchors.centerIn: parent
                spacing: CortetsuTokens.spacing.largeIncreased

                CortetsuIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: Weather.icon
                    fontStyle: CortetsuTokens.font.icon.builders.extraLarge.scale(3).build()
                    color: CortetsuColours.palette.m3secondary
                    animate: true
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: -CortetsuTokens.spacing.small

                    CortetsuText {
                        text: Weather.temp
                        font: CortetsuTokens.font.body.builders.large.size(28 * 2).weight(Font.Medium).build()
                        color: CortetsuColours.palette.m3primary
                    }

                    CortetsuText {
                        Layout.leftMargin: CortetsuTokens.padding.extraSmall
                        text: Weather.description
                        font: CortetsuTokens.font.body.medium
                        color: CortetsuColours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: CortetsuTokens.spacing.medium

            DetailCard {
                icon: "water_drop"
                label: "Humidity"
                value: Weather.humidity + "%"
                colour: CortetsuColours.palette.m3secondary
            }
            DetailCard {
                icon: "thermostat"
                label: "Feels Like"
                value: Weather.feelsLike
                colour: CortetsuColours.palette.m3primary
            }
            DetailCard {
                icon: "air"
                label: "Wind"
                value: Weather.windSpeed ? Weather.windSpeed + " km/h" : "--"
                colour: CortetsuColours.palette.m3tertiary
            }
        }

        CortetsuText {
            Layout.topMargin: CortetsuTokens.spacing.medium
            Layout.leftMargin: CortetsuTokens.padding.medium
            visible: forecastRepeater.count > 0
            text: qsTr("7-Day Forecast")
            font: CortetsuTokens.font.body.builders.medium.weight(Font.DemiBold).build()
            color: CortetsuColours.palette.m3onSurface
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: CortetsuTokens.spacing.medium

            Repeater {
                id: forecastRepeater

                model: Weather.forecast

                CortetsuSurface {
                    id: forecastItem

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: forecastItemColumn.implicitHeight + CortetsuTokens.padding.medium * 2

                    radius: CortetsuTokens.rounding.large
                    color: CortetsuColours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: forecastItemColumn

                        anchors.centerIn: parent
                        spacing: CortetsuTokens.spacing.small

                        CortetsuText {
                            Layout.alignment: Qt.AlignHCenter
                            text: forecastItem.index === 0 ? qsTr("Today") : new Date(forecastItem.modelData.date).toLocaleDateString(Qt.locale(), "ddd")
                            font: CortetsuTokens.font.body.builders.medium.weight(Font.DemiBold).build()
                            color: CortetsuColours.palette.m3primary
                        }

                        CortetsuText {
                            Layout.topMargin: -CortetsuTokens.spacing.extraSmall
                            Layout.alignment: Qt.AlignHCenter
                            text: new Date(forecastItem.modelData.date).toLocaleDateString(Qt.locale(), "MMM d")
                            font: CortetsuTokens.font.body.small
                            opacity: 0.7
                            color: CortetsuColours.palette.m3onSurfaceVariant
                        }

                        CortetsuIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: forecastItem.modelData.icon
                            fontStyle: CortetsuTokens.font.icon.extraLarge
                            color: CortetsuColours.palette.m3secondary
                        }

                        CortetsuText {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                const min = Weather.formatTemp(forecastItem.modelData.minTempC).slice(0, -1);
                                const max = Weather.formatTemp(forecastItem.modelData.maxTempC).slice(0, -1);
                                return `${min} / ${max}`;
                            }
                            font: CortetsuTokens.font.body.builders.small.weight(Font.DemiBold).build()
                            color: CortetsuColours.palette.m3tertiary
                        }
                    }
                }
            }
        }
    }

    component DetailCard: CortetsuSurface {
        id: detailRoot

        property string icon
        property string label
        property string value
        property color colour

        Layout.fillWidth: true
        Layout.preferredHeight: 60
        radius: CortetsuTokens.rounding.medium
        color: CortetsuColours.tPalette.m3surfaceContainer

        Row {
            anchors.centerIn: parent
            spacing: CortetsuTokens.spacing.medium

            CortetsuIcon {
                text: detailRoot.icon
                color: detailRoot.colour
                fontStyle: CortetsuTokens.font.icon.large
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                CortetsuText {
                    text: detailRoot.label
                    font: CortetsuTokens.font.body.small
                    opacity: 0.7
                    horizontalAlignment: Text.AlignLeft
                }
                CortetsuText {
                    text: detailRoot.value
                    font: CortetsuTokens.font.body.builders.small.weight(Font.DemiBold).build()
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }
    }

    component WeatherStat: Row {
        id: weatherStat

        property string icon
        property string label
        property string value
        property color colour

        spacing: CortetsuTokens.spacing.small

        CortetsuIcon {
            text: weatherStat.icon
            fontStyle: CortetsuTokens.font.icon.extraLarge
            color: weatherStat.colour
        }

        Column {
            CortetsuText {
                text: weatherStat.label
                font: CortetsuTokens.font.body.small
                color: CortetsuColours.palette.m3onSurfaceVariant
            }
            CortetsuText {
                text: weatherStat.value
                font: CortetsuTokens.font.body.builders.small.weight(Font.DemiBold).build()
                color: CortetsuColours.palette.m3onSurface
            }
        }
    }
}
