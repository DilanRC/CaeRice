import QtQuick
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: CortetsuTokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    CortetsuStateLayer {
        radius: CortetsuTokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: CortetsuTokens.padding.medium
        anchors.rightMargin: CortetsuTokens.padding.medium
        anchors.margins: CortetsuTokens.padding.small

        CortetsuIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData?.icon ?? ""
            color: CortetsuColours.palette.m3onSurfaceVariant
            fontStyle: CortetsuTokens.font.icon.builders.large.scale(1.3).build()
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: CortetsuTokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width
            implicitHeight: name.implicitHeight + desc.implicitHeight

            CortetsuText {
                id: name

                text: root.modelData?.name ?? ""
                font: CortetsuTokens.font.body.medium
            }

            CortetsuText {
                id: desc

                text: root.modelData?.desc ?? ""
                font: CortetsuTokens.font.body.small
                color: CortetsuColours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - CortetsuTokens.rounding.extraLargeIncreased

                anchors.top: name.bottom
            }
        }
    }
}
