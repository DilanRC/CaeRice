pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("All apps")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: CortetsuTokens.spacing.extraSmall / 2

        Repeater {
            id: list

            model: [...DesktopEntries.applications.values].sort((a, b) => a.name.localeCompare(b.name))

            ConnectedRect {
                id: appItem

                required property DesktopEntry modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                last: index === list.count - 1
                implicitHeight: appRow.implicitHeight + appRow.anchors.margins * 2

                CortetsuStateLayer {
                    onClicked: {
                        root.nState.selectedApp = appItem.modelData;
                        root.nState.openSubPage(2);
                    }
                }

                RowLayout {
                    id: appRow

                    anchors.fill: parent
                    anchors.margins: CortetsuTokens.padding.medium
                    anchors.leftMargin: CortetsuTokens.padding.largeIncreased
                    anchors.rightMargin: CortetsuTokens.padding.largeIncreased
                    spacing: CortetsuTokens.spacing.medium

                    IconImage {
                        asynchronous: true
                        implicitSize: Math.round(CortetsuTokens.font.icon.large.pointSize * 1.8)
                        source: Quickshell.iconPath(appItem.modelData.icon, "image-missing")
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        CortetsuText {
                            Layout.fillWidth: true
                            text: appItem.modelData.name
                            font: CortetsuTokens.font.body.small
                            elide: Text.ElideRight
                        }

                        CortetsuText {
                            Layout.fillWidth: true
                            visible: text
                            text: (appItem.modelData.comment || appItem.modelData.genericName) ?? ""
                            color: CortetsuColours.palette.m3outline
                            font: CortetsuTokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    CortetsuIcon {
                        visible: Strings.testRegexList(CortetsuConfig.favouriteApps, appItem.modelData.id)
                        text: "favorite"
                        fill: 1
                        color: CortetsuColours.palette.m3primary
                        fontStyle: CortetsuTokens.font.icon.small
                    }

                    CortetsuIcon {
                        text: "chevron_right"
                        color: CortetsuColours.palette.m3onSurfaceVariant
                        fontStyle: CortetsuTokens.font.icon.medium
                    }
                }
            }
        }
    }
}
