pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../components/containers"
import "../../components"
import ".."

Scope {
    id: root
    required property ShellScreen screen
    required property var bar

    ExclusionZone { anchors.left: true; exclusiveZone: root.bar.exclusiveZone }
    ExclusionZone { anchors.top: true }
    ExclusionZone { anchors.right: true }
    ExclusionZone { anchors.bottom: true }

    component ExclusionZone: StyledWindow {
        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: CortetsuConfig.borderThickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
