import QtQuick
import qs.services

AnchorAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial
    }

    property int type: AnchorAnim.DefaultSpatial

    duration: {
        if (type < AnchorAnim.StandardSmall || type > AnchorAnim.SlowSpatial)
            return CortetsuTokens.anim.durations.expressiveDefaultSpatial;

        if (type == AnchorAnim.FastSpatial)
            return CortetsuTokens.anim.durations.expressiveFastSpatial;
        if (type == AnchorAnim.DefaultSpatial)
            return CortetsuTokens.anim.durations.expressiveDefaultSpatial;
        if (type == AnchorAnim.SlowSpatial)
            return CortetsuTokens.anim.durations.expressiveSlowSpatial;

        const types = ["small", "normal", "large", "extraLarge"];
        const idx = type % 4; // 0-7 are the 4 standard types
        return CortetsuTokens.anim.durations[types[idx]];
    }
    easing: {
        if (type == AnchorAnim.FastSpatial)
            return CortetsuTokens.anim.expressiveFastSpatial;
        if (type == AnchorAnim.DefaultSpatial)
            return CortetsuTokens.anim.expressiveDefaultSpatial;
        if (type == AnchorAnim.SlowSpatial)
            return CortetsuTokens.anim.expressiveSlowSpatial;

        if (type >= AnchorAnim.StandardSmall && type <= AnchorAnim.StandardExtraLarge)
            return CortetsuTokens.anim.standard;
        if (type >= AnchorAnim.EmphasizedSmall && type <= AnchorAnim.EmphasizedExtraLarge)
            return CortetsuTokens.anim.emphasized;

        return CortetsuTokens.anim.expressiveDefaultSpatial;
    }
}
