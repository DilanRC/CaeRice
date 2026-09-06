pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wallpapers")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: CortetsuTokens.spacing.small

        ButtonRow {
            Layout.bottomMargin: CortetsuTokens.spacing.medium
            Layout.alignment: Qt.AlignHCenter
            spacing: CortetsuTokens.spacing.small

            IconTextButton {
                icon: "photo_library"
                text: qsTr("Browse")
                font: CortetsuTokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: CortetsuTokens.padding.extraLarge
                verticalPadding: CortetsuTokens.padding.medium
                onClicked: browseDialog.open()

                FileDialog {
                    id: browseDialog

                    title: qsTr("Select an image")
                    filterLabel: qsTr("Image files")
                    filters: Images.validImageExtensions
                    onAccepted: path => {
                        CortetsuWallpapers.setWallpaper(path);
                        root.nState.closeSubPage();
                    }
                }
            }

            IconTextButton {
                icon: "shuffle"
                text: qsTr("Random")
                font: CortetsuTokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: CortetsuTokens.padding.extraLarge
                verticalPadding: CortetsuTokens.padding.medium
                type: IconTextButton.Tonal
                onClicked: {
                    CortetsuWallpapers.setRandom();
                    root.nState.closeSubPage();
                }
            }
        }

        WallItem {
            imgHeight: Math.round(width * 0.3)
            radius: CortetsuTokens.rounding.extraLarge
            source: Quickshell.shellPath("assets/wallpaper.webp")
            text: qsTr("Featured wallpaper")
            fillLabel: false
            onClicked: {
                CortetsuWallpapers.setWallpaper(Quickshell.shellPath("assets/wallpaper.webp"));
                root.nState.closeSubPage();
            }
        }

        CortetsuText {
            Layout.topMargin: CortetsuTokens.spacing.large
            text: qsTr("Local wallpapers")
            font: CortetsuTokens.font.title.small
        }

        GridLayout {
            Layout.fillWidth: true
            visible: localWalls.count > 0

            columns: CortetsuConfig.nexusWallpapersPerRow
            rowSpacing: CortetsuTokens.spacing.medium
            columnSpacing: CortetsuTokens.spacing.large

            Repeater {
                id: localWalls

                model: {
                    const walls = CortetsuWallpapers.list;
                    const baseDir = Paths.wallsdir;
                    const categories = {};
                    const list = [];
                    for (const w of walls) {
                        if (w.parentDir !== baseDir) {
                            const category = CortetsuWallpapers.getCategoryFor(w);
                            if (category && (!(category in categories) || categories[category].name.localeCompare(w.name) > 0))
                                categories[category] = w;
                        } else {
                            list.push(w);
                        }
                    }
                    list.push(...Object.values(categories));
                    list.sort((a, b) => ((a.parentDir === baseDir) - (b.parentDir === baseDir)) || a.name.localeCompare(b.name));
                    while (list.length < CortetsuConfig.nexusWallpapersPerRow)
                        list.push(null);
                    return list;
                }

                WallItem {
                    required property var modelData

                    // Empty placeholders for sizing
                    opacity: modelData ? 1 : 0
                    enabled: modelData

                    source: String(modelData?.path ?? "")
                    text: {
                        if (!modelData)
                            return "";

                        if (modelData.parentDir !== Paths.wallsdir) {
                            const category = CortetsuWallpapers.getCategoryFor(modelData);
                            return category.slice(0, 1).toUpperCase() + category.slice(1);
                        }
                        return modelData.name;
                    }
                    onClicked: {
                        if (modelData.parentDir !== Paths.wallsdir) {
                            root.nState.selectedWallpaperCategory = CortetsuWallpapers.getCategoryFor(modelData);
                            root.nState.openSubPage(2); // Category page
                        } else {
                            CortetsuWallpapers.setWallpaper(modelData.path);
                            root.nState.closeSubPage();
                        }
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true

            asynchronous: true
            active: localWalls.count === 0
            visible: active

            sourceComponent: CortetsuSurface {
                color: CortetsuColours.tPalette.m3surfaceContainer
                radius: CortetsuTokens.rounding.extraLarge
                implicitHeight: noWallsLayout.implicitHeight + CortetsuTokens.padding.extraExtraLarge * 2

                ColumnLayout {
                    id: noWallsLayout

                    anchors.centerIn: parent
                    spacing: CortetsuTokens.spacing.extraSmall

                    CortetsuIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: CortetsuColours.palette.m3outline
                        fontStyle: CortetsuTokens.font.icon.extraLarge
                    }

                    CortetsuText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No local wallpapers found")
                        color: CortetsuColours.palette.m3outline
                        font: CortetsuTokens.font.title.small
                    }
                }
            }
        }
    }
}
