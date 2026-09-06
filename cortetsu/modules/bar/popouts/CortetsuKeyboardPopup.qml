pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules.bar.popouts.kblayout
import "../../CortetsuDesign.js" as CortetsuDesign

ColumnLayout {
    id: root
    width: 240
    spacing: CortetsuDesign.spacingCompact

    KbLayoutModel { id: layouts }
    Component.onCompleted: layouts.start()

    CortetsuSectionHeader { title: qsTr("Keyboard layout"); detail: layouts.activeLabel }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 320)
        clip: true
        spacing: CortetsuDesign.spacingCompact
        model: layouts.visibleModel
        delegate: CortetsuListRow {
            required property int layoutIndex
            required property string label
            width: ListView.view.width
            icon: layoutIndex === layouts.activeIndex ? "check" : "keyboard"
            title: label
            subtitle: layoutIndex > 3 ? qsTr("Unavailable: XKB supports 4 layouts") : ""
            enabled: layoutIndex <= 3
            onClicked: layouts.switchTo(layoutIndex)
        }
    }

    CortetsuText {
        visible: layouts.visibleModel.count === 0
        text: qsTr("No additional layouts")
        color: CortetsuDesign.colorOnSurfaceVariant
    }
}
