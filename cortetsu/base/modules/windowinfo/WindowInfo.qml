import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property HyprlandToplevel client

    implicitWidth: child.implicitWidth
    implicitHeight: screen.height * CortetsuTokens.sizes.winfo.heightMult

    RowLayout {
        id: child

        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.large

        spacing: CortetsuTokens.spacing.medium

        Preview {
            screen: root.screen
            client: root.client
        }

        ColumnLayout {
            spacing: CortetsuTokens.spacing.medium

            Layout.preferredWidth: CortetsuTokens.sizes.winfo.detailsWidth
            Layout.fillHeight: true

            CortetsuSurface {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: CortetsuColours.tPalette.m3surfaceContainer
                radius: CortetsuTokens.rounding.large
                clip: true

                Details {
                    client: root.client
                }
            }

            CortetsuSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: buttons.implicitHeight

                color: CortetsuColours.tPalette.m3surfaceContainer
                radius: CortetsuTokens.rounding.large

                Buttons {
                    id: buttons

                    client: root.client
                }
            }
        }
    }
}
