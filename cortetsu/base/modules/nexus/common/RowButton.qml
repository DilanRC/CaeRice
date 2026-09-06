pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

ConnectedRect {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text
    property alias subtext: subLabel.text
    property string trailingIcon
    property alias disabled: stateLayer.disabled

    readonly property alias iconLabel: iconLabel
    readonly property alias label: label
    readonly property alias subLabel: subLabel

    signal clicked(event: MouseEvent)

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + CortetsuTokens.padding.medium * 2

    CortetsuStateLayer {
        id: stateLayer

        onClicked: e => root.clicked(e)
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: CortetsuTokens.padding.largeIncreased

        spacing: CortetsuTokens.spacing.medium
        opacity: root.disabled ? 0.5 : 1

        Behavior on opacity {
            Anim {}
        }

        CortetsuIcon {
            id: iconLabel

            color: CortetsuColours.palette.m3onSurfaceVariant
            fontStyle: CortetsuTokens.font.icon.medium
            fill: 1
        }

        Column {
            id: column

            Layout.fillWidth: true
            spacing: 0

            CortetsuText {
                id: label

                anchors.left: parent.left
                anchors.right: parent.right

                font: CortetsuTokens.font.body.small
                elide: Text.ElideRight
            }

            CortetsuText {
                id: subLabel

                anchors.left: parent.left
                anchors.right: parent.right

                visible: text
                color: CortetsuColours.palette.m3outline
                font: CortetsuTokens.font.label.small
                elide: Text.ElideRight
            }
        }

        Loader {
            asynchronous: true
            active: root.trailingIcon
            visible: active

            sourceComponent: CortetsuIcon {
                text: root.trailingIcon
                color: CortetsuColours.palette.m3onSurfaceVariant
                fontStyle: CortetsuTokens.font.icon.medium
            }
        }
    }
}
