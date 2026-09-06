import QtQuick
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    implicitWidth: Math.round(CortetsuTokens.font.body.large.pointSize * 1.2)
    implicitHeight: Math.round(CortetsuTokens.font.body.large.pointSize * 1.2)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const screenState = ShellState.forActive();
            screenState.launcher = !screenState.launcher;
        }
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent
        sourceComponent: SysInfo.isDefaultLogo ? cortetsuLogo : distroIcon
    }

    Component {
        id: cortetsuLogo

        Logo {
            implicitWidth: Math.round(CortetsuTokens.font.body.large.pointSize * 1.6)
            implicitHeight: Math.round(CortetsuTokens.font.body.large.pointSize * 1.6)
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: Math.round(CortetsuTokens.font.body.large.pointSize * 1.2)
            colour: CortetsuColours.palette.m3tertiary
        }
    }
}
