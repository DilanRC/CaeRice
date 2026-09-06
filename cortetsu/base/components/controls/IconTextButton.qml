import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

ButtonBase {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text
    property alias spacing: row.spacing

    readonly property alias iconLabel: iconLabel
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

    implicitWidth: row.implicitWidth + horizontalPadding * 2
    implicitHeight: row.implicitHeight + verticalPadding * 2

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: CortetsuTokens.spacing.small

        CortetsuIcon {
            id: iconLabel

            Layout.alignment: Qt.AlignVCenter
            color: root.onColour
            fill: root.internalChecked ? 1 : 0
            fontStyle: {
                const f = Qt.font(root.font);
                f.pointSize = Math.round(root.font.pointSize * 1.2);
                return f;
            }

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        CortetsuText {
            id: label

            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: 1
            color: root.onColour
            font: root.font
        }
    }
}
