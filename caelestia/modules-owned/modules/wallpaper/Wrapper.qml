pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import qs.components
import qs.services
import "../OverlayPolicy.js" as OverlayPolicy

Item {
    id: root
    required property ShellScreen screen
    required property ScreenState screenState
    readonly property bool shouldBeActive: screenState.wallpaperManager
    readonly property bool globalOtherOverlayOpen: {
        for (const candidate of Screens.screens) {
            if (OverlayPolicy.hasCompetingPanel(ShellState.forScreen(candidate)))
                return true;
        }
        return false;
    }

    function closeCompetingPanels(): void {
        for (const candidate of Screens.screens)
            OverlayPolicy.closeForWallpaper(ShellState.forScreen(candidate));
    }

    visible: opacity > 0.001
    opacity: shouldBeActive ? 1 : 0
    scale: shouldBeActive ? 1 : 0.985
    transformOrigin: Item.Center

    Behavior on opacity { NumberAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 140 } }

    Rectangle {
        anchors.fill: parent
        visible: root.shouldBeActive
        color: Qt.alpha(Colours.palette.m3scrim, 0.44)
    }

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: root.shouldBeActive
        sourceComponent: Content {
            screen: root.screen
            screenState: root.screenState
        }
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            closeCompetingPanels();
            Qt.callLater(() => contentLoader.item?.openManager());
        } else {
            contentLoader.item?.closeManager();
            Wallpapers.stopPreview();
        }
    }

    onGlobalOtherOverlayOpenChanged: {
        if (shouldBeActive && globalOtherOverlayOpen) {
            screenState.wallpaperManager = false;
            Wallpapers.stopPreview();
        }
    }
}
