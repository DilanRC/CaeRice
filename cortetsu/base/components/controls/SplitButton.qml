import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Row {
    id: root

    enum Type {
        Filled,
        Tonal
    }

    property real horizontalPadding: CortetsuTokens.padding.medium
    property real verticalPadding: CortetsuTokens.padding.small
    property int type: SplitButton.Filled
    property bool disabled
    property bool menuOnTop
    property string fallbackIcon
    property string fallbackText
    property real minLeftWidth

    property alias menuItems: menu.items
    property alias active: menu.active
    property alias expanded: menu.expanded
    readonly property alias menu: menu
    readonly property alias iconLabel: iconLabel
    readonly property alias label: label
    readonly property alias stateLayer: stateLayer
    readonly property alias textRow: textRow
    readonly property alias expandBtn: expandBtn

    property color colour: type == SplitButton.Filled ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3secondaryContainer
    property color textColour: type == SplitButton.Filled ? CortetsuColours.palette.m3onPrimary : CortetsuColours.palette.m3onSecondaryContainer
    property color disabledColour: Qt.alpha(CortetsuColours.palette.m3onSurface, 0.1)
    property color disabledTextColour: Qt.alpha(CortetsuColours.palette.m3onSurface, 0.38)

    spacing: Math.floor(CortetsuTokens.spacing.extraSmall / 2)

    CortetsuSurface {
        radius: implicitHeight / 2 * Math.min(1, CortetsuTokens.rounding.scale)
        topRightRadius: CortetsuTokens.rounding.medium / 2
        bottomRightRadius: CortetsuTokens.rounding.medium / 2
        color: root.disabled ? root.disabledColour : root.colour

        implicitWidth: Math.max(root.minLeftWidth, textRow.implicitWidth + root.horizontalPadding * 2)
        implicitHeight: expandBtn.implicitHeight

        CortetsuStateLayer {
            id: stateLayer

            topRightRadius: parent.topRightRadius
            bottomRightRadius: parent.bottomRightRadius
            color: root.textColour
            disabled: root.disabled
            onClicked: root.active?.clicked()
        }

        RowLayout {
            id: textRow

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: Math.floor(root.verticalPadding / 4)
            spacing: CortetsuTokens.spacing.small

            CortetsuIcon {
                id: iconLabel

                Layout.alignment: Qt.AlignVCenter
                animate: true
                text: root.active?.activeIcon ?? root.fallbackIcon
                color: root.disabled ? root.disabledTextColour : root.textColour
                fill: 1
            }

            CortetsuText {
                id: label

                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
                animate: true
                text: root.active?.activeText ?? root.fallbackText
                color: root.disabled ? root.disabledTextColour : root.textColour
                clip: true

                Behavior on Layout.preferredWidth {
                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }
        }
    }

    CortetsuSurface {
        id: expandBtn

        property real rad: root.expanded ? implicitHeight / 2 * Math.min(1, CortetsuTokens.rounding.scale) : CortetsuTokens.rounding.medium / 2

        radius: implicitHeight / 2 * Math.min(1, CortetsuTokens.rounding.scale)
        topLeftRadius: rad
        bottomLeftRadius: rad
        color: root.disabled ? root.disabledColour : root.colour

        implicitWidth: implicitHeight
        implicitHeight: expandIcon.implicitHeight + root.verticalPadding * 2

        CortetsuStateLayer {
            id: expandStateLayer

            rect.topLeftRadius: parent.topLeftRadius
            rect.bottomLeftRadius: parent.bottomLeftRadius
            color: root.textColour
            disabled: root.disabled
            onClicked: root.expanded = !root.expanded
        }

        CortetsuIcon {
            id: expandIcon

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.expanded ? 0 : -Math.floor(root.verticalPadding / 4)

            text: "expand_more"
            color: root.disabled ? root.disabledTextColour : root.textColour
            rotation: root.expanded ? 180 : 0

            Behavior on anchors.horizontalCenterOffset {
                Anim {}
            }

            Behavior on rotation {
                Anim {}
            }
        }

        Behavior on rad {
            Anim {}
        }
    }

    Menu {
        id: menu

        attachTo: expandBtn
        attachSideY: root.menuOnTop ? Menu.Top : Menu.Bottom
        thisSideY: root.menuOnTop ? Menu.Bottom : Menu.Top
        marginY: CortetsuTokens.spacing.small * (root.menuOnTop ? -1 : 1)
    }
}
