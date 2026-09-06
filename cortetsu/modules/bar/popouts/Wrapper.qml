pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.modules.nexus
import qs.modules.windowinfo

Item {
    id: root

    required property ShellScreen screen
    required property real offsetScale

    readonly property alias content: content
    readonly property alias winfo: winfo
    readonly property alias nexus: nexus
    readonly property real nonAnimWidth: children.find(c => c.shouldBeActive)?.implicitWidth ?? content.implicitWidth
    readonly property real nonAnimHeight: children.find(c => c.shouldBeActive)?.implicitHeight ?? content.implicitHeight
    readonly property Item current: (content.item as Content)?.current ?? null
    readonly property bool isDetached: detachedMode.length > 0

    property alias currentName: popoutState.currentName
    property alias hasCurrent: popoutState.hasCurrent
    property real currentCenter
    property string detachedMode
    property string queuedMode
    property bool bottomAttached
    property real bottomOffset: 54
    property real bottomRightMargin: 4
    property real bottomAnchorCenter: -1

    property int animLength: 0
    property var animCurve

    function setAnims(detach: bool): void {
        animLength = detach ? 220 : 160;
        animCurve = Easing.OutCubic;
    }

    function detach(mode: string): void {
        bottomAttached = false;
        bottomAnchorCenter = -1;
        setAnims(true);
        if (mode === "winfo") {
            detachedMode = mode;
        } else {
            queuedMode = mode;
            detachedMode = "any";
        }
        setAnims(false);
        focus = true;
    }

    function close(): void {
        hasCurrent = false;
        detachedMode = "";
        bottomAttached = false;
        bottomAnchorCenter = -1;
    }

    onHasCurrentChanged: {
        if (!hasCurrent) {
            bottomAttached = false;
            bottomAnchorCenter = -1;
        }
    }

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight
    focus: hasCurrent

    Keys.onEscapePressed: {
        if (currentName === "wirelesspassword" && content.item) {
            const passwordPopout = (content.item as Content)?.children.find(c => c.name === "wirelesspassword");
            if (passwordPopout && passwordPopout.item) {
                passwordPopout.item.closeDialog();
                return;
            }
        }
        close();
    }

    Keys.onPressed: event => {
        if (currentName === "wirelesspassword")
            event.accepted = false;
    }

    PopoutState {
        id: popoutState
        onDetachRequested: mode => root.detach(mode)
    }

    HyprlandFocusGrab {
        active: root.isDetached
        windows: [QsWindow.window]
        onCleared: root.close()
    }

    Binding {
        when: root.isDetached || (root.hasCurrent && root.currentName === "wirelesspassword")
        target: QsWindow.window
        property: "WlrLayershell.keyboardFocus"
        value: WlrKeyboardFocus.OnDemand
    }

    Comp {
        id: content
        shouldBeActive: root.hasCurrent && !root.detachedMode
        anchors.fill: parent
        sourceComponent: Content { popouts: popoutState }
    }

    Comp {
        id: winfo
        shouldBeActive: root.detachedMode === "winfo"
        anchors.centerIn: parent
        sourceComponent: WindowInfo { screen: root.screen; client: Hypr.activeToplevel }
    }

    Comp {
        id: nexus
        shouldBeActive: root.detachedMode === "any"
        anchors.centerIn: parent
        sourceComponent: Rectangle {
            radius: 24
            color: "transparent"
            implicitWidth: nexusInner.implicitWidth
            implicitHeight: nexusInner.implicitHeight
            Nexus {
                id: nexusInner
                anchors.fill: parent
                nState.screen: root.screen
                nState.animatingContainer: nexus.opacity < 1
                nState.currentPageIdx: ["appearance", "network", "bluetooth", "audio"].indexOf(root.queuedMode)
                onClose: root.close()
            }
        }
    }

    Behavior on implicitWidth { NumberAnimation { duration: root.animLength; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight {
        enabled: root.offsetScale < 1
        NumberAnimation { duration: root.animLength; easing.type: Easing.OutCubic }
    }

    component Comp: Loader {
        id: comp
        property bool shouldBeActive
        active: false
        opacity: 0
        states: State {
            name: "active"
            when: comp.shouldBeActive
            PropertyChanges { comp.opacity: 1; comp.active: true }
        }
        transitions: [
            Transition {
                from: ""; to: "active"
                SequentialAnimation {
                    PropertyAction { property: "active" }
                    NumberAnimation { property: "opacity"; duration: comp.parent.animLength; easing.type: Easing.OutCubic }
                }
            },
            Transition {
                from: "active"; to: ""
                SequentialAnimation {
                    NumberAnimation { property: "opacity"; duration: comp.parent.animLength; easing.type: Easing.OutCubic }
                    PropertyAction { property: "active" }
                }
            }
        ]
    }
}
