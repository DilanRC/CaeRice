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

    implicitHeight: 190
    radius: Tokens.rounding.extraLarge
    color: Colours.palette.m3surfaceContainer
    border.width: 1
    border.color: Colours.palette.m3outlineVariant

    Row {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 14
        height: 56
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
            spacing: 0

            Row {
                width: parent.width

                StyledText {
                    width: parent.width * 0.52
                    text: root.title
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width * 0.48
                    text: root.headline
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.small
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
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
        anchors.topMargin: 4
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 8
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
        id: details
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: progressTrack.visible ? progressTrack.bottom : header.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 13
        anchors.bottomMargin: 13
        spacing: 6

        Repeater {
            model: root.rows

            delegate: Row {
                required property var modelData
                width: parent.width
                height: 19
                spacing: 8

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.52
                    text: String(modelData?.label ?? "")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
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
