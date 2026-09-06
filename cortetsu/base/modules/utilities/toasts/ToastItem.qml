import QtQuick
import "../../CortetsuDesign.js" as CortetsuDesign
import "../../CortetsuTypography.js" as CortetsuTypography

Rectangle {
    id: root

    required property var toast
    signal dismissed()
    implicitHeight: body.implicitHeight + CortetsuDesign.spacingStandard * 2
    radius: CortetsuDesign.radiusMedium
    color: CortetsuDesign.colorSurfaceHigh
    border.width: 1
    border.color: toast.type === 2 ? CortetsuDesign.colorVermillion : CortetsuDesign.colorOutlineVariant

    Row {
        id: body
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingStandard
        spacing: CortetsuDesign.spacingStandard

        Text {
            width: 28
            height: parent.height
            text: root.toast.icon || "info"
            color: CortetsuDesign.colorTertiary
            font.family: CortetsuTypography.iconFamily
            font.pixelSize: CortetsuTypography.iconMediumPx
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Column {
            width: parent.width - 28 - parent.spacing
            spacing: 2

            Text {
                width: parent.width
                text: root.toast.title
                color: CortetsuDesign.colorWashi
                font.family: CortetsuTypography.uiFamily
                font.pixelSize: CortetsuTypography.bodyPx
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.toast.message
                color: CortetsuDesign.colorMuted
                font.family: CortetsuTypography.uiFamily
                font.pixelSize: CortetsuTypography.bodyPx
                wrapMode: Text.Wrap
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: root.dismissed()
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.dismissed()
    }
}
