import QtQuick
import qs.components
import qs.components.blobs
import qs.services

Item {
    id: root

    property alias icon: icon.text
    property alias color: blobGroup.color
    readonly property alias hovered: btn.containsMouse
    property bool open
    property int padding
    property int topMovement: CortetsuTokens.padding.large
    property bool pressOverride
    property bool hoverOverride
    property real animDriver
    default required property Item content

    implicitWidth: btn.implicitWidth * 0.9
    implicitHeight: btn.implicitHeight * 0.9

    Binding {
        target: root.content
        property: "opacity"
        value: root.animDriver
    }

    BlobGroup {
        id: blobGroup

        color: CortetsuColours.palette.m3surfaceContainerHighest
        smoothing: root.CortetsuTokens.rounding.medium
        cornerFill: false

        Behavior on color {
            CAnim {}
        }
    }

    BlobRect {
        id: btnRect

        anchors.fill: parent
        anchors.margins: (!(btn.pressed || root.pressOverride) && (btn.containsMouse || root.hoverOverride) ? -CortetsuTokens.padding.extraSmall : 0) + (root.open ? -CortetsuTokens.padding.extraSmall : 0)
        group: blobGroup
        radius: root.open ? CortetsuTokens.rounding.large : CortetsuTokens.rounding.medium

        Behavior on anchors.margins {
            Anim {}
        }

        Behavior on radius {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    BlobRect {
        id: rect

        anchors.right: parent.right
        anchors.top: parent.top

        implicitWidth: parent.width
        implicitHeight: parent.height

        group: blobGroup
        radius: CortetsuTokens.rounding.large
        deformScale: 0.00001

        states: State {
            name: "open"
            when: root.open

            PropertyChanges {
                rect.anchors.rightMargin: root.width - root.CortetsuTokens.spacing.small
                rect.anchors.topMargin: -root.topMovement
                rect.implicitWidth: root.content.implicitWidth + root.padding * 2
                rect.implicitHeight: root.content.implicitHeight + root.padding * 2
                root.animDriver: 1
            }
        }

        transitions: Transition {
            Anim {
                properties: "rightMargin,implicitWidth"
            }
            Anim {
                properties: "topMargin,implicitHeight"
                easing: root.CortetsuTokens.anim.expressiveFastSpatial
            }
            Anim {
                property: "animDriver"
                type: Anim.DefaultEffects
            }
        }

        MouseArea { // MouseArea to catch inputs
            anchors.fill: parent
            clip: true
            children: [root.content]
        }
    }

    MouseArea {
        id: btn

        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + CortetsuTokens.padding.extraSmall * 2
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.open = !root.open

        CortetsuIcon {
            id: icon

            anchors.centerIn: parent
            text: "view_apps"
            color: CortetsuColours.palette.m3onSurfaceVariant
            fontStyle: CortetsuTokens.font.icon.medium
        }
    }
}
