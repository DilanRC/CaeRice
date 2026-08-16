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

    readonly property string value: String(entry?.value ?? "")
    readonly property string filePath: String(entry?.filePath ?? "")
    readonly property bool isImage: filePath.length > 0 && filePath !== "null"
    readonly property bool pinned: Boolean(entry?.pinned ?? false)
    readonly property string recorded: String(entry?.recorded ?? "")
    readonly property string trimmedValue: value.trim()
    readonly property bool isUrl:
        !isImage && /^(https?:\/\/|www\.)/i.test(trimmedValue)
    readonly property bool looksCommand:
        !isImage && !isUrl && /^(sudo\s|cd\s|git\s|qs\s|pkill\s|kill\s|pacman\s|yay\s|paru\s|hyprctl\s|systemctl\s|journalctl\s|docker\s|lazydocker\s|cat\s|grep\s|ls\s|cp\s|mv\s|rm\s|curl\s|wget\s|npm\s|pnpm\s|bun\s|go\s|python\s|fish\s|bash\s|sh\s)/i.test(trimmedValue)
    readonly property string iconName:
        isImage ? "image" :
        isUrl ? "language" :
        looksCommand ? "terminal" : "content_paste"

    implicitHeight: isImage ? 104 : 86
    radius: Tokens.rounding.extraLarge

    color: selected
        ? Qt.alpha(Colours.palette.m3secondaryContainer, 0.88)
        : cardMouse.containsMouse
            ? Colours.palette.m3surfaceContainerHighest
            : Colours.palette.m3surfaceContainer

    border.width: selected ? 2 : 1
    border.color: selected
        ? Qt.alpha(Colours.palette.m3primary, 0.88)
        : Qt.alpha(Colours.palette.m3outlineVariant, 0.72)

    scale: cardMouse.containsMouse ? 1.008 : 1

    Behavior on color {
        ColorAnimation { duration: 110 }
    }

    Behavior on border.color {
        ColorAnimation { duration: 110 }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 110
            easing.type: Easing.OutCubic
        }
    }

    // Soft selection rail. It follows the active colour scheme instead of
    // hard-coding the pink accent from the reference mock-up.
    Rectangle {
        visible: root.selected
        width: 3
        height: parent.height - 24
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        radius: 2
        color: Colours.palette.m3primary
    }

    MouseArea {
        id: cardMouse
        z: 0
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onPressed: root.selectRequested()

        onDoubleClicked: event => {
            if (event.button === Qt.LeftButton)
                root.activateRequested();
        }

        onClicked: event => {
            if (event.button === Qt.MiddleButton)
                root.deleteRequested();
            else if (event.button === Qt.RightButton)
                root.pinRequested();
            else
                root.selectRequested();
        }
    }

    Row {
        z: 1
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 13

        StyledRect {
            id: previewBox

            anchors.verticalCenter: parent.verticalCenter
            width: root.isImage ? 82 : 54
            height: root.isImage ? 82 : 54
            radius: root.isImage
                ? Tokens.rounding.large
                : Tokens.rounding.extraLarge
            color: Qt.alpha(Colours.palette.m3primary, root.selected ? 0.18 : 0.11)
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3primary, root.selected ? 0.34 : 0.17)
            clip: true

            Image {
                visible: root.isImage
                anchors.fill: parent
                anchors.margins: 4
                source: root.isImage ? `file://${root.filePath}` : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
                mipmap: true
            }

            MaterialIcon {
                visible: !root.isImage
                anchors.centerIn: parent
                text: root.iconName
                color: Colours.palette.m3primary
                fill: root.looksCommand ? 1 : 0
                fontStyle: Tokens.font.icon.large
            }
        }

        Column {
            id: copyColumn

            width: Math.max(80, parent.width - previewBox.width - actions.width - 39)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            StyledText {
                width: parent.width
                text: root.isImage
                    ? qsTr("Image")
                    : root.value
                maximumLineCount: root.isImage ? 1 : 2
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                font: Tokens.font.body.medium
            }

            StyledText {
                width: parent.width
                text: root.isImage && root.value.length > 0
                    ? `${root.recorded} · ${root.value}`
                    : root.recorded
                maximumLineCount: 1
                elide: Text.ElideRight
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }
        }

        Row {
            id: actions

            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Item {
                width: 34
                height: 34

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.large
                    color: pinMouse.containsMouse
                        ? Qt.alpha(Colours.palette.m3primary, 0.14)
                        : "transparent"
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.pinned ? "keep" : "keep_off"
                    fill: root.pinned ? 1 : 0
                    color: root.pinned
                        ? Colours.palette.m3primary
                        : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.medium
                }

                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectRequested();
                        root.pinRequested();
                    }
                }
            }

            Item {
                width: 34
                height: 34

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.large
                    color: copyMouse.containsMouse
                        ? Qt.alpha(Colours.palette.m3primary, 0.14)
                        : "transparent"
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "content_copy"
                    color: copyMouse.containsMouse
                        ? Colours.palette.m3primary
                        : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.medium
                }

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectRequested();
                        root.activateRequested();
                    }
                }
            }

            Item {
                width: 34
                height: 34

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.large
                    color: deleteMouse.containsMouse
                        ? Qt.alpha(Colours.palette.m3primary, 0.14)
                        : "transparent"
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "delete"
                    color: deleteMouse.containsMouse
                        ? Colours.palette.m3primary
                        : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.medium
                }

                MouseArea {
                    id: deleteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectRequested();
                        root.deleteRequested();
                    }
                }
            }
        }
    }
}
