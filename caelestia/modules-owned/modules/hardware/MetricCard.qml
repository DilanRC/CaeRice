pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../CortetsuDesign.js" as CortetsuDesign
import "../CortetsuTypography.js" as CortetsuTypography
import qs.services

Rectangle {
    id: root

    property string title: ""
    property string icon: "monitor_heart"
    property string headline: ""
    property string subtitle: ""
    property real progress: -1
    property var rows: []
    property string modeLabel: ""

    signal modeRequested()

    implicitHeight: 190
    radius: CortetsuDesign.radiusLarge
    color: CortetsuDesign.colorSurface
    border.width: 1
    border.color: CortetsuDesign.colorOutlineVariant

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

        Rectangle {
            width: 42
            height: 42
            radius: CortetsuDesign.radiusMedium
            color: CortetsuDesign.colorSecondaryContainer

            CortetsuIcon {
                anchors.centerIn: parent
                text: root.icon
                color: CortetsuDesign.colorOnSecondaryContainer
                iconSize: CortetsuTypography.iconLargePx
            }
        }

        Column {
            width: Math.max(40, parent.width - 54 - (modeButton.visible ? 48 : 0))
            spacing: 0

            Row {
                width: parent.width

                CortetsuText {
                    width: parent.width * 0.52
                    text: root.title
                    color: CortetsuDesign.colorOnSurfaceVariant
                    textSize: CortetsuTypography.labelMediumPx
                    elide: Text.ElideRight
                }

                CortetsuText {
                    width: parent.width * 0.48
                    text: root.headline
                    color: CortetsuDesign.colorOnSurface
                    textSize: CortetsuTypography.titleSmallPx
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }

            CortetsuText {
                width: parent.width
                visible: text.length > 0
                text: root.subtitle
                color: CortetsuDesign.colorOutline
                textSize: CortetsuTypography.bodySmallPx
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        id: modeButton
        visible: root.modeLabel.length > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 14
        anchors.rightMargin: 16
        width: 42
        height: 26
        radius: 999
        color: CortetsuDesign.colorSurfaceHigh
        border.width: 1
        border.color: CortetsuDesign.colorOutlineVariant
        z: 3

        CortetsuStateLayer {
            radius: parent.radius
            onClicked: root.modeRequested()
        }

        CortetsuText {
            anchors.centerIn: parent
            text: root.modeLabel
            color: CortetsuDesign.colorPrimary
            textSize: CortetsuTypography.labelSmallPx
        }
    }

    Rectangle {
        id: progressTrack
        visible: root.progress >= 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: 4
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 8
        radius: 999
        color: CortetsuDesign.colorSurfaceHigh

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.progress))
            height: parent.height
            radius: parent.radius
            color: CortetsuDesign.colorPrimary
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

                CortetsuText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.52
                    text: String(modelData?.label ?? "")
                    color: CortetsuDesign.colorOutline
                    textSize: CortetsuTypography.labelSmallPx
                    elide: Text.ElideRight
                }

                CortetsuText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.48 - 8
                    text: String(modelData?.value ?? "—")
                    color: CortetsuDesign.colorOnSurfaceVariant
                    textSize: CortetsuTypography.labelSmallPx
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }
        }
    }
}
