import QtQuick.Layouts
import ".."
import "../.."
import "../../../components"
import "../../../services"
import "../../CortetsuDesign.js" as CortetsuDesign

ColumnLayout {
    spacing: CortetsuDesign.spacingCompact
    CortetsuSectionHeader { title: qsTr("Lock state"); detail: qsTr("Keyboard indicators") }
    CortetsuListRow { icon: "keyboard_capslock"; title: qsTr("Caps Lock"); subtitle: Hypr.capsLock ? qsTr("Enabled") : qsTr("Disabled") }
    CortetsuListRow { icon: "pin"; title: qsTr("Num Lock"); subtitle: Hypr.numLock ? qsTr("Enabled") : qsTr("Disabled") }
}
