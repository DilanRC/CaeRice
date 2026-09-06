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
}
