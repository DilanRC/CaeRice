import QtQuick
import QtQuick.Shapes
import QtQuick.Templates
import qs.components
import qs.services

Switch {
    id: root

    property int cLayer: 1
    property bool disabled

    enabled: !disabled

    implicitWidth: implicitIndicatorWidth
    implicitHeight: implicitIndicatorHeight

    indicator: CortetsuSurface {
        radius: CortetsuTokens.rounding.full
        color: {
            if (root.disabled)
                return root.checked ? Qt.alpha(CortetsuColours.palette.m3onSurface, 0.12) : Qt.alpha(CortetsuColours.palette.m3surfaceContainerHighest, 0.38);
            return root.checked ? CortetsuColours.palette.m3primary : CortetsuColours.layer(CortetsuColours.palette.m3surfaceContainerHighest, root.cLayer);
        }

        implicitWidth: implicitHeight * 1.7
        implicitHeight: CortetsuTokens.font.body.medium.pointSize + CortetsuTokens.padding.small * 2

        CortetsuSurface {
            readonly property real nonAnimWidth: root.pressed ? implicitHeight * 1.2 : implicitHeight

            radius: CortetsuTokens.rounding.full
            color: {
                if (root.disabled)
                    return root.checked ? CortetsuColours.palette.m3surface : Qt.alpha(CortetsuColours.palette.m3onSurface, 0.12);
                return root.checked ? CortetsuColours.palette.m3onPrimary : CortetsuColours.layer(CortetsuColours.palette.m3outline, root.cLayer + 1);
            }

            x: root.checked ? parent.implicitWidth - nonAnimWidth - CortetsuTokens.padding.extraSmall / 2 : CortetsuTokens.padding.extraSmall / 2
            implicitWidth: nonAnimWidth
            implicitHeight: parent.implicitHeight - CortetsuTokens.padding.extraSmall
            anchors.verticalCenter: parent.verticalCenter

            CortetsuSurface {
                anchors.fill: parent
                radius: parent.radius

                color: root.checked ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3onSurface
                opacity: root.pressed ? 0.1 : root.hovered ? 0.08 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Shape {
                id: icon

                property point start1: {
                    if (root.pressed)
                        return Qt.point(width * 0.2, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.15, height / 2);
                    return Qt.point(width * 0.15, height * 0.15);
                }
                property point end1: {
                    if (root.pressed) {
                        if (root.checked)
                            return Qt.point(width * 0.4, height / 2);
                        return Qt.point(width * 0.8, height / 2);
                    }
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.7);
                    return Qt.point(width * 0.85, height * 0.85);
                }
                property point start2: {
                    if (root.pressed) {
                        if (root.checked)
                            return Qt.point(width * 0.4, height / 2);
                        return Qt.point(width * 0.2, height / 2);
                    }
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.7);
                    return Qt.point(width * 0.15, height * 0.85);
                }
                property point end2: {
                    if (root.pressed)
                        return Qt.point(width * 0.8, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.85, height * 0.2);
                    return Qt.point(width * 0.85, height * 0.15);
                }

                anchors.centerIn: parent
                width: height
                height: parent.implicitHeight - CortetsuTokens.padding.medium
                preferredRendererType: Shape.CurveRenderer
                asynchronous: true

                ShapePath {
                    strokeWidth: root.CortetsuTokens.font.body.large.pointSize * 0.15
                    strokeColor: {
                        if (root.disabled)
                            return root.checked ? CortetsuColours.palette.m3outline : CortetsuColours.palette.m3surfaceContainer;
                        return root.checked ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3surfaceContainerHighest;
                    }
                    fillColor: "transparent"
                    capStyle: root.CortetsuTokens.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

                    startX: icon.start1.x
                    startY: icon.start1.y

                    PathLine {
                        x: icon.end1.x
                        y: icon.end1.y
                    }
                    PathMove {
                        x: icon.start2.x
                        y: icon.start2.y
                    }
                    PathLine {
                        x: icon.end2.x
                        y: icon.end2.y
                    }

                    Behavior on strokeColor {
                        CAnim {}
                    }
                }

                Behavior on start1 {
                    PropAnim {}
                }
                Behavior on end1 {
                    PropAnim {}
                }
                Behavior on start2 {
                    PropAnim {}
                }
                Behavior on end2 {
                    PropAnim {}
                }
            }

            Behavior on x {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: false
    }

    component PropAnim: PropertyAnimation {
        duration: CortetsuTokens.anim.durations.expressiveFastSpatial
        easing: CortetsuTokens.anim.expressiveFastSpatial
    }
}
