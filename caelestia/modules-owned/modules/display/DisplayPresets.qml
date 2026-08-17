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
    required property var candidateOutputs
    signal candidateLoaded(var candidate)

    property var presets: []
    property string statusText: qsTr("Named layouts")
    property string presetName: ""
    property string actionKind: ""
    readonly property string helperPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-display-presets"

    radius: Tokens.rounding.extraLarge
    color: Colours.palette.m3surfaceContainerHigh
    border.width: 1
    border.color: Colours.palette.m3outlineVariant

    function run(kind, args): void {
        if (worker.running) return;
        actionKind = kind; worker.command = [helperPath, kind].concat(args); worker.running = true;
    }
    function refresh(): void { run("list", []); }
    function save(): void {
        if (!presetName.trim().length) { statusText = qsTr("Enter a preset name first"); return; }
        run("save", ["--name", presetName.trim(), "--candidate", JSON.stringify({outputs:candidateOutputs})]);
    }
    function loadPreset(name): void { run("get", ["--name", name]); }
    function deletePreset(name): void { run("delete", ["--name", name]); }
    Component.onCompleted: refresh()

    Process {
        id: worker
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed=JSON.parse(text.trim());
                    if (!(parsed?.ok ?? false)) root.statusText=parsed?.error ?? qsTr("Preset action failed");
                    else if (root.actionKind === "list") { root.presets=parsed?.presets ?? []; root.statusText=qsTr("%1 saved layout(s)").arg(root.presets.length); }
                    else if (root.actionKind === "get") { root.candidateLoaded(parsed?.preset?.candidate ?? {}); root.statusText=qsTr("Loaded %1 · Dry run before Preview").arg(parsed?.name ?? ""); }
                    else { root.statusText=root.actionKind === "save" ? qsTr("Preset saved") : qsTr("Preset deleted"); Qt.callLater(root.refresh); }
                } catch(error) { root.statusText=qsTr("Preset helper returned invalid JSON"); }
            }
        }
    }

    Column {
        anchors.fill: parent; anchors.margins: 12; spacing: 7
        Row {
            width: parent.width; height: 28
            StyledText { width: parent.width * 0.55; text: qsTr("Saved layouts"); color: Colours.palette.m3onSurface; font: Tokens.font.title.small }
            StyledText { width: parent.width * 0.45; text: root.statusText; color: Colours.palette.m3outline; font: Tokens.font.label.small; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight }
        }
        Row {
            width: parent.width; height: 38; spacing: 6
            StyledRect {
                width: parent.width - 82; height: 38; radius: Tokens.rounding.medium; color: Colours.palette.m3surfaceContainer
                StyledText { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; visible: nameInput.text.length===0; text: qsTr("name this layout"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
                TextInput { id:nameInput; anchors.fill: parent; anchors.leftMargin:10; anchors.rightMargin:10; verticalAlignment:TextInput.AlignVCenter; text:root.presetName; onTextChanged:root.presetName=text; color:Colours.palette.m3onSurface; selectionColor:Colours.palette.m3primary }
            }
            StyledRect { width:76; height:38; radius:Tokens.rounding.medium; color:Colours.palette.m3primaryContainer; enabled:!worker.running; StateLayer { radius:parent.radius; onClicked:root.save() }; StyledText { anchors.centerIn:parent; text:qsTr("Save"); color:Colours.palette.m3onPrimaryContainer; font:Tokens.font.label.small } }
        }
        Row {
            width: parent.width; height: 38; spacing: 5
            Repeater {
                model: Array.from(root.presets ?? []).slice(0,3)
                delegate: StyledRect {
                    required property var modelData
                    width:(parent.width-10)/3; height:38; radius:Tokens.rounding.medium; color:Colours.palette.m3secondaryContainer
                    StateLayer { radius:parent.radius; onClicked:root.loadPreset(modelData?.name ?? "") }
                    Row { anchors.fill:parent; anchors.margins:7; spacing:3
                        StyledText { width:parent.width-24; anchors.verticalCenter:parent.verticalCenter; text:modelData?.name ?? ""; color:Colours.palette.m3onSecondaryContainer; font:Tokens.font.label.small; elide:Text.ElideRight }
                        MaterialIcon { anchors.verticalCenter:parent.verticalCenter; text:"close"; color:Colours.palette.m3onSecondaryContainer; fontStyle:Tokens.font.icon.small; MouseArea { anchors.fill:parent; onClicked:mouse => { mouse.accepted=true; root.deletePreset(modelData?.name ?? ""); } } }
                    }
                }
            }
        }
    }
}
