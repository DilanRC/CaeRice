import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

CortetsuSurface {
    id: root

    required property var dialog
    required property FolderContents folder

    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.small

        CortetsuText {
            text: qsTr("Filter:")
        }

        CortetsuSurface {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Tokens.spacing.medium

            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            CortetsuText {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium

                text: `${root.dialog.filterLabel} (${root.dialog.filters.map(f => `*.${f}`).join(", ")})`
            }
        }

        CortetsuSurface {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: cancelText.implicitHeight + Tokens.padding.medium * 2

            CortetsuStateLayer {
                disabled: !root.dialog.selectionValid
                onClicked: root.dialog.accepted(root.folder.currentItem.modelData.path)
            }

            CortetsuText {
                id: selectText

                anchors.centerIn: parent
                anchors.margins: Tokens.padding.medium

                text: qsTr("Select")
                color: root.dialog.selectionValid ? Colours.palette.m3onSurface : Colours.palette.m3outline
            }
        }

        CortetsuSurface {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: cancelText.implicitHeight + Tokens.padding.medium * 2

            CortetsuStateLayer {
                onClicked: {
                    root.dialog.rejected();
                }
            }

            CortetsuText {
                id: cancelText

                anchors.centerIn: parent
                anchors.margins: Tokens.padding.medium

                text: qsTr("Cancel")
            }
        }
    }
}
