import QtQuick
import "../../CortetsuDesign.js" as CortetsuDesign
import "../../CortetsuTypography.js" as CortetsuTypography
import "../../../services"

Item {
    id: root

    implicitWidth: 260
    implicitHeight: 360

    Column {
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingStandard
        spacing: CortetsuDesign.spacingStandard

        Rectangle {
            width: parent.width
            height: width
            radius: CortetsuDesign.radiusMedium
            color: CortetsuDesign.colorSurfaceHigh

            Text {
                anchors.centerIn: parent
                text: "music_note"
                color: CortetsuDesign.colorSecondary
                font.family: CortetsuTypography.iconFamily
                font.pixelSize: 44
            }
        }

        Text {
            width: parent.width
            text: Players.active?.trackTitle || qsTr("No media")
            color: CortetsuDesign.colorWashi
            font.family: CortetsuTypography.uiFamily
            font.pixelSize: CortetsuTypography.bodyPx + 3
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: Players.active?.trackArtist || qsTr("No active player")
            color: CortetsuDesign.colorMuted
            font.family: CortetsuTypography.uiFamily
            font.pixelSize: CortetsuTypography.bodyPx
            elide: Text.ElideRight
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: CortetsuDesign.spacingComfortable

            Text {
                text: "skip_previous"
                color: CortetsuDesign.colorWashi
                font.family: CortetsuTypography.iconFamily
                font.pixelSize: CortetsuTypography.iconMediumPx
                MouseArea { anchors.fill: parent; onClicked: Players.active?.previous() }
            }
            Text {
                text: Players.active?.isPlaying ? "pause" : "play_arrow"
                color: CortetsuDesign.colorPrimary
                font.family: CortetsuTypography.iconFamily
                font.pixelSize: CortetsuTypography.iconMediumPx
                MouseArea { anchors.fill: parent; onClicked: Players.active?.togglePlaying() }
            }
            Text {
                text: "skip_next"
                color: CortetsuDesign.colorWashi
                font.family: CortetsuTypography.iconFamily
                font.pixelSize: CortetsuTypography.iconMediumPx
                MouseArea { anchors.fill: parent; onClicked: Players.active?.next() }
            }
        }
    }
}
