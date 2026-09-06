import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property int rootHeight

    spacing: CortetsuTokens.spacing.extraSmall

    CortetsuText {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: Weather.description
        color: CortetsuColours.palette.m3onSurfaceVariant
        font: CortetsuTokens.font.body.large
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: CortetsuTokens.spacing.medium

        CortetsuText {
            id: temp

            animate: true
            text: Weather.temp
            color: CortetsuColours.palette.m3primary
            font: CortetsuTokens.font.headline.builders.large.scale(1.5).weight(Font.DemiBold).width(80).build()
        }

        CortetsuIcon {
            animate: true
            text: Weather.icon
            color: CortetsuColours.palette.m3secondary
            fontStyle: CortetsuTokens.font.headline.builders.large.scale(1.5).build()
        }
    }

    CortetsuText {
        visible: root.rootHeight > CortetsuTokens.sizes.lock.showWeatherDetailsHeight
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: qsTr("Feels like %1").arg(Weather.temp)
        color: CortetsuColours.palette.m3onSurfaceVariant
        font: CortetsuTokens.font.body.large
    }

    CortetsuText {
        visible: root.rootHeight > CortetsuTokens.sizes.lock.showWeatherDetailsHeight
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: {
            const today = Weather.forecast[0];
            return qsTr("High %1 • Low %2").arg(Weather.formatTemp(today?.maxTempC)).arg(Weather.formatTemp(today?.minTempC));
        }
        color: CortetsuColours.palette.m3onSurfaceVariant
        font: CortetsuTokens.font.body.medium
    }
}
