pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components

FocusScope {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property bool displayVisible

    function openDisplayManager(): void {
        editor.openDisplayManager();
    }

    Editor {
        id: editor
        anchors.fill: parent
        screen: root.screen
        screenState: root.screenState
        displayVisible: root.displayVisible
    }

    PreviewControls {
        id: previewControls
        z: 20
        width: Math.min(390, Math.max(330, parent.width * 0.28))
        height: 144
        x: Math.round((parent.width + Math.min(1260, parent.width - 96)) / 2 - 22 - width - 14)
        y: Math.round((parent.height + Math.min(900, parent.height - 64)) / 2 - 22 - height - 14)
        candidateOutputs: editor.candidateOutputs
    }
}
