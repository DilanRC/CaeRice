pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services

Item {
    id: root
    required property ShellScreen screen
    required property ScreenState screenState
    readonly property bool shouldBeActive: screenState.updaterCenter
    visible: shouldBeActive
    opacity: shouldBeActive ? 1 : 0
    scale: shouldBeActive ? 1 : 0.985
    transformOrigin: Item.Center
    Behavior on opacity { NumberAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 120 } }
    Rectangle { anchors.fill: parent; visible: root.shouldBeActive; color: Qt.alpha(Colours.palette.m3scrim, 0.42) }
    Loader {
        id: loader
        anchors.fill: parent
        active: root.shouldBeActive
        sourceComponent: Content { screen: root.screen; screenState: root.screenState; updaterVisible: root.shouldBeActive }
    }
    onShouldBeActiveChanged: {
        if (shouldBeActive) Qt.callLater(() => { if (loader.item) loader.item.openUpdater(); });
    }
}
