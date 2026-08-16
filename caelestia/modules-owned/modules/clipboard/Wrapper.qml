pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState

    readonly property bool shouldBeActive:
        screenState.clipboard

    visible: shouldBeActive
    opacity: shouldBeActive ? 1 : 0
    scale: shouldBeActive ? 1 : 0.985
    transformOrigin: Item.Center

    Behavior on opacity {
        NumberAnimation {
            duration: 110
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 110
        }
    }

    /*
     * Only the desktop scrim is translucent. Content.qml owns a fully opaque
     * adaptive dark panel, so bright wallpapers cannot bleed through it.
     */
    Rectangle {
        anchors.fill: parent
        color:
            Qt.alpha(
                Colours.palette.m3scrim,
                Colours.light ? 0.20 : 0.15
            )
        visible: root.shouldBeActive
    }

    Loader {
        id: contentLoader

        anchors.fill: parent

        /*
         * No hidden clipboard tree: closing the drawer destroys FileView,
         * ListView and image preview delegates. The Clipse listener remains
         * the lightweight history backend for the whole session.
         */
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
