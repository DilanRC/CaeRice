import QtQuick
import ".."
import "../CortetsuDesign.js" as CortetsuDesign
import "../CortetsuTypography.js" as CortetsuTypography
import "../../components"
import "../../services"

CortetsuPopupSurface {
    id: root
    required property var monitor
    required property var screenState
    required property real volume
    required property bool muted
    required property real brightness
    implicitWidth: 264
    implicitHeight: indicators.implicitHeight + CortetsuDesign.spacingStandard * 2

    Column {
        id: indicators
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingStandard
        spacing: CortetsuDesign.spacingCompact

        Repeater {
            model: [
                { icon: root.muted ? "volume_off" : "volume_up", label: qsTr("Volume"), value: root.volume },
                { icon: "brightness_6", label: qsTr("Brightness"), value: root.brightness }
            ]
            delegate: CortetsuSurface {
                required property var modelData
                implicitWidth: indicators.width
                implicitHeight: 62
                radiusValue: CortetsuDesign.radiusMedium
                baseColor: CortetsuDesign.colorSurfaceHigh
                outlined: false

                Column {
                    anchors.fill: parent
                    anchors.margins: CortetsuDesign.spacingStandard
                    spacing: CortetsuDesign.spacingCompact

                    Row {
                        width: parent.width
                        spacing: CortetsuDesign.spacingStandard
                        CortetsuIcon { text: modelData.icon; color: root.muted && index === 0 ? CortetsuDesign.colorOnSurfaceVariant : CortetsuDesign.colorPrimary; iconSize: CortetsuTypography.iconMediumPx }
                        CortetsuText { text: `${modelData.label}  ${Math.round(modelData.value * 100)}%`; textSize: CortetsuTypography.bodyPx; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Rectangle {
                        width: parent.width
                        height: 4
                        radius: 2
                        color: CortetsuDesign.colorOutlineVariant

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, modelData.value))
                            height: parent.height
                            radius: parent.radius
                            color: root.muted && index === 0 ? CortetsuDesign.colorOnSurfaceVariant : CortetsuDesign.colorPrimary
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onWheel: event => {
                        if (index === 0) {
                            if (event.angleDelta.y > 0) CortetsuAudio.incrementVolume();
                            else CortetsuAudio.decrementVolume();
                        } else if (root.monitor) {
                            root.monitor.setBrightness(root.brightness + (event.angleDelta.y > 0 ? 0.05 : -0.05));
                        }
                    }
                }
            }
        }
    }
}
