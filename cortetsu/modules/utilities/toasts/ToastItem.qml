import QtQuick
import "../.."
import "../../CortetsuDesign.js" as CortetsuDesign

CortetsuSurface {
    id: root

    required property var toast
    signal dismissed()
    implicitHeight: body.implicitHeight + CortetsuDesign.spacingStandard * 2
    width: parent ? parent.width : implicitWidth
    height: implicitHeight
    radiusValue: CortetsuDesign.radiusMedium
    baseColor: CortetsuDesign.colorSurfaceGlass
    outlined: true
    focus: true
    activeFocusOnTab: true
    focused: root.activeFocus
    outlineColor: toast.type === 2 ? CortetsuDesign.colorVermillion : CortetsuDesign.colorOutlineVariant

    Row {
        id: body
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingStandard
        spacing: CortetsuDesign.spacingStandard

        CortetsuIcon {
            width: 28
            height: parent.height
            text: root.toast.icon || "info"
            color: CortetsuDesign.colorTertiary
            iconSize: CortetsuDesign.iconMediumPx
        }

        Column {
            width: parent.width - 28 - parent.spacing
            spacing: 2

            CortetsuText {
                width: parent.width
                text: root.toast.title
                textSize: CortetsuDesign.bodyPx
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            CortetsuText {
                width: parent.width
                text: root.toast.message
                textSize: CortetsuDesign.bodyPx
                color: CortetsuDesign.colorOnSurfaceVariant
                wrapMode: Text.Wrap
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: root.dismissed()
    }

    Keys.onEnterPressed: root.dismissed()
    Keys.onReturnPressed: root.dismissed()
    Keys.onSpacePressed: root.dismissed()
    Keys.onEscapePressed: root.dismissed()

    Timer {
        interval: 5000
        running: true
        onTriggered: root.dismissed()
    }
}
