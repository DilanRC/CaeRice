pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

CortetsuSurface {
    id: root

    required property var dialog

    implicitWidth: inner.implicitWidth + CortetsuTokens.padding.medium * 2
    implicitHeight: inner.implicitHeight + CortetsuTokens.padding.medium * 2

    color: CortetsuColours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.medium
        spacing: CortetsuTokens.spacing.small

        Item {
            implicitWidth: implicitHeight
            implicitHeight: upIcon.implicitHeight + CortetsuTokens.padding.small

            CortetsuStateLayer {
                radius: CortetsuTokens.rounding.medium
                disabled: root.dialog.cwd.length === 1
                onClicked: root.dialog.cwd.pop()
            }

            CortetsuIcon {
                id: upIcon

                anchors.centerIn: parent
                text: "drive_folder_upload"
                color: root.dialog.cwd.length === 1 ? CortetsuColours.palette.m3outline : CortetsuColours.palette.m3onSurface
                grade: 200
            }
        }

        CortetsuSurface {
            Layout.fillWidth: true

            radius: CortetsuTokens.rounding.medium
            color: CortetsuColours.tPalette.m3surfaceContainerHigh

            implicitHeight: pathComponents.implicitHeight + pathComponents.anchors.margins * 2

            RowLayout {
                id: pathComponents

                anchors.fill: parent
                anchors.margins: CortetsuTokens.padding.extraSmall / 2
                anchors.leftMargin: 0

                spacing: CortetsuTokens.spacing.small

                Repeater {
                    model: root.dialog.cwd

                    RowLayout {
                        id: folder

                        required property string modelData
                        required property int index

                        spacing: 0

                        Loader {
                            asynchronous: true
                            Layout.rightMargin: CortetsuTokens.spacing.small
                            active: folder.index > 0
                            sourceComponent: CortetsuText {
                                text: "/"
                                color: CortetsuColours.palette.m3onSurfaceVariant
                                font: CortetsuTokens.font.body.builders.small.weight(Font.Bold).build()
                            }
                        }

                        Item {
                            implicitWidth: homeIcon.implicitWidth + (homeIcon.active ? CortetsuTokens.padding.extraSmall : 0) + folderName.implicitWidth + CortetsuTokens.padding.medium * 2
                            implicitHeight: folderName.implicitHeight + CortetsuTokens.padding.small

                            Loader {
                                asynchronous: true
                                anchors.fill: parent
                                active: folder.index < root.dialog.cwd.length - 1
                                sourceComponent: CortetsuStateLayer {
                                    onClicked: {
                                        root.dialog.cwd = root.dialog.cwd.slice(0, folder.index + 1);
                                    }

                                    radius: CortetsuTokens.rounding.medium
                                }
                            }

                            Loader {
                                id: homeIcon

                                asynchronous: true

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: CortetsuTokens.padding.medium

                                active: folder.index === 0 && folder.modelData === "Home"
                                sourceComponent: CortetsuIcon {
                                    text: "home"
                                    color: root.dialog.cwd.length === 1 ? CortetsuColours.palette.m3onSurface : CortetsuColours.palette.m3onSurfaceVariant
                                    fill: 1
                                }
                            }

                            CortetsuText {
                                id: folderName

                                anchors.left: homeIcon.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: homeIcon.active ? CortetsuTokens.padding.extraSmall : 0

                                text: folder.modelData
                                color: folder.index < root.dialog.cwd.length - 1 ? CortetsuColours.palette.m3onSurfaceVariant : CortetsuColours.palette.m3onSurface
                                font: CortetsuTokens.font.body.builders.small.weight(Font.Bold).build()
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
