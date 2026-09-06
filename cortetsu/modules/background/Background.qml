import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../../services"

Variants {
    model: CortetsuScreens.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData

        screen: modelData
        WlrLayershell.namespace: "cortetsu-background"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: CortetsuConfig.wallpaperEnabled ? WlrLayer.Background : WlrLayer.Bottom
        color: CortetsuConfig.wallpaperEnabled ? "black" : "transparent"
        surfaceFormat.opaque: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        ShellState.ComponentRef {
            screen: win.screen
            slot: "background"
            component: win
        }

        Item {
            id: behindClock
            anchors.fill: parent

            Loader {
                id: wallpaper
                anchors.fill: parent
                asynchronous: true
                active: CortetsuConfig.wallpaperEnabled
                sourceComponent: Wallpaper {}
            }

            Visualiser {
                anchors.fill: parent
                screen: win.modelData
                wallpaper: wallpaper
            }
        }

        Loader {
            id: clockLoader
            anchors.margins: 28
            anchors.leftMargin: 88
            asynchronous: true
            active: CortetsuConfig.desktopClockEnabled
            state: CortetsuConfig.desktopClockPosition

            states: [
                State { name: "top-left"; AnchorChanges { target: clockLoader; anchors.top: parent.top; anchors.left: parent.left } },
                State { name: "top-center"; AnchorChanges { target: clockLoader; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter } },
                State { name: "top-right"; AnchorChanges { target: clockLoader; anchors.top: parent.top; anchors.right: parent.right } },
                State { name: "middle-left"; AnchorChanges { target: clockLoader; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left } },
                State { name: "middle-center"; AnchorChanges { target: clockLoader; anchors.verticalCenter: parent.verticalCenter; anchors.horizontalCenter: parent.horizontalCenter } },
                State { name: "middle-right"; AnchorChanges { target: clockLoader; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right } },
                State { name: "bottom-left"; AnchorChanges { target: clockLoader; anchors.bottom: parent.bottom; anchors.left: parent.left } },
                State { name: "bottom-center"; AnchorChanges { target: clockLoader; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter } },
                State { name: "bottom-right"; AnchorChanges { target: clockLoader; anchors.bottom: parent.bottom; anchors.right: parent.right } }
            ]

            sourceComponent: DesktopClock {
                wallpaper: behindClock
                absX: clockLoader.x
                absY: clockLoader.y
            }
        }
    }
}
