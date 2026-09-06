import QtQuick
import Quickshell
import "../../services"

Item {
    id: root
    required property var screenState
    required property var popouts
    readonly property PersistentProperties props: PersistentProperties {
        property bool recordingListExpanded: false
        property string recordingConfirmDelete: ""
        property string recordingMode: ""
        reloadableId: "utilities"
    }
    readonly property bool shouldBeActive: screenState.utilities && !(screenState.session && CortetsuConfig.notificationExpire === false)
    readonly property real totalPadding: 40
    readonly property real nonAnimHeight: ((content.item as Content)?.nonAnimHeight ?? 0) + totalPadding
    property real offsetScale: shouldBeActive ? 0 : 1
    visible: offsetScale < 1
    anchors.bottomMargin: 66 + (-implicitHeight - 5 - 66) * offsetScale
    implicitHeight: content.implicitHeight + totalPadding
    implicitWidth: Math.min(520, parent.width - 16)
    opacity: 1 - offsetScale

    Behavior on offsetScale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Loader {
        id: content
        anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 20
        asynchronous: true
        active: root.shouldBeActive || root.visible
        sourceComponent: Content {
            implicitWidth: root.implicitWidth - root.totalPadding
            props: root.props
            screenState: root.screenState
            popouts: root.popouts
        }
    }
}
