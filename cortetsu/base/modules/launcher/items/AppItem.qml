import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DesktopEntry modelData
    required property ScreenState screenState

    implicitHeight: CortetsuTokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    CortetsuStateLayer {
        radius: CortetsuTokens.rounding.large
        onClicked: {
            Apps.launch(root.modelData);
            root.screenState.launcher = false;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: CortetsuTokens.padding.medium
        anchors.rightMargin: CortetsuTokens.padding.medium
        anchors.margins: CortetsuTokens.padding.small

        IconImage {
            id: icon

            asynchronous: false
            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: CortetsuTokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - favouriteIcon.width
            implicitHeight: name.implicitHeight + comment.implicitHeight

            CortetsuText {
                id: name

                text: root.modelData?.name ?? ""
                font: CortetsuTokens.font.body.medium
            }

            CortetsuText {
                id: comment

                text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font: CortetsuTokens.font.body.small
                color: CortetsuColours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - favouriteIcon.width - CortetsuTokens.rounding.extraLargeIncreased

                anchors.top: name.bottom
            }
        }

        Loader {
            id: favouriteIcon

            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            active: root.modelData && Strings.testRegexList(CortetsuConfig.favouriteApps, root.modelData.id)

            sourceComponent: CortetsuIcon {
                text: "favorite"
                fill: 1
                color: CortetsuColours.palette.m3primary
            }
        }
    }
}
