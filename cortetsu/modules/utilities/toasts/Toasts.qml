import QtQuick
import "../../CortetsuDesign.js" as CortetsuDesign
import "../../../services"

Item {
    id: root

    readonly property int spacing: CortetsuDesign.spacingStandard
    readonly property var visibleToasts: CortetsuToaster.toasts.slice(0, 5)
    implicitWidth: 360
    implicitHeight: column.childrenRect.height
    width: implicitWidth
    height: implicitHeight
    z: 100
    focus: visibleToasts.length > 0

    onVisibleToastsChanged: {
        if (visibleToasts.length > 0)
            forceActiveFocus();
    }

    Column {
        id: column
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: root.visibleToasts

            delegate: ToastItem {
                required property int index
                width: root.width
                toast: root.visibleToasts[index]
                onDismissed: CortetsuToaster.dismiss(root.visibleToasts[index].id)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 1000
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: {
            root.forceActiveFocus();
            if (root.visibleToasts.length > 0)
                CortetsuToaster.dismiss(root.visibleToasts[0].id);
        }
    }

    Keys.onEscapePressed: {
        if (root.visibleToasts.length > 0)
            CortetsuToaster.dismiss(root.visibleToasts[0].id);
    }
}
