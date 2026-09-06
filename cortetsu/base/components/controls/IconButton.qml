import QtQuick
import qs.components
import qs.services

ButtonBase {
    id: root

    property alias icon: label.text
    readonly property alias label: label

    font: CortetsuTokens.font.icon.medium
    padding: type === IconButton.Text ? CortetsuTokens.padding.extraSmall / 2 : CortetsuTokens.padding.small

    activeColour: type === IconButton.Filled ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3secondary
    inactiveColour: {
        if (!isToggle && type === IconButton.Filled)
            return CortetsuColours.palette.m3primary;
        return type === IconButton.Filled ? CortetsuColours.tPalette.m3surfaceContainer : CortetsuColours.palette.m3secondaryContainer;
    }
    activeOnColour: type === IconButton.Filled ? CortetsuColours.palette.m3onPrimary : type === IconButton.Tonal ? CortetsuColours.palette.m3onSecondary : CortetsuColours.palette.m3primary
    inactiveOnColour: {
        if (!isToggle && type === IconButton.Filled)
            return CortetsuColours.palette.m3onPrimary;
        return type === IconButton.Tonal ? CortetsuColours.palette.m3onSecondaryContainer : CortetsuColours.palette.m3onSurfaceVariant;
    }

    implicitWidth: implicitHeight
    implicitHeight: {
        // Ensure even size so icon is centered properly
        const h = label.implicitHeight + padding * 2;
        if (h % 2 !== 0)
            return h + 1;
        return h;
    }

    CortetsuIcon {
        id: label

        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1 // AHHHHHHH material symbols whyyyy
        color: root.onColour
        fontStyle: root.font
        fill: !root.isToggle || root.internalChecked ? 1 : 0

        Behavior on fill {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
