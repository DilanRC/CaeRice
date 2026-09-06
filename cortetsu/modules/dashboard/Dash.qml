import QtQuick
import "../CortetsuDesign.js" as CortetsuDesign
import "../CortetsuTypography.js" as CortetsuTypography
import "../../services"

Item {
    id: root

    required property var screenState
    required property var facePicker
    implicitWidth: 900
    implicitHeight: 420

    Row {
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingStandard
        spacing: CortetsuDesign.spacingStandard

        Rectangle {
            width: 100
            height: parent.height
            radius: CortetsuDesign.radiusLarge
            color: CortetsuDesign.colorSurface

            Column {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.hourStr
                    color: CortetsuDesign.colorSecondary
                    font.family: CortetsuTypography.uiFamily
                    font.pixelSize: CortetsuTypography.titleLargePx + 6
                    font.bold: true
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.minuteStr
                    color: CortetsuDesign.colorSecondary
                    font.family: CortetsuTypography.uiFamily
                    font.pixelSize: CortetsuTypography.titleLargePx + 6
                    font.bold: true
                }
                Text {
                    visible: CortetsuConfig.useTwelveHourClock
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.amPmStr
                    color: CortetsuDesign.colorPrimary
                    font.pixelSize: CortetsuTypography.bodyPx
                }
            }
        }

        Rectangle {
            width: (parent.width - 100 - parent.spacing * 2) / 2
            height: parent.height
            radius: CortetsuDesign.radiusLarge
            color: CortetsuDesign.colorSurface

            Column {
                anchors.centerIn: parent
                spacing: CortetsuDesign.spacingCompact
                Text {
                    text: Weather.icon + "  " + Weather.temp
                    color: CortetsuDesign.colorPrimary
                    font.family: CortetsuTypography.uiFamily
                    font.pixelSize: CortetsuTypography.titleLargePx
                }
                Text {
                    text: Weather.city || qsTr("Weather")
                    color: CortetsuDesign.colorWashi
                    font.family: CortetsuTypography.uiFamily
                    font.pixelSize: CortetsuTypography.bodyLargePx
                }
                Text {
                    text: Weather.description
                    color: CortetsuDesign.colorMuted
                    font.family: CortetsuTypography.uiFamily
                    font.pixelSize: CortetsuTypography.bodyPx
                }
            }
        }

        Rectangle {
            width: (parent.width - 100 - parent.spacing * 2) / 2
            height: parent.height
            radius: CortetsuDesign.radiusLarge
            color: CortetsuDesign.colorSurface

            Column {
                anchors.centerIn: parent
                spacing: CortetsuDesign.spacingCompact
                Text {
                    text: Players.active?.trackTitle || qsTr("No media")
                    color: CortetsuDesign.colorWashi
                    font.family: CortetsuTypography.uiFamily
                    font.pixelSize: CortetsuTypography.titleMediumPx
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    text: Players.active?.trackArtist || qsTr("No active player")
                    color: CortetsuDesign.colorMuted
                    font.family: CortetsuTypography.uiFamily
                    font.pixelSize: CortetsuTypography.bodyPx
                }
                Text {
                    text: Players.active?.isPlaying ? qsTr("Playing") : qsTr("Paused")
                    color: CortetsuDesign.colorPrimary
                    font.family: CortetsuTypography.uiFamily
                    font.pixelSize: CortetsuTypography.bodyPx
                }
            }
        }
    }
}
