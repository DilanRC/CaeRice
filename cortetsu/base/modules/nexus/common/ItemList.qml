pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

ConnectedRect {
    id: root

    property bool showList
    property string placeholderIcon
    property string placeholderText
    property int extraHeight

    property alias model: list.model
    property alias delegate: list.delegate
    readonly property alias list: list

    Layout.fillWidth: true
    implicitHeight: (showList && list.count > 0 ? list.contentHeight : placeholder.implicitHeight + CortetsuTokens.padding.extraLarge * 2) + extraHeight
    color: CortetsuColours.tPalette.m3surfaceContainer
    clip: true

    Behavior on implicitHeight {
        Anim {}
    }

    Loader {
        id: placeholder

        anchors.centerIn: parent
        active: opacity > 0
        opacity: root.showList && list.count > 0 ? 0 : 1

        sourceComponent: ColumnLayout {
            spacing: CortetsuTokens.spacing.extraSmall

            CortetsuIcon {
                Layout.alignment: Qt.AlignHCenter
                text: root.placeholderIcon
                color: CortetsuColours.palette.m3outline
                fontStyle: CortetsuTokens.font.icon.large
                animate: true
            }

            CortetsuText {
                Layout.alignment: Qt.AlignHCenter
                text: root.placeholderText
                color: CortetsuColours.palette.m3outline
                font: CortetsuTokens.font.body.large
                animate: true
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    ListView {
        id: list

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        spacing: 0
        interactive: false
        opacity: root.showList ? 1 : 0

        add: Transition {
            Anim {
                property: "opacity"
                from: 0
                to: 1
                type: Anim.DefaultEffects
            }
        }

        remove: Transition {
            Anim {
                property: "opacity"
                to: 0
                type: Anim.DefaultEffects
            }
        }

        move: Transition {
            Anim {
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
            Anim {
                property: "y"
            }
        }

        displaced: Transition {
            Anim {
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
            Anim {
                property: "y"
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
