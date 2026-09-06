import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    spacing: Tokens.spacing.small

    CortetsuText {
        text: qsTr("Capslock: %1").arg(Hypr.capsLock ? "Enabled" : "Disabled")
    }

    CortetsuText {
        text: qsTr("Numlock: %1").arg(Hypr.numLock ? "Enabled" : "Disabled")
    }
}
