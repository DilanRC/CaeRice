import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    implicitWidth: layout.implicitWidth + layout.anchors.margins * 2

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: CortetsuTokens.padding.large
        spacing: CortetsuTokens.spacing.medium

        Resource {
            icon: "memory"
            value: Cpu.percentage
        }

        Resource {
            icon: "memory_alt"
            value: Memory.percentage
            fgColour: CortetsuColours.palette.m3tertiary
        }

        Resource {
            icon: "hard_disk"
            value: Storage.percentage
            fgColour: CortetsuColours.palette.m3secondary
        }
    }
    component Resource: CircularProgress {
        id: res

        required property string icon

        Layout.fillHeight: true
        implicitSize: height
        strokeWidth: CortetsuTokens.sizes.dashboard.resourceProgressThickness

        Behavior on clampedVal {
            Anim {}
        }

        CortetsuIcon {
            anchors.centerIn: parent
            text: res.icon
            font: CortetsuTokens.font.icon.large
            color: res.fgColour
        }
    }
}
