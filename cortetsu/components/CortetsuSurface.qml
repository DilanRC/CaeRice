import QtQuick
import "../modules/CortetsuDesign.js" as CortetsuDesign

Rectangle {
    id: root

    color: "transparent"
    Behavior on color {
        ColorAnimation {
            duration: CortetsuDesign.motionStandardMs
            easing.type: Easing.OutCubic
        }
    }
}
