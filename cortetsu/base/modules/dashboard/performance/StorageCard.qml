import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.controls
import qs.services

CortetsuSurface {
    id: root

    readonly property color accent: CortetsuColours.palette.m3secondary
    readonly property real percentage: Storage.primaryDisk?.perc ?? 0

    color: CortetsuColours.tPalette.m3surfaceContainer
    radius: CortetsuTokens.rounding.extraExtraLarge

    implicitWidth: layout.implicitWidth + layout.anchors.margins * 2
    implicitHeight: layout.implicitHeight + CortetsuTokens.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: CortetsuTokens.padding.extraLarge
        spacing: 0

        RowLayout {
            id: row

            Layout.alignment: Qt.AlignHCenter
            spacing: CortetsuTokens.spacing.large

            CircularProgress {
                fgColour: root.accent
                value: root.percentage
                implicitSize: usageColumn.implicitHeight + thickness + CortetsuTokens.padding.large * 2
                startAngle: -225
                sweepAngle: 270

                Behavior on clampedVal {
                    Anim {}
                }

                ColumnLayout {
                    id: usageColumn

                    anchors.centerIn: parent
                    spacing: 0

                    CortetsuIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hard_drive"
                        color: root.accent
                        fontStyle: CortetsuTokens.font.icon.medium
                    }

                    CortetsuText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(root.percentage * 100) + "%"
                        font: CortetsuTokens.font.title.builders.large.width(90).build()
                        color: root.accent
                    }

                    CortetsuText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Used")
                        font: CortetsuTokens.font.body.small
                        color: CortetsuColours.palette.m3onSurfaceVariant
                    }
                }
            }

            ColumnLayout {
                Layout.minimumWidth: CortetsuTokens.sizes.dashboard.perfStorageTextWidth
                spacing: CortetsuTokens.spacing.extraSmall

                CortetsuText {
                    text: qsTr("Storage")
                    font: CortetsuTokens.font.title.medium
                }

                CortetsuText {
                    text: {
                        if (!Storage.primaryDisk)
                            return qsTr("No disks detected");

                        const fmt = UsageFmt.formatKib(Storage.primaryDisk.used, Storage.primaryDisk.total);
                        return `${+fmt.value.toFixed(1)} / ${+fmt.total.toFixed(1)} ${fmt.unit}`;
                    }
                    font: CortetsuTokens.font.body.large
                    color: root.accent
                }
            }
        }

        SplitButton {
            Layout.alignment: Qt.AlignHCenter

            type: SplitButton.Tonal
            disabled: !Storage.disks.length
            fallbackIcon: "storage"
            fallbackText: qsTr("No disks")
            menuOnTop: true
            minLeftWidth: row.implicitWidth * 0.6

            menuItems: disks.instances
            active: menuItems.find(m => m.modelData === Storage.primaryDisk) ?? menuItems[0] ?? null
            menu.onItemSelected: item => Storage.manualPrimaryDisk = (item as DiskItem).modelData

            Variants {
                id: disks

                model: Storage.disks

                DiskItem {}
            }
        }
    }

    component DiskItem: MenuItem {
        required property var modelData

        icon: modelData === Storage.primaryDisk ? "check" : ""
        text: modelData.mount
        activeIcon: "storage"
    }
}
