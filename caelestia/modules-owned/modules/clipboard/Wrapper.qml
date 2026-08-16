pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
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
        NumberAnimation {
            duration: 110
            easing.type: Easing.OutCubic
        }
    }

    // ContentWindow already supplies the global drawer scrim. This additional
    // scheme-aware veil is deliberately subtle: it gives the clipboard visual
    // focus without hard-coding a black rectangle that fights light schemes.
    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: 0.10
        visible: root.shouldBeActive
    }

    Loader {
        id: contentLoader
        anchors.fill: parent

        // Clipboard has no independent process. Destroy the heavy Content tree
        // as soon as the drawer closes so FileView/ListView/image delegates stop
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
