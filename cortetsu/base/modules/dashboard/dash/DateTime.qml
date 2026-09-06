import QtQuick
import "../../CortetsuDesign.js" as CortetsuDesign
import "../../CortetsuTypography.js" as CortetsuTypography
import "../../../services"

Item {
    implicitWidth: 92
    implicitHeight: 180

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.hourStr
            color: CortetsuDesign.colorSecondary
            font.family: CortetsuTypography.uiFamily
            font.pixelSize: 28
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "•••"
            color: CortetsuDesign.colorPrimary
            font.pixelSize: 24
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.minuteStr
            color: CortetsuDesign.colorSecondary
            font.family: CortetsuTypography.uiFamily
            font.pixelSize: 28
            font.bold: true
        }
        Text {
            visible: CortetsuConfig.useTwelveHourClock
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.amPmStr
            color: CortetsuDesign.colorPrimary
            font.family: CortetsuTypography.uiFamily
            font.pixelSize: 16
        }
    }
}
