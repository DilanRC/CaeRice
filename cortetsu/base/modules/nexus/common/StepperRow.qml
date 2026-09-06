pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property real value
    property real from: 0
    property real to: 99
    property real stepSize: 1

    signal moved(value: real)

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.medium
        anchors.leftMargin: CortetsuTokens.padding.largeIncreased
        anchors.rightMargin: CortetsuTokens.padding.largeIncreased
        spacing: CortetsuTokens.spacing.medium

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

        StyledSpinBox {
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.value
            cLayer: 2
            onValueModified: root.moved(value)
        }
    }
}
