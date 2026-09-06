pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import qs.components
import qs.components.effects
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker

    property color pfpFallbackColour: CortetsuColours.layer(CortetsuColours.palette.m3surfaceContainerHighest, 2)

    anchors.fill: parent
    anchors.margins: CortetsuTokens.padding.large

    Behavior on pfpFallbackColour {
        CAnim {}
    }

    Item {
        id: pfpContainer

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: logoShape.right
        anchors.leftMargin: -(CortetsuTokens.padding.largeIncreased + CortetsuTokens.padding.extraLarge) / 2
        implicitWidth: height

        MaterialShape {
            id: shape

            anchors.centerIn: parent
            implicitSize: parent.height
            shape: MaterialShape.Pill
            color: Qt.alpha(root.pfpFallbackColour, 1)
            opacity: root.pfpFallbackColour.a
            layer.enabled: true

            MouseArea {
                id: mouse

                containmentMask: QtObject {
                    function contains(pt: point): bool {
                        return shape.contains(pt) && !logoShape.contains(mouse.mapToItem(logoShape, pt)) && !uptimeShape.contains(mouse.mapToItem(uptimeShape, pt));
                    }
                }

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.screenState.dashboard = false;
                    root.facePicker.open();
                }
            }
        }

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: Mask {
                maskSource: shape
            }

            Loader {
                anchors.centerIn: parent
                asynchronous: true
                active: pfp.status !== Image.Ready

                sourceComponent: CortetsuIcon {
                    text: "person_add"
                    color: CortetsuColours.palette.m3onSurfaceVariant
                    fontStyle: CortetsuTokens.font.icon.extraLarge
                    fill: 1
                    grade: -2 // Ugh material symbols are such a pain with fill
                }
            }

            CachingImage {
                id: pfp

                anchors.fill: parent
                path: `${Paths.home}/.face`
            }

            CortetsuSurface {
                anchors.fill: parent
                color: Qt.alpha(CortetsuColours.palette.m3scrim, pfp.status === Image.Ready ? 0.4 : 0)
                opacity: mouse.containsMouse ? 1 : 0
                layer.enabled: opacity < 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                MaterialShape {
                    anchors.centerIn: parent
                    implicitSize: parent.height * 0.7
                    shape: MaterialShape.Diamond
                    color: CortetsuColours.palette.m3primary
                    scale: mouse.pressed ? 0.9 : mouse.containsMouse ? 1 : 0.7

                    Behavior on color {
                        CAnim {}
                    }

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    CortetsuIcon {
                        anchors.centerIn: parent
                        text: "person_edit"
                        color: CortetsuColours.palette.m3onPrimary
                        fontStyle: CortetsuTokens.font.icon.large
                    }
                }
            }
        }
    }

    MaterialShape {
        id: logoShape

        x: CortetsuTokens.padding.extraSmall
        implicitSize: CortetsuTokens.sizes.dashboard.logoSize + CortetsuTokens.padding.small * 2
        shape: MaterialShape.Gem
        color: CortetsuColours.palette.m3primaryContainer

        Behavior on color {
            CAnim {}
        }

        Loader {
            anchors.centerIn: parent
            sourceComponent: SysInfo.isDefaultLogo ? cortetsuLogo : osLogo
        }
    }

    Component {
        id: osLogo

        ColouredIcon {
            id: icon

            source: SysInfo.osLogo
            implicitSize: CortetsuTokens.sizes.dashboard.logoSize
            colour: CortetsuColours.palette.m3onPrimaryContainer
        }
    }

    Component {
        id: cortetsuLogo

        Logo {
            implicitWidth: CortetsuTokens.sizes.dashboard.logoSize
            implicitHeight: CortetsuTokens.sizes.dashboard.logoSize
            topColour: CortetsuColours.palette.m3primary
            bottomColour: CortetsuColours.palette.m3onPrimaryContainer
        }
    }

    MaterialShape {
        id: uptimeShape

        anchors.bottom: parent.bottom
        anchors.left: pfpContainer.right
        anchors.bottomMargin: -CortetsuTokens.padding.small // Clamshell is taller than what it is visually
        anchors.leftMargin: -CortetsuTokens.padding.extraLargeIncreased
        implicitSize: CortetsuTokens.sizes.dashboard.uptimeSize + CortetsuTokens.padding.small * 2
        shape: MaterialShape.ClamShell
        color: CortetsuColours.palette.m3tertiaryContainer

        Behavior on color {
            CAnim {}
        }

        CortetsuIcon {
            anchors.centerIn: parent
            text: "clock_arrow_up"
            color: CortetsuColours.palette.m3onTertiaryContainer
            fontStyle: CortetsuTokens.font.icon.medium
        }
    }

    CortetsuText {
        anchors.left: uptimeShape.right
        anchors.verticalCenter: uptimeShape.verticalCenter
        anchors.leftMargin: CortetsuTokens.spacing.small
        anchors.verticalCenterOffset: Math.round(fontInfo.pointSize * 0.1)

        text: "up " + SysInfo.uptime.split(",").slice(0, 2).join(",") // Max 2 components
        width: CortetsuTokens.sizes.dashboard.userWidth - x - CortetsuTokens.padding.extraLarge
        elide: Text.ElideRight
    }

    CortetsuSurface {
        id: bubble1

        anchors.left: pfpContainer.right
        anchors.top: bubble2.bottom
        anchors.leftMargin: CortetsuTokens.spacing.small
        anchors.topMargin: -CortetsuTokens.spacing.extraSmall

        implicitWidth: 10
        implicitHeight: 10
        radius: CortetsuTokens.rounding.full
        color: CortetsuColours.palette.m3secondaryContainer
    }

    CortetsuSurface {
        id: bubble2

        anchors.left: bubble1.right
        anchors.verticalCenter: wmContainer.bottom
        anchors.leftMargin: CortetsuTokens.spacing.extraSmall

        implicitWidth: 15
        implicitHeight: 15
        radius: CortetsuTokens.rounding.full
        color: CortetsuColours.palette.m3secondaryContainer
    }

    CortetsuSurface {
        id: wmContainer

        anchors.left: bubble2.left
        anchors.leftMargin: -CortetsuTokens.padding.medium
        y: CortetsuTokens.padding.extraSmall

        radius: CortetsuTokens.rounding.largeIncreased
        color: CortetsuColours.palette.m3secondaryContainer
        implicitWidth: wmLabel.implicitWidth + CortetsuTokens.padding.medium * 2
        implicitHeight: wmLabel.implicitHeight + CortetsuTokens.padding.small * 2

        Row {
            id: wmLabel

            anchors.centerIn: parent
            spacing: CortetsuTokens.spacing.extraSmall

            CortetsuIcon {
                id: wmIcon

                anchors.verticalCenter: parent.verticalCenter
                text: "select_window"
                color: CortetsuColours.palette.m3onSecondaryContainer
                fontStyle: wmText.font
            }

            CortetsuText {
                id: wmText

                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Math.round(fontInfo.pointSize * 0.1)
                text: SysInfo.wm + "..."
                color: CortetsuColours.palette.m3onSecondaryContainer
                font: CortetsuTokens.font.body.builders.small.vaxis("slnt", -4).build()
                width: Math.min(implicitWidth, CortetsuTokens.sizes.dashboard.userWidth - wmContainer.x - CortetsuTokens.padding.medium * 2 - wmIcon.implicitWidth - wmLabel.spacing - CortetsuTokens.padding.extraLarge)
                elide: Text.ElideRight
            }
        }
    }
}
