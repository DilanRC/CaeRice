pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../CortetsuDesign.js" as CortetsuDesign

Item {
    id: root

    required property ShellScreen screen
    required property var screenState

    readonly property bool shouldBeActive: screenState.cortetsuState?.overview ?? false

    property real visibilityProgress: shouldBeActive ? 1 : 0

    visible: visibilityProgress > 0.001
    opacity: visibilityProgress
    scale: 0.96 + 0.04 * visibilityProgress
    transformOrigin: Item.Center

    Behavior on visibilityProgress {
        NumberAnimation {
            duration: CortetsuDesign.motionStandardMs
            easing.type: Easing.OutCubic
        }
    }

    Loader {
        id: contentLoader

        anchors.fill: parent
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screen: root.screen
            screenState: root.screenState
            overviewVisible: root.shouldBeActive
        }
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            Qt.callLater(() => {
                if (contentLoader.item)
                    contentLoader.item.openOverview();
            });
        }
    }
}
