pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../../../components"
import "../../CortetsuDesign.js" as CortetsuDesign

CortetsuPopupSurface {
    id: root
    required property PopoutState popouts
    required property QsMenuHandle trayItem
    implicitWidth: (stack.currentItem?.implicitWidth ?? 0) + CortetsuDesign.spacingStandard * 2
    implicitHeight: (stack.currentItem?.implicitHeight ?? 0) + CortetsuDesign.spacingStandard * 2

    StackView {
        id: stack
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingStandard
        initialItem: menuComponent.createObject(null, { handle: root.trayItem })
        pushEnter: Transition {}
        pushExit: Transition {}
        popEnter: Transition {}
        popExit: Transition {}
    }

    function activateEntry(entry): void {
        if (!entry.enabled)
            return;
        if (entry.hasChildren)
            stack.push(menuComponent.createObject(null, { handle: entry, subMenu: true }));
        else {
            entry.triggered();
            root.popouts.hasCurrent = false;
        }
    }

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
                    focus: modelData.enabled && index === 0
                    activeFocusOnTab: modelData.enabled
                    implicitWidth: 320
                    implicitHeight: modelData.isSeparator ? 1 : row.implicitHeight + CortetsuDesign.spacingCompact
                    color: modelData.isSeparator ? CortetsuDesign.colorOutlineVariant : "transparent"
                    disabled: !modelData.enabled
                    focused: activeFocus && !modelData.isSeparator
                    hovered: stateLayer.containsMouse
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
                        id: stateLayer
                        anchors.fill: parent
                        radius: parent.radius
                        disabled: !modelData.enabled
                        onClicked: root.activateEntry(modelData)
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            root.activateEntry(modelData);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right && modelData.hasChildren) {
                            root.activateEntry(modelData);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left && menu.subMenu) {
                            stack.pop();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            root.popouts.hasCurrent = false;
                            event.accepted = true;
                        }
                    }
                }
            }

            CortetsuButton {
                visible: menu.subMenu
                compact: true
                icon: "chevron_left"
                label: qsTr("Back")
                onClicked: stack.pop()
                Keys.onEscapePressed: root.popouts.hasCurrent = false
            }
        }
    }
}
