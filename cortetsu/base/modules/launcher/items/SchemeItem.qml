import QtQuick
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property Schemes.Scheme modelData
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

        CortetsuSurface {
            id: preview

            anchors.verticalCenter: parent.verticalCenter

            border.width: 1
            border.color: Qt.alpha(`#${root.modelData?.colours?.outline}`, 0.5)

            color: `#${root.modelData?.colours?.surface}`
            radius: CortetsuTokens.rounding.full
            implicitWidth: parent.height * 0.8
            implicitHeight: parent.height * 0.8

            Item {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right

                implicitWidth: parent.implicitWidth / 2
                clip: true

                CortetsuSurface {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right

                    implicitWidth: preview.implicitWidth
                    color: `#${root.modelData?.colours?.primary}`
                    radius: CortetsuTokens.rounding.full
                }
            }
        }

        Column {
            anchors.left: preview.right
            anchors.leftMargin: CortetsuTokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter

            width: parent.width - preview.width - anchors.leftMargin - (current.active ? current.width + CortetsuTokens.spacing.medium : 0)
            spacing: 0

            CortetsuText {
                text: root.modelData?.flavour ?? ""
                font: CortetsuTokens.font.body.medium
            }

            CortetsuText {
                text: root.modelData?.name ?? ""
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

            active: `${root.modelData?.name} ${root.modelData?.flavour}` === Schemes.currentScheme

            sourceComponent: CortetsuIcon {
                text: "check"
                color: CortetsuColours.palette.m3onSurfaceVariant
                fontStyle: CortetsuTokens.font.icon.large
            }
        }
    }
}
