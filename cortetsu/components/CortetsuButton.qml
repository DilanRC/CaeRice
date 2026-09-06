import QtQuick
import "../modules/CortetsuDesign.js" as CortetsuDesign
import "../modules/CortetsuTypography.js" as CortetsuTypography

Item {
    id: root

    focus: !disabled
    activeFocusOnTab: !disabled

    property string label
    property string icon
    property bool active: false
    property bool danger: false
    property bool disabled: false
    property bool compact: false
    signal clicked()

    implicitWidth: row.implicitWidth + CortetsuDesign.spacingStandard * 2
    implicitHeight: compact ? 32 : CortetsuDesign.controlHeight
    opacity: disabled ? 0.48 : 1

    CortetsuSurface {
        id: surface
        anchors.fill: parent
        radiusValue: CortetsuDesign.radiusPill
        active: root.active
        danger: root.danger
        disabled: root.disabled
        focused: root.activeFocus
        baseColor: root.active ? CortetsuDesign.colorPrimary : CortetsuDesign.colorSurfaceGlass
        outlined: !root.active
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: CortetsuDesign.spacingCompact

        CortetsuIcon {
            visible: root.icon.length > 0
            text: root.icon
            iconSize: root.compact ? CortetsuTypography.iconSmallPx : CortetsuTypography.iconMediumPx
            color: root.active ? CortetsuDesign.colorOnPrimary : CortetsuDesign.colorOnSurface
            anchors.verticalCenter: parent.verticalCenter
        }

        CortetsuText {
            visible: root.label.length > 0
            text: root.label
            textSize: root.compact ? CortetsuTypography.labelMediumPx : CortetsuTypography.bodyPx
            color: root.active ? CortetsuDesign.colorOnPrimary : CortetsuDesign.colorOnSurface
            anchors.verticalCenter: parent.verticalCenter
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
