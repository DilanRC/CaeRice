pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.services
import "../../CortetsuDesign.js" as CortetsuDesign

StackView {
    id: root
    required property PopoutState popouts
    required property QsMenuHandle trayItem
    implicitWidth: currentItem?.implicitWidth ?? 0
    implicitHeight: currentItem?.implicitHeight ?? 0
    initialItem: menuComponent.createObject(null, { handle: root.trayItem })
    pushEnter: Transition {}
    pushExit: Transition {}
    popEnter: Transition {}
    popExit: Transition {}

    Component {
        id: menuComponent
        Column {
            id: menu
            required property QsMenuHandle handle
            property bool subMenu: false
            padding: CortetsuDesign.spacingCompact
            spacing: CortetsuDesign.spacingCompact

            QsMenuOpener { id: opener; menu: menu.handle }

            Repeater {
                model: opener.children
                CortetsuSurface {
                    required property QsMenuEntry modelData
                    implicitWidth: 320
                    implicitHeight: modelData.isSeparator ? 1 : row.implicitHeight + CortetsuDesign.spacingCompact
                    color: modelData.isSeparator ? CortetsuDesign.colorOutlineVariant : "transparent"
                    radius: CortetsuDesign.radiusPill

                    Row {
                        id: row
                        anchors.fill: parent
                        anchors.margins: CortetsuDesign.spacingCompact
                        spacing: CortetsuDesign.spacingCompact
                        IconImage { visible: modelData.icon !== ""; implicitSize: label.implicitHeight; source: modelData.icon }
                        CortetsuText { id: label; width: parent.width - (modelData.hasChildren ? 28 : 0); text: modelData.text; color: modelData.enabled ? CortetsuDesign.colorOnSurface : CortetsuDesign.colorOutline; elide: Text.ElideRight }
                        CortetsuIcon { visible: modelData.hasChildren; text: "chevron_right"; color: CortetsuDesign.colorOnSurfaceVariant }
                    }

                    CortetsuStateLayer {
                        anchors.fill: parent
                        radius: parent.radius
                        disabled: !modelData.enabled
                        onClicked: {
                            if (modelData.hasChildren)
                                root.push(menuComponent.createObject(null, { handle: modelData, subMenu: true }));
                            else {
                                modelData.triggered();
                                root.popouts.hasCurrent = false;
                            }
                        }
                    }
                }
            }

            CortetsuButton {
                visible: menu.subMenu
                compact: true
                icon: "chevron_left"
                label: qsTr("Back")
                onClicked: root.pop()
            }
        }
    }
}
