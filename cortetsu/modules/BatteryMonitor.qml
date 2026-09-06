import QtQuick
import Quickshell
import Quickshell.Services.UPower

Scope {
    id: root

    property real lastPercentage: 100
    property bool criticalNoticeSent: false

    function notify(title: string, message: string): void {
        Quickshell.execDetached(["notify-send", "--app-name=Cortetsu", title, message]);
    }

    function inspect(): void {
        if (!UPower.displayDevice.ready)
            return;
        const percentage = UPower.displayDevice.percentage * 100;
        if (!UPower.onBattery) {
            lastPercentage = percentage;
            criticalNoticeSent = false;
            return;
        }
        if (percentage <= 10 && lastPercentage > 10)
            notify(qsTr("Battery low"), qsTr("Battery level is %1%").arg(Math.round(percentage)));
        if (percentage <= 3 && !criticalNoticeSent) {
            criticalNoticeSent = true;
            notify(qsTr("Critical battery"), qsTr("Hibernating to prevent data loss"));
            hibernateTimer.start();
        }
        lastPercentage = percentage;
    }

    Connections {
        target: UPower
        function onOnBatteryChanged(): void { root.inspect(); }
    }
    Connections {
        target: UPower.displayDevice
        function onReadyChanged(): void { root.inspect(); }
        function onPercentageChanged(): void { root.inspect(); }
    }
    Timer {
        id: hibernateTimer
        interval: 5000
        onTriggered: Quickshell.execDetached(["systemctl", "hibernate"])
    }
}
