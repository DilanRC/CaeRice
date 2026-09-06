import QtQuick
import "../modules/CortetsuDesign.js" as CortetsuDesign

CortetsuSurface {
    id: root

    property color popupColor: CortetsuDesign.colorSurfaceGlassStrong
    property real popupRadius: CortetsuDesign.radiusLarge

    radiusValue: root.popupRadius
    baseColor: root.popupColor
    outlined: true
}
