import QtQuick
import qs.components
import qs.services

TextFieldBase {
    id: root

    readonly property alias bg: bg
    readonly property alias searchIcon: searchIcon
    readonly property alias clearIcon: clearIcon

    leftPadding: searchIcon.width + searchIcon.anchors.leftMargin + CortetsuTokens.spacing.medium
    rightPadding: clearIcon.width + clearIcon.anchors.rightMargin + CortetsuTokens.spacing.medium
    topPadding: CortetsuTokens.padding.large
    bottomPadding: CortetsuTokens.padding.large

    onPressed: {
        if (!stateLayer.disabled)
            stateLayer.press(stateLayer.mouseX, stateLayer.mouseY);
    }

    background: CortetsuSurface {
        id: bg

        anchors.fill: parent
        color: CortetsuColours.tPalette.m3surfaceContainer
        radius: CortetsuTokens.rounding.full

        CortetsuStateLayer {
            id: stateLayer

            cursorShape: Qt.IBeamCursor
            disabled: root.activeFocus
            manualPressOverride: tapHandler.pressed
            onClicked: root.focus = true
        }
    }

    CortetsuText {
        id: placeholder

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.leftPadding

        text: root.placeholderText
        color: root.placeholderTextColor
        font: root.font

        opacity: root.text ? 0 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    CortetsuIcon {
        id: searchIcon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: CortetsuTokens.padding.large

        text: "search"
        color: CortetsuColours.palette.m3onSurfaceVariant
        fontStyle: CortetsuTokens.font.icon.builders.medium.scale(0.9).build()
    }

    IconButton {
        id: clearIcon

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: CortetsuTokens.padding.medium

        icon: "clear"
        type: IconButton.Text
        radius: CortetsuTokens.rounding.full
        radiusMorph: false
        enabled: root.text
        stateLayer.hoverEnabled: enabled
        onClicked: root.clear()

        opacity: root.text ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    TapHandler {
        id: tapHandler
    }
}
