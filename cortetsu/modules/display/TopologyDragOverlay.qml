pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property var editorItem

    readonly property var candidateOutputs: editorItem?.candidateOutputs ?? []
    readonly property var bounds: editorItem?.layoutBounds() ?? ({ minX: 0, minY: 0, width: 1920, height: 1080 })
    readonly property real factor: editorItem ? editorItem.topologyScale(width, height) : 1

    Repeater {
        model: root.candidateOutputs

        delegate: Item {
            id: handle
            required property var modelData
            required property int index

            readonly property var modeSize: root.editorItem.parseMode(modelData?.mode)
            readonly property real logicalWidth: modeSize.width / Math.max(0.5, Number(modelData?.scale ?? 1))
            readonly property real logicalHeight: modeSize.height / Math.max(0.5, Number(modelData?.scale ?? 1))

            x: 18 + (Number(modelData?.x ?? 0) - root.bounds.minX) * root.factor
            y: 18 + (Number(modelData?.y ?? 0) - root.bounds.minY) * root.factor
            width: Math.max(90, logicalWidth * root.factor)
            height: Math.max(54, logicalHeight * root.factor)
            visible: modelData?.enabled ?? true

            MouseArea {
                id: dragArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                property real startPointerX: 0
                property real startPointerY: 0
                property real startLogicalX: 0
                property real startLogicalY: 0

                onPressed: mouse => {
                    root.editorItem.selectedIndex = handle.index;
                    const point = dragArea.mapToItem(root, mouse.x, mouse.y);
                    startPointerX = point.x;
                    startPointerY = point.y;
                    startLogicalX = Number(handle.modelData?.x ?? 0);
                    startLogicalY = Number(handle.modelData?.y ?? 0);
                    mouse.accepted = true;
                }

                onPositionChanged: mouse => {
                    if (!pressed || root.factor <= 0)
                        return;
                    const point = dragArea.mapToItem(root, mouse.x, mouse.y);
                    const logicalX = startLogicalX + (point.x - startPointerX) / root.factor;
                    const logicalY = startLogicalY + (point.y - startPointerY) / root.factor;
                    const snappedX = Math.round(logicalX / 10) * 10;
                    const snappedY = Math.round(logicalY / 10) * 10;
                    root.editorItem.selectedIndex = handle.index;
                    root.editorItem.updateSelected("x", snappedX);
                    root.editorItem.updateSelected("y", snappedY);
                }
            }
        }
    }
}
