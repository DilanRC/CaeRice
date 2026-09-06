.pragma library

function fontBuilder(family, pointSize) {
    var state = {
        family: family,
        pointSize: pointSize,
        weight: 400,
        letterSpacing: 0,
        scale: 1,
        width: 100,
        axes: {}
    };
    var builder = {
        size: function(value) { state.pointSize = value; return builder; },
        scale: function(value) { state.scale = value; return builder; },
        weight: function(value) { state.weight = value; return builder; },
        width: function(value) { state.width = value; return builder; },
        letterSpacing: function(value) { state.letterSpacing = value; return builder; },
        vaxis: function(axis, value) { state.axes[axis] = value; return builder; },
        vaxes: function(value) { state.axes = value || {}; return builder; },
        fill: function(value) { state.axes.FILL = value; return builder; },
        grade: function(value) { state.axes.GRAD = value; return builder; },
        capitalisation: function(value) { state.capitalisation = value; return builder; },
        build: function() {
            return Qt.font({
                family: state.family,
                pixelSize: Math.max(1, state.pointSize * state.scale),
                weight: state.weight,
                letterSpacing: state.letterSpacing
            });
        }
    };
    return builder;
}

function builders(family, small, medium, large) {
    return {
        small: fontBuilder(family, small),
        medium: fontBuilder(family, medium),
        large: fontBuilder(family, large)
    };
}

function iconSize(family, value) {
    return fontBuilder(family, value);
}
