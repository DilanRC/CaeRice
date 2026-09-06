import "media"
import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.components
import qs.services

Item {
    id: root

    required property ScreenState screenState

    implicitWidth: CortetsuTokens.sizes.dashboard.mediaTabWidth
    implicitHeight: CortetsuTokens.sizes.dashboard.mediaTabHeight

    BackgroundShapes {
        anchors.fill: parent
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.large
        spacing: CortetsuTokens.spacing.extraLarge

        CoverVisualiser {
            Layout.fillHeight: true
            implicitWidth: CortetsuTokens.sizes.dashboard.mediaSectionWidth
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            state: Players.active ? "" : "noMedia"

            states: State {
                name: "noMedia"

                PropertyChanges {
                    noMedia.opacity: 1
                    content.opacity: 0
                }
            }

            transitions: [
                Transition {
                    from: ""

                    SequentialAnimation {
                        Anim {
                            target: content
                            property: "opacity"
                            type: Anim.DefaultEffects
                        }
                        Anim {
                            target: noMedia
                            property: "opacity"
                            type: Anim.SlowEffects
                        }
                    }
                },
                Transition {
                    to: ""

                    SequentialAnimation {
                        Anim {
                            target: noMedia
                            property: "opacity"
                            type: Anim.DefaultEffects
                        }
                        Anim {
                            target: content
                            property: "opacity"
                            type: Anim.SlowEffects
                        }
                    }
                }
            ]

            Loader {
                id: noMedia

                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -CortetsuTokens.padding.extraLarge * 2
                asynchronous: true
                active: opacity > 0
                opacity: 0

                sourceComponent: ColumnLayout {
                    spacing: CortetsuTokens.spacing.small

                    MaterialShape {
                        Layout.topMargin: (pathBounds().height - implicitSize) / 2
                        Layout.bottomMargin: (pathBounds().height - implicitSize) / 2 + CortetsuTokens.spacing.small
                        Layout.alignment: Qt.AlignHCenter
                        color: CortetsuColours.palette.m3primaryContainer
                        implicitSize: icon.implicitHeight + CortetsuTokens.padding.extraLarge * 2
                        shape: MaterialShape.ClamShell

                        Behavior on color {
                            CAnim {}
                        }

                        CortetsuIcon {
                            id: icon

                            anchors.centerIn: parent
                            text: "queue_music"
                            fontStyle: CortetsuTokens.font.icon.builders.large.scale(2).build()
                            color: CortetsuColours.palette.m3onPrimaryContainer
                        }
                    }

                    CortetsuText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Nothing playing")
                        font: CortetsuTokens.font.headline.medium
                    }

                    CortetsuText {
                        text: qsTr("Play something for it to show up here!")
                        color: CortetsuColours.palette.m3onSurfaceVariant
                        font: CortetsuTokens.font.body.large
                    }
                }
            }

            Loader {
                id: content

                anchors.fill: parent
                asynchronous: true
                active: opacity > 0

                sourceComponent: RowLayout {
                    spacing: CortetsuTokens.spacing.extraLarge

                    Details {
                        Layout.fillWidth: true
                    }

                    LyricsAndSelector {
                        Layout.fillHeight: true
                        implicitWidth: CortetsuTokens.sizes.dashboard.mediaSectionWidth
                    }
                }
            }
        }
    }
}
