import QtQuick
import "CortetsuDesign.js" as CortetsuDesign

Rectangle {
    id: root

    property bool hovered: false
    property bool pressed: false
    property bool active: false
    property bool focused: false
    property bool disabled: false
    property bool danger: false
    property bool outlined: true
    property real radiusValue: CortetsuDesign.radiusMedium
    property color baseColor: CortetsuDesign.colorTetsu
    property color hoverColor: Qt.lighter(baseColor, 1.16)
    property color activeColor: danger
        ? CortetsuDesign.colorVermillion
        : CortetsuDesign.colorIndigo
    property color outlineColor: focused
        ? CortetsuDesign.colorWashi
        : active || danger
        ? CortetsuDesign.colorVermillion
        : Qt.darker(CortetsuDesign.colorMuted, 2.15)

    radius: radiusValue
    color: pressed
        ? Qt.darker(active ? activeColor : hoverColor, 1.12)
        : active
            ? activeColor
            : hovered
                ? hoverColor
                : baseColor
    border.width: outlined || focused ? 1 : 0
    border.color: outlineColor

    Behavior on color {
        ColorAnimation {
            duration: CortetsuDesign.motionFastMs
            easing.type: Easing.OutCubic
        }
    }
}
