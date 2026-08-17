pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.gamingCenter
    readonly property real panelWidth: Math.min(1240, width - 96)
    readonly property real panelHeight: Math.min(900, height - 64)
    readonly property real panelLeft: Math.round((width - panelWidth) / 2)
    readonly property real panelTop: Math.round((height - panelHeight) / 2)

    visible: shouldBeActive
    opacity: shouldBeActive ? 1 : 0
    scale: shouldBeActive ? 1 : 0.985
    transformOrigin: Item.Center

    Behavior on opacity { NumberAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 120 } }

    Rectangle {
        anchors.fill: parent
        visible: root.shouldBeActive
        color: Qt.alpha(Colours.palette.m3scrim, 0.42)
    }

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: root.shouldBeActive
        sourceComponent: Content {
            screen: root.screen
            screenState: root.screenState
            gamingVisible: root.shouldBeActive
        }
    }

    AdvancedProfileControls {
        z: 30
        visible: root.shouldBeActive && contentLoader.item && contentLoader.item.page === 2 && contentLoader.item.selectedAppId.length > 0
        width: Math.min(690, root.panelWidth * 0.56)
        height: 236
        x: root.panelLeft + 22
        y: root.panelTop + root.panelHeight - height - 26
        contentItem: contentLoader.item ?? null
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            Qt.callLater(() => { if (contentLoader.item) contentLoader.item.openGamingCenter(); });
    }
}
