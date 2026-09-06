pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.components
import qs.components.effects
import qs.components.widgets
import qs.services
import qs.modules

CortetsuSurface {
    id: root

    readonly property real fontScale: {
        const diff = width / 391 - 1; // 391 is the width at 1080 height screen
        return 1 + Math.pow(Math.abs(diff), 0.8) * Math.sign(diff);
    }

    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2
    radius: CortetsuTokens.rounding.extraLarge
    color: CortetsuColours.tPalette.m3surfaceContainer

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.large
        spacing: CortetsuTokens.spacing.large

        Resource {
            id: cpu

            icon: "memory"
            value: Math.round(Cpu.percentage * 100) + "%"
            fillValue: Cpu.percentage
            colour: CortetsuColours.palette.m3primary
            shapeColour: CortetsuColours.palette.m3primaryContainer
            fillColour: Qt.alpha(CortetsuColours.palette.m3secondary, 0.3)
            shape: MaterialShape.Pentagon

            MaterialShape {
                x: cpu.mShape.pointAtAngle(45).x - implicitSize / 2 + CortetsuTokens.padding.medium
                y: cpu.mShape.pointAtAngle(45).y - implicitSize / 2

                shape: Cpu.temperature > 90 ? MaterialShape.SoftBurst : MaterialShape.Circle
                color: Cpu.temperature > 90 ? CortetsuColours.palette.m3errorContainer : CortetsuColours.palette.m3secondaryContainer
                implicitSize: {
                    const size = Math.round(tempLabel.implicitHeight * 2);
                    return size % 2 === 0 ? size : size + 1; // Ensure even size so center works properly
                }

                Behavior on color {
                    CAnim {}
                }

                CortetsuText {
                    id: tempLabel

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Math.round(fontInfo.pointSize * 0.04)

                    text: {
                        const temp = Cpu.temperature;
                        const useF = CortetsuConfig.useFahrenheitPerformance;
                        return `${Math.ceil(useF ? temp * 1.8 + 32 : temp)}°${useF ? "F" : "C"}`;
                    }
                    color: Cpu.temperature > 90 ? CortetsuColours.palette.m3onErrorContainer : CortetsuColours.palette.m3secondary
                    font: CortetsuTokens.font.title.builders.medium.scale(cpu.width / 112).width(50).build()
                }
            }
        }

        Resource {
            icon: "memory_alt"
            value: Math.round(Memory.percentage * 100) + "%"
            fillValue: Memory.percentage
            colour: CortetsuColours.palette.m3tertiary
            shapeColour: CortetsuColours.palette.m3onTertiary
            fillColour: Qt.alpha(CortetsuColours.palette.m3tertiary, 0.3)
            shape: MaterialShape.Slanted
        }

        Resource {
            icon: "hard_disk"
            value: Math.round(Storage.percentage * 100) + "%"
            fillValue: Storage.percentage
            colour: CortetsuColours.palette.m3secondary
            shapeColour: CortetsuColours.palette.m3secondaryContainer
            fillColour: Qt.alpha(CortetsuColours.palette.m3secondary, 0.4)
            shape: MaterialShape.Gem
        }
    }

    component Resource: Item {
        id: res

        required property string icon
        required property string value
        required property color colour
        required property color shapeColour
        property color fillColour
        property real fillValue: -1
        property alias shape: shape.shape
        readonly property alias mShape: shape

        Layout.fillWidth: true
        implicitHeight: width

        Behavior on shapeColour {
            CAnim {}
        }

        MaterialShape {
            id: shape

            implicitSize: res.width
            color: Qt.alpha(res.shapeColour, 1)
            opacity: res.shapeColour.a
            layer.enabled: true
        }

        Loader {
            id: fillLoader

            anchors.fill: shape
            active: res.fillValue >= 0
            asynchronous: true

            layer.enabled: active
            layer.effect: Mask {
                maskSource: shape
            }

            sourceComponent: Item {
                WavyTopRect {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    implicitHeight: shape.implicitSize * res.fillValue
                    color: res.fillColour
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -CortetsuTokens.spacing.extraSmall

            CortetsuIcon {
                Layout.alignment: Qt.AlignHCenter
                text: res.icon
                color: CortetsuColours.palette.m3secondary
                fontStyle: CortetsuTokens.font.icon.builders.medium.scale(root.fontScale).build()
            }

            CortetsuText {
                Layout.alignment: Qt.AlignHCenter
                text: res.value
                color: res.colour
                font: CortetsuTokens.font.headline.builders.large.scale(root.fontScale).width(50).build()
            }
        }

        Behavior on fillValue {
            Anim {}
        }
    }
}
