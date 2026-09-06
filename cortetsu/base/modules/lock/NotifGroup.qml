pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.components
import qs.components.effects
import qs.modules
import qs.services
import qs.utils

CortetsuSurface {
    id: root

    required property string modelData

    readonly property list<var> notifs: Notifs.list.filter(notif => notif.appName === modelData)
    readonly property var props: {
        let img = "";
        let icon = "";
        let hasCritical = false;
        let hasNormal = false;
        for (const n of notifs) {
            if (!img && n.image.length > 0)
                img = n.image;
            if (!icon && n.appIcon.length > 0)
                icon = n.appIcon;
            if (n.urgency === NotificationUrgency.Critical)
                hasCritical = true;
            else if (n.urgency === NotificationUrgency.Normal)
                hasNormal = true;
        }
        return {
            img,
            icon,
            urgency: hasCritical ? "critical" : hasNormal ? "normal" : "low"
        };
    }
    readonly property string image: props.img
    readonly property string appIcon: props.icon
    readonly property string urgency: props.urgency

    property bool expanded

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: content.implicitHeight + CortetsuTokens.padding.medium * 2

    clip: true
    radius: CortetsuTokens.rounding.large
    color: root.urgency === "critical" ? CortetsuColours.palette.m3secondaryContainer : CortetsuColours.layer(CortetsuColours.palette.m3surfaceContainerHigh, 2)

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: CortetsuTokens.padding.medium

        spacing: CortetsuTokens.spacing.medium

        Item {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            implicitWidth: TokenConfig.sizes.notifs.image
            implicitHeight: TokenConfig.sizes.notifs.image

            Component {
                id: imageComp

                Image {
                    source: Qt.resolvedUrl(root.image)
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: {
                        const size = TokenConfig.sizes.notifs.image * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1);
                        return Qt.size(size, size);
                    }
                    cache: false
                    asynchronous: false
                    width: TokenConfig.sizes.notifs.image
                    height: TokenConfig.sizes.notifs.image
                }
            }

            Component {
                id: appIconComp

                ColouredIcon {
                    implicitSize: Math.round(TokenConfig.sizes.notifs.image * 0.6)
                    source: Quickshell.iconPath(root.appIcon)
                    colour: root.urgency === "critical" ? CortetsuColours.palette.m3onError : root.urgency === "low" ? CortetsuColours.palette.m3onSurface : CortetsuColours.palette.m3onSecondaryContainer
                    layer.enabled: root.appIcon.endsWith("symbolic")
                }
            }

            Component {
                id: materialIconComp

                CortetsuIcon {
                    text: Icons.getNotifIcon(root.notifs[0]?.summary, root.urgency)
                    color: root.urgency === "critical" ? CortetsuColours.palette.m3onError : root.urgency === "low" ? CortetsuColours.palette.m3onSurface : CortetsuColours.palette.m3onSecondaryContainer
                    fontStyle: CortetsuTokens.font.icon.large
                }
            }

            ClippingRectangle {
                anchors.fill: parent
                color: root.urgency === "critical" ? CortetsuColours.palette.m3error : root.urgency === "low" ? CortetsuColours.layer(CortetsuColours.palette.m3surfaceContainerHighest, 3) : CortetsuColours.palette.m3secondaryContainer
                radius: CortetsuTokens.rounding.full

                Loader {
                    asynchronous: true
                    anchors.centerIn: parent
                    sourceComponent: root.image ? imageComp : root.appIcon ? appIconComp : materialIconComp
                }
            }

            Loader {
                asynchronous: true
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                active: root.appIcon && root.image

                sourceComponent: CortetsuSurface {
                    implicitWidth: CortetsuTokens.sizes.notifs.badge
                    implicitHeight: CortetsuTokens.sizes.notifs.badge

                    color: root.urgency === "critical" ? CortetsuColours.palette.m3error : root.urgency === "low" ? CortetsuColours.palette.m3surfaceContainerHighest : CortetsuColours.palette.m3secondaryContainer
                    radius: CortetsuTokens.rounding.full

                    ColouredIcon {
                        anchors.centerIn: parent
                        implicitSize: Math.round(CortetsuTokens.sizes.notifs.badge * 0.6)
                        source: Quickshell.iconPath(root.appIcon)
                        colour: root.urgency === "critical" ? CortetsuColours.palette.m3onError : root.urgency === "low" ? CortetsuColours.palette.m3onSurface : CortetsuColours.palette.m3onSecondaryContainer
                        layer.enabled: root.appIcon.endsWith("symbolic")
                    }
                }
            }
        }

        ColumnLayout {
            Layout.topMargin: -CortetsuTokens.padding.extraSmall
            Layout.bottomMargin: -CortetsuTokens.padding.extraSmall / 2 - (root.expanded ? 0 : spacing)
            Layout.fillWidth: true
            spacing: Math.round(CortetsuTokens.spacing.extraSmall)

            RowLayout {
                Layout.bottomMargin: -parent.spacing
                Layout.fillWidth: true
                spacing: CortetsuTokens.spacing.medium

                CortetsuText {
                    Layout.fillWidth: true
                    text: root.modelData
                    color: CortetsuColours.palette.m3onSurfaceVariant
                    font: CortetsuTokens.font.body.small
                    elide: Text.ElideRight
                }

                CortetsuText {
                    animate: true
                    text: root.notifs[0]?.timeStr ?? ""
                    color: CortetsuColours.palette.m3outline
                    font: CortetsuTokens.font.body.small
                }

                CortetsuSurface {
                    implicitWidth: expandBtn.implicitWidth + CortetsuTokens.padding.large
                    implicitHeight: groupCount.implicitHeight + CortetsuTokens.padding.extraSmall

                    color: root.urgency === "critical" ? CortetsuColours.palette.m3error : CortetsuColours.layer(CortetsuColours.palette.m3surfaceContainerHighest, 2)
                    radius: CortetsuTokens.rounding.full

                    opacity: root.notifs.length > CortetsuConfig.notificationGroupPreviewNum ? 1 : 0
                    Layout.preferredWidth: root.notifs.length > CortetsuConfig.notificationGroupPreviewNum ? implicitWidth : 0

                    CortetsuStateLayer {
                        color: root.urgency === "critical" ? CortetsuColours.palette.m3onError : CortetsuColours.palette.m3onSurface
                        onClicked: root.expanded = !root.expanded
                    }

                    RowLayout {
                        id: expandBtn

                        anchors.centerIn: parent
                        spacing: CortetsuTokens.spacing.extraSmall

                        CortetsuText {
                            id: groupCount

                            Layout.leftMargin: CortetsuTokens.padding.extraSmall / 2
                            animate: true
                            text: root.notifs.length
                            color: root.urgency === "critical" ? CortetsuColours.palette.m3onError : CortetsuColours.palette.m3onSurface
                            font: CortetsuTokens.font.body.small
                        }

                        CortetsuIcon {
                            Layout.rightMargin: -CortetsuTokens.padding.extraSmall / 2
                            animate: true
                            text: root.expanded ? "expand_less" : "expand_more"
                            color: root.urgency === "critical" ? CortetsuColours.palette.m3onError : CortetsuColours.palette.m3onSurface
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on Layout.preferredWidth {
                        Anim {}
                    }
                }
            }

            Repeater {
                model: ScriptModel {
                    values: root.notifs.slice(0, CortetsuConfig.notificationGroupPreviewNum) as Array
                }

                NotifLine {
                    id: notif

                    ParallelAnimation {
                        running: true

                        Anim {
                            type: Anim.DefaultEffects
                            target: notif
                            property: "opacity"
                            from: 0
                            to: 1
                        }
                        Anim {
                            target: notif
                            property: "scale"
                            from: 0.7
                            to: 1
                        }
                        Anim {
                            target: notif.Layout
                            property: "preferredHeight"
                            from: 0
                            to: notif.implicitHeight
                        }
                    }

                    ParallelAnimation {
                        running: notif.modelData.closed
                        onFinished: notif.modelData.unlock(notif)

                        Anim {
                            type: Anim.DefaultEffects
                            target: notif
                            property: "opacity"
                            to: 0
                        }
                        Anim {
                            target: notif
                            property: "scale"
                            to: 0.7
                        }
                        Anim {
                            target: notif.Layout
                            property: "preferredHeight"
                            to: 0
                        }
                    }
                }
            }

            Loader {
                asynchronous: true
                Layout.fillWidth: true

                opacity: root.expanded ? 1 : 0
                Layout.preferredHeight: root.expanded ? implicitHeight : 0
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    Repeater {
                        model: ScriptModel {
                            values: root.notifs.slice(CortetsuConfig.notificationGroupPreviewNum) as Array
                        }

                        NotifLine {}
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component NotifLine: CortetsuText {
        id: notifLine

        required property NotifData modelData

        Layout.fillWidth: true
        textFormat: Text.MarkdownText
        text: {
            const summary = modelData.summary.replace(/\n/g, " ");
            const body = modelData.body.replace(/\n/g, " ");
            const colour = root.urgency === "critical" ? CortetsuColours.palette.m3secondary : CortetsuColours.palette.m3outline;

            if (metrics.text === metrics.elidedText)
                return `${summary} <span style='color:${colour}'>${body}</span>`;

            const t = metrics.elidedText.length - 3;
            if (t < summary.length)
                return `${summary.slice(0, t)}...`;

            return `${summary} <span style='color:${colour}'>${body.slice(0, t - summary.length)}...</span>`;
        }
        color: root.urgency === "critical" ? CortetsuColours.palette.m3onSecondaryContainer : CortetsuColours.palette.m3onSurface

        Component.onCompleted: modelData.lock(this)
        Component.onDestruction: modelData.unlock(this)

        TextMetrics {
            id: metrics

            text: `${notifLine.modelData.summary} ${notifLine.modelData.body}`.replace(/\n/g, " ")
            font: notifLine.font
            elideWidth: notifLine.width
            elide: Text.ElideRight
        }
    }
}
