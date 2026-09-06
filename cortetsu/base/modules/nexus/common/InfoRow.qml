pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property alias value: value.text
    property string icon
    property color iconColour: CortetsuColours.palette.m3onSurfaceVariant
    property Component leadingComponent: icon ? iconComp : null

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

    Component {
        id: iconComp

        CortetsuIcon {
            text: root.icon
            color: root.iconColour
            fontStyle: CortetsuTokens.font.icon.small
        }
    }

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.medium
        anchors.leftMargin: CortetsuTokens.padding.largeIncreased
        anchors.rightMargin: CortetsuTokens.padding.largeIncreased
        spacing: CortetsuTokens.spacing.medium

        Loader {
            visible: root.leadingComponent
            active: root.leadingComponent
            sourceComponent: root.leadingComponent
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            CortetsuText {
                id: label

                Layout.fillWidth: true
                font: CortetsuTokens.font.body.small
                elide: Text.ElideRight
            }

            CortetsuText {
                Layout.fillWidth: true
                visible: root.subtext
                text: root.subtext
                color: CortetsuColours.palette.m3outline
                font: CortetsuTokens.font.label.small
                elide: Text.ElideRight
            }
        }

        CortetsuText {
            id: value

            Layout.maximumWidth: root.width / 2
            horizontalAlignment: Text.AlignRight
            color: CortetsuColours.palette.m3onSurfaceVariant
            font: CortetsuTokens.font.body.small
            elide: Text.ElideRight
        }
    }
}
