pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property var entry
    required property bool selected

    signal activateRequested()
    signal deleteRequested()
    signal pinRequested()
    signal selectRequested()

    readonly property string value:
        String(entry?.value ?? "")

    readonly property string filePath:
        String(entry?.filePath ?? "")

    readonly property bool isImage:
        filePath.length > 0 && filePath !== "null"

    readonly property bool pinned:
        Boolean(entry?.pinned ?? false)

    readonly property string recorded:
        String(entry?.recorded ?? "")

    readonly property string trimmedValue:
        value.trim()

    readonly property bool isUrl:
        !isImage &&
        /^(https?:\/\/|www\.)/i.test(trimmedValue)

    readonly property bool looksCommand:
        !isImage &&
        !isUrl &&
        /^(sudo\s|cd\s|git\s|qs\s|pkill\s|kill\s|pacman\s|yay\s|paru\s|hyprctl\s|systemctl\s|journalctl\s|docker\s|lazydocker\s|cat\s|grep\s|ls\s|cp\s|mv\s|rm\s|curl\s|wget\s|npm\s|pnpm\s|bun\s|go\s|python\s|fish\s|bash\s|sh\s)/i
            .test(trimmedValue)

    readonly property string iconName:
        isImage
            ? "image"
            : isUrl
                ? "language"
                : looksCommand
                    ? "terminal"
                    : "content_paste"

    readonly property string fileName: {
        if (!isImage)
            return "";

        const parts = filePath.split("/");
        return parts.length > 0
            ? parts[parts.length - 1]
            : filePath;
    }

    readonly property string recordedDisplay: {
        let text = recorded.replace("T", " ");
        text = text.replace(/\.\d+.*$/, "");

        const parts = text.split(" ");

        if (parts.length >= 2)
            return `${parts[0]} · ${parts[1]}`;

        return text;
    }

    readonly property color surfaceColour:
        Colours.light
            ? Qt.lighter(Colours.palette.m3inverseSurface, 1.12)
            : Colours.palette.m3surfaceContainer

    readonly property color hoverColour:
        Colours.light
            ? Qt.lighter(Colours.palette.m3inverseSurface, 1.20)
            : Colours.palette.m3surfaceContainerHighest

    readonly property color textPrimary:
        Colours.light
            ? Colours.palette.m3inverseOnSurface
            : Colours.palette.m3onSurface

    readonly property color textMuted:
        Colours.light
            ? Qt.alpha(Colours.palette.m3inverseOnSurface, 0.66)
            : Colours.palette.m3onSurfaceVariant

    readonly property color accent:
        Colours.palette.m3primaryFixedDim

    readonly property color accentSoft:
        Qt.alpha(accent, selected ? 0.18 : 0.11)

    implicitHeight:
        isImage ? 106 : 92

    radius: Tokens.rounding.extraLarge

    color:
        selected
            ? Qt.alpha(accent, 0.14)
            : cardMouse.containsMouse
                ? hoverColour
                : surfaceColour

    border.width:
        selected ? 2 : 1

    border.color:
        selected
            ? Qt.alpha(accent, 0.82)
            : cardMouse.containsMouse
                ? Qt.alpha(accent, 0.24)
                : Qt.alpha(textMuted, 0.12)

    scale:
        cardMouse.containsMouse ? 1.006 : 1

    Behavior on color {
        ColorAnimation {
            duration: 105
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 105
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 105
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        visible: root.selected
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - 24
        radius: 2
        color: root.accent
    }

    MouseArea {
        id: cardMouse

        z: 0
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons:
            Qt.LeftButton |
            Qt.MiddleButton |
            Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onPressed:
            root.selectRequested()

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
        spacing: 14

        StyledRect {
            id: previewBox

            anchors.verticalCenter: parent.verticalCenter

            width:
                root.isImage ? 84 : 54

            height:
                root.isImage ? 84 : 54

            radius:
                root.isImage
                    ? Tokens.rounding.large
                    : Tokens.rounding.extraLarge

            color: root.accentSoft

            border.width: 1
            border.color:
                Qt.alpha(root.accent, root.selected ? 0.38 : 0.18)

            clip: true

            Image {
                visible: root.isImage
                anchors.fill: parent
                anchors.margins: 4
                source:
                    root.isImage
                        ? `file://${root.filePath}`
                        : ""
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
                color: root.accent
                fill: root.looksCommand ? 1 : 0
                fontStyle: Tokens.font.icon.large
            }
        }

        Column {
            id: copyColumn

            width:
                Math.max(
                    90,
                    parent.width -
                    previewBox.width -
                    actions.width -
                    42
                )

            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            StyledText {
                width: parent.width

                text:
                    root.isImage
                        ? qsTr("Image")
                        : root.value

                maximumLineCount:
                    root.isImage ? 1 : 2

                elide: Text.ElideRight
                wrapMode: Text.Wrap

                color:
                    root.isUrl || root.looksCommand
                        ? root.accent
                        : root.textPrimary

                font: Tokens.font.body.medium
            }

            StyledText {
                width: parent.width

                text:
                    root.isImage
                        ? `${root.recordedDisplay} · ${root.fileName}`
                        : root.recordedDisplay

                maximumLineCount: 1
                elide: Text.ElideRight
                color: root.textMuted
                font: Tokens.font.label.small
            }
        }

        Row {
            id: actions

            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Item {
                width: 36
                height: 36

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.large

                    color:
                        pinMouse.containsMouse
                            ? Qt.alpha(root.accent, 0.13)
                            : "transparent"
                }

                MaterialIcon {
                    anchors.centerIn: parent

                    text:
                        root.pinned
                            ? "keep"
                            : "keep_off"

                    fill:
                        root.pinned ? 1 : 0

                    color:
                        root.pinned || pinMouse.containsMouse
                            ? root.accent
                            : root.textMuted

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
                width: 36
                height: 36

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.large

                    color:
                        copyMouse.containsMouse
                            ? Qt.alpha(root.accent, 0.13)
                            : "transparent"
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "content_copy"

                    color:
                        copyMouse.containsMouse
                            ? root.accent
                            : root.textMuted

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
                width: 36
                height: 36

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.large

                    color:
                        deleteMouse.containsMouse
                            ? Qt.alpha(
                                Colours.palette.m3error,
                                0.12
                            )
                            : "transparent"
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "delete"

                    color:
                        deleteMouse.containsMouse
                            ? Colours.palette.m3error
                            : root.textMuted

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
