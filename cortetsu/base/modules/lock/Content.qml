import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

RowLayout {
    id: root

    required property var lock

    spacing: CortetsuTokens.spacing.largeIncreased * 2

    ColumnLayout {
        Layout.fillWidth: true
        spacing: CortetsuTokens.spacing.medium

        WeatherInfo {
            Layout.fillWidth: true
            rootHeight: root.height
        }

        Fetch {
            Layout.fillWidth: true
            rootHeight: root.height
        }

        Media {
            Layout.fillWidth: true
            Layout.fillHeight: true
            lock: root.lock
        }
    }

    Center {
        lock: root.lock
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: CortetsuTokens.spacing.medium

        Resources {
            Layout.fillWidth: true
        }

        CortetsuSurface {
            Layout.fillWidth: true
            Layout.fillHeight: true

            bottomRightRadius: CortetsuTokens.rounding.extraLarge
            radius: CortetsuTokens.rounding.medium
            color: CortetsuColours.tPalette.m3surfaceContainer

            NotifDock {
                lock: root.lock
            }
        }
    }
}
