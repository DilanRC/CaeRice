pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.filedialog
import qs.services

CortetsuSurface {
    id: root

    required property var dialog

    implicitWidth: Sizes.sidebarWidth
    implicitHeight: inner.implicitHeight + CortetsuTokens.padding.medium * 2

    color: CortetsuColours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: CortetsuTokens.padding.medium
        spacing: CortetsuTokens.spacing.extraSmall

        CortetsuText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: CortetsuTokens.padding.extraSmall / 2
            Layout.bottomMargin: CortetsuTokens.spacing.medium
            text: qsTr("Files")
            color: CortetsuColours.palette.m3onSurface
            font: CortetsuTokens.font.body.builders.large.weight(Font.Bold).build()
        }

        Repeater {
            model: ["Home", "Downloads", "Desktop", "Documents", "Music", "Pictures", "Videos"]

            CortetsuSurface {
                id: place

                required property string modelData
                readonly property bool selected: modelData === root.dialog.cwd[root.dialog.cwd.length - 1]

                Layout.fillWidth: true
                implicitHeight: placeInner.implicitHeight + CortetsuTokens.padding.medium * 2

                radius: CortetsuTokens.rounding.full
                color: Qt.alpha(CortetsuColours.palette.m3secondaryContainer, selected ? 1 : 0)

                CortetsuStateLayer {
                    color: place.selected ? CortetsuColours.palette.m3onSecondaryContainer : CortetsuColours.palette.m3onSurface
                    onClicked: {
                        if (place.modelData === "Home")
                            root.dialog.cwd = ["Home"];
                        else
                            root.dialog.cwd = ["Home", place.modelData];
                    }
                }

                RowLayout {
                    id: placeInner

                    anchors.fill: parent
                    anchors.margins: CortetsuTokens.padding.medium
                    anchors.leftMargin: CortetsuTokens.padding.large
                    anchors.rightMargin: CortetsuTokens.padding.large

                    spacing: CortetsuTokens.spacing.medium

                    CortetsuIcon {
                        text: {
                            const p = place.modelData;
                            if (p === "Home")
                                return "home";
                            if (p === "Downloads")
                                return "file_download";
                            if (p === "Desktop")
                                return "desktop_windows";
                            if (p === "Documents")
                                return "description";
                            if (p === "Music")
                                return "music_note";
                            if (p === "Pictures")
                                return "image";
                            if (p === "Videos")
                                return "video_library";
                            return "folder";
                        }
                        color: place.selected ? CortetsuColours.palette.m3onSecondaryContainer : CortetsuColours.palette.m3onSurface
                        fontStyle: CortetsuTokens.font.icon.medium
                        fill: place.selected ? 1 : 0

                        Behavior on fill {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    CortetsuText {
                        Layout.fillWidth: true
                        text: place.modelData
                        color: place.selected ? CortetsuColours.palette.m3onSecondaryContainer : CortetsuColours.palette.m3onSurface
                        font: CortetsuTokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
