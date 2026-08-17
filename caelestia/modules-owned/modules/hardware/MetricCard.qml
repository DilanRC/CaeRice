pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property string title: ""
    property string icon: "monitor_heart"
    property string headline: ""
    property string subtitle: ""
    property real progress: -1
    property var rows: []

    implicitHeight: 176
    radius: Tokens.rounding.extraLarge
    color: Colours.palette.m3surfaceContainer
    border.width: 1
    border.color: Colours.palette.m3outlineVariant

    Row {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 12

        StyledRect {
            width: 42
            height: 42
            radius: Tokens.rounding.large
            color: Colours.palette.m3secondaryContainer

            MaterialIcon {
                anchors.centerIn: parent
                text: root.icon
                fill: 1
                color: Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.large
            }
        }

        Column {
            width: Math.max(40, parent.width - 54)
            spacing: 1

            StyledText {
                width: parent.width
                text: root.title
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
                elide: Text.ElideRight
            }

            StyledText {
                width: parent.width
                text: root.headline
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.medium
                elide: Text.ElideRight
            }

            StyledText {
                width: parent.width
                visible: text.length > 0
                text: root.subtitle
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }
    }

    StyledRect {
        id: progressTrack
        visible: root.progress >= 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: 14
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 7
        radius: Tokens.rounding.full
        color: Colours.palette.m3surfaceContainerHighest

        StyledRect {
            width: parent.width * Math.max(0, Math.min(1, root.progress))
            height: parent.height
            radius: parent.radius
            color: Colours.palette.m3primary
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 14
        spacing: 5

        Repeater {
            model: root.rows

            delegate: Row {
                required property var modelData
                width: parent.width
                spacing: 8

                StyledText {
                    width: parent.width * 0.52
                    text: String(modelData?.label ?? "")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width * 0.48 - 8
                    text: String(modelData?.value ?? "—")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }
        }
    }
}
