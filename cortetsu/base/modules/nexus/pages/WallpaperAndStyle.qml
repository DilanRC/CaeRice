pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wallpaper & style")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: CortetsuTokens.spacing.large

        StyledClippingRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: {
                const screen = root.nState.screen;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            color: CortetsuColours.tPalette.m3surfaceContainer
            radius: CortetsuTokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: CortetsuConfig.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: CortetsuTokens.spacing.extraSmall

                    CortetsuIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: CortetsuColours.palette.m3onSurfaceVariant
                        fontStyle: CortetsuTokens.font.icon.extraLarge
                    }

                    CortetsuText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Wallpaper disabled")
                        color: CortetsuColours.palette.m3onSurfaceVariant
                        font: CortetsuTokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: CortetsuConfig.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }

                Loader {
                    id: wallIndicatorLoader

                    anchors.centerIn: parent

                    opacity: 0
                    active: opacity > 0

                    sourceComponent: CortetsuSurface {
                        implicitWidth: wallLoadingIndicator.implicitSize + CortetsuTokens.padding.largeIncreased * 2
                        implicitHeight: wallLoadingIndicator.implicitSize + CortetsuTokens.padding.largeIncreased * 2

                        color: CortetsuColours.palette.m3primaryContainer
                        radius: CortetsuTokens.rounding.full

                        LoadingIndicator {
                            id: wallLoadingIndicator

                            anchors.centerIn: parent
                            containsIcon: true
                            implicitSize: Math.min(wallWrapper.implicitWidth, wallWrapper.implicitHeight) * 0.4
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Timer {
                    id: wallLoadDebounceTimer

                    interval: 100
                    onTriggered: {
                        if (wallImg.status !== Image.Ready)
                            wallIndicatorLoader.opacity = 1;
                    }
                }

                FadeImage {
                    id: wallImg

                    anchors.fill: parent
                    source: CortetsuWallpapers.current
                    preventInit: wallIndicatorLoader.opacity > 0
                    fadeOutAnim: Anim.DefaultEffects
                    fadeInAnim: Anim.SlowEffects

                    onSourceChanged: wallLoadDebounceTimer.restart()

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            wallLoadDebounceTimer.stop();
                            wallIndicatorLoader.opacity = 0;
                        }
                    }
                }
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: CortetsuTokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: qsTr("Wallpapers")
                font: CortetsuTokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: CortetsuTokens.padding.extraLarge
                verticalPadding: CortetsuTokens.padding.medium
                disabled: !CortetsuConfig.wallpaperEnabled
                onClicked: root.nState.openSubPage(1) // Wallpaper page
            }

            IconTextButton {
                icon: "palette"
                text: qsTr("CortetsuColours")
                font: CortetsuTokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: CortetsuTokens.padding.extraLarge
                verticalPadding: CortetsuTokens.padding.medium
                onClicked: root.nState.openSubPage(3) // CortetsuColours page
            }
        }

        ToggleRow {
            first: true
            text: qsTr("Display wallpaper")
            checked: CortetsuConfig.wallpaperEnabled
            onToggled: CortetsuConfig.wallpaperEnabled = checked
        }

        ToggleRow {
            Layout.topMargin: CortetsuTokens.spacing.extraSmall / 2 - parent.spacing

            text: qsTr("Transparency")
            subtext: qsTr("Base %1, layers %2").arg(CortetsuColours.transparency.base).arg(CortetsuColours.transparency.layers)
            checked: CortetsuColours.transparency.enabled
            onToggled: CortetsuConfig.transparencyEnabled = checked
        }

        ToggleRow {
            Layout.topMargin: CortetsuTokens.spacing.extraSmall / 2 - parent.spacing

            last: true
            text: qsTr("Dark theme")
            checked: !CortetsuColours.light
            onToggled: CortetsuColours.setMode(checked ? "dark" : "light")
        }
    }
}
