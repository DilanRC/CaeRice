pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.clipboard

    visible: shouldBeActive
    opacity: shouldBeActive ? 1 : 0
    scale: shouldBeActive ? 1 : 0.985
    transformOrigin: Item.Center

    Behavior on opacity {
        NumberAnimation { duration: 110 }
    }

    Behavior on scale {
        NumberAnimation { duration: 110 }
    }

    Loader {
        id: contentLoader
        anchors.fill: parent

        // Clipboard has no independent process. Destroy the heavy Content tree as
        // soon as the drawer closes so FileView/ListView/image delegates stop
        // consuming resources while hidden.
        active: root.shouldBeActive

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
