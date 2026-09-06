import QtQuick

// First-party circular-indicator manager.
// The manager exposes the animated arc fractions consumed by CircularIndicator.
QtObject {
    enum IndeterminateAnimationType {
        Advance,
        Retreat
    }

    property real progress: 0
    property real completeEndProgress: 0
    property int indeterminateAnimationType: CircularIndicatorManager.Advance

    readonly property real duration: 1000
    readonly property real completeEndDuration: 350
    readonly property real rotation: progress * 360
    readonly property real startFraction: {
        const p = Math.max(0, Math.min(1, progress));
        return indeterminateAnimationType === CircularIndicatorManager.Retreat ? (1 - p) * 0.75 : p * 0.75;
    }
    readonly property real endFraction: {
        const start = startFraction;
        const sweep = 0.25 + Math.max(0, Math.min(1, completeEndProgress)) * (1 - start - 0.25);
        return Math.min(1, start + sweep);
    }
}
