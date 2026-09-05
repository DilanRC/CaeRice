pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root
    required property ScreenState screenState
    readonly property bool shouldBeActive: screenState.cortetsuState?.calendar ?? false
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    implicitWidth: Math.min(900, parent.width - Tokens.padding.large * 2)
    implicitHeight: Math.min(660, parent.height - Tokens.padding.large * 2)
    y: parent.height - implicitHeight - Tokens.padding.large + offsetScale * (implicitHeight + 24)
    opacity: 1 - offsetScale
    onShouldBeActiveChanged: if (shouldBeActive) content.forceActiveFocus()

    Behavior on offsetScale { Anim {} }

    Content {
        id: content
        anchors.fill: parent
        screenState: root.screenState
    }
}
