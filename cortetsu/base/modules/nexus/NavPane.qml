import "navpane"
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property NexusState nState

    spacing: CortetsuTokens.spacing.large

    SearchBar {
        id: searchField

        Layout.fillWidth: true

        placeholderText: qsTr("Search settings")
        font: CortetsuTokens.font.body.large

        bg.color: CortetsuColours.tPalette.m3surfaceContainerLowest
        bg.border.color: CortetsuColours.palette.m3outlineVariant
        searchIcon.fontStyle: CortetsuTokens.font.icon.medium
        searchIcon.anchors.leftMargin: CortetsuTokens.padding.largeIncreased
        clearIcon.font: CortetsuTokens.font.icon.medium
        clearIcon.padding: CortetsuTokens.padding.extraSmall

        Behavior on bg.border.color {
            CAnim {}
        }

        Binding {
            target: root.nState
            property: "searchOpen"
            value: searchField.text.length > 0
        }
    }

    NavLocations {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: -topMargin
        Layout.bottomMargin: -bottomMargin
        nState: root.nState
    }
}
