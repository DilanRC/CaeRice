pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    property var state: ({})
    property string statusText: qsTr("Patch base commit")
    readonly property string helperPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-updater-commit-base"
    readonly property bool ready: state?.ready ?? false

    radius: Tokens.rounding.large
    color: Colours.palette.m3surfaceContainerHighest
    border.width: 1
    border.color: root.ready ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

    function refresh(): void {
        if (!probe.running)
            probe.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: probe
        command: [root.helperPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    root.state = parsed;
                    if ((parsed?.other_dirty ?? []).length)
                        root.statusText = qsTr("Unrelated repo changes block base commit")
                    else if (parsed?.ready)
                        root.statusText = qsTr("Verified base change ready for local commit")
                    else if (parsed?.base_dirty)
                        root.statusText = qsTr("Base changed but no verified Apply is recorded")
                    else
                        root.statusText = qsTr("No pending patch-base commit")
                } catch (error) {
                    root.statusText = qsTr("Commit-base status unavailable")
                }
            }
        }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Column {
            width: parent.width - 118
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            StyledText { width: parent.width; text: root.statusText; color: Colours.palette.m3onSurface; font: Tokens.font.label.small; elide: Text.ElideRight }
            StyledText { width: parent.width; text: root.state?.applied_ref ?? ""; color: Colours.palette.m3outline; font: Tokens.font.label.small; elide: Text.ElideMiddle }
        }

        StyledRect {
            width: 110
            height: parent.height
            radius: Tokens.rounding.medium
            color: root.ready ? Colours.palette.m3tertiaryContainer : Colours.palette.m3surfaceContainerHigh
            enabled: root.ready
            opacity: enabled ? 1 : 0.55
            StateLayer {
                radius: parent.radius
                onClicked: {
                    Quickshell.execDetached(["kitty", "--hold", "--title", "CaeRice commit patch base", root.helperPath, "commit", "--confirm", "COMMIT"]);
                    root.statusText = qsTr("Commit opened in terminal · no push is performed")
                }
            }
            StyledText { anchors.centerIn: parent; text: qsTr("Commit base"); color: root.ready ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3outline; font: Tokens.font.label.small }
        }
    }
}
