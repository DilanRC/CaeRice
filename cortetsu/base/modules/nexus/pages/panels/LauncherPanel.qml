pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Launcher")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: CortetsuTokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            checked: CortetsuConfig.launcher.enabled
            onToggled: CortetsuConfig.launcher.enabled = checked
        }

        ToggleRow {
            text: qsTr("Show on hover")
            subtext: qsTr("Reveal when the cursor reaches the screen edge")
            checked: CortetsuConfig.launcher.showOnHover
            onToggled: CortetsuConfig.launcher.showOnHover = checked
        }

        TextFieldRow {
            id: prefixRow

            last: true
            label: qsTr("Action prefix")
            subtext: qsTr("Prefix used to run actions in the launcher")
            errorText: qsTr("Prefix must not be alphanumeric")
            value: CortetsuConfig.actionPrefix === ">" ? "" : CortetsuConfig.actionPrefix // TODO: replace with empty only when not loaded once loaded state is exposed
            placeholderText: ">"
            maximumLength: 1
            smallField: true
            validate: /^[^a-zA-Z0-9\s]$/
            onEditingFinished: value => {
                if (!field.valid)
                    return;
                // Empty commits restore the Cortetsu default action prefix.
                CortetsuConfig.actionPrefix = value || ">";
                if (CortetsuConfig.actionPrefix === ">")
                    clear();
            }
        }

        // Display
        SectionHeader {
            text: qsTr("Display")
        }

        StepperRow {
            first: true
            label: qsTr("Max items shown")
            value: CortetsuConfig.launcher.maxShown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => CortetsuConfig.launcher.maxShown = v
        }

        StepperRow {
            label: qsTr("Max wallpapers")
            value: CortetsuConfig.launcher.maxWallpapers
            from: 1
            to: 30
            stepSize: 1
            onMoved: v => CortetsuConfig.launcher.maxWallpapers = v
        }

        StepperRow {
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the launcher opens")
            value: CortetsuConfig.launcher.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => CortetsuConfig.launcher.dragThreshold = v
        }

        // Behaviour
        SectionHeader {
            text: qsTr("Behaviour")
        }

        ToggleRow {
            first: true
            text: qsTr("Vim keybinds")
            subtext: qsTr("Navigate results with Ctrl+hjkl")
            checked: CortetsuConfig.vimKeybinds
            onToggled: CortetsuConfig.vimKeybinds = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Enable dangerous actions")
            subtext: qsTr("Allow actions that shut down or log out")
            checked: CortetsuConfig.enableDangerousActions
            onToggled: CortetsuConfig.enableDangerousActions = checked
        }

        // Fuzzy search
        SectionHeader {
            text: qsTr("Fuzzy search")
        }

        ToggleRow {
            first: true
            text: qsTr("Apps")
            checked: CortetsuConfig.useFuzzyApps
            onToggled: CortetsuConfig.useFuzzyApps = checked
        }

        ToggleRow {
            text: qsTr("Actions")
            checked: CortetsuConfig.useFuzzyActions
            onToggled: CortetsuConfig.useFuzzyActions = checked
        }

        ToggleRow {
            text: qsTr("Schemes")
            checked: CortetsuConfig.useFuzzySchemes
            onToggled: CortetsuConfig.useFuzzySchemes = checked
        }

        ToggleRow {
            text: qsTr("Variants")
            checked: CortetsuConfig.useFuzzyVariants
            onToggled: CortetsuConfig.useFuzzyVariants = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Wallpapers")
            checked: CortetsuConfig.useFuzzyWallpapers
            onToggled: CortetsuConfig.useFuzzyWallpapers = checked
        }
    }
}
