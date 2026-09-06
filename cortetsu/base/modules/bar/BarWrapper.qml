import QtQuick

// The legacy top bar is retired. BottomHub owns the visible system bar.
Item {
    id: root
    required property var screen
    required property var screenState
    required property var popouts
    required property bool fullscreen
    readonly property bool disabled: true
    readonly property int clampedWidth: 0
    readonly property int padding: 0
    readonly property int contentWidth: 0
    readonly property int exclusiveZone: 0
    readonly property bool shouldBeVisible: false
    property bool isHovered: false
    visible: false
    implicitWidth: 0
    function closeTray(): void {}
    function checkPopout(y: real): void {}
    function handleWheel(y: real, angleDelta: point): void {}
}
