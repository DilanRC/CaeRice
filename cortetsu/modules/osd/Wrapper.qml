import QtQuick
import "../CortetsuDesign.js" as CortetsuDesign
import "../../services"

Item {
    id: root
    required property var screen
    required property var screenState
    required property bool sidebarOrSessionVisible
    readonly property var monitor: Brightness.getMonitorForScreen(screen)
    property bool hovered: false
    property real offsetScale: screenState.osd ? 0 : 1
    property real sidebarOffset: sidebarOrSessionVisible ? CortetsuDesign.spacingStandard : 0
    property real volume: Audio.volume
    property bool muted: Audio.muted
    property real brightness: monitor?.brightness ?? 0

    function show(): void {
        screenState.osd = true;
        hideTimer.restart();
    }

    visible: offsetScale < 1
    anchors.rightMargin: (-implicitWidth - CortetsuDesign.spacingStandard - sidebarOffset) * offsetScale
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    opacity: 1 - offsetScale

    Connections { target: Audio; function onVolumeChanged(): void { root.volume = Audio.volume; root.show(); } function onMutedChanged(): void { root.muted = Audio.muted; root.show(); } }
    Connections { target: monitor; function onBrightnessChanged(): void { root.brightness = monitor.brightness; root.show(); } }

    Behavior on offsetScale { NumberAnimation { duration: CortetsuDesign.motionStandardMs; easing.type: Easing.OutCubic } }
    Timer { id: hideTimer; interval: 1800; onTriggered: if (!root.hovered) root.screenState.osd = false }

    Content {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        monitor: root.monitor
        screenState: root.screenState
        volume: root.volume
        muted: root.muted
        brightness: root.brightness
    }
}
