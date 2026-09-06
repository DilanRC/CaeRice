pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.modules.bar.popouts

Item {
    id: root

    required property ShellScreen screen
    required property real borderThickness
    readonly property alias content: content
    property real offsetScale: x > 0 || content.hasCurrent ? 0 : 1

    visible: width > 0 && height > 0
    clip: true
    implicitWidth: content.implicitWidth * (1 - offsetScale)
    implicitHeight: content.implicitHeight

    x: content.isDetached
        ? (parent.width - content.nonAnimWidth) / 2
        : content.bottomAttached
            ? content.bottomAnchorCenter >= 0
                ? Math.max(8, Math.min(parent.width - content.nonAnimWidth - 8, content.bottomAnchorCenter - content.nonAnimWidth / 2))
                : parent.width - content.nonAnimWidth - content.bottomRightMargin
            : 0
    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;
        if (content.bottomAttached)
            return parent.height - content.nonAnimHeight - content.bottomOffset;
        const off = content.currentCenter - borderThickness - content.nonAnimHeight / 2;
        const diff = parent.height - Math.floor(off + content.nonAnimHeight);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    Behavior on offsetScale { Anim {} }

    Wrapper {
        id: content
        screen: root.screen
        offsetScale: root.offsetScale
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: (-implicitWidth - 5) * root.offsetScale
    }
}
