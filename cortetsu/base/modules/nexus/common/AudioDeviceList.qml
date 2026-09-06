pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.modules.nexus.common

ItemList {
    id: root

    property var nodes: []
    property int currentId: -1
    property string iconName: "speaker"

    signal selected(node: PwNode)

    last: true
    showList: true

    model: ScriptModel {
        values: [...root.nodes].sort((a, b) => (a.description || a.name || "").localeCompare(b.description || b.name || ""))
    }

    delegate: Item {
        id: device

        required property PwNode modelData
        required property int index
        readonly property bool active: device.modelData?.id === root.currentId

        anchors.left: root.list.contentItem.left
        anchors.right: root.list.contentItem.right
        implicitHeight: deviceLayout.implicitHeight + deviceLayout.anchors.margins * 2

        CortetsuStateLayer {
            radius: CortetsuTokens.rounding.extraSmall
            bottomLeftRadius: device.index === root?.list.count - 1 ? CortetsuTokens.rounding.extraLarge : radius
            bottomRightRadius: device.index === root?.list.count - 1 ? CortetsuTokens.rounding.extraLarge : radius
            onClicked: root.selected(device.modelData)
        }

        RowLayout {
            id: deviceLayout

            anchors.fill: parent
            anchors.margins: CortetsuTokens.padding.medium
            anchors.leftMargin: CortetsuTokens.padding.largeIncreased
            anchors.rightMargin: CortetsuTokens.padding.largeIncreased
            spacing: CortetsuTokens.spacing.medium

            CortetsuSurface {
                implicitWidth: implicitHeight
                implicitHeight: devIcon.implicitHeight + CortetsuTokens.padding.small * 2
                radius: CortetsuTokens.rounding.full
                color: device.active ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3secondaryContainer

                CortetsuIcon {
                    id: devIcon

                    anchors.centerIn: parent
                    text: root.iconName
                    color: device.active ? CortetsuColours.palette.m3onPrimary : CortetsuColours.palette.m3onSecondaryContainer
                    fontStyle: CortetsuTokens.font.icon.medium
                    fill: device.active ? 1 : 0

                    Behavior on fill {
                        Anim {}
                    }
                }
            }

            CortetsuText {
                Layout.fillWidth: true
                text: device.modelData?.description || device.modelData?.name || qsTr("Unknown")
                font: CortetsuTokens.font.body.small
                elide: Text.ElideRight
            }

            CortetsuIcon {
                text: "check"
                color: CortetsuColours.palette.m3primary
                fontStyle: CortetsuTokens.font.icon.medium
                opacity: device.active ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }
}
