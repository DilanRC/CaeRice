import QtQuick
import "../../CortetsuDesign.js" as CortetsuDesign
import "../../../services"

Item {
    id: root

    readonly property int spacing: CortetsuDesign.spacingStandard
    implicitWidth: 360
    implicitHeight: column.implicitHeight

    Column {
        id: column
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: CortetsuToaster.toasts.slice(0, 5)

            delegate: ToastItem {
                required property var modelData
                width: root.width
                toast: modelData
                onDismissed: CortetsuToaster.dismiss(modelData.id)
            }
        }
    }
}
