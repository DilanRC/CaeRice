pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../CortetsuDesign.js" as CortetsuDesign

Item {
    id: root

    required property ShellScreen screen
    required property var screenState

    readonly property bool shouldBeActive: screenState.cortetsuState?.hardware ?? false

    visible: shouldBeActive
    opacity: shouldBeActive ? 1 : 0
    scale: shouldBeActive ? 1 : 0.985
    transformOrigin: Item.Center

    Behavior on opacity {
        NumberAnimation { duration: 120 }
    }

    Behavior on scale {
        NumberAnimation { duration: 120 }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.shouldBeActive
        color: Qt.alpha(CortetsuDesign.colorScrim, 0.42)
    }

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: root.shouldBeActive

        sourceComponent: Content {
            screen: root.screen
            screenState: root.screenState
            hardwareVisible: root.shouldBeActive
        }
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            Qt.callLater(() => {
                if (contentLoader.item)
                    contentLoader.item.openHardware();
            });
        }
    }
}
