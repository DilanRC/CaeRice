import QtQuick

NumberAnimation {
    enum Type { StandardSmall, Standard, StandardLarge, StandardExtraLarge, EmphasizedSmall, Emphasized, EmphasizedLarge, EmphasizedExtraLarge, FastSpatial, DefaultSpatial, SlowSpatial, FastEffects, DefaultEffects, SlowEffects }
    property int type: Anim.DefaultSpatial
    duration: type === Anim.SlowSpatial || type === Anim.SlowEffects ? 280 : type === Anim.FastSpatial || type === Anim.FastEffects ? 120 : 180
    easing.type: Easing.OutCubic
}
