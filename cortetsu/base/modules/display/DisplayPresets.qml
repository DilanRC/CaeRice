pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import ".."
import "../CortetsuDesign.js" as CortetsuDesign
import "../CortetsuTypography.js" as CortetsuTypography

Rectangle {
    id: root
    required property var candidateOutputs
    signal candidateLoaded(var candidate)

    property var presets: []
    property string statusText: qsTr("Named layouts")
    property string presetName: ""
    property string actionKind: ""
    readonly property string helperPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/cortetsu-display-presets"

    radius: CortetsuDesign.radiusLarge
    color: CortetsuDesign.colorSurfaceHigh
    border.width: 1
    border.color: CortetsuDesign.colorOutlineVariant

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
            CortetsuText { width: parent.width * 0.55; text: qsTr("Saved layouts"); color: CortetsuDesign.colorOnSurface; textSize: CortetsuTypography.titleSmallPx }
            CortetsuText { width: parent.width * 0.45; text: root.statusText; color: CortetsuDesign.colorOutline; textSize: CortetsuTypography.labelSmallPx; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight }
        }
        Row {
            width: parent.width; height: 38; spacing: 6
            Rectangle {
                width: parent.width - 82; height: 38; radius: CortetsuDesign.radiusSmall; color: CortetsuDesign.colorSurface
                CortetsuText { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; visible: nameInput.text.length===0; text: qsTr("name this layout"); color: CortetsuDesign.colorOutline; textSize: CortetsuTypography.labelSmallPx }
                TextInput { id:nameInput; anchors.fill: parent; anchors.leftMargin:10; anchors.rightMargin:10; verticalAlignment:TextInput.AlignVCenter; text:root.presetName; onTextChanged:root.presetName=text; color:CortetsuDesign.colorOnSurface; selectionColor:CortetsuDesign.colorPrimary }
            }
            Rectangle {
                width: 76
                height: 38
                radius: CortetsuDesign.radiusSmall
                color: CortetsuDesign.colorPrimaryContainer
                enabled: !worker.running
                CortetsuStateLayer { radius: parent.radius; onClicked: root.save() }
                CortetsuText { anchors.centerIn: parent; text: qsTr("Save"); color: CortetsuDesign.colorOnPrimaryContainer; textSize: CortetsuTypography.labelSmallPx }
            }
        }
        Row {
            width: parent.width; height: 38; spacing: 5
            Repeater {
                model: Array.from(root.presets ?? []).slice(0,3)
                delegate: Rectangle {
                    required property var modelData
                    width:(parent.width-10)/3; height:38; radius:CortetsuDesign.radiusSmall; color:CortetsuDesign.colorSecondaryContainer
                    CortetsuStateLayer { radius:parent.radius; onClicked:root.loadPreset(modelData?.name ?? "") }
                    Row { anchors.fill:parent; anchors.margins:7; spacing:3
                        CortetsuText { width:parent.width-24; anchors.verticalCenter:parent.verticalCenter; text:modelData?.name ?? ""; color:CortetsuDesign.colorOnSecondaryContainer; textSize: CortetsuTypography.labelSmallPx; elide:Text.ElideRight }
                        CortetsuIcon { anchors.verticalCenter:parent.verticalCenter; text:"close"; color:CortetsuDesign.colorOnSecondaryContainer; iconSize: CortetsuTypography.iconSmallPx; MouseArea { anchors.fill:parent; onClicked:mouse => { mouse.accepted=true; root.deletePreset(modelData?.name ?? ""); } } }
                    }
                }
            }
        }
    }
}
