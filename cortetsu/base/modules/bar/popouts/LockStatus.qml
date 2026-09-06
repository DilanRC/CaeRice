import QtQuick.Layouts
import qs.components
import qs.services

ColumnLayout {
    spacing: CortetsuTokens.spacing.small

    CortetsuText {
        text: qsTr("Capslock: %1").arg(Hypr.capsLock ? "Enabled" : "Disabled")
    }

    CortetsuText {
        text: qsTr("Numlock: %1").arg(Hypr.numLock ? "Enabled" : "Disabled")
    }
}
