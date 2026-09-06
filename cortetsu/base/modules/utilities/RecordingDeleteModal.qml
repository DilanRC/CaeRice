pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import qs.modules

Loader {
    id: root

    required property var props
    required property matrix4x4 deformMatrix

    asynchronous: true
    anchors.fill: parent

    opacity: root.props.recordingConfirmDelete ? 1 : 0
    active: opacity > 0

    sourceComponent: MouseArea {
        id: deleteConfirmation

        property string path

        Component.onCompleted: path = root.props.recordingConfirmDelete

        hoverEnabled: true
        onClicked: root.props.recordingConfirmDelete = ""

        Item {
            anchors.fill: parent
            anchors.margins: -Tokens.padding.large
            anchors.rightMargin: -Tokens.padding.large - CortetsuConfig.borderThickness
            anchors.bottomMargin: -Tokens.padding.large - CortetsuConfig.borderThickness
            opacity: 0.5

            CortetsuSurface {
                anchors.fill: parent
                anchors.rightMargin: -parent.width * (1 - root.deformMatrix.m11) / 2 // Additional bit to account for deform
                anchors.bottomMargin: -parent.height * 0.1 // Additional bit to account for overshoot
                topLeftRadius: Tokens.rounding.extraLarge
                color: Colours.palette.m3scrim
            }

            Shape {
                id: shape

                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                asynchronous: true

                // Bottom left
                ShapePath {
                    startX: -CortetsuConfig.borderSmoothing * 2
                    startY: shape.height - CortetsuConfig.borderThickness
                    strokeWidth: 0
                    fillGradient: LinearGradient {
                        orientation: LinearGradient.Horizontal
                        x1: -CortetsuConfig.borderSmoothing * 2

                        GradientStop {
                            position: 0
                            color: Qt.alpha(Colours.palette.m3scrim, 0)
                        }
                        GradientStop {
                            position: 1
                            color: Colours.palette.m3scrim
                        }
                    }

                    PathLine {
                        relativeX: CortetsuConfig.borderSmoothing
                        relativeY: 0
                    }
                    PathCubic {
                        relativeX: CortetsuConfig.borderSmoothing
                        relativeY: -CortetsuConfig.borderSmoothing
                        relativeControl1X: CortetsuConfig.borderSmoothing * 0.93
                        relativeControl1Y: -CortetsuConfig.borderSmoothing * 0.07
                        relativeControl2X: CortetsuConfig.borderSmoothing * 0.93
                        relativeControl2Y: -CortetsuConfig.borderSmoothing * 0.07
                    }
                    PathLine {
                        relativeX: 0
                        relativeY: CortetsuConfig.borderSmoothing + CortetsuConfig.borderThickness
                    }
                    PathLine {
                        relativeX: -CortetsuConfig.borderSmoothing * 2
                        relativeY: 0
                    }
                }

                // Top right curve
                ShapePath {
                    startX: shape.width - CortetsuConfig.borderSmoothing - CortetsuConfig.borderThickness + (1 - root.deformMatrix.m11) * shape.width / 2
                    strokeWidth: 0
                    fillGradient: LinearGradient {
                        orientation: LinearGradient.Vertical
                        y1: -CortetsuConfig.borderSmoothing * 2

                        GradientStop {
                            position: 0
                            color: Qt.alpha(Colours.palette.m3scrim, 0)
                        }
                        GradientStop {
                            position: 1
                            color: Colours.palette.m3scrim
                        }
                    }

                    PathCubic {
                        relativeX: CortetsuConfig.borderSmoothing
                        relativeY: -CortetsuConfig.borderSmoothing
                        relativeControl1X: CortetsuConfig.borderSmoothing * 0.93
                        relativeControl1Y: -CortetsuConfig.borderSmoothing * 0.07
                        relativeControl2X: CortetsuConfig.borderSmoothing * 0.93
                        relativeControl2Y: -CortetsuConfig.borderSmoothing * 0.07
                    }
                    PathLine {
                        relativeX: 0
                        relativeY: -CortetsuConfig.borderSmoothing
                    }
                    PathLine {
                        relativeX: CortetsuConfig.borderThickness
                        relativeY: 0
                    }
                    PathLine {
                        relativeX: 0
                    }
                }
            }
        }

        CortetsuSurface {
            anchors.centerIn: parent
            radius: Tokens.rounding.extraLarge
            color: Colours.palette.m3surfaceContainerHigh

            scale: 0
            Component.onCompleted: scale = Qt.binding(() => root.props.recordingConfirmDelete ? 1 : 0)

            width: Math.min(parent.width - Tokens.padding.extraLargeIncreased, implicitWidth)
            implicitWidth: deleteConfirmationLayout.implicitWidth + Tokens.padding.extraExtraLarge
            implicitHeight: deleteConfirmationLayout.implicitHeight + Tokens.padding.extraExtraLarge

            MouseArea {
                anchors.fill: parent
            }

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: 3
            }

            ColumnLayout {
                id: deleteConfirmationLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.large * 1.5
                spacing: Tokens.spacing.medium

                CortetsuText {
                    text: qsTr("Delete recording?")
                    font: Tokens.font.body.large
                }

                CortetsuText {
                    Layout.fillWidth: true
                    text: qsTr("Recording '%1' will be permanently deleted.").arg(deleteConfirmation.path)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                RowLayout {
                    Layout.topMargin: Tokens.spacing.medium
                    Layout.alignment: Qt.AlignRight
                    spacing: Tokens.spacing.medium

                    TextButton {
                        text: qsTr("Cancel")
                        type: TextButton.Text
                        onClicked: root.props.recordingConfirmDelete = ""
                    }

                    TextButton {
                        text: qsTr("Delete")
                        type: TextButton.Text
                        onClicked: {
                            CortetsuUtils.deleteFile(Qt.resolvedUrl(root.props.recordingConfirmDelete));
                            root.props.recordingConfirmDelete = "";
                        }
                    }
                }
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
