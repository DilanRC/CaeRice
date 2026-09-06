import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import qs.modules

CortetsuSurface {
    id: root

    readonly property real nonAnimHeight: layout.implicitHeight + (IdleInhibitor.enabled ? activeChip.implicitHeight + activeChip.anchors.topMargin : 0) + CortetsuTokens.padding.extraLargeIncreased

    implicitHeight: nonAnimHeight

    radius: CortetsuTokens.rounding.large
    color: CortetsuColours.tPalette.m3surfaceContainer
    clip: true

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: CortetsuTokens.padding.large
        spacing: CortetsuTokens.spacing.medium

        CortetsuSurface {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + CortetsuTokens.padding.large

            radius: CortetsuTokens.rounding.full
            color: IdleInhibitor.enabled ? CortetsuColours.palette.m3secondary : CortetsuColours.palette.m3secondaryContainer

            CortetsuIcon {
                id: icon

                anchors.centerIn: parent
                text: "coffee"
                color: IdleInhibitor.enabled ? CortetsuColours.palette.m3onSecondary : CortetsuColours.palette.m3onSecondaryContainer
                fontStyle: CortetsuTokens.font.icon.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            CortetsuText {
                Layout.fillWidth: true
                text: qsTr("Keep Awake")
                font: CortetsuTokens.font.body.medium
                elide: Text.ElideRight
            }

            CortetsuText {
                Layout.fillWidth: true
                text: IdleInhibitor.enabled ? qsTr("Preventing sleep mode") : qsTr("Normal power management")
                color: CortetsuColours.palette.m3onSurfaceVariant
                font: CortetsuTokens.font.body.small
                elide: Text.ElideRight
            }
        }

        StyledSwitch {
            checked: IdleInhibitor.enabled
            onToggled: IdleInhibitor.enabled = checked
        }
    }

    Loader {
        id: activeChip

        asynchronous: true
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.topMargin: CortetsuTokens.spacing.large
        anchors.bottomMargin: IdleInhibitor.enabled ? CortetsuTokens.padding.large : -implicitHeight
        anchors.leftMargin: CortetsuTokens.padding.large

        opacity: IdleInhibitor.enabled ? 1 : 0
        scale: IdleInhibitor.enabled ? 1 : 0.5

        Component.onCompleted: active = Qt.binding(() => opacity > 0)

        sourceComponent: CortetsuSurface {
            implicitWidth: activeText.implicitWidth + CortetsuTokens.padding.medium * 2
            implicitHeight: activeText.implicitHeight + CortetsuTokens.padding.small

            radius: CortetsuTokens.rounding.full
            color: CortetsuColours.palette.m3primary

            CortetsuText {
                id: activeText

                anchors.centerIn: parent
                text: qsTr("Active since %1").arg(Qt.formatTime(IdleInhibitor.enabledSince, CortetsuConfig.useTwelveHourClock ? "hh:mm a" : "hh:mm"))
                color: CortetsuColours.palette.m3onPrimary
                font: CortetsuTokens.font.body.builders.small.size(Math.round(CortetsuTokens.font.body.small.pointSize * 0.9)).build()
            }
        }

        Behavior on anchors.bottomMargin {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.StandardSmall
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
