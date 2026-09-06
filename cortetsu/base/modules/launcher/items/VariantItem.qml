import QtQuick
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property M3Variants.Variant modelData
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

            text: root.modelData?.icon ?? ""
            fontStyle: CortetsuTokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: CortetsuTokens.spacing.large
            anchors.verticalCenter: icon.verticalCenter

            width: parent.width - icon.width - anchors.leftMargin - (current.active ? current.width + CortetsuTokens.spacing.medium : 0)
            spacing: 0

            CortetsuText {
                text: root.modelData?.name ?? ""
                font: CortetsuTokens.font.body.medium
            }

            CortetsuText {
                text: root.modelData?.description ?? ""
                font: CortetsuTokens.font.body.small
                color: CortetsuColours.palette.m3outline

                elide: Text.ElideRight
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        Loader {
            id: current

            asynchronous: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            active: root.modelData?.variant === Schemes.currentVariant

            sourceComponent: CortetsuIcon {
                text: "check"
                color: CortetsuColours.palette.m3onSurfaceVariant
                fontStyle: CortetsuTokens.font.icon.large
            }
        }
    }
}
