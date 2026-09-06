import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("CortetsuColours")
    isSubPage: true

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        implicitHeight: {
            const f = parent.parent as Flickable;
            return f.height - f.topMargin - f.bottomMargin;
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: CortetsuTokens.padding.extraSmall

            CortetsuIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "handyman"
                color: CortetsuColours.palette.m3outlineVariant
                fontStyle: CortetsuTokens.font.icon.extraLarge
            }

            CortetsuText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Page under construction")
                color: CortetsuColours.palette.m3outlineVariant
                font: CortetsuTokens.font.title.large
            }

            CortetsuText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("This page will be available in a future update.")
                color: CortetsuColours.palette.m3outlineVariant
                font: CortetsuTokens.font.body.large
            }
        }
    }
}
