pragma ComponentBehavior: Bound

import QtQuick
import qs.components

StyledRect {
    id: root

    required property var entry
    required property bool selected

    signal activateRequested()
    signal deleteRequested()
    signal pinRequested()
    signal selectRequested()

    readonly property string value: entry?.value ?? ""
    readonly property string filePath: entry?.filePath ?? ""
    readonly property bool isImage: filePath.length > 0 && filePath !== "null"
    readonly property bool pinned: entry?.pinned ?? false
    readonly property string recorded: entry?.recorded ?? ""

    implicitHeight: isImage ? 112 : 86
    radius: Tokens.rounding.extraLarge

    color: selected
        ? Colours.palette.m3secondaryContainer
        : mouse.containsMouse
            ? Colours.palette.m3surfaceContainerHighest
            : Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0.92)

    border.width: selected ? 2 : 1
    border.color: selected
        ? Colours.palette.m3primary
        : Qt.alpha(Colours.palette.m3outlineVariant, 0.72)

    Behavior on color { ColorAnimation { duration: 110 } }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        StyledRect {
            visible: root.isImage
            width: 88
            height: 88
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainer
            clip: true

            Image {
                anchors.fill: parent
                anchors.margins: 4
                source: root.isImage ? `file://${root.filePath}` : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
            }
        }

        Column {
            width: parent.width - (root.isImage ? 100 : 0) - actions.width - 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Row {
                width: parent.width
                spacing: 7

                MaterialIcon {
                    text: root.isImage ? "image" : "content_paste"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    width: parent.width - 34
                    text: root.isImage ? qsTr("Image") : root.value
                    maximumLineCount: root.isImage ? 1 : 2
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    font: Tokens.font.body.medium
                    color: root.selected
                        ? Colours.palette.m3onSecondaryContainer
                        : Colours.palette.m3onSurface
                }
            }

            StyledText {
                width: parent.width
                text: root.recorded
                elide: Text.ElideRight
                font: Tokens.font.label.small
                color: Colours.palette.m3outline
            }
        }

        Row {
            id: actions
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            MaterialIcon {
                text: root.pinned ? "keep" : "keep_off"
                color: root.pinned ? Colours.palette.m3primary : Colours.palette.m3outline
                fontStyle: Tokens.font.icon.medium
            }

            MaterialIcon {
                text: "delete"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.medium
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onPressed: root.selectRequested()
        onDoubleClicked: {
            if (mouse.button === Qt.LeftButton)
                root.activateRequested();
        }
        onClicked: {
            if (mouse.button === Qt.MiddleButton)
                root.deleteRequested();
            else if (mouse.button === Qt.RightButton)
                root.pinRequested();
            else
                root.selectRequested();
        }
    }
}
