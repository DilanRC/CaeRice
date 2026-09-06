pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import "../../../components"
import "../../CortetsuDesign.js" as CortetsuDesign

Column {
    id: root

    spacing: CortetsuDesign.spacingStandard
    width: 280

    CortetsuSectionHeader {
        title: qsTr("Power")
        detail: UPower.displayDevice.isLaptopBattery ? qsTr("%1% remaining").arg(Math.round(UPower.displayDevice.percentage * 100)) : qsTr("No battery detected")
    }

    CortetsuSurface {
        width: parent.width
        implicitHeight: details.implicitHeight + CortetsuDesign.spacingStandard * 2
        color: CortetsuDesign.colorSurfaceGlass
        radius: CortetsuDesign.radiusLarge

        Column {
            id: details
            anchors.fill: parent
            anchors.margins: CortetsuDesign.spacingStandard
            spacing: CortetsuDesign.spacingCompact

            CortetsuText {
                width: parent.width
                text: UPower.displayDevice.isLaptopBattery ? (UPower.onBattery ? qsTr("Time remaining: %1").arg(formatSeconds(UPower.displayDevice.timeToEmpty)) : qsTr("Time until charged: %1").arg(formatSeconds(UPower.displayDevice.timeToFull))) : qsTr("Power profile: %1").arg(PowerProfile.toString(PowerProfiles.profile))
                color: CortetsuDesign.colorOnSurfaceVariant

                function formatSeconds(seconds: int): string {
                    if (seconds <= 0)
                        return qsTr("Calculating...");
                    const hours = Math.floor(seconds / 3600);
                    const minutes = Math.floor(seconds / 60) % 60;
                    return hours > 0 ? qsTr("%1h %2m").arg(hours).arg(minutes) : qsTr("%1m").arg(minutes);
                }
            }

            CortetsuText {
                visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
                width: parent.width
                text: qsTr("Performance limited: %1").arg(PerformanceDegradationReason.toString(PowerProfiles.degradationReason))
                color: CortetsuDesign.colorVermillion
                wrapMode: Text.WordWrap
            }
        }
    }

    CortetsuSectionHeader {
        title: qsTr("Profile")
        detail: PowerProfile.toString(PowerProfiles.profile)
    }

    Row {
        spacing: CortetsuDesign.spacingCompact
        anchors.horizontalCenter: parent.horizontalCenter

        ProfileButton { profile: PowerProfile.PowerSaver; icon: "energy_savings_leaf"; label: qsTr("Saver") }
        ProfileButton { profile: PowerProfile.Balanced; icon: "balance"; label: qsTr("Balanced") }
        ProfileButton { profile: PowerProfile.Performance; icon: "rocket_launch"; label: qsTr("Performance") }
    }

    component ProfileButton: Item {
        required property int profile
        required property string icon
        required property string label
        implicitWidth: 76
        implicitHeight: 64

        CortetsuSurface {
            anchors.fill: parent
            color: PowerProfiles.profile === parent.profile ? CortetsuDesign.colorPrimaryContainer : CortetsuDesign.colorSurfaceGlass
            radius: CortetsuDesign.radiusMedium
            outlined: true
        }
        CortetsuStateLayer {
            anchors.fill: parent
            radius: CortetsuDesign.radiusMedium
            onClicked: PowerProfiles.profile = parent.profile
        }
        Column {
            anchors.centerIn: parent
            spacing: 2
            CortetsuIcon { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.icon; color: CortetsuDesign.colorPrimary }
            CortetsuText { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.label }
        }
    }
}
