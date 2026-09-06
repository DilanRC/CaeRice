pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.components.containers
import qs.services
import qs.modules.nexus.common

DialogRowButton {
    id: root

    required property var model
    property var selectedItem

    function keyFor(item: var): string {
        return item.id;
    }

    function labelFor(item: var): string {
        return item.label;
    }

    onOpenChanged: {
        if (open)
            selectedItem = null;
    }

    acceptAllowed: !!selectedItem
    separateContent: true
    horizontalContentMargin: -CortetsuTokens.padding.small

    content: Component {
        VerticalFadeListView {
            spacing: 0
            topMargin: CortetsuTokens.padding.large
            bottomMargin: CortetsuTokens.padding.large

            model: root.model

            delegate: CortetsuSurface {
                id: item

                required property var modelData
                readonly property bool selected: root.selectedItem === root.keyFor(modelData)

                anchors.left: ListView.view.contentItem.left
                anchors.right: ListView.view.contentItem.right
                anchors.margins: 1 // Gets cut off for some reason without this
                implicitHeight: label.implicitHeight + CortetsuTokens.padding.medium * 2

                radius: stateLayer.pressed ? CortetsuTokens.rounding.extraSmall : selected ? CortetsuTokens.rounding.largeIncreased : CortetsuTokens.rounding.medium
                color: Qt.alpha(CortetsuColours.palette.m3tertiaryContainer, selected ? 1 : 0)

                Behavior on radius {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }

                CortetsuStateLayer {
                    id: stateLayer

                    onClicked: root.selectedItem = root.keyFor(item.modelData)
                }

                CortetsuText {
                    id: label

                    anchors.left: parent.left
                    anchors.right: item.selected ? checkIcon.left : parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: CortetsuTokens.padding.large
                    anchors.rightMargin: item.selected ? CortetsuTokens.spacing.medium : anchors.margins

                    text: root.labelFor(item.modelData)
                    color: item.selected ? CortetsuColours.palette.m3onTertiaryContainer : CortetsuColours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                CortetsuIcon {
                    id: checkIcon

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: CortetsuTokens.padding.large

                    text: "check"
                    color: CortetsuColours.palette.m3onTertiaryContainer
                    fontStyle: CortetsuTokens.font.icon.medium
                    opacity: item.selected ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.SlowEffects
                        }
                    }
                }
            }
        }
    }
}
