pragma Singleton

import QtQml

// Interaction and overlay geometry defaults owned by Cortetsu.
QtObject {
    property QtObject border: QtObject {
        property real rounding: 8
        property real minThickness: 1
        property real thickness: CortetsuConfig.borderThickness
        property bool smoothing: true
    }
    property QtObject general: QtObject { property bool showOverFullscreen: true }
    property QtObject appearance: QtObject { property real deformScale: 100 }
    property QtObject bar: QtObject { property bool showOnHover: false; property real dragThreshold: 24 }
    property QtObject launcher: QtObject { property bool enabled: true; property bool showOnHover: false; property real dragThreshold: 24 }
    property QtObject dashboard: QtObject { property bool enabled: true; property bool showOnHover: false; property real dragThreshold: 24 }
    property QtObject session: QtObject { property bool enabled: true; property real dragThreshold: 24 }
    property QtObject sidebar: QtObject { property bool enabled: true; property bool showOnHover: false; property real dragThreshold: 24; property real minHoverThreshold: 96 }
    property QtObject utilities: QtObject { property bool enabled: true }
}
