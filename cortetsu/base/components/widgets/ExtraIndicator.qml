import "../effects"
import QtQuick
import qs.components
import qs.services

CortetsuSurface {
    required property int extra

    anchors.right: parent.right
    anchors.margins: CortetsuTokens.padding.medium

    color: CortetsuColours.palette.m3tertiary
    radius: CortetsuTokens.rounding.medium

    implicitWidth: count.implicitWidth + CortetsuTokens.padding.medium * 2
    implicitHeight: count.implicitHeight + CortetsuTokens.padding.small

    opacity: extra > 0 ? 1 : 0
    scale: extra > 0 ? 1 : 0.5

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 2
    }

    CortetsuText {
        id: count

        anchors.centerIn: parent
        animate: parent.opacity > 0
        text: qsTr("+%1").arg(parent.extra)
        color: CortetsuColours.palette.m3onTertiary
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
            duration: CortetsuTokens.anim.durations.expressiveFastSpatial
        }
    }

    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }
}
