import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.components
import qs.components.controls
import qs.services
import qs.modules

CortetsuSurface {
    id: root

    required property string icon
    required property string label
    required property string subLabel
    required property color accent
    required property real usage
    required property real temperature

    color: CortetsuColours.tPalette.m3surfaceContainer
    radius: CortetsuTokens.rounding.extraLarge

    implicitWidth: CortetsuTokens.sizes.dashboard.perfHeroCardWidth
    implicitHeight: Math.max(tempProg.implicitHeight + detailsRow.implicitHeight + CortetsuTokens.spacing.large, usageShape.implicitHeight + usageLabel.implicitHeight) + CortetsuTokens.padding.large * 2

    CircularProgress {
        id: tempProg

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: CortetsuTokens.padding.large

        fgColour: root.accent

        spacing: CortetsuTokens.spacing.extraSmall
        strokeWidth: CortetsuTokens.padding.extraSmall
        implicitSize: Math.max(icon.implicitWidth, icon.implicitHeight) + CortetsuTokens.padding.medium * 2
        value: root.usage

        Behavior on clampedVal {
            Anim {}
        }

        CortetsuIcon {
            id: icon

            anchors.centerIn: parent
            text: root.icon
            color: root.accent
            fontStyle: CortetsuTokens.font.icon.medium
        }
    }

    ColumnLayout {
        anchors.left: tempProg.right
        anchors.right: usageShape.left
        anchors.verticalCenter: tempProg.verticalCenter
        anchors.margins: CortetsuTokens.spacing.large
        spacing: CortetsuTokens.spacing.extraSmall

        CortetsuText {
            text: root.label
            font: CortetsuTokens.font.title.medium
            color: root.accent
        }

        CortetsuText {
            Layout.fillWidth: true
            text: root.subLabel
            font: CortetsuTokens.font.body.small
            color: CortetsuColours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }
    }

    ColumnLayout {
        id: detailsRow

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: CortetsuTokens.padding.largeIncreased
        spacing: CortetsuTokens.spacing.extraSmall

        RowLayout {
            Layout.leftMargin: -CortetsuTokens.padding.extraSmall
            spacing: CortetsuTokens.spacing.extraSmall

            CortetsuIcon {
                Layout.topMargin: Math.round(fontInfo.pointSize * 0.08)
                text: root.temperature > 90 ? "thermometer_alert" : "thermometer"
                color: root.temperature > 90 ? CortetsuColours.palette.m3error : root.accent
                fontStyle: CortetsuTokens.font.icon.medium
                fill: 1
            }

            CortetsuText {
                text: `${Math.ceil(CortetsuConfig.useFahrenheitPerformance ? root.temperature * 1.8 + 32 : root.temperature)}°${CortetsuConfig.useFahrenheitPerformance ? "F" : "C"}`
                font: CortetsuTokens.font.body.builders.medium.build()
            }
        }

        StyledProgressBar {
            value: root.temperature / 100
            implicitHeight: CortetsuTokens.padding.small
            fgColour: root.accent
            indeterminate: isNaN(root.usage) || isNaN(root.temperature)
        }
    }

    MaterialShape {
        id: usageShape

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: CortetsuTokens.padding.medium

        implicitSize: CortetsuTokens.sizes.dashboard.perfUsageShapeSize
        color: CortetsuColours.palette.m3secondaryContainer
        shape: {
            if (root.usage >= 0.8)
                return MaterialShape.SoftBurst;
            if (root.usage >= 0.4)
                return MaterialShape.Sunny;
            return MaterialShape.Cookie4Sided;
        }

        Behavior on color {
            CAnim {}
        }

        CortetsuText {
            id: usageLabel

            anchors.bottom: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            text: qsTr("Usage")
            color: CortetsuColours.palette.m3onSurfaceVariant
            font: CortetsuTokens.font.body.small
        }

        CortetsuText {
            anchors.centerIn: parent
            text: isNaN(root.usage) ? "...%" : Math.round(root.usage * 100) + "%"
            color: root.accent
            font: CortetsuTokens.font.headline.builders.small.width(50).build()
        }
    }
}
