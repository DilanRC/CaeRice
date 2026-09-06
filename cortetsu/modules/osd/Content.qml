import QtQuick
import ".."
import "../CortetsuDesign.js" as CortetsuDesign
import "../CortetsuTypography.js" as CortetsuTypography
import "../../services"

Column {
    id: root
    required property var monitor
    required property var screenState
    required property real volume
    required property bool muted
    required property real brightness
    padding: CortetsuDesign.spacingStandard
    spacing: CortetsuDesign.spacingCompact

    function adjustVolume(delta: real): void {
        if (delta > 0) CortetsuAudio.incrementVolume(); else CortetsuAudio.decrementVolume();
    }

    Repeater {
        model: [
            { icon: root.muted ? "volume_off" : "volume_up", label: qsTr("Volume"), value: root.volume },
            { icon: "brightness_6", label: qsTr("Brightness"), value: root.brightness }
        ]
        delegate: CortetsuSurface {
            required property var modelData
            implicitWidth: 240
            implicitHeight: 48
            radiusValue: CortetsuDesign.radiusMedium
            baseColor: CortetsuDesign.colorSurfaceGlass
            outlined: true
            Row {
                anchors.fill: parent
                anchors.margins: CortetsuDesign.spacingStandard
                spacing: CortetsuDesign.spacingStandard
                CortetsuIcon { text: modelData.icon; color: CortetsuDesign.colorPrimary; iconSize: CortetsuTypography.iconMediumPx }
                CortetsuText { text: `${modelData.label}  ${Math.round(modelData.value * 100)}%`; textSize: CortetsuTypography.bodyPx; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea {
                anchors.fill: parent
                onWheel: event => {
                    if (index === 0) root.adjustVolume(event.angleDelta.y);
                    else if (root.monitor) root.monitor.setBrightness(root.brightness + (event.angleDelta.y > 0 ? 0.05 : -0.05));
                }
            }
        }
    }
}
