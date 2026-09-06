import QtQuick
import qs.components
import qs.services

ButtonBase {
    id: root

    property alias text: label.text
    readonly property alias label: label

    horizontalPadding: CortetsuTokens.padding.medium
    verticalPadding: CortetsuTokens.padding.small

    activeColour: type === TextButton.Filled ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3secondary
    inactiveColour: {
        if (!isToggle && type === TextButton.Filled)
            return CortetsuColours.palette.m3primary;
        return type === TextButton.Filled ? CortetsuColours.tPalette.m3surfaceContainer : CortetsuColours.palette.m3secondaryContainer;
    }
    activeOnColour: {
        if (type === TextButton.Text)
            return CortetsuColours.palette.m3primary;
        return type === TextButton.Filled ? CortetsuColours.palette.m3onPrimary : CortetsuColours.palette.m3onSecondary;
    }
    inactiveOnColour: {
        if (!isToggle && type === TextButton.Filled)
            return CortetsuColours.palette.m3onPrimary;
        if (type === TextButton.Text)
            return CortetsuColours.palette.m3primary;
        return type === TextButton.Filled ? CortetsuColours.palette.m3onSurface : CortetsuColours.palette.m3onSecondaryContainer;
    }

    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: label.implicitHeight + verticalPadding * 2

    CortetsuText {
        id: label

        anchors.centerIn: parent
        color: root.onColour
        font: root.font
    }
}
