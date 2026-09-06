pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.components.containers
import qs.modules
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Apps")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: CortetsuTokens.spacing.extraSmall / 2

        // Default applications
        SectionHeader {
            first: true
            text: qsTr("Default applications")
        }

        DefaultRow {
            first: true
            icon: "terminal"
            label: qsTr("Terminal")
            status: CortetsuConfig.terminalCommand.join(" ")
            onSelected: app => CortetsuConfig.terminalCommand = app.command
        }

        DefaultRow {
            icon: "volume_up"
            label: qsTr("Audio")
            status: CortetsuConfig.audioCommand.join(" ")
            onSelected: app => CortetsuConfig.audioCommand = app.command
        }

        DefaultRow {
            icon: "play_circle"
            label: qsTr("Media playback")
            status: CortetsuConfig.playbackCommand.join(" ")
            onSelected: app => CortetsuConfig.playbackCommand = app.command
        }

        DefaultRow {
            last: true
            icon: "folder"
            label: qsTr("File manager")
            status: CortetsuConfig.explorerCommand.join(" ")
            onSelected: app => CortetsuConfig.explorerCommand = app.command
        }

        // Library
        SectionHeader {
            text: qsTr("Library")
        }

        NavRow {
            first: true
            last: true
            icon: "apps"
            text: qsTr("All apps")
            subtext: qsTr("Browse installed apps, set favourites and hidden")
            onClicked: root.nState.openSubPage(1)
        }
    }

    component DefaultRow: PopupRow {
        id: row

        readonly property int popupHeight: root.flickable.height - y + root.flickable.contentY - CortetsuTokens.padding.large - CortetsuTokens.padding.extraExtraLarge

        signal selected(app: DesktopEntry)

        keepPopupAsChild: {
            if (root.nState.animatingContainer || root.opacity < 1)
                return true;

            let p = root.parent;
            while (p && p.objectName !== "PageContainer")
                p = p.parent;
            return p?.opacity < 1;
        }
        popup.topMovement: Math.max(CortetsuTokens.sizes.nexus.minPopupHeight - popupHeight, CortetsuTokens.padding.large)

        Loader {
            anchors.centerIn: parent
            active: row.popup.animDriver > 0

            sourceComponent: VerticalFadeListView {
                id: list

                implicitWidth: CortetsuTokens.sizes.nexus.popupWidth
                                implicitHeight: Math.max(CortetsuTokens.sizes.nexus.minPopupHeight, Math.min(row.popupHeight, CortetsuTokens.sizes.nexus.maxPopupHeight))

                model: {
                    const apps = [...DesktopEntries.applications.values];
                    const favourited = new Set(apps.filter(a => Strings.testRegexList(CortetsuConfig.favouriteApps, a.id)));
                    return apps.sort((a, b) => (favourited.has(b) - favourited.has(a)) || a.name.localeCompare(b.name));
                }

                delegate: CortetsuStateLayer {
                    id: appItem

                    required property DesktopEntry modelData
                    required property int index

                    anchors.fill: undefined
                    anchors.left: list.contentItem.left
                    anchors.right: list.contentItem.right
                    implicitHeight: itemLayout.implicitHeight + itemLayout.anchors.margins * 2
                    radius: CortetsuTokens.rounding.small

                    onClicked: {
                        row.popup.open = false;
                        row.selected(modelData);
                    }

                    RowLayout {
                        id: itemLayout

                        anchors.fill: parent
                        anchors.margins: CortetsuTokens.padding.medium
                        spacing: CortetsuTokens.spacing.medium

                        IconImage {
                        asynchronous: false
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
                    }
                }
            }
        }
    }
}
