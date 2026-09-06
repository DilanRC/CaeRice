import QtQuick.Layouts
import qs.components
import qs.services

CortetsuSurface {
    id: root

    required property var dialog
    required property FolderContents folder

    implicitHeight: inner.implicitHeight + CortetsuTokens.padding.medium * 2

    color: CortetsuColours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.medium

        spacing: CortetsuTokens.spacing.small

        CortetsuText {
            text: qsTr("Filter:")
        }

        CortetsuSurface {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: CortetsuTokens.spacing.medium

            color: CortetsuColours.tPalette.m3surfaceContainerHigh
            radius: CortetsuTokens.rounding.medium

            CortetsuText {
                anchors.fill: parent
                anchors.margins: CortetsuTokens.padding.medium

                text: `${root.dialog.filterLabel} (${root.dialog.filters.map(f => `*.${f}`).join(", ")})`
            }
        }

        CortetsuSurface {
            color: CortetsuColours.tPalette.m3surfaceContainerHigh
            radius: CortetsuTokens.rounding.medium

            implicitWidth: cancelText.implicitWidth + CortetsuTokens.padding.medium * 2
            implicitHeight: cancelText.implicitHeight + CortetsuTokens.padding.medium * 2

            CortetsuStateLayer {
                disabled: !root.dialog.selectionValid
                onClicked: root.dialog.accepted(root.folder.currentItem.modelData.path)
            }

            CortetsuText {
                id: selectText

                anchors.centerIn: parent
                anchors.margins: CortetsuTokens.padding.medium

                text: qsTr("Select")
                color: root.dialog.selectionValid ? CortetsuColours.palette.m3onSurface : CortetsuColours.palette.m3outline
            }
        }

        CortetsuSurface {
            color: CortetsuColours.tPalette.m3surfaceContainerHigh
            radius: CortetsuTokens.rounding.medium

            implicitWidth: cancelText.implicitWidth + CortetsuTokens.padding.medium * 2
            implicitHeight: cancelText.implicitHeight + CortetsuTokens.padding.medium * 2

            CortetsuStateLayer {
                onClicked: {
                    root.dialog.rejected();
                }
            }

            CortetsuText {
                id: cancelText

                anchors.centerIn: parent
                anchors.margins: CortetsuTokens.padding.medium

                text: qsTr("Cancel")
            }
        }
    }
}
