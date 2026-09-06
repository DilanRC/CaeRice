import QtQuick
import QtQuick.Layouts
import "../"
import "../../services"
import qs.utils

CortetsuSurface {
    id: root
    required property NotifData modelData
    required property var props
    required property bool expanded
    required property var screenState
    property bool hovered: false
    readonly property real nonAnimHeight: summary.implicitHeight + body.implicitHeight + CortetsuDesign.spacingComfortable * 2
    implicitHeight: nonAnimHeight
    radiusValue: CortetsuDesign.radiusMedium
    outlined: false
    baseColor: modelData.urgency === 2 ? Qt.darker(CortetsuDesign.colorVermillion, 1.8) : CortetsuDesign.colorSurfaceHigh
    opacity: modelData.closed ? 0 : 1

    Component.onCompleted: modelData.lock(root)
    Component.onDestruction: modelData.unlock(root)

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.expanded = !root.expanded
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingComfortable
        spacing: CortetsuDesign.spacingCompact
        RowLayout {
            Layout.fillWidth: true
            CortetsuIcon { text: Icons.getNotifIcon(root.modelData.summary, root.modelData.urgency); iconSize: 20; color: CortetsuDesign.colorTertiary }
            CortetsuText { id: summary; Layout.fillWidth: true; text: root.modelData.summary; textSize: 16; elide: Text.ElideRight; font.weight: Font.DemiBold }
            CortetsuText { text: root.modelData.timeStr; textSize: 11; color: CortetsuDesign.colorOnSurfaceVariant }
        }
        CortetsuText {
            id: body
            Layout.fillWidth: true
            text: root.modelData.body
            textSize: 13
            maximumLineCount: root.expanded ? 8 : 2
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            visible: text.length > 0
        }
        RowLayout {
            Layout.fillWidth: true
            visible: root.expanded || root.modelData.actions.length > 0
            Repeater {
                model: root.modelData.actions
                delegate: Rectangle {
                    required property var modelData
                    implicitWidth: actionText.implicitWidth + 20; implicitHeight: 30; radius: 10
                    color: CortetsuDesign.colorSecondaryContainer
                    CortetsuText { id: actionText; anchors.centerIn: parent; text: modelData.text; textSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: modelData.invoke() }
                }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                implicitWidth: 64; implicitHeight: 30; radius: 10; color: CortetsuDesign.colorPrimaryContainer
                CortetsuText { anchors.centerIn: parent; text: qsTr("Close"); textSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: root.modelData.close() }
            }
        }
    }
}
