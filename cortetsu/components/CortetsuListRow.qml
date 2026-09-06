import QtQuick
import "../modules/CortetsuDesign.js" as CortetsuDesign

Item {
    id: root

    focus: !disabled
    activeFocusOnTab: !disabled

    property string icon
    property string title
    property string subtitle
    property bool selected: false
    property bool disabled: false
    signal clicked()

    implicitHeight: CortetsuDesign.rowHeight
    opacity: disabled ? 0.48 : 1

    CortetsuSurface {
        anchors.fill: parent
        radiusValue: CortetsuDesign.radiusSmall
        active: root.selected
        disabled: root.disabled
        focused: root.activeFocus
        baseColor: root.selected ? CortetsuDesign.colorPrimaryContainer : "transparent"
        hoverColor: CortetsuDesign.colorSurfaceGlass
        outlined: false
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    Row {
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingCompact
        spacing: CortetsuDesign.spacingStandard

        CortetsuIcon {
            visible: root.icon.length > 0
            text: root.icon
            iconSize: CortetsuDesign.iconMediumPx
            color: root.selected ? CortetsuDesign.colorOnPrimaryContainer : CortetsuDesign.colorPrimary
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            width: parent.width - x

            CortetsuText {
                width: parent.width
                text: root.title
                textSize: CortetsuDesign.bodyPx
                color: root.selected ? CortetsuDesign.colorOnPrimaryContainer : CortetsuDesign.colorOnSurface
                elide: Text.ElideRight
            }
            CortetsuText {
                width: parent.width
                visible: text.length > 0
                text: root.subtitle
                textSize: CortetsuDesign.labelSmallPx
                color: CortetsuDesign.colorOnSurfaceVariant
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !root.disabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Keys.onEnterPressed: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()
}
