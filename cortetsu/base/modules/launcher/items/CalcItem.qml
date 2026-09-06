import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services
import qs.modules

Item {
    id: root

    required property var list
    readonly property string math: list.search.text.slice(`${CortetsuConfig.actionPrefix}calc `.length)

    function onClicked(): void {
        Quickshell.execDetached(["wl-copy", Qalculator.rawResult]);
        root.list.screenState.launcher = false;
    }

    onMathChanged: {
        if (math.length > 0)
            Qalculator.evalAsync(math);
    }

    implicitHeight: CortetsuTokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    CortetsuStateLayer {
        radius: CortetsuTokens.rounding.large
        onClicked: root.onClicked()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: CortetsuTokens.padding.medium

        spacing: CortetsuTokens.spacing.medium

        CortetsuIcon {
            text: "function"
            fontStyle: CortetsuTokens.font.icon.extraLarge
            Layout.alignment: Qt.AlignVCenter
        }

        CortetsuText {
            id: result

            color: {
                if (text.includes("error: ") || text.includes("warning: "))
                    return CortetsuColours.palette.m3error;
                if (!root.math)
                    return CortetsuColours.palette.m3onSurfaceVariant;
                return CortetsuColours.palette.m3onSurface;
            }

            text: root.math.length > 0 ? (Qalculator.result || qsTr("Calculating...")) : qsTr("Type an expression to calculate")
            elide: Text.ElideLeft

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        CortetsuSurface {
            color: CortetsuColours.palette.m3tertiary
            radius: CortetsuTokens.rounding.large
            clip: true

            implicitWidth: (stateLayer.containsMouse ? label.implicitWidth + label.anchors.rightMargin : 0) + icon.implicitWidth + CortetsuTokens.padding.medium * 2
            implicitHeight: Math.max(label.implicitHeight, icon.implicitHeight) + CortetsuTokens.padding.small

            Layout.alignment: Qt.AlignVCenter

            CortetsuStateLayer {
                id: stateLayer

                onClicked: {
                    Quickshell.execDetached([...CortetsuConfig.terminalCommand, "fish", "-C", `exec qalc -i '${root.math}'`]);
                    root.list.screenState.launcher = false;
                }

                color: CortetsuColours.palette.m3onTertiary
            }

            CortetsuText {
                id: label

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: icon.left
                anchors.rightMargin: CortetsuTokens.spacing.small

                text: qsTr("Open in calculator")
                color: CortetsuColours.palette.m3onTertiary
                font: CortetsuTokens.font.label.medium

                opacity: stateLayer.containsMouse ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            CortetsuIcon {
                id: icon

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: CortetsuTokens.padding.medium

                text: "open_in_new"
                color: CortetsuColours.palette.m3onTertiary
                fontStyle: CortetsuTokens.font.icon.large
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.Emphasized
                }
            }
        }
    }
}
