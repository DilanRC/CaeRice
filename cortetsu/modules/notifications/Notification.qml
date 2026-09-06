import QtQuick
import QtQuick.Layouts
import "../"
import "../../components"
import "../../services"
import qs.utils
import "../CortetsuDesign.js" as CortetsuDesign
import "../CortetsuTypography.js" as CortetsuTypography

CortetsuSurface {
    id: root
    required property var modelData
    required property var props
    required property bool expanded
    required property var screenState
    property bool hovered: false
    readonly property real nonAnimHeight: contentLayout.implicitHeight + CortetsuDesign.spacingComfortable * 2
    implicitHeight: nonAnimHeight
    radiusValue: CortetsuDesign.radiusMedium
    outlined: false
    focus: true
    activeFocusOnTab: true
    focused: root.activeFocus
    baseColor: modelData.urgency >= 2 ? Qt.darker(CortetsuDesign.colorVermillion, 1.8) : CortetsuDesign.colorSurfaceHigh
    outlineColor: modelData.urgency >= 2 ? CortetsuDesign.colorVermillion : CortetsuDesign.colorOutlineVariant
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

    Keys.onEnterPressed: root.expanded = !root.expanded
    Keys.onReturnPressed: root.expanded = !root.expanded
    Keys.onSpacePressed: root.expanded = !root.expanded
    Keys.onEscapePressed: root.modelData.close()

    ColumnLayout {
        id: contentLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: CortetsuDesign.spacingComfortable
        spacing: CortetsuDesign.spacingCompact
        RowLayout {
            Layout.fillWidth: true
            CortetsuIcon {
                text: Icons.getNotifIcon(root.modelData.summary, root.modelData.urgency)
                iconSize: CortetsuTypography.iconMediumPx
                color: root.modelData.urgency >= 2 ? CortetsuDesign.colorVermillion : CortetsuDesign.colorTertiary
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                CortetsuText {
                    id: summary
                    Layout.fillWidth: true
                    text: root.modelData.summary
                    textSize: CortetsuTypography.bodyLargePx
                    elide: Text.ElideRight
                    font.weight: Font.DemiBold
                }
                CortetsuText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.modelData.appName || qsTr("System notification")
                    textSize: CortetsuTypography.labelSmallPx
                    color: CortetsuDesign.colorOnSurfaceVariant
                    elide: Text.ElideRight
                }
            }
            CortetsuText { text: root.modelData.timeStr; textSize: CortetsuTypography.labelSmallPx; color: CortetsuDesign.colorOnSurfaceVariant }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: CortetsuDesign.spacingCompact
            Image {
                Layout.preferredWidth: visible ? 52 : 0
                Layout.preferredHeight: visible ? 52 : 0
                visible: source.length > 0
                source: root.modelData.image
                sourceSize.width: 104
                sourceSize.height: 104
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
                clip: true
            }
            CortetsuText {
                id: body
                Layout.fillWidth: true
                text: root.modelData.body
                textSize: CortetsuTypography.bodyPx
                maximumLineCount: root.expanded ? 8 : 2
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                visible: text.length > 0
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: true
            Repeater {
                model: root.modelData.actions
                delegate: CortetsuButton {
                    required property int index
                    Layout.fillWidth: false
                    compact: true
                    label: root.modelData.actions[index].text
                    onClicked: root.modelData.actions[index].invoke()
                }
            }
            Item { Layout.fillWidth: true }
            CortetsuButton {
                compact: true
                label: qsTr("Dismiss")
                icon: "close"
                danger: true
                onClicked: root.modelData.close()
            }
        }
    }
}
