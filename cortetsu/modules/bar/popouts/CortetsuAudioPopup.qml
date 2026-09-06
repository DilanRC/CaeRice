import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"
import "../../CortetsuDesign.js" as CortetsuDesign
import "../.."

CortetsuSurface {
    id: root
    required property var popouts
    implicitWidth: 336
    implicitHeight: body.implicitHeight + CortetsuDesign.spacingComfortable * 2
    radiusValue: CortetsuDesign.radiusLarge
    baseColor: CortetsuDesign.colorSurfaceGlass
    outlined: true

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingComfortable
        spacing: CortetsuDesign.spacingStandard

        CortetsuSectionHeader {
            title: qsTr("Audio")
            detail: CortetsuAudio.muted ? qsTr("Muted") : qsTr("%1%").arg(Math.round(CortetsuAudio.volume * 100))
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: CortetsuDesign.spacingCompact
            CortetsuIcon {
                text: Icons.getVolumeIcon(CortetsuAudio.volume, CortetsuAudio.muted)
                iconSize: CortetsuDesign.iconMediumPx
                color: CortetsuDesign.colorPrimary
            }
            CortetsuSlider {
                Layout.fillWidth: true
                value: CortetsuAudio.volume
                onMoved: value => CortetsuAudio.setVolume(value)
            }
            CortetsuButton {
                compact: true
                icon: CortetsuAudio.muted ? "volume_off" : "volume_up"
                onClicked: if (CortetsuAudio.sink?.audio) CortetsuAudio.sink.audio.muted = !CortetsuAudio.sink.audio.muted
            }
        }

        CortetsuSectionHeader { title: qsTr("Output"); detail: CortetsuAudio.sink?.description ?? qsTr("No device") }
        Repeater {
            model: CortetsuAudio.sinks
            delegate: CortetsuListRow {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.description ?? modelData.name ?? qsTr("Unknown device")
                icon: "speaker"
                selected: CortetsuAudio.sink?.id === modelData.id
                onClicked: CortetsuAudio.setAudioSink(modelData)
            }
        }
    }
}
