pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../CortetsuDesign.js" as CortetsuDesign
import ".."
import qs.modules.launcher.services

Item {
    id: root

    required property ShellScreen screen
    required property var screenState
    required property var panels

    readonly property bool shouldBeActive: screenState.launcher

    /*
     * 62px dock + 2px bottom margin + 8px breathing room.
     * This is the gap that keeps the native launcher above CustomDock.
     */
    readonly property real dockOffset: 72

    readonly property real maxHeight: {
        let max = (screen?.height ?? 0) + CortetsuDesign.spacingSpacious - dockOffset;
        if (screenState.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    property real offsetScale: shouldBeActive ? 0 : 1

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight);
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    visible: offsetScale < 1
    // Open: sits above the dock. Closed: slides completely below it.
    anchors.bottomMargin:
        dockOffset +
        (-implicitHeight - 5 - dockOffset) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 630 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Component.onCompleted: Qt.callLater(() => Apps) // Load apps on init

    Behavior on offsetScale {
        CortetsuAnim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        // Keep the first-party launcher instance alive through its close
        // animation. Rapid panel changes must not destroy a delegate while
        // Qt is still incubating it.
        active: true

        sourceComponent: Content {
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight
        }
    }
}
