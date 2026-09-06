import "performance"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Services
import qs.components
import qs.modules
import qs.services

Item {
    id: root

    implicitWidth: placeholder.active ? Tokens.sizes.dashboard.perfPlaceholderWidth : content.implicitWidth
    implicitHeight: placeholder.active ? placeholder.implicitHeight + Tokens.padding.extraLarge * 2 : content.implicitHeight

    Loader {
        id: placeholder

        anchors.centerIn: parent
        active: !CortetsuConfig.dashboard.performance.showCpu && !(CortetsuConfig.dashboard.performance.showGpu && Gpu.type !== GpuType.None) && !CortetsuConfig.dashboard.performance.showMemory && !CortetsuConfig.dashboard.performance.showStorage && !CortetsuConfig.dashboard.performance.showNetwork && !(UPower.displayDevice.isLaptopBattery && CortetsuConfig.dashboard.performance.showBattery)
        asynchronous: true

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.medium

            CortetsuIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "tune"
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                color: Colours.palette.m3onSurfaceVariant
            }

            CortetsuText {
                Layout.topMargin: -Tokens.spacing.small
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("No widgets enabled")
                font: Tokens.font.title.large
                color: Colours.palette.m3onSurface
            }

            CortetsuText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Enable widgets in the dashboard settings")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium
        visible: !placeholder.active

        ColumnLayout {
            id: mainColumn

            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            RowLayout {
                spacing: Tokens.spacing.medium
                visible: cpuCard.active || gpuCard.active

                WrappedLoader {
                    id: cpuCard

                    active: CortetsuConfig.dashboard.performance.showCpu

                    sourceComponent: HeroCard {
                        icon: "memory"
                        label: qsTr("CPU")
                        subLabel: Cpu.name
                        usage: Cpu.percentage
                        temperature: Cpu.temperature
                        accent: Colours.palette.m3primary

                        ServiceRef {
                            service: Cpu
                        }
                    }
                }

                WrappedLoader {
                    id: gpuCard

                    active: CortetsuConfig.dashboard.performance.showGpu && Gpu.type !== GpuType.None

                    sourceComponent: HeroCard {
                        icon: "desktop_windows"
                        label: qsTr("GPU")
                        subLabel: Gpu.name
                        usage: Gpu.percentage
                        temperature: Gpu.temperature
                        accent: Colours.palette.m3secondary

                        ServiceRef {
                            service: Gpu
                        }
                    }
                }
            }

            RowLayout {
                spacing: Tokens.spacing.medium
                visible: storageCard.active || networkCard.active || memoryCard.active

                WrappedLoader {
                    id: storageCard

                    active: CortetsuConfig.dashboard.performance.showStorage
                    sourceComponent: StorageCard {}
                }

                WrappedLoader {
                    id: networkCard

                    active: CortetsuConfig.dashboard.performance.showNetwork
                    sourceComponent: NetworkCard {}
                }

                WrappedLoader {
                    id: memoryCard

                    active: CortetsuConfig.dashboard.performance.showMemory
                    sourceComponent: MemoryCard {}
                }
            }
        }

        WrappedLoader {
            Layout.fillWidth: false
            active: UPower.displayDevice.isLaptopBattery && CortetsuConfig.dashboard.performance.showBattery
            sourceComponent: BatteryTank {}
        }
    }

    component WrappedLoader: Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: active
    }
}
