pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.clipboard
    property real visibilityProgress: shouldBeActive ? 1 : 0

    visible: visibilityProgress > 0.001
    opacity: visibilityProgress
    scale: 0.97 + 0.03 * visibilityProgress
    transformOrigin: Item.Center

    Behavior on visibilityProgress {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screen: root.screen
            screenState: root.screenState
            clipboardVisible: root.shouldBeActive
        }
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            Qt.callLater(() => {
                if (contentLoader.item)
                    contentLoader.item.openClipboard();
            });
        }
    }
}
