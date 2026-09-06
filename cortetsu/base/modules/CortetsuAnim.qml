import QtQuick
import "CortetsuDesign.js" as CortetsuDesign

NumberAnimation {
    enum Type { StandardSmall, Standard, StandardLarge, StandardExtraLarge,
        EmphasizedSmall, Emphasized, EmphasizedLarge, EmphasizedExtraLarge,
        FastSpatial, DefaultSpatial, SlowSpatial, FastEffects, DefaultEffects, SlowEffects }
    property int type: CortetsuAnim.DefaultSpatial
    duration: type >= CortetsuAnim.FastEffects ? CortetsuDesign.motionFastMs : CortetsuDesign.motionStandardMs
    easing.type: Easing.OutCubic
}
