pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.components.blobs
import qs.components.controls
import qs.services
import qs.modules.nexus

Item {
    id: root

    readonly property NexusState nState: NexusState {
        id: nState

        onClose: root.close()
    }
    property color blobColour: CortetsuColours.tPalette.m3surfaceContainerLow

    signal close

    implicitWidth: Math.round(implicitHeight * CortetsuTokens.sizes.nexus.ratio)
    implicitHeight: Math.round(nState.screen.height * CortetsuTokens.sizes.nexus.heightMult)

    Behavior on blobColour {
        CAnim {}
    }

    TapHandler {
        onTapped: root.focus = true
    }

    BlobGroup {
        id: blobGroup

        smoothing: root.CortetsuTokens.rounding.medium
        color: root.blobColour
    }

    BlobInvertedRect {
        anchors.fill: parent
        group: blobGroup
        opacity: root.blobColour.a
        radius: CortetsuTokens.rounding.large

        borderLeft: navPane.width + navPane.anchors.margins * 2
        borderRight: CortetsuTokens.padding.medium
        borderTop: CortetsuTokens.padding.medium
        borderBottom: CortetsuTokens.padding.medium
    }

    BlobRect {
        id: windowBtnRect

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.nState.isWindow ? 0 : CortetsuTokens.padding.extraSmall

        group: blobGroup
        opacity: root.blobColour.a
        radius: CortetsuTokens.rounding.medium

        implicitWidth: windowBtn.implicitWidth + (root.nState.isWindow ? CortetsuTokens.padding.extraSmall : CortetsuTokens.padding.small) * 2
        implicitHeight: windowBtn.implicitHeight + (root.nState.isWindow ? CortetsuTokens.padding.extraSmall : CortetsuTokens.padding.small)
    }

    IconButton {
        id: windowBtn

        anchors.centerIn: windowBtnRect
        icon: nState.isWindow ? "close" : "pip"
        type: IconButton.Text
        label.fill: 0
        inactiveOnColour: hovered ? nState.isWindow ? CortetsuColours.palette.m3error : CortetsuColours.palette.m3primary : CortetsuColours.palette.m3onSurfaceVariant
        stateLayer.opacity: 0
        onClicked: {
            if (!nState.isWindow)
                WindowFactory.create();
            root.close();
        }

        label.scale: pressed ? 0.8 : 1
        label.renderType: Text.QtRendering

        Behavior on label.scale {
            Anim {}
        }
    }

    NavPane {
        id: navPane

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: CortetsuTokens.padding.large

        nState: nState
        width: Math.min(CortetsuTokens.sizes.nexus.maxNavWidth, Math.round(root.width / 3))
    }

    Pages {
        anchors.left: navPane.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: navPane.anchors.margins + anchors.margins
        anchors.margins: CortetsuTokens.padding.extraLarge

        nState: nState
    }
}
